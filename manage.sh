#!/bin/bash
# Claude Code macOS Sound Hooks - 管理脚本
# 用于快速启用/禁用声音通知

CONFIG_DIR="$HOME/.claude/claude-code-sounds"
CONFIG_FILE="$CONFIG_DIR/config.json"
HOOKS_DIR="$HOME/.claude/hooks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 有效的 hook 名称列表
VALID_HOOKS=("stop" "notification" "subagent_stop" "pre_tool_use" "global")

# 确保配置目录存在
mkdir -p "$CONFIG_DIR"

# 如果配置文件不存在，创建默认配置
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "hooks": {
    "stop": { "enabled": true, "sound": "/System/Library/Sounds/Glass.aiff" },
    "notification": { "enabled": true, "sound": "/System/Library/Sounds/Basso.aiff" },
    "subagent_stop": { "enabled": true, "sound": "/System/Library/Sounds/Glass.aiff" },
    "pre_tool_use": { "enabled": true, "sound": "/System/Library/Sounds/Pop.aiff" }
  },
  "global": { "enabled": true }
}
EOF
fi

# 校验 hook 名称是否合法
is_valid_hook() {
    local hook="$1"
    for valid in "${VALID_HOOKS[@]}"; do
        if [ "$valid" = "$hook" ]; then
            return 0
        fi
    done
    return 1
}

# 显示帮助
show_help() {
    echo "🐟 Claude Code Sound Hooks 管理器"
    echo ""
    echo "用法：$0 <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  status              查看当前配置状态"
    echo "  enable <hook>       启用某个声音通知"
    echo "  disable <hook>      禁用某个声音通知"
    echo "  toggle <hook>       切换某个声音通知状态"
    echo "  all-on              启用所有声音通知"
    echo "  all-off             禁用所有声音通知"
    echo "  edit                编辑配置文件"
    echo ""
    echo "Hook 名称:"
    echo "  stop                任务完成提示 (Glass)"
    echo "  notification        需要关注提示 (Basso)"
    echo "  subagent_stop       子任务完成提示 (Glass)"
    echo "  pre_tool_use        权限请求提示 (Pop)"
    echo "  global              全局开关"
    echo ""
    echo "示例:"
    echo "  $0 status                    # 查看状态"
    echo "  $0 disable stop              # 禁用任务完成提示"
    echo "  $0 enable notification       # 启用授权请求提示"
    echo "  $0 all-off                   # 关闭所有声音"
    echo "  $0 toggle global             # 切换全局开关"
}

# 显示当前状态
show_status() {
    echo "🐟 Claude Code Sound Hooks 状态"
    echo "================================"
    
    if command -v jq &>/dev/null; then
        echo ""
        echo "全局开关：$(jq -r '.global.enabled' "$CONFIG_FILE" 2>/dev/null || echo 'true')"
        echo ""
        echo "各 Hook 状态:"
        echo "  stop                : $(jq -r '.hooks.stop.enabled' "$CONFIG_FILE" 2>/dev/null || echo 'true')"
        echo "  notification        : $(jq -r '.hooks.notification.enabled' "$CONFIG_FILE" 2>/dev/null || echo 'true')"
        echo "  subagent_stop       : $(jq -r '.hooks.subagent_stop.enabled' "$CONFIG_FILE" 2>/dev/null || echo 'true')"
        echo "  pre_tool_use        : $(jq -r '.hooks.pre_tool_use.enabled' "$CONFIG_FILE" 2>/dev/null || echo 'true')"
    else
        echo ""
        echo "⚠️  未安装 jq，无法读取详细配置"
        echo "   安装：brew install jq"
    fi
    echo ""
    echo "配置文件：$CONFIG_FILE"
    echo ""
    echo "💡 提示：运行 '$0 enable/disable <hook>' 来修改配置"
}

# 设置 Hook 状态
set_hook() {
    local hook_name="$1"
    local enabled="$2"
    
    # 参数校验
    if [ -z "$hook_name" ]; then
        echo "❌ 请指定 hook 名称"
        echo "   用法：$0 enable <hook>"
        exit 1
    fi
    
    if ! is_valid_hook "$hook_name"; then
        echo "❌ 无效的 hook 名称：$hook_name"
        echo "   有效值：${VALID_HOOKS[*]}"
        exit 1
    fi
    
    if ! command -v jq &>/dev/null; then
        echo "❌ 错误：需要安装 jq"
        echo "   运行：brew install jq"
        exit 1
    fi
    
    # 更新配置
    local tmp_file=$(mktemp)
    trap "rm -f $tmp_file" EXIT
    if [ "$hook_name" = "global" ]; then
        jq ".global.enabled = $enabled" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    else
        jq ".hooks.${hook_name}.enabled = $enabled" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    fi
    
    if [ "$enabled" = "true" ]; then
        echo "✅ 已启用 $hook_name"
    else
        echo "⏸️  已禁用 $hook_name"
    fi
    
    # 重新应用配置（重新安装）
    echo "🔄 应用配置..."
    bash "$SCRIPT_DIR/install.sh"
}

# 切换 Hook 状态
toggle_hook() {
    local hook_name="$1"
    
    if [ -z "$hook_name" ]; then
        echo "❌ 请指定 hook 名称"
        exit 1
    fi
    
    if ! is_valid_hook "$hook_name"; then
        echo "❌ 无效的 hook 名称：$hook_name"
        exit 1
    fi
    
    if ! command -v jq &>/dev/null; then
        echo "❌ 错误：需要安装 jq"
        exit 1
    fi
    
    local current
    if [ "$hook_name" = "global" ]; then
        current=$(jq -r '.global.enabled' "$CONFIG_FILE")
    else
        current=$(jq -r ".hooks.${hook_name}.enabled" "$CONFIG_FILE")
    fi
    
    local new_value
    if [ "$current" = "true" ]; then
        new_value="false"
        echo "⏸️  禁用 $hook_name"
    else
        new_value="true"
        echo "✅ 启用 $hook_name"
    fi
    
    set_hook "$hook_name" "$new_value"
}

# 全部启用/禁用
all_hooks() {
    local enabled="$1"
    
    if ! command -v jq &>/dev/null; then
        echo "❌ 错误：需要安装 jq"
        exit 1
    fi
    
    local tmp_file=$(mktemp)
    trap "rm -f $tmp_file" EXIT
    jq ".global.enabled = $enabled | .hooks.stop.enabled = $enabled | .hooks.notification.enabled = $enabled | .hooks.subagent_stop.enabled = $enabled | .hooks.pre_tool_use.enabled = $enabled" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    
    if [ "$enabled" = "true" ]; then
        echo "✅ 已启用所有声音通知"
    else
        echo "⏸️  已禁用所有声音通知"
    fi
    bash "$SCRIPT_DIR/install.sh"
}

# 主逻辑
case "${1:-}" in
    status)
        show_status
        ;;
    enable)
        set_hook "${2:-}" "true"
        ;;
    disable)
        set_hook "${2:-}" "false"
        ;;
    toggle)
        toggle_hook "${2:-}"
        ;;
    all-on)
        all_hooks "true"
        ;;
    all-off)
        all_hooks "false"
        ;;
    edit)
        ${EDITOR:-nano} "$CONFIG_FILE"
        bash "$SCRIPT_DIR/install.sh"
        ;;
    -h|--help|help|"")
        show_help
        ;;
    *)
        echo "❌ 未知命令：$1"
        echo ""
        show_help
        exit 1
        ;;
esac
