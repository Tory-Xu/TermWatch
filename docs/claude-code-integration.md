# Claude Code 接入 TermWatch 通知系统教程

## 概述

本教程将指导你如何配置 Claude Code 钩子系统，使其能够通过 TermWatch 向 macOS 和 Apple Watch 发送通知。当 Claude Code 等待输入或完成任务时，你将收到及时的通知提醒。

## 系统要求

- macOS 10.14 或更高版本
- Claude Code 1.0.51 或更高版本
- TermWatch 项目（已安装）
- terminal-notifier（推荐）或系统内置 osascript
- 可选：Pushover 账号（用于 Apple Watch 通知）

## 前置准备

### 1. 确保 TermWatch 已正确安装

```bash
# 检查 TermWatch 状态（使用本地安装的命令）
termwatch --status

# 测试 macOS 通知
notify_success "测试通知"

# 或者使用完整命令
termwatch success "测试通知"
```

**注意**：TermWatch 安装后会在本地提供以下命令：
- `termwatch` - 主命令
- `notify_success` - 成功通知快捷命令
- `notify_error` - 错误通知快捷命令  
- `notify_warning` - 警告通知快捷命令
- `notify_info` - 信息通知快捷命令

### 2. 检查 Claude Code 配置目录

```bash
ls -la ~/.claude/
```

## 快速安装

### 🚀 一键安装（推荐）

运行以下命令即可自动完成所有配置：

```bash
# 进入 TermWatch 目录
cd /path/to/TermWatch

# 运行一键安装脚本
bash scripts/install-claude-integration.sh
```

安装脚本将自动：
- ✅ 检查系统依赖（Claude Code、jq、TermWatch）
- ✅ 创建钩子脚本目录和文件
- ✅ 配置 Claude Code 钩子系统
- ✅ 测试通知功能
- ✅ 备份现有配置

**安装完成后只需重启 Claude Code 即可使用！**

---

## 手动安装（可选）

如果你更喜欢手动配置，可以按照以下步骤操作：

### 第一步：检查依赖

```bash
# 检查 Claude Code
claude --version

# 检查 jq（如未安装则安装）
jq --version || brew install jq

# 检查 TermWatch
termwatch --status
```

### 第二步：运行安装脚本

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/your-repo/TermWatch/main/scripts/install-claude-integration.sh | bash
```

### 第三步：重启 Claude Code

```bash
# 退出当前会话
exit

# 重新启动 Claude Code
claude
```

## 远程推送通知配置（可选）

TermWatch 支持多种远程推送服务，包括微信推送（Server酱）和 Apple Watch 推送（Pushover）。

### 1. Server酱配置（微信推送）

#### 注册和配置 Server酱

1. 访问 [sct.ftqq.com](https://sct.ftqq.com/) 注册账号
2. 关注"Server酱"微信公众号
3. 在 Server酱 控制台获取 SendKey

#### 配置 TermWatch

编辑配置文件：
```bash
nano ~/.termwatch/config/user.conf
```

添加 Server酱 配置：
```bash
# Server酱配置
SERVER_CHAN_SENDKEY="你的SendKey"
ENABLE_SERVER_CHAN=true
```

#### 测试 Server酱 推送

```bash
# 测试微信推送
notify_success "Server酱推送测试 - 来自Claude Code"

# 检查推送状态
termwatch --status
```

### 2. Pushover配置（Apple Watch推送）

#### 注册和配置 Pushover

1. 访问 [pushover.net](https://pushover.net/) 注册账号
2. 在 iPhone App Store 下载 Pushover 应用并登录
3. 获取 User Key 和 API Token

#### 配置 TermWatch

```bash
# 编辑配置文件
nano ~/.termwatch/config/user.conf
```

添加 Pushover 配置：
```bash
# Pushover配置
PUSHOVER_USER="你的用户密钥"
PUSHOVER_TOKEN="你的API令牌"
ENABLE_PUSHOVER=true
```

#### 测试 Apple Watch 通知

```bash
# 测试Apple Watch推送
notify_success "Apple Watch 测试通知"

# 检查所有推送渠道状态
termwatch --status
```

### 3. 多渠道推送验证

配置完成后，TermWatch 会同时向所有已配置的渠道推送通知：

```bash
# 测试所有推送渠道
notify_success "多渠道推送测试"
```

你应该会收到：
- 📱 macOS 系统通知
- 💬 微信 Server酱 消息（如果已配置）
- ⌚ Apple Watch Pushover 通知（如果已配置）

## 钩子触发时机

| 钩子类型 | 触发时机 | 通知内容 | 验证状态 |
|---------|---------|---------|---------|
| `Notification` | Claude 发送系统通知时 | 原始通知消息 | ⚠️ 少见触发 |
| `Stop` | Claude 完成主要任务/会话时 | "Claude Code 任务已完成" | ⚠️ 需要完全退出 |
| `SubagentStop` | Claude 子任务完成时 | "Claude Code 任务已完成" | ⚠️ 子任务触发 |
| `PostToolUse` | 使用指定工具后 | "Claude Code 任务已完成" | ✅ **推荐使用** |

**重要说明**：
- **Stop钩子**：只在Claude会话完全结束时触发，不是每次回答后都触发
- **PostToolUse钩子**：更可靠，可以配置监听常用工具（如TodoWrite、Bash、Edit等）
- **建议配置**：使用PostToolUse钩子作为主要通知方式，Stop钩子作为备用

## 故障排除

### 1. 钩子未触发

**问题**：修改配置后钩子不工作

**解决方案**：
- **重新启动 Claude Code**（最重要）
- 检查 `~/.claude/settings.json` 语法是否正确：`python3 -m json.tool ~/.claude/settings.json`
- 使用 `claude --debug` 查看钩子执行日志
- **Stop钩子特殊情况**：只在会话完全结束时触发，建议使用PostToolUse钩子进行测试

### 1.1 钩子配置加载问题

**问题**：在当前会话中修改钩子配置不生效

**原因**：Claude在会话开始时加载钩子配置，中途修改不会立即生效

**解决方案**：
1. 保存钩子配置文件
2. 使用 `exit` 命令退出当前Claude会话  
3. 重新启动Claude Code
4. 在新会话中测试钩子功能

### 2. 脚本权限问题

**问题**：钩子脚本无法执行

**解决方案**：
```bash
chmod +x ~/.claude/hooks/notify.sh
chmod +x ~/.claude/hooks/stop.sh
```

### 3. TermWatch 命令问题

**问题**：找不到 TermWatch 命令

**解决方案**：
- 确保 TermWatch 已正确安装：`which termwatch`
- 检查命令别名是否生效：`alias | grep termwatch`
- 重新加载shell配置：`source ~/.zshrc` 或 `source ~/.bash_profile`
- 手动测试：`termwatch --status`

### 4. 通知不显示

**问题**：macOS 通知不显示

**解决方案**：
- 检查系统偏好设置 > 通知 > 终端 设置
- 确保安装了 `terminal-notifier`：`brew install terminal-notifier`
- 测试基础通知：`terminal-notifier -message "测试" -title "测试"`

### 5. 远程推送问题

#### Server酱推送失败

**问题**：微信收不到通知

**解决方案**：
- 确认 SendKey 配置正确
- 检查 Server酱 控制台状态
- 确保关注了"Server酱"微信公众号
- 检查推送频率限制

#### Apple Watch 收不到通知

**问题**：iPhone 收到但 Apple Watch 收不到

**解决方案**：
- 确认 Pushover 配置正确
- 检查 iPhone Watch 应用 > 通知 > Pushover 设置
- 确保 Apple Watch 已配对并连接

### 6. 钩子配置缓存问题

**问题**：修改钩子配置后，Claude仍使用旧路径

**原因**：Claude在会话启动时锁定钩子配置

**解决方案**：
```bash
# 脚本已经直接可用，无需创建额外文件
# 路径: ~/.claude/hooks/stop.sh
```

## 高级配置

### 推荐的PostToolUse钩子配置

基于实际测试，以下是更实用的钩子配置：

```json
"PostToolUse": [
  {
    "matcher": "Bash|Write|Edit|MultiEdit",
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/hooks/stop.sh"
      }
    ]
  }
]
```

这个配置会在Claude执行以下操作后发送通知：
- `Bash` - 运行命令行工具
- `Write` - 创建新文件
- `Edit` - 编辑文件
- `MultiEdit` - 批量编辑文件

### 自定义通知消息

可以修改钩子脚本中的通知内容：

```bash
# 在 ~/.claude/hooks/stop.sh 中自定义消息
"$TERMWATCH_SCRIPT" success "🎉 Claude 已完成你的请求！"
```

### 添加条件过滤

可以为特定类型的任务添加条件判断：

```bash
# 示例：只在特定条件下发送通知
if [[ "$message" == *"构建"* ]]; then
    "$TERMWATCH_SCRIPT" success "$message"
fi
```

### 钩子日志记录

在钩子脚本中添加详细日志：

```bash
# 添加到钩子脚本中
echo "[$(date)] Claude Hook: $message" >> ~/.claude/hook.log
```

### 智能通知频率控制

避免通知过于频繁，可以在钩子脚本中添加频率控制：

```bash
# 检查最近通知时间，避免频繁通知
LAST_NOTIFY_FILE="$HOME/.claude/last_notify"
CURRENT_TIME=$(date +%s)
NOTIFY_INTERVAL=30  # 30秒内最多一次通知

if [[ -f "$LAST_NOTIFY_FILE" ]]; then
    LAST_TIME=$(cat "$LAST_NOTIFY_FILE")
    TIME_DIFF=$((CURRENT_TIME - LAST_TIME))
    if [[ $TIME_DIFF -lt $NOTIFY_INTERVAL ]]; then
        exit 0  # 跳过通知
    fi
fi

echo "$CURRENT_TIME" > "$LAST_NOTIFY_FILE"
```

## 最佳实践

1. **优先使用PostToolUse钩子**：比Stop钩子更可靠和实用
2. **定期测试**：定期测试通知功能确保正常工作
3. **备份配置**：备份 `~/.claude/settings.json` 配置文件
4. **监控日志**：使用 `claude --debug` 监控钩子执行状态
5. **渐进配置**：先配置 macOS 通知，再配置 Apple Watch 通知
6. **频率控制**：避免通知过于频繁，影响工作效率
7. **及时重启**：修改钩子配置后及时重启Claude Code生效

## 实际测试结果

**经过实际验证，以下配置已确认可用**：

### ✅ 已验证工作的配置
- **PostToolUse钩子**：监听TodoWrite工具，成功触发通知
- **TermWatch集成**：macOS系统通知正常工作
- **Server酱集成**：微信推送成功发送
- **Pushover集成**：Apple Watch通知成功发送
- **多渠道推送**：同时推送到macOS、微信、Apple Watch
- **钩子脚本**：bash脚本执行正常，JSON解析正确
- **脚本管理**：统一的hooks目录管理，便于维护

### ⚠️ 需要注意的问题
- **Stop钩子**：只在会话完全结束时触发，实用性有限
- **配置加载**：修改钩子配置后必须重启Claude Code才能生效
- **触发频率**：PostToolUse钩子可能频繁触发，建议添加频率控制

## 结论

通过配置 Claude Code 钩子与 TermWatch 的集成，你可以：

- ✅ **实时收到任务完成通知**（通过PostToolUse钩子验证）
- ✅ **多平台推送通知**：macOS + 微信 + Apple Watch（已测试可用）
- ✅ **统一的钩子脚本管理**（hooks目录集中管理）
- ✅ **自定义通知内容和触发条件**
- ✅ **灵活的钩子配置系统**

**推荐配置**：使用PostToolUse钩子监听常用工具（Bash、Write、Edit等），这比Stop钩子更实用和可靠。

配置完成后，重新启动 Claude Code 即可享受智能通知功能！

---

**更新日期**：2025年7月21日  
**测试版本**：Claude Code 1.0.51  
**验证状态**：✅ 已实际测试通过

如有问题，请参考故障排除章节或提交Issue。