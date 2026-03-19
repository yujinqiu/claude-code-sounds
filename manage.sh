#!/bin/bash
# Claude Code macOS Sound Hooks - 管理脚本
# 用于快速启用/禁用声音通知

CONFIG_DIR="$HOME/.claude/claude-code-macos-sound-hooks"
CONFIG_FILE="$CONFIG_DIR/config.json"
HOOKS_DIR="$HOME/.claude/hooks"

# 确保配置目录存在
mkdir -p "$CONFIG_DIR"

# 如果配置文件不存在，创建默认配置
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "hooks": {
    "stop": { "enabled": true, "sound": "/System/Library/Sounds/Sosumi.aiff" },
    "notification": { "enabled": true, "sound": "/System/Library/Sounds/Basso.aiff" },
    "subagent_stop": { "enabled": true, "sound": "/System/Library/Sounds/Ping.aiff" },
    "permission_request": { "enabled": true, "sound": "/System/Library/Sounds/Frog.aiff" }
  },
  "global": { "enabled": true }
}
EOF
fi

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
    echo "  stop                任务完成提示 (Sosumi)"
    echo "  notification        授权请求提示 (Basso)"
    echo "  subagent_stop       子任务完成提示 (Ping)"
    echo "  permission_request  权限请求提示 (Frog)"
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
        echo "  permission_request  : $(jq -r '.hooks.permission_request.enabled' "$CONFIG_FILE" 2>/dev/null || echo 'true')"
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
    
    if ! command -v jq &>/dev/null; then
        echo "❌ 错误：需要安装 jq"
        echo "   运行：brew install jq"
        exit 1
    fi
    
    # 更新配置
    local tmp_file=$(mktemp)
    if [ "$hook_name" = "global" ]; then
        jq ".global.enabled = $enabled" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    else
        jq ".hooks.${hook_name}.enabled = $enabled" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    fi
    
    echo "✅ 已${enabled} $hook_name"
    
    # 重新应用配置（重新安装）
    echo "🔄 应用配置..."
    bash "$(dirname "$0")/install.sh"
}

# 切换 Hook 状态
toggle_hook() {
    local hook_name="$1"
    
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
    jq ".global.enabled = $enabled | .hooks.stop.enabled = $enabled | .hooks.notification.enabled = $enabled | .hooks.subagent_stop.enabled = $enabled | .hooks.permission_request.enabled = $enabled" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    
    echo "✅ 已${enabled}所有声音通知"
    bash "$(dirname "$0")/install.sh"
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
        bash "$(dirname "$0")/install.sh"
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
