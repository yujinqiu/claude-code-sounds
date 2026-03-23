#!/bin/bash
# Claude Code macOS Sound Hooks - 安装脚本
# 在 macOS 上为 Claude Code 的关键事件添加系统声音通知
# 核心原理：在 ~/.claude/settings.json 中注册 hooks，指向播放声音的脚本

set -e

echo "🐟 Claude Code macOS Sound Hooks 安装程序"
echo "=========================================="

# ── 路径定义 ──────────────────────────────────────────────

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CONFIG_DIR="$CLAUDE_DIR/claude-code-sounds"
CONFIG_FILE="$CONFIG_DIR/config.json"

# ── 前置检查 ──────────────────────────────────────────────

if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ 此脚本仅支持 macOS (需要 afplay 命令)"
    exit 1
fi

mkdir -p "$HOOKS_DIR"
mkdir -p "$CONFIG_DIR"

# ── 配置文件 ──────────────────────────────────────────────

if [ ! -f "$CONFIG_FILE" ]; then
    echo "📝 创建默认配置文件..."
    cat > "$CONFIG_FILE" << 'CONF'
{
  "_comment": "Claude Code macOS Sound Hooks 配置文件",
  "_help": "将 enabled 设为 false 可禁用对应声音; sound 可改为任意 .aiff 路径",
  "hooks": {
    "stop": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Glass.aiff",
      "description": "任务完成时播放"
    },
    "notification": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Bottle.aiff",
      "description": "需要用户关注时播放"
    },
    "subagent_stop": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Tink.aiff",
      "description": "子任务完成时播放"
    },
    "pre_tool_use": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Submarine.aiff",
      "description": "权限请求时播放"
    }
  },
  "global": {
    "enabled": true
  }
}
CONF
else
    echo "📝 使用现有配置文件: $CONFIG_FILE"
fi

# ── 配置读取函数 ──────────────────────────────────────────

read_config() {
    local jq_expr="$1"
    local default="$2"
    if command -v jq &>/dev/null; then
        jq -r "$jq_expr // \"$default\"" "$CONFIG_FILE"
    else
        echo "$default"
    fi
}

GLOBAL_ENABLED=$(read_config '.global.enabled' 'true')
if [ "$GLOBAL_ENABLED" != "true" ]; then
    echo "⚠️  全局声音已禁用 (config.json → global.enabled = false)"
fi

# ── 创建 Hook 脚本 ────────────────────────────────────────
# 每个脚本运行时读取 config.json，支持热更新配置

echo "📝 创建 Hook 脚本..."

# 通用播放脚本：读取配置 → 检查开关 → 播放声音
create_hook_script() {
    local hook_name="$1"
    local default_sound="$2"
    local script_path="$HOOKS_DIR/${hook_name}_hook.sh"

    cat > "$script_path" << SCRIPT
#!/bin/bash
# Claude Code Hook: $hook_name
# 运行时从 config.json 读取配置，支持热更新

CONFIG="$CONFIG_DIR/config.json"

# 无 jq 时使用默认值
if command -v jq &>/dev/null && [ -f "\$CONFIG" ]; then
    GLOBAL=\$(jq -r '.global.enabled // true' "\$CONFIG")
    ENABLED=\$(jq -r '.hooks.$hook_name.enabled // true' "\$CONFIG")
    SOUND=\$(jq -r '.hooks.$hook_name.sound // "$default_sound"' "\$CONFIG")
else
    GLOBAL=true
    ENABLED=true
    SOUND="$default_sound"
fi

[ "\$GLOBAL" = "true" ] && [ "\$ENABLED" = "true" ] && afplay "\$SOUND" &>/dev/null &
exit 0
SCRIPT

    chmod +x "$script_path"
    echo "  ✅ ${hook_name}_hook.sh"
}

create_hook_script "stop"          "/System/Library/Sounds/Glass.aiff"
create_hook_script "notification"  "/System/Library/Sounds/Bottle.aiff"
create_hook_script "subagent_stop" "/System/Library/Sounds/Tink.aiff"
create_hook_script "pre_tool_use"  "/System/Library/Sounds/Submarine.aiff"

# ── 注册到 settings.json (关键步骤!) ─────────────────────
# Claude Code 只执行 settings.json 中声明的 hooks，不会自动扫描目录

echo "⚙️  注册 Hooks 到 Claude Code settings.json..."

HOOKS_JSON=$(cat << 'HOOKDEF'
{
  "Stop": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "bash ~/.claude/hooks/stop_hook.sh"
        }
      ]
    }
  ],
  "Notification": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "bash ~/.claude/hooks/notification_hook.sh"
        }
      ]
    }
  ],
  "SubagentStop": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "bash ~/.claude/hooks/subagent_stop_hook.sh"
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "bash ~/.claude/hooks/pre_tool_use_hook.sh"
        }
      ]
    }
  ]
}
HOOKDEF
)

# 合并到现有 settings.json (不覆盖其他配置)
if [ -f "$SETTINGS_FILE" ]; then
    echo "  📄 发现现有 settings.json，合并 hooks 配置..."

    if command -v jq &>/dev/null; then
        # jq 可用：精确合并
        MERGED=$(jq --argjson hooks "$HOOKS_JSON" '.hooks = ($hooks * (.hooks // {}))' "$SETTINGS_FILE")
        echo "$MERGED" > "$SETTINGS_FILE"
    else
        # 无 jq：使用 Python (macOS 自带)
        python3 -c "
import json, sys

with open('$SETTINGS_FILE', 'r') as f:
    settings = json.load(f)

hooks = json.loads('''$HOOKS_JSON''')
existing_hooks = settings.get('hooks', {})
hooks.update(existing_hooks)
settings['hooks'] = hooks

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
    fi
else
    echo "  📄 创建新的 settings.json..."
    if command -v jq &>/dev/null; then
        echo "{}" | jq --argjson hooks "$HOOKS_JSON" '. + {hooks: $hooks}' > "$SETTINGS_FILE"
    else
        python3 -c "
import json
settings = {'hooks': json.loads('''$HOOKS_JSON''')}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
    fi
fi

echo "  ✅ Hooks 已注册到 settings.json"

# ── 测试 ──────────────────────────────────────────────────

echo ""
echo "🎵 测试声音..."
afplay /System/Library/Sounds/Sosumi.aiff &>/dev/null &
echo "  (如果听到提示音，说明系统声音正常)"

# ── 完成 ──────────────────────────────────────────────────

echo ""
echo "=========================================="
echo "✅ 安装完成！"
echo ""
echo "📍 Hook 脚本: $HOOKS_DIR/"
echo "⚙️  注册配置: $SETTINGS_FILE (hooks 字段)"
echo "🎛️  声音配置: $CONFIG_FILE"
echo ""
echo "声音事件:"
echo "  Stop          → Glass      (任务完成)"
echo "  Notification  → Bottle       (需要关注)"
echo "  SubagentStop  → Tink       (子任务完成)"
echo "  PreToolUse    → Submarine  (权限请求)"
echo ""
echo "🔄 请重启 Claude Code 以生效"
echo ""
