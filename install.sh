#!/bin/bash
# Claude Code macOS Sound Hooks - 安装脚本
# 基于 https://github.com/ChanMeng666/claude-code-audio-hooks 原理实现
# 简化版：直接使用 macOS 系统声音，无需额外依赖

set -e

echo "🐟 Claude Code macOS Sound Hooks 安装程序"
echo "=========================================="

# 定义路径
HOOKS_DIR="$HOME/.claude/hooks"
CONFIG_DIR="$HOME/.claude/claude-code-macos-sound-hooks"
CONFIG_FILE="$CONFIG_DIR/config.json"

# 创建目录
echo "📁 创建目录..."
mkdir -p "$HOOKS_DIR"
mkdir -p "$CONFIG_DIR"

# 创建/读取配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📝 创建默认配置文件..."
    cat > "$CONFIG_FILE" << 'EOF'
{
  "_comment": "Claude Code macOS Sound Hooks 配置文件",
  "_help": "将 enabled 设为 false 可禁用对应声音通知",
  "hooks": {
    "stop": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Sosumi.aiff",
      "description": "任务完成时播放"
    },
    "notification": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Basso.aiff",
      "description": "需要授权时播放"
    },
    "subagent_stop": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Ping.aiff",
      "description": "子任务完成时播放"
    },
    "permission_request": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Frog.aiff",
      "description": "权限请求时播放"
    }
  },
  "global": {
    "enabled": true,
    "_comment": "设为 false 可临时禁用所有声音通知"
  }
}
EOF
else
    echo "📝 使用现有配置文件..."
fi

# 读取配置的函数
is_hook_enabled() {
    local hook_name="$1"
    if command -v jq &>/dev/null; then
        jq -r ".hooks.${hook_name}.enabled // true" "$CONFIG_FILE"
    else
        # 没有 jq 时默认启用
        echo "true"
    fi
}

is_global_enabled() {
    if command -v jq &>/dev/null; then
        jq -r ".global.enabled // true" "$CONFIG_FILE"
    else
        echo "true"
    fi
}

# 检查全局开关
GLOBAL_ENABLED=$(is_global_enabled)
if [ "$GLOBAL_ENABLED" != "true" ]; then
    echo "⚠️  全局声音通知已禁用，所有 Hook 将不会播放声音"
fi

# 创建 hook 脚本
echo "📝 创建 Hook 脚本..."

# 1. stop_hook.sh - 任务完成时播放声音
STOP_ENABLED=$(is_hook_enabled "stop")
if [ "$STOP_ENABLED" = "true" ] && [ "$GLOBAL_ENABLED" = "true" ]; then
    cat > "$HOOKS_DIR/stop_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Stop Hook - 任务完成时播放声音
# 使用 macOS 系统声音：Sosumi (经典完成提示音)

# 检测是否在终端中运行（避免在 IDE 中误触发）
if [[ -t 1 ]]; then
    afplay /System/Library/Sounds/Sosumi.aiff &>/dev/null &
fi
EOF
    echo "  ✅ stop_hook: 已启用 (Sosumi)"
else
    # 创建空脚本或禁用脚本
    cat > "$HOOKS_DIR/stop_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Stop Hook - 已禁用
exit 0
EOF
    echo "  ⏸️  stop_hook: 已禁用"
fi

# 2. notification_hook.sh - 需要授权时播放声音
NOTIFICATION_ENABLED=$(is_hook_enabled "notification")
if [ "$NOTIFICATION_ENABLED" = "true" ] && [ "$GLOBAL_ENABLED" = "true" ]; then
    cat > "$HOOKS_DIR/notification_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Notification Hook - 需要授权时播放声音
# 使用 macOS 系统声音：Basso (警告音)

# 检测是否在终端中运行
if [[ -t 1 ]]; then
    afplay /System/Library/Sounds/Basso.aiff &>/dev/null &
fi
EOF
    echo "  ✅ notification_hook: 已启用 (Basso)"
else
    cat > "$HOOKS_DIR/notification_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Notification Hook - 已禁用
exit 0
EOF
    echo "  ⏸️  notification_hook: 已禁用"
fi

