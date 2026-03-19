#!/bin/bash
# Claude Code macOS Sound Hooks - 安装脚本
# 基于 https://github.com/ChanMeng666/claude-code-audio-hooks 原理实现
# 简化版：直接使用 macOS 系统声音，无需额外依赖

set -e

echo "🐟 Claude Code macOS Sound Hooks 安装程序"
echo "=========================================="

# 定义路径
HOOKS_DIR="$HOME/.claude/hooks"
SOUND_HOOKS_DIR="$HOME/.claude/claude-code-macos-sound-hooks"

# 创建目录
echo "📁 创建目录..."
mkdir -p "$HOOKS_DIR"
mkdir -p "$SOUND_HOOKS_DIR"

# 创建 hook 脚本
echo "📝 创建 Hook 脚本..."

# 1. stop_hook.sh - 任务完成时播放声音
cat > "$HOOKS_DIR/stop_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Stop Hook - 任务完成时播放声音
# 使用 macOS 系统声音：Sosumi (经典完成提示音)

# 检测是否在终端中运行（避免在 IDE 中误触发）
if [[ -t 1 ]]; then
    afplay /System/Library/Sounds/Sosumi.aiff &>/dev/null &
fi
EOF

# 2. notification_hook.sh - 需要授权时播放声音
cat > "$HOOKS_DIR/notification_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Notification Hook - 需要授权时播放声音
# 使用 macOS 系统声音：Basso (警告音)

# 检测是否在终端中运行
if [[ -t 1 ]]; then
    afplay /System/Library/Sounds/Basso.aiff &>/dev/null &
fi
EOF

# 3. subagent_stop_hook.sh - 子代理任务完成
cat > "$HOOKS_DIR/subagent_stop_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Subagent Stop Hook - 子任务完成时播放声音
# 使用 macOS 系统声音：Ping (清脆提示音)

if [[ -t 1 ]]; then
    afplay /System/Library/Sounds/Ping.aiff &>/dev/null &
fi
EOF

# 4. permission_request_hook.sh - 权限请求时播放声音
cat > "$HOOKS_DIR/permission_request_hook.sh" << 'EOF'
#!/bin/bash
# Claude Code Permission Request Hook - 权限请求时播放声音
# 使用 macOS 系统声音：Frog (青蛙声，引起注意)

if [[ -t 1 ]]; then
    afplay /System/Library/Sounds/Frog.aiff &>/dev/null &
fi
EOF

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
