# Claude Code Sounds

基于 [claude-code-audio-hooks](https://github.com/ChanMeng666/claude-code-audio-hooks) 原理的简化实现。

## 🎯 功能

| Hook 类型 | 触发时机 | 系统声音 |
|----------|---------|---------|
| stop_hook | 任务完成 | Glass (成功·愉悦) |
| notification_hook | 需要用户关注 | Bottle (清脆·关注) |
| subagent_stop_hook | 子任务完成 | Tink (轻提示) |
| pre_tool_use_hook | 权限请求 | Submarine (需要授权) |

## 🚀 快速开始

### 安装

```bash
git clone https://github.com/yujinqiu/claude-code-sounds.git
cd claude-code-sounds
bash install.sh
```

### 管理声音通知

使用 `manage.sh` 脚本快速控制：

```bash
# 查看当前状态
./manage.sh status

# 禁用任务完成提示
./manage.sh disable stop

# 启用授权请求提示
./manage.sh enable notification

# 关闭所有声音
./manage.sh all-off

# 开启所有声音
./manage.sh all-on

# 切换全局开关
./manage.sh toggle global
```

## ⚙️ 配置说明

### 配置文件位置

`~/.claude/claude-code-sounds/config.json`

### 配置示例

```json
{
  "hooks": {
    "stop": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Sosumi.aiff",
      "description": "任务完成时播放"
    },
    "notification": {
      "enabled": false,
      "sound": "/System/Library/Sounds/Bottle.aiff",
      "description": "需要用户关注时播放"
    },
    "subagent_stop": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Ping.aiff",
      "description": "子任务完成时播放"
    },
    "pre_tool_use": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Frog.aiff",
      "description": "权限请求时播放"
    }
  },
  "global": {
    "enabled": true
  }
}
```

### 配置方式

**方式 1：使用管理脚本（推荐）**
```bash
./manage.sh disable stop      # 禁用任务完成提示
./manage.sh enable global     # 启用全局开关
```

**方式 2：直接编辑配置文件**
```bash
./manage.sh edit
```

**方式 3：修改配置后重新安装**
```bash
# 编辑 config.json 后
bash install.sh
```

## 🎵 自定义声音

编辑配置文件中的 `sound` 字段：

```json
{
  "hooks": {
    "stop": {
      "enabled": true,
      "sound": "/System/Library/Sounds/Glass.aiff"
    }
  }
}
```

macOS 系统声音位于：`/System/Library/Sounds/`

可用声音：
- `Sosumi.aiff` - 经典完成音
- `Basso.aiff` - 警告音
- `Ping.aiff` - 清脆提示音
- `Frog.aiff` - 青蛙声
- `Glass.aiff` - 玻璃声
- `Hero.aiff` - 英雄音效
- `Morse.aiff` - 摩尔斯电码
- `Submarine.aiff` - 潜艇声

## 📋 管理命令

| 命令 | 说明 |
|------|------|
| `./manage.sh status` | 查看当前配置状态 |
| `./manage.sh enable <hook>` | 启用某个声音 |
| `./manage.sh disable <hook>` | 禁用某个声音 |
| `./manage.sh toggle <hook>` | 切换某个声音状态 |
| `./manage.sh all-on` | 启用所有声音 |
| `./manage.sh all-off` | 禁用所有声音 |
| `./manage.sh edit` | 编辑配置文件 |

Hook 名称：`stop`, `notification`, `subagent_stop`, `pre_tool_use`, `global`

## ❓ 常见问题

### Q: 如何临时禁用所有声音？
```bash
./manage.sh all-off
# 或
./manage.sh toggle global
```

### Q: 只想听任务完成的声音？
```bash
./manage.sh disable notification
./manage.sh disable subagent_stop
./manage.sh disable pre_tool_use
```

### Q: 如何恢复默认配置？
```bash
rm ~/.claude/claude-code-sounds/config.json
bash install.sh
```

## 🗑️ 卸载

```bash
rm -rf ~/.claude/hooks/*.sh
rm -rf ~/.claude/claude-code-sounds
```
