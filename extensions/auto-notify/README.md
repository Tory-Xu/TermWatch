# TermWatch Auto-Notify 扩展

智能命令执行监控和自动通知扩展，为 TermWatch 添加自动化的命令执行监控功能。

## ✨ 功能特性

### 核心功能
- **智能时间监控** - 只有超过设定阈值（默认30秒）的命令才会通知
- **自动成功/失败判断** - 根据命令退出码自动发送成功或失败通知
- **强制通知模式** - 使用 `!command` 可强制通知任何命令
- **重要命令识别** - npm、docker、git 等重要命令自动通知
- **智能过滤** - 自动过滤 cd、ls、pwd 等短时间命令

### 通知方式
- **macOS 本地通知** - 系统通知中心显示
- **远程推送** - 继承 TermWatch 的 Server酱 和 Bark 推送配置
- **iTerm2 触发器** - 识别构建输出和特定日志格式

## 🚀 快速安装

### 自动安装（推荐）
```bash
# 在 TermWatch 项目根目录运行
bash extensions/auto-notify/scripts/install.sh
```

### 手动安装
```bash
# 1. 复制扩展文件
cp extensions/auto-notify/src/* ~/.termwatch/
cp extensions/auto-notify/config/* ~/.termwatch/config/

# 2. 修改 shell 配置
echo 'source ~/.termwatch/zsh_hooks.sh' >> ~/.zshrc

# 3. 重新加载配置
source ~/.zshrc
```

## 📖 使用方法

### 基础使用
```bash
# 普通命令（超过30秒才通知）
npm install
docker build .
make clean && make

# 强制通知（无论时间长短）
!git status
!ls -la
!pwd

# 重要命令（自动识别并通知）
git push origin main
npm start
docker-compose up
```

### 管理命令
```bash
# 查看状态
termwatch_status

# 切换自动通知开关
termwatch_toggle

# 编辑配置
nano ~/.termwatch/config/auto_notify.conf
```

### 脚本中使用
```bash
#!/bin/bash
# 加载日志辅助函数
source ~/.termwatch/log_helpers.sh

# 直接输出日志触发通知
log_success "任务完成"
log_error "任务失败"

# 使用命令包装器
run_with_notify "npm install" "安装依赖"
```

## ⚙️ 配置选项

配置文件位置：`~/.termwatch/config/auto_notify.conf`

```bash
# 是否启用自动通知
ENABLE_AUTO_NOTIFY=true

# 通知阈值（秒）- 只有执行时间超过此值的命令才会通知
AUTO_NOTIFY_THRESHOLD=30

# 忽略的命令列表（不会触发通知）
IGNORE_COMMANDS=("cd" "ls" "pwd" "echo" "cat" "less" "more" "vi" "vim" "nano" "man" "help" "history" "clear" "exit")

# 重要命令列表（无论执行时间都会通知）
IMPORTANT_COMMANDS=("make" "npm" "yarn" "cargo" "docker" "kubectl" "git push" "git pull" "pytest" "jest")
```

## 🔧 iTerm2 触发器配置（可选）

手动配置 iTerm2 触发器以识别特定日志格式：

1. 打开 iTerm2 → Preferences → Profiles → Advanced → Triggers
2. 添加触发器：

| 正则表达式 | 动作 | 参数 |
|------------|------|------|
| `^\\[TERMWATCH\\] SUCCESS: (.+)$` | Run Command | `bash ~/.termwatch/termwatch.sh success "\\1"` |
| `^\\[TERMWATCH\\] ERROR: (.+)$` | Run Command | `bash ~/.termwatch/termwatch.sh error "\\1"` |
| `^Build succeeded` | Run Command | `bash ~/.termwatch/termwatch.sh success "构建成功"` |
| `^Build failed` | Run Command | `bash ~/.termwatch/termwatch.sh error "构建失败"` |

## 🗑️ 卸载

```bash
# 运行卸载脚本
bash extensions/auto-notify/scripts/uninstall.sh

# 或手动卸载
rm -f ~/.termwatch/{auto_notify.sh,zsh_hooks.sh,log_helpers.sh}
rm -f ~/.termwatch/config/auto_notify.conf
# 然后从 ~/.zshrc 中移除相关配置行
```

## 🔍 故障排除

### 通知不生效？
```bash
# 检查配置是否正确加载
termwatch_status

# 重新加载 shell 配置
source ~/.zshrc

# 测试基础通知功能
termwatch --test
```

### 命令没有被监控？
```bash
# 检查命令是否在忽略列表中
grep -A 5 "IGNORE_COMMANDS" ~/.termwatch/config/auto_notify.conf

# 检查时间阈值设置
grep "AUTO_NOTIFY_THRESHOLD" ~/.termwatch/config/auto_notify.conf
```

### 钩子函数未生效？
```bash
# 检查钩子函数是否已加载
declare -f termwatch_preexec
declare -f termwatch_precmd

# 检查钩子数组
echo ${preexec_functions[@]}
echo ${precmd_functions[@]}
```

## 📁 文件结构

```
extensions/auto-notify/
├── README.md                    # 扩展说明文档
├── src/
│   ├── auto_notify.sh          # 自动通知核心模块
│   ├── zsh_hooks.sh            # ZSH 钩子函数
│   └── log_helpers.sh          # 日志辅助函数
├── config/
│   └── auto_notify.conf        # 默认配置文件
├── scripts/
│   ├── install.sh              # 安装脚本
│   ├── uninstall.sh            # 卸载脚本
│   └── test.sh                 # 测试脚本
└── docs/
    ├── usage.md                # 使用指南
    └── configuration.md        # 配置说明
```

## 🤝 与 TermWatch 的集成

本扩展完全兼容 TermWatch 的所有功能：

- ✅ **继承推送配置** - 自动使用 TermWatch 的 Bark/Server酱 配置
- ✅ **共享通知模板** - 使用相同的通知样式和模板
- ✅ **统一配置管理** - 配置文件位于 `~/.termwatch/config/` 目录
- ✅ **日志系统集成** - 日志写入 TermWatch 统一日志系统
- ✅ **命令别名兼容** - 不影响现有的 `notify`、`termwatch` 等命令

## 📋 版本要求

- **TermWatch**: >= 1.0.0
- **操作系统**: macOS 10.14+
- **Shell**: zsh 或 bash
- **依赖**: 无额外依赖，完全基于 TermWatch 现有功能

## 📄 许可证

本扩展采用与 TermWatch 相同的 MIT 许可证。