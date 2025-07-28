# Auto-Notify 扩展配置说明

## 配置文件位置

主配置文件：`~/.termwatch/config/auto_notify.conf`

这个文件在首次安装扩展时会自动创建，包含所有可配置的选项。

## 基础配置

### 启用/禁用扩展
```bash
# 是否启用自动通知
ENABLE_AUTO_NOTIFY=true
```
- `true`: 启用自动通知
- `false`: 禁用自动通知

### 通知阈值
```bash
# 通知阈值（秒）- 只有执行时间超过此值的命令才会通知
AUTO_NOTIFY_THRESHOLD=30
```
- 默认值：30 秒
- 建议范围：10-120 秒
- 用途：过滤短时间命令，避免通知轰炸

### 忽略命令列表
```bash
# 忽略的命令列表（不会触发通知）
IGNORE_COMMANDS=("cd" "ls" "pwd" "echo" "cat" "less" "more" "vi" "vim" "nano" "man" "help" "history" "clear" "exit" "which" "whereis" "whoami" "date" "uptime")
```

常见的忽略命令分类：
- **导航命令**: `cd`, `pwd`, `ls`, `find`
- **查看命令**: `cat`, `less`, `more`, `head`, `tail`
- **编辑器**: `vi`, `vim`, `nano`, `emacs`
- **系统信息**: `ps`, `top`, `htop`, `who`, `whoami`
- **帮助命令**: `man`, `help`, `--help`

### 重要命令列表
```bash
# 重要命令列表（无论执行时间都会通知）
IMPORTANT_COMMANDS=("make" "npm" "yarn" "pnpm" "cargo" "docker" "kubectl" "git push" "git pull" "git clone" "pytest" "jest" "gradle" "mvn" "bundle" "pip install" "composer install" "brew install" "apt install" "yum install")
```

重要命令分类：
- **构建工具**: `make`, `cmake`, `ninja`
- **包管理器**: `npm`, `yarn`, `pip`, `brew`, `apt`
- **容器技术**: `docker`, `podman`, `kubectl`
- **版本控制**: `git push`, `git pull`, `git clone`
- **测试框架**: `pytest`, `jest`, `mocha`, `junit`
- **编译器**: `gcc`, `clang`, `rustc`, `go build`

## 高级配置

### 强制通知前缀
```bash
# 强制通知的命令前缀（以 ! 开头的命令总是通知）
FORCE_NOTIFY_PREFIX="!"
```
使用示例：
```bash
!echo "这会立即通知"
!git status
!ls -la
```

### 显示选项
```bash
# 是否显示命令执行的详细信息（参数等）
SHOW_COMMAND_DETAILS=true

# 命令截断长度（超过此长度的命令会被截断显示）
COMMAND_TRUNCATE_LENGTH=50

# 是否启用命令执行时间统计
ENABLE_TIME_TRACKING=true

# 是否在通知中包含当前目录信息
INCLUDE_WORKING_DIR=false
```

### 自定义通知模板
```bash
# 自定义通知模板（可以使用变量 {command}, {duration}, {exit_code}, {dir}）
CUSTOM_SUCCESS_TEMPLATE="✅ 命令执行成功\n命令: {command}\n耗时: {duration}"
CUSTOM_ERROR_TEMPLATE="❌ 命令执行失败\n命令: {command}\n耗时: {duration}\n退出码: {exit_code}"
```

可用变量：
- `{command}`: 执行的命令
- `{duration}`: 执行时间
- `{exit_code}`: 退出码
- `{dir}`: 当前目录（需要启用 `INCLUDE_WORKING_DIR`）

## 命令分类配置

### 构建类命令
```bash
# 构建类命令（较低阈值，因为用户通常会等待）
BUILD_COMMANDS=("make" "npm run build" "yarn build" "cargo build" "go build" "gradle build" "mvn compile")
BUILD_THRESHOLD=15
```

### 测试类命令
```bash
# 测试类命令
TEST_COMMANDS=("npm test" "yarn test" "pytest" "jest" "cargo test" "go test" "mvn test")
TEST_THRESHOLD=10
```

### 安装类命令
```bash
# 安装类命令（较高阈值，因为通常需要很长时间）
INSTALL_COMMANDS=("npm install" "yarn install" "pip install" "brew install" "apt install")
INSTALL_THRESHOLD=60
```

### 部署类命令
```bash
# 部署类命令（总是通知，无论时间）
DEPLOY_COMMANDS=("docker push" "kubectl apply" "terraform apply" "ansible-playbook")
DEPLOY_THRESHOLD=0
```

## 配置示例

### 开发环境配置
适合日常开发工作的配置：

```bash
# 基础设置
ENABLE_AUTO_NOTIFY=true
AUTO_NOTIFY_THRESHOLD=20
SHOW_COMMAND_DETAILS=true
ENABLE_TIME_TRACKING=true

# 忽略更多日常命令
IGNORE_COMMANDS=("cd" "ls" "pwd" "echo" "cat" "less" "more" "vi" "vim" "nano" "man" "help" "history" "clear" "exit" "grep" "find" "ps" "top" "htop" "tail" "head")

# 关注开发相关的重要命令
IMPORTANT_COMMANDS=("npm" "yarn" "cargo" "docker" "git push" "git pull" "pytest" "jest" "make")

# 构建命令快速通知
BUILD_THRESHOLD=10
TEST_THRESHOLD=5
```

### 生产环境配置
适合服务器运维的配置：

```bash
# 基础设置
ENABLE_AUTO_NOTIFY=true
AUTO_NOTIFY_THRESHOLD=60
SHOW_COMMAND_DETAILS=false
INCLUDE_WORKING_DIR=true

# 关注部署和运维命令
IMPORTANT_COMMANDS=("docker" "kubectl" "systemctl" "service" "nginx" "apache2" "mysql" "postgresql" "redis")

# 部署命令立即通知
DEPLOY_THRESHOLD=0
```

### 极简配置
只关注最重要通知的配置：

```bash
# 基础设置
ENABLE_AUTO_NOTIFY=true
AUTO_NOTIFY_THRESHOLD=120
SHOW_COMMAND_DETAILS=false

# 最小化重要命令列表
IMPORTANT_COMMANDS=("git push" "docker push" "kubectl apply")

# 忽略大部分命令
IGNORE_COMMANDS=("cd" "ls" "pwd" "echo" "cat" "less" "more" "vi" "vim" "nano" "man" "help" "history" "clear" "exit" "grep" "find" "ps" "top" "htop" "tail" "head" "curl" "wget" "ssh" "scp")
```

## 动态配置

### 运行时切换
```bash
# 临时禁用通知
termwatch_toggle

# 查看当前状态
termwatch_status
```

### 环境变量覆盖
可以通过环境变量临时覆盖配置：

```bash
# 临时设置不同的阈值
export AUTO_NOTIFY_THRESHOLD=60
some_long_command

# 临时禁用自动通知
export ENABLE_AUTO_NOTIFY=false
batch_of_commands
```

## 配置验证

### 检查配置语法
```bash
# 测试配置文件是否有语法错误
bash -n ~/.termwatch/config/auto_notify.conf
```

### 查看当前配置
```bash
# 显示所有配置项
source ~/.termwatch/config/auto_notify.conf
echo "启用状态: $ENABLE_AUTO_NOTIFY"
echo "通知阈值: $AUTO_NOTIFY_THRESHOLD"
echo "忽略命令数: ${#IGNORE_COMMANDS[@]}"
echo "重要命令数: ${#IMPORTANT_COMMANDS[@]}"
```

### 重新加载配置
```bash
# 重新加载扩展配置
source ~/.termwatch/zsh_hooks.sh

# 或重新加载整个 shell 配置
source ~/.zshrc
```

## 配置备份和恢复

### 备份配置
```bash
# 创建配置备份
cp ~/.termwatch/config/auto_notify.conf ~/.termwatch/config/auto_notify.conf.backup.$(date +%Y%m%d)
```

### 恢复配置  
```bash
# 从备份恢复
cp ~/.termwatch/config/auto_notify.conf.backup.20240128 ~/.termwatch/config/auto_notify.conf

# 重新加载配置
source ~/.termwatch/zsh_hooks.sh
```

### 重置为默认配置
```bash
# 删除配置文件，重新生成默认配置
rm ~/.termwatch/config/auto_notify.conf
source ~/.termwatch/auto_notify.sh  # 这会重新生成默认配置
```

## 调试配置

### 启用调试模式
在配置文件中添加：

```bash
# 调试模式
DEBUG_AUTO_NOTIFY=true
VERBOSE_LOGGING=true
```

### 查看调试信息
```bash
# 查看扩展运行日志
tail -f ~/.termwatch/logs/termwatch.log | grep AUTO_NOTIFY
```

### 测试特定命令
```bash
# 测试命令是否会被监控
echo "测试命令: ls" | ~/.termwatch/auto_notify.sh should_monitor_command

# 测试命令是否为重要命令
echo "测试命令: npm" | ~/.termwatch/auto_notify.sh is_important_command
```

## 常见配置问题

### 1. 配置不生效
**原因**: 没有重新加载配置
**解决**: `source ~/.zshrc`

### 2. 通知太频繁
**解决**: 
- 增加 `AUTO_NOTIFY_THRESHOLD` 值
- 添加更多命令到 `IGNORE_COMMANDS`

### 3. 重要命令没有通知
**解决**:
- 检查命令是否在 `IGNORE_COMMANDS` 中
- 将命令添加到 `IMPORTANT_COMMANDS`
- 使用强制通知模式 `!command`

### 4. 配置文件损坏
**解决**:
```bash
# 备份损坏的配置
mv ~/.termwatch/config/auto_notify.conf ~/.termwatch/config/auto_notify.conf.broken

# 重新生成默认配置
source ~/.termwatch/auto_notify.sh
```

## 扩展配置

### 与 TermWatch 基础配置的关系
Auto-Notify 扩展完全继承 TermWatch 的基础配置：
- 推送服务配置（Bark、Server酱）
- 通知模板和样式
- 静音时间设置
- 日志配置

### 配置优先级
1. 环境变量
2. `~/.termwatch/config/auto_notify.conf`
3. 扩展默认值
4. TermWatch 基础配置

## 更多信息

- [使用指南](usage.md)
- [TermWatch 主配置](../../config/user.conf.example)
- [故障排除](../../docs/troubleshooting.md)