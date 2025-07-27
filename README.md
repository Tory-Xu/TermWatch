# TermWatch

**专为 Claude Code 设计的智能终端通知工具 - 将 AI 编程任务状态实时推送到 macOS、iPhone 和 Apple Watch**，**Android** 和 **Watch** 设备同样支持。

![macOS](https://img.shields.io/badge/macOS-Compatible-blue)
![Apple Watch](https://img.shields.io/badge/Apple%20Watch-Supported-green)
![Version](https://img.shields.io/badge/version-1.0.0-orange)

## 📚 目录

- [✨ 功能特性](#-功能特性)
- [🚀 快速开始](#-快速开始)
  - [安装](#安装)
  - [基本使用](#基本使用)
  - [实际使用场景](#实际使用场景)
- [📱 手机和 Apple Watch 通知设置](#-手机和-apple-watch-通知设置)
  - [📱 Bark（强烈推荐）- iOS 原生推送](#-bark强烈推荐--ios-原生推送)
  - [🚀 Server酱（备选）- 免费微信推送，支持 iPhone 和 android](#-server酱备选--免费微信推送支持-iphone-和-android)
  - [🎛️ 多服务控制](#️-多服务控制)
- [⚙️ 配置选项](#️-配置选项)
- [📋 命令参考](#-命令参考)
  - [基本命令](#基本命令)
  - [通知类型](#通知类型)
  - [高级用法](#高级用法)
- [📁 项目结构](#-项目结构)
- [🤖 Claude Code 集成](#-claude-code-集成)
  - [核心功能](#核心功能)
  - [快速配置](#快速配置)
- [🛠️ 系统要求](#️-系统要求)
- [🔧 故障排除](#-故障排除)
  - [通知不显示](#通知不显示)
  - [Apple Watch 收不到通知](#apple-watch-收不到通知)
  - [配置问题](#配置问题)
- [🤝 贡献](#-贡献)
- [📄 许可证](#-许可证)
- [🙏 致谢](#-致谢)
- [🌟 为什么选择 TermWatch](#-为什么选择-termwatch)

## ✨ 功能特性

- 🤖 **Claude Code Hook 集成**: 原生支持 Claude Code 钩子系统，智能监控 AI 编程任务状态
- 🚀 **智能通知**: 自动发送命令执行完成通知，支持任务完成、等待输入等多种场景
- ⌚ **Apple Watch 同步**: 通过 Bark/Server酱支持 Apple Watch 和 iPhone 通知
- 🎛️ **灵活配置**: 支持自定义通知条件、消息模板和多服务推送策略
- 🔕 **静音时间**: 支持设置免打扰时间段，避免深夜干扰
- 📱 **多种通知类型**: 成功、错误、警告、信息四种通知类型
- 🛡️ **通知去重**: 智能去重机制，避免重复通知干扰
- 🔗 **Hook 系统**: 支持 Claude Code 的 user-prompt-submit 和 finish-commands 钩子

## 🚀 快速开始

### 安装

```bash
# 克隆项目
git clone https://github.com/Tory-Xu/TermWatch.git
cd TermWatch

# 运行安装脚本（包含 Claude Code 钩子配置）
./install.sh

# 重载 shell 配置
source ~/.zshrc  # 或 source ~/.bash_profile

# 验证 Claude Code 集成状态
termwatch --status
```

### 基本使用

```bash
# 发送基础通知
notify "Hello TermWatch!"

# 发送不同类型通知
notify_success "任务完成"
notify_error "出现错误"
notify_warning "注意事项"
notify_info "信息提示"

# 自定义标题
termwatch -t "自定义标题" "自定义消息"
```

### 实际使用场景

**Claude Code 集成场景：**
```bash
# Claude 完成代码重构后自动通知
# 通知内容："✅ Claude 完成任务: 重构 auth 模块 (耗时 3m 25s)"

# Claude 需要用户确认时立即通知
# 通知内容："🔔 Claude 等待输入中: 需要确认数据库迁移方案"
```

**普通终端使用：**
```bash
# 长时间命令完成后通知
npm install && notify_success "依赖安装完成"

# 构建失败时通知
npm run build || notify_error "构建失败，请检查日志"

# 部署完成通知
./deploy.sh && notify_success "部署完成" || notify_error "部署失败"

# 监控脚本执行
./long-running-script.sh; notify_success "脚本执行完成"
```

## 📱 手机和 Apple Watch 通知设置

TermWatch 支持两种远程推送服务，可以将通知发送到手机和 Apple Watch：

### 📱 Bark（强烈推荐）- iOS 原生推送

**优势：**
- ✅ **完全免费且开源**
- 📱 **完美支持 iPhone 和 Apple Watch**
- 🎯 **支持多种通知级别和声音**
- 🔐 **支持自建服务器保护隐私**
- 🏎️ **响应速度快，通知样式丰富**
- ⚙️ **配置简单，无需注册账号**

**设置步骤：**

1. **安装 Bark 应用**
   - 从 App Store 下载 [Bark](https://apps.apple.com/app/bark-custom-notifications/id1403753865) 应用
   - 打开应用获取推送 Key

2. **配置 TermWatch**
   ```bash
   # 运行配置脚本（推荐）
   bash scripts/configure-bark.sh
   
   # 或手动配置
   nano ~/.termwatch/config/user.conf
   ```

3. **测试通知**
   ```bash
   bash src/termwatch.sh --test
   ```

4. **关闭 mac 收到 iPhone 镜像通知**
   - iPhone 进入 Bark 通知设置页面，关闭“在Mac上显示”

### 🚀 Server酱（备选）- 免费微信推送，支持 iPhone 和 android

**适合场景：** 已有微信，希望通过微信接收通知

**优势：**
- ✅ 完全免费（每日1000条消息）
- 📱 直接推送到微信
- ⌚ 支持 Apple Watch（通过微信）
- 🇨🇳 国内网络稳定

**设置步骤：**

1. **注册 Server酱**
   ```bash
   # 运行配置脚本
   bash scripts/configure-serverchan.sh
   ```
   
2. **手动配置**（可选）
   - 访问 [sct.ftqq.com](https://sct.ftqq.com/) 微信登录
   - 获取 SendKey（SCT开头的34位字符）
   - 编辑配置文件：
   ```bash
   nano ~/.termwatch/config/user.conf
   # 添加：SERVERCHAN_SENDKEY="xxx"
   ```

3. **测试通知**
   ```bash
   bash src/termwatch.sh --test
   ```


### 🎛️ 多服务控制

TermWatch 支持精细化的推送服务控制：

**配置选项：**
```bash
# 推送服务开关（可独立控制每个服务）
ENABLE_BARK=true           # 是否启用 Bark 推送（推荐）
ENABLE_SERVERCHAN=true     # 是否启用 Server酱 推送
ENABLE_PARALLEL_PUSH=false # 推送模式选择
```

**推送模式：**
- **优先级模式** (`ENABLE_PARALLEL_PUSH=false`): 优先使用 Bark，失败时尝试 Server酱
- **并行模式** (`ENABLE_PARALLEL_PUSH=true`): 同时发送到所有启用的服务

**使用场景：**
- **只用 Bark（推荐）**：`ENABLE_BARK=true, ENABLE_SERVERCHAN=false`
- **只用微信**：`ENABLE_BARK=false, ENABLE_SERVERCHAN=true`
- **双重保障**：`ENABLE_PARALLEL_PUSH=true` 同时发送到两个服务
- **智能备份**：`ENABLE_PARALLEL_PUSH=false` 主用 Bark，备用 Server酱

## ⚙️ 配置选项

编辑 `~/.termwatch/config/user.conf` 来自定义设置：

```bash
# 基本设置
AUTO_NOTIFY_THRESHOLD=30          # 自动通知阈值（秒）
NOTIFICATION_SOUND=default        # 通知声音
NOTIFICATION_TITLE="我的终端"     # 默认通知标题

# 消息模板
SUCCESS_TEMPLATE="✅ 任务完成"
ERROR_TEMPLATE="❌ 任务失败"
WARNING_TEMPLATE="⚠️ 注意"
INFO_TEMPLATE="ℹ️ 信息"

# 静音时间
ENABLE_QUIET_HOURS=true
QUIET_HOURS_START=22              # 22:00 开始静音
QUIET_HOURS_END=8                 # 8:00 结束静音

# 通知去重
ENABLE_DEDUPLICATION=true
DUPLICATE_THRESHOLD=300           # 相同通知最小间隔（秒）
```

## 📋 命令参考

### 基本命令

```bash
termwatch [选项] [消息]          # 发送通知
termwatch <类型> <消息>          # 发送指定类型通知
termwatch --help                 # 显示帮助
termwatch --status               # 显示状态信息
termwatch --test                 # 发送测试通知
termwatch --uninstall            # 一键卸载 TermWatch
```

### 通知类型

| 命令 | 说明 | 示例 |
|------|------|------|
| `notify` | 基础通知 | `notify "Hello World"` |
| `notify_success` | 成功通知 | `notify_success "构建完成"` |
| `notify_error` | 错误通知 | `notify_error "构建失败"` |
| `notify_warning` | 警告通知 | `notify_warning "磁盘空间不足"` |
| `notify_info` | 信息通知 | `notify_info "开始备份"` |

### 高级用法

```bash
# 自定义标题和消息
termwatch -t "项目构建" "构建已完成，耗时 5 分钟"

# 链式命令使用
command1 && notify_success "第一步完成" && command2 && notify_success "全部完成"

# 条件通知
if [ $? -eq 0 ]; then
    notify_success "操作成功"
else
    notify_error "操作失败"
fi
```

## 📁 项目结构

```
TermWatch/
├── README.md                    # 项目说明
├── install.sh                   # 安装脚本
├── src/
│   └── termwatch.sh            # 核心通知脚本
├── config/
│   ├── default.conf            # 默认配置
│   └── user.conf.example       # 用户配置示例
├── scripts/
│   ├── configure-bark.sh       # Bark 配置脚本（推荐）
│   ├── configure-serverchan.sh # Server酱配置脚本
│   ├── test-notification.sh    # 通知测试脚本
│   └── uninstall.sh           # 卸载脚本
└── docs/
    ├── setup-guide.md          # 详细设置指南
    ├── troubleshooting.md      # 故障排除指南
    └── claude-code-integration.md # Claude Code 集成教程
```

## 🤖 Claude Code 集成

TermWatch 专为 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 设计，通过钩子系统实现 AI 编程任务的智能通知：

### 核心功能

- 📋 **任务完成通知**：Claude 完成编程任务时自动推送，包含任务摘要和执行时长
- 🔔 **等待输入提醒**：Claude 需要用户输入时立即发送提醒，避免错过重要交互
- 🌐 **多渠道推送**：同时推送到 macOS 本地通知、iPhone、Apple Watch
- ⚙️ **零配置集成**：运行安装脚本即可自动配置 Claude Code 钩子
- 📊 **状态追踪**：实时追踪 AI 任务执行状态，包括开始、进行中、完成等
- 🎯 **智能过滤**：根据任务类型和重要性智能过滤通知

### 快速配置

```bash
# 安装时自动配置 Claude Code 钩子
./install.sh

# 或单独配置 Claude Code 集成
bash scripts/configure-claude-hooks.sh

# 验证集成状态
termwatch --status
```

**钩子工作流程：**
1. **user-prompt-submit**: 用户提交任务时触发，记录任务开始
2. **finish-commands**: Claude 完成所有命令时触发，发送完成通知
3. **智能判断**: 根据任务执行时长和类型决定是否发送通知

详细配置教程请参考：[Claude Code 集成指南](docs/claude-code-integration.md)

## 🛠️ 系统要求

- **操作系统**: macOS 10.14 或更高版本
- **通知工具**: terminal-notifier（推荐）或系统内置 osascript
- **Apple Watch**: 可选，需要 Pushover 配置
- **Shell**: bash 或 zsh

## 🔧 故障排除

### Claude Code 集成问题

1. **钩子未触发**：
   ```bash
   # 检查钩子配置
   cat ~/.claude/settings.json | grep termwatch
   
   # 重新配置钩子
   bash scripts/configure-claude-hooks.sh
   
   # 重启 Claude Code
   ```

2. **通知延迟**：
   - 检查日志：`tail -f ~/.termwatch/logs/claude-hook.log`
   - 调整通知阈值：`CLAUDE_NOTIFY_THRESHOLD=10`

### 通知不显示

1. 检查 macOS 通知设置：
   - 系统偏好设置 > 通知 > 终端
   - 确保允许通知、横幅、声音等选项已启用

2. 检查通知工具：
   ```bash
   # 测试 terminal-notifier
   terminal-notifier -message "测试" -title "TermWatch"
   
   # 或测试 osascript
   osascript -e 'display notification "测试" with title "TermWatch"'
   ```

### Apple Watch 收不到通知

1. **Bark 用户**：
   - 确保 Bark 正确配置
   - 检查 iPhone 上的 Bark 应用是否正常
   - 确认 Apple Watch 通知设置：
     - iPhone: Watch 应用 > 通知 > Bark > 允许通知

2. **Server酱 用户**：
   - 确保微信通知已开启
   - 确认 Apple Watch 微信通知设置

### 配置问题

```bash
# 查看当前状态
termwatch --status

# 一键卸载（推荐）
termwatch --uninstall

# 完整卸载（手动）
./scripts/uninstall.sh

# 重新安装
./scripts/uninstall.sh && ./install.sh

# 查看日志
tail -f ~/.termwatch/logs/termwatch.log
```

### Claude Code 钩子管理

```bash
# 查看钩子状态
termwatch --claude-status

# 仅卸载 Claude 钩子
bash scripts/unconfigure-claude-hooks.sh

# 重新安装钩子
bash scripts/configure-claude-hooks.sh
```

### 🗑️ 完全卸载说明

TermWatch 卸载程序提供了安全、完整的清理功能：

**自动清理内容：**
- 📁 **配置目录**: 完全删除 `~/.termwatch` 目录及所有内容
- 📝 **Shell 配置**: 精确移除以下内容：
  - `# TermWatch 通知工具` 注释块
  - `termwatch` 命令别名
  - `notify` 系列别名 (`notify`, `notify_success`, `notify_error`, `notify_warning`, `notify_info`)
  - 其他包含 `termwatch`/`TermWatch` 的配置行
- 🤖 **Claude Code 钩子集成** (可选，需用户确认)：
  - `~/.claude/hooks/termwatch/` 钩子目录和脚本
  - `~/.claude/settings.json` 中的 TermWatch 钩子配置
  - Claude 配置备份文件清理
- 🔗 **符号链接**: 清理可能的系统链接
- 🗂️ **日志缓存**: 删除所有运行日志和缓存文件

**安全保障措施：**
- ✅ **自动备份**: 修改任何配置文件前自动创建带时间戳的备份
- ✅ **精确清理**: 只移除 TermWatch 相关配置，不影响其他设置  
- ✅ **用户确认**: Claude Code 钩子清理需要用户明确确认
- ✅ **保留系统工具**: `terminal-notifier` 等系统工具保持完整
- ✅ **权限不变**: 系统通知权限设置完全不受影响

**卸载后操作：**
```bash
# 重启终端或重新加载配置
source ~/.zshrc     # 或 ~/.bash_profile

# 如果清理了 Claude Code 钩子，请重启 Claude Code
# 验证卸载完成
command -v termwatch  # 应该显示 "not found"
```

**恢复配置（如果需要）：**
```bash
# Shell 配置恢复
# 备份文件位置: 原文件名.termwatch_backup_时间戳
# 例如: ~/.zshrc.termwatch_backup_20240127_143052
cp ~/.zshrc.termwatch_backup_20240127_143052 ~/.zshrc
source ~/.zshrc

# Claude Code 钩子恢复
# 备份位置: ~/.claude/hooks/termwatch_backup_时间戳
cp -r ~/.claude/hooks/termwatch_backup_20240127_143052 ~/.claude/hooks/termwatch
# 然后重启 Claude Code
```

### 🤖 Claude Code 钩子集成说明

如果你安装了 [Claude Code 集成](docs/claude-code-integration.md)，卸载程序会检测并提供清理选项：

**交互式清理过程：**
1. **钩子目录清理**: 询问是否删除 `~/.claude/hooks/termwatch/` 
2. **配置文件清理**: 询问是否清理 `~/.claude/settings.json` 中的钩子设置
3. **备份文件清理**: 询问是否删除旧的 Claude 配置备份

**注意事项：**
- 清理 Claude 钩子会影响 Claude Code 的通知功能
- 所有清理操作都会先创建备份
- 可以选择性保留某些组件
- 需要重启 Claude Code 使更改生效

**手动清理方法（如果需要）：**
```bash
# 手动删除钩子目录
rm -rf ~/.claude/hooks/termwatch

# 手动编辑 Claude 配置（移除 TermWatch 相关的 hooks 配置）
nano ~/.claude/settings.json
```

更多故障排除信息请查看 [troubleshooting.md](docs/troubleshooting.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - AI 编程助手
- [terminal-notifier](https://github.com/julienXX/terminal-notifier) - macOS 通知工具
- [Bark](https://github.com/Finb/Bark) - iOS 推送服务
- [Server酱](https://sct.ftqq.com/) - 微信推送服务
- 所有贡献者和用户的支持

## 🌟 为什么选择 TermWatch

**专为 AI 编程时代设计：**
- 🤖 **原生 Claude Code Hook 支持**：深度集成 Claude Code 钩子的通知工具
- 📱 **全平台覆盖**：macOS、iPhone、Apple Watch 无缝同步，同样支持 Android 设备
- 🚀 **极简配置**：一键安装，自动配置所有集成
- 🔐 **隐私优先**：支持自建服务器，数据完全掌控
- 🎯 **智能通知**：根据任务类型和执行时长智能决定通知策略

**使用场景：**
- 让 Claude Code 帮你重构代码时，完成后立即收到通知
- Claude 执行长时间构建任务，可以安心做其他事情
- Claude 需要你的输入时，立即在手表上收到提醒
- 多个 Claude 任务并行执行，实时掌握每个任务状态

---

**如果 TermWatch 对你有帮助，请给项目点个 ⭐ 支持一下！**

特别适合 Claude Code 用户，让 AI 编程更加高效！🚀