# TermWatch

**将终端命令执行通知发送到 macOS 和 Apple Watch 的智能工具**

![macOS](https://img.shields.io/badge/macOS-Compatible-blue)
![Apple Watch](https://img.shields.io/badge/Apple%20Watch-Supported-green)
![Version](https://img.shields.io/badge/version-1.0.0-orange)

## ✨ 功能特性

- 🚀 **智能通知**: 自动发送命令执行完成通知
- ⌚ **Apple Watch 同步**: 通过 Pushover 支持 Apple Watch 通知
- 🎛️ **灵活配置**: 支持自定义通知条件和消息模板
- 🔕 **静音时间**: 支持设置免打扰时间段
- 📱 **多种通知类型**: 成功、错误、警告、信息四种通知类型
- 🛡️ **通知去重**: 避免重复通知干扰

## 🚀 快速开始

### 安装

```bash
# 克隆项目
git clone https://github.com/yourusername/TermWatch.git
cd TermWatch

# 运行安装脚本
./install.sh

# 重载 shell 配置
source ~/.zshrc  # 或 source ~/.bash_profile
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

### 🚀 Server酱（推荐）- 免费微信推送

**优势：**
- ✅ 完全免费（每日1000条消息）
- 📱 直接推送到微信
- ⌚ 支持 Apple Watch（通过微信）
- 🇨🇳 国内网络稳定
- 🚀 响应速度快

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

### 📡 Pushover（备选）- Apple Watch 专用推送

**适合场景：** 需要国际化推送或独立于微信的通知服务

**设置步骤：**

1. **注册 Pushover 账号**
   - 访问 [pushover.net](https://pushover.net/) 注册账号
   - 下载 iPhone 应用并登录

2. **配置 TermWatch**
   ```bash
   # 运行配置脚本
   bash scripts/configure-pushover.sh
   
   # 或手动配置
   nano ~/.termwatch/config/user.conf
   ```

### 🎛️ 多服务控制

TermWatch 支持精细化的推送服务控制：

**配置选项：**
```bash
# 推送服务开关（可独立控制每个服务）
ENABLE_SERVERCHAN=true     # 是否启用 Server酱 推送
ENABLE_PUSHOVER=true       # 是否启用 Pushover 推送
ENABLE_PARALLEL_PUSH=false # 推送模式选择
```

**推送模式：**
- **优先级模式** (`ENABLE_PARALLEL_PUSH=false`): 优先使用 Server酱，失败时尝试 Pushover
- **并行模式** (`ENABLE_PARALLEL_PUSH=true`): 同时发送到所有启用的服务

**使用场景：**
- 只用微信：`ENABLE_SERVERCHAN=true, ENABLE_PUSHOVER=false`
- 只用 Apple Watch：`ENABLE_SERVERCHAN=false, ENABLE_PUSHOVER=true`
- 双重保障：`ENABLE_PARALLEL_PUSH=true` 同时发送到两个服务
- 智能备份：`ENABLE_PARALLEL_PUSH=false` 主用 Server酱，备用 Pushover

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
│   ├── configure-pushover.sh   # Pushover 配置脚本
│   ├── configure-serverchan.sh # Server酱配置脚本
│   ├── test-notification.sh    # 通知测试脚本
│   └── uninstall.sh           # 卸载脚本
└── docs/
    ├── setup-guide.md          # 详细设置指南
    ├── troubleshooting.md      # 故障排除指南
    └── claude-code-integration.md # Claude Code 集成教程
```

## 🤖 第三方集成

### Claude Code 集成

TermWatch 已完美集成到 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 中，通过钩子系统实现智能通知：

- 📋 **任务完成通知**：Claude 完成任务时自动推送
- 🔔 **等待输入提醒**：Claude 需要用户输入时发送提醒
- 🌐 **多渠道推送**：同时推送到 macOS、微信、Apple Watch
- ⚙️ **自动化配置**：无需手动干预，智能识别推送时机

详细配置教程请参考：[Claude Code 集成指南](docs/claude-code-integration.md)

## 🛠️ 系统要求

- **操作系统**: macOS 10.14 或更高版本
- **通知工具**: terminal-notifier（推荐）或系统内置 osascript
- **Apple Watch**: 可选，需要 Pushover 配置
- **Shell**: bash 或 zsh

## 🔧 故障排除

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

1. 确保 Pushover 正确配置
2. 检查 iPhone 上的 Pushover 应用是否已登录
3. 确认 Apple Watch 通知设置：
   - iPhone: Watch 应用 > 通知 > Pushover > 允许通知

### 配置问题

```bash
# 查看当前状态
termwatch --status

# 重新安装
./scripts/uninstall.sh && ./install.sh

# 查看日志
tail -f ~/.termwatch/logs/termwatch.log
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

- [terminal-notifier](https://github.com/julienXX/terminal-notifier) - macOS 通知工具
- [Pushover](https://pushover.net/) - 跨平台推送服务
- 所有贡献者和用户的支持

---

**如果 TermWatch 对你有帮助，请给项目点个 ⭐ 支持一下！**