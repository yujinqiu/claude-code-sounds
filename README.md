# Claude Code Sound Hooks 实现原理

## 参考项目

基于开源项目实现：
- **claude-code-audio-hooks**: https://github.com/ChanMeng666/claude-code-audio-hooks (28⭐)
- **claude-code-notification**: https://github.com/wyattjoh/claude-code-notification (59⭐)

---

## 核心原理

### 1. Claude Code Hooks 机制

Claude Code CLI 支持 **Hook 系统**，在特定事件发生时自动执行 `~/.claude/hooks/` 目录下的脚本：

```
~/.claude/hooks/
├── stop_hook.sh              # 任务完成/停止时触发
├── notification_hook.sh      # 需要用户授权/通知时触发
├── subagent_stop_hook.sh     # 子代理任务完成时触发
├── permission_request_hook.sh # 请求权限时触发
├── session_start_hook.sh     # 会话开始时触发
├── session_end_hook.sh       # 会话结束时触发
└── ...
```

### 2. 工作流程

```
┌─────────────┐    触发事件    ┌──────────────┐   执行脚本   ┌─────────────┐
│  Claude Code │ ────────────> │  Hook 系统    │ ──────────> │  播放声音    │
│   CLI       │               │ ~/.claude/   │             │  afplay     │
│             │               │ hooks/*.sh   │             │             │
└─────────────┘               └──────────────┘             └─────────────┘
```

### 3. 事件类型

| Hook 文件名 | 触发时机 | 示例场景 |
|------------|---------|---------|
| `stop_hook.sh` | Claude 完成响应 | "分析完代码了" |
| `notification_hook.sh` | 需要用户注意 | "需要授权执行命令" |
| `subagent_stop_hook.sh` | 后台子任务完成 | "子代理分析完毕" |
| `permission_request_hook.sh` | 请求权限 | "允许执行这个命令吗？" |

---

## 实现细节

### 基础版本 (最简单)

```bash
#!/bin/bash
# ~/.claude/hooks/stop_hook.sh

# 播放 macOS 系统声音
afplay /System/Library/Sounds/Sosumi.aiff
```

### 进阶版本 (带终端检测)

```bash
#!/bin/bash
# ~/.claude/hooks/stop_hook.sh

# 检测是否在终端中运行（避免在 IDE/编辑器中误触发）
if [[ -t 1 ]]; then
    # 后台播放，不阻塞
    afplay /System/Library/Sounds/Sosumi.aiff &>/dev/null &
fi
```

### 完整版本 (参考开源项目)

```bash
#!/bin/bash
# ~/.claude/hooks/stop_hook.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared/hook_config.sh"

# 从配置读取音频文件，支持自定义
get_and_play_audio "stop" "task-complete.mp3"
```

---

## macOS 系统声音

位置：`/System/Library/Sounds/`

```bash
# 列出所有可用声音
ls /System/Library/Sounds/*.aiff

# 预览声音
afplay /System/Library/Sounds/Sosumi.aiff
```

### 推荐声音

| 声音文件 | 用途 | 听感 |
|---------|------|------|
| `Sosumi.aiff` | 任务完成 | 经典"登登"声 |
| `Basso.aiff` | 错误/警告 | 低沉警告音 |
| `Ping.aiff` | 子任务完成 | 清脆提示音 |
| `Frog.aiff` | 需要授权 | 青蛙声（引起注意） |
| `Glass.aiff` | 一般通知 | 玻璃破碎声 |
| `Hero.aiff` | 重要完成 | 英雄登场音效 |

---

## 安装步骤

### 一键安装（推荐）

```bash
bash ~/.openclaw/workspace/scripts/claude-code-macos-sound-hooks/install.sh
```

### 手动安装

```bash
# 1. 创建 hooks 目录
mkdir -p ~/.claude/hooks

# 2. 创建 stop_hook.sh
cat > ~/.claude/hooks/stop_hook.sh << 'EOF'
#!/bin/bash
if [[ -t 1 ]]; then
    afplay /System/Library/Sounds/Sosumi.aiff &>/dev/null &
fi
EOF

# 3. 设置执行权限
chmod +x ~/.claude/hooks/stop_hook.sh

# 4. 重启 Claude Code
```

---

## 配置与自定义

### 禁用某个 Hook

```bash
chmod -x ~/.claude/hooks/stop_hook.sh  # 禁用
chmod +x ~/.claude/hooks/stop_hook.sh  # 启用
```

### 自定义声音

编辑 Hook 脚本，修改 `afplay` 后的路径：

```bash
# 使用自定义声音文件
afplay ~/Music/custom-sound.aiff &>/dev/null &
```

### 添加多个声音（随机播放）

```bash
#!/bin/bash
SOUNDS=(
    "/System/Library/Sounds/Sosumi.aiff"
    "/System/Library/Sounds/Ping.aiff"
    "/System/Library/Sounds/Glass.aiff"
)

RANDOM_SOUND=${SOUNDS[$RANDOM % ${#SOUNDS[@]}]}
afplay "$RANDOM_SOUND" &>/dev/null &
```

---

## 故障排查

### Hook 不执行

1. 检查脚本是否有执行权限：
   ```bash
   ls -la ~/.claude/hooks/*.sh
   ```

2. 检查 Claude Code 版本（需要最新版）：
   ```bash
   claude --version
   ```

3. 查看日志：
   ```bash
   cat ~/.claude/hooks/*.log 2>/dev/null
   ```

### 声音不播放

1. 测试系统声音：
   ```bash
   afplay /System/Library/Sounds/Sosumi.aiff
   ```

2. 检查系统音量：
   ```bash
   osascript -e "output volume of (get volume settings)"
   ```

3. 检查是否在终端运行：
   ```bash
   [[ -t 1 ]] && echo "在终端中" || echo "不在终端中"
   ```

---

## 总结

这个实现的核心就是：
1. **利用 Claude Code 的 Hook 机制** - 在 `~/.claude/hooks/` 放脚本
2. **事件触发** - Claude 在特定事件时自动执行对应 Hook
3. **播放声音** - 使用 `afplay` 播放 macOS 系统声音

简单、可靠、无额外依赖！