# 3. subagent_stop_hook.sh - 子代理任务完成
SUBAGENT_ENABLED=$(is_hook_enabled "subagent_stop")
if [ "$SUBAGENT_ENABLED" = "true" ] && [ "$GLOBAL_ENABLED" = "true" ]; then
    cat > "$HOOKS_DIR/subagent_stop_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Subagent Stop Hook - 子任务完成时播放声音
# 使用 macOS 系统声音：Ping (清脆提示音)

if [[ -t 1 ]]; then
    afplay /System/Library/Sounds/Ping.aiff &>/dev/null &
fi
EOF
    echo "  ✅ subagent_stop_hook: 已启用 (Ping)"
else
    cat > "$HOOKS_DIR/subagent_stop_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Subagent Stop Hook - 已禁用
exit 0
EOF
    echo "  ⏸️  subagent_stop_hook: 已禁用"
fi

# 4. permission_request_hook.sh - 权限请求时播放声音
PERMISSION_ENABLED=$(is_hook_enabled "permission_request")
if [ "$PERMISSION_ENABLED" = "true" ] && [ "$GLOBAL_ENABLED" = "true" ]; then
    cat > "$HOOKS_DIR/permission_request_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Permission Request Hook - 权限请求时播放声音
# 使用 macOS 系统声音：Frog (青蛙声，引起注意)

if [[ -t 1 ]]; then
    afplay /System/Library/Sounds/Frog.aiff &>/dev/null &
fi
EOF
    echo "  ✅ permission_request_hook: 已启用 (Frog)"
else
    cat > "$HOOKS_DIR/permission_request_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Permission Request Hook - 已禁用
exit 0
EOF
    echo "  ⏸️  permission_request_hook: 已禁用"
fi

# 设置执行权限
echo "🔧 设置权限..."
chmod +x "$HOOKS_DIR"/*.sh

# 创建配置说明文件
cat > "$SOUND_HOOKS_DIR/README.md" << 'EOF'
# Claude Code macOS Sound Hooks

基于 [claude-code-audio-hooks](https://github.com/ChanMeng666/claude-code-audio-hooks) 原理的简化实现。

## 功能

| Hook 类型 | 触发时机 | 系统声音 |
|----------|---------|---------|
| stop_hook | 任务完成 | Sosumi (经典完成音) |
| notification_hook | 需要授权 | Basso (警告音) |
| subagent_stop_hook | 子任务完成 | Ping (清脆提示音) |
| permission_request_hook | 权限请求 | Frog (青蛙声) |

## 自定义声音

编辑 `~/.claude/hooks/*.sh` 文件，修改 `afplay` 命令后的声音文件路径。

macOS 系统声音位于：`/System/Library/Sounds/`

可用声音：
- Sosumi.aiff (默认完成音)
- Basso.aiff (警告音)
- Ping.aiff (清脆音)
- Frog.aiff (青蛙声)
- Pop.aiff
- Glass.aiff
- Hero.aiff
- Morse.aiff
- Submarine.aiff
- etc.

## 禁用某个 Hook

```bash
chmod -x ~/.claude/hooks/stop_hook.sh  # 禁用任务完成提示
chmod +x ~/.claude/hooks/stop_hook.sh  # 启用
```

## 卸载

```bash
rm -rf ~/.claude/hooks/*.sh
rm -rf ~/.claude/claude-code-macos-sound-hooks
```
EOF

# 测试
echo ""
echo "🎵 测试声音..."
afplay /System/Library/Sounds/Sosumi.aiff &>/dev/null &
echo "✅ 如果听到提示音，说明安装成功！"

echo ""
echo "=========================================="
echo "✅ 安装完成！"
echo ""
echo "📍 Hook 文件位置：$HOOKS_DIR"
echo "📖 说明文档：$SOUND_HOOKS_DIR/README.md"
echo ""
echo "🔄 请重启 Claude Code 以启用声音通知"
echo ""
echo "可用声音预览:"
echo "  - Sosumi: 任务完成 (stop_hook)"
echo "  - Basso:  需要授权 (notification_hook)"
echo "  - Ping:   子任务完成 (subagent_stop_hook)"
echo "  - Frog:   权限请求 (permission_request_hook)"
echo ""
