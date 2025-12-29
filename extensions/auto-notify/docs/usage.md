# Auto-Notify 扩展使用指南

## 概述

TermWatch Auto-Notify 扩展为 TermWatch 添加智能的命令执行监控功能，自动识别重要命令并在完成时发送通知。

## 安装

### 通过主安装脚本
```bash
cd /path/to/TermWatch
./install.sh
# 在配置向导中选择 "4️⃣ 安装 Auto-Notify 扩展"
```

### 独立安装
```bash
cd /path/to/TermWatch
bash extensions/auto-notify/scripts/install.sh
```

## 基础用法

### 自动监控
扩展会自动监控所有命令的执行：

```bash
# 这些命令如果执行超过30秒会自动通知
npm install
docker build .
make clean && make
git clone https://github.com/large-repo.git

# 这些命令会被智能过滤，不会通知
cd /some/path
ls -la
pwd
echo "hello"
```

### 强制通知模式
使用 `!` 前缀可以强制通知任何命令，无论执行时间：

```bash
!git status          # 立即通知 git 状态
!ls -la              # 立即通知目录列表
!echo "完成了!"       # 立即通知消息
!pwd                 # 立即通知当前目录
```

### 重要命令自动识别
以下命令会被自动识别为重要命令，无论执行时间都会通知：

```bash
# 构建类命令
make
npm run build
yarn build
cargo build
go build

# 测试类命令
npm test
pytest
jest
cargo test

# 部署类命令
docker push
kubectl apply
git push
```

## 管理功能

### 查看状态
```bash
termwatch_status
```
输出示例：
```
=== TermWatch 自动通知状态 ===
扩展版本: Auto-Notify v1.0.0
状态: ✅ 已启用
时间阈值: 30秒
监控的钩子: preexec, precmd

配置文件: /Users/username/.termwatch/config/auto_notify.conf
缓存目录: /Users/username/.termwatch/cache

使用方法:
  普通命令: command     # 超过阈值时通知
  强制通知: !command    # 无论时间长短都通知
  切换状态: termwatch_toggle
```

### 切换开关
```bash
termwatch_toggle
```
输出示例：
```
🔕 TermWatch 自动通知已禁用
```
或
```
🔔 TermWatch 自动通知已启用
```

## 脚本集成

### 日志辅助函数
扩展提供了一系列日志辅助函数，可以在脚本中使用：

```bash
#!/bin/bash

# 加载日志辅助函数
source ~/.termwatch/log_helpers.sh

# 基础日志输出
log_success "操作成功完成"
log_error "发生了错误"
log_warning "这是一个警告"
log_info "这是信息"
```

### 命令包装器
使用命令包装器可以自动判断命令成功失败：

```bash
#!/bin/bash
source ~/.termwatch/log_helpers.sh

# 简单包装器
run_with_notify "npm install" "安装依赖包"
run_with_notify "npm run build" "构建项目"

# 带时间戳的包装器
run_with_timestamp "docker build -t myapp ." "构建 Docker 镜像"
```

### 批量任务执行
处理多个任务时可以使用批量执行器：

```bash
#!/bin/bash
source ~/.termwatch/log_helpers.sh

# 定义任务列表
tasks=(
    "npm install"
    "npm run lint"
    "npm run test"
    "npm run build"
)

# 批量执行
run_batch_with_notify "前端构建流程" "${tasks[@]}"
```

## 配置选项

### 配置文件位置
主配置文件：`~/.termwatch/config/auto_notify.conf`

### 主要配置项

```bash
# 是否启用自动通知
ENABLE_AUTO_NOTIFY=true

# 通知阈值（秒）
AUTO_NOTIFY_THRESHOLD=30

# 忽略的命令列表
IGNORE_COMMANDS=("cd" "ls" "pwd" "echo" "cat" "less" "more" "vi" "vim")

# 重要命令列表（无论执行时间都会通知）
IMPORTANT_COMMANDS=("make" "npm" "yarn" "cargo" "docker" "kubectl" "git push")

# 强制通知的命令前缀
FORCE_NOTIFY_PREFIX="!"
```

### 高级配置

```bash
# 是否显示命令执行的详细信息
SHOW_COMMAND_DETAILS=true

# 命令截断长度
COMMAND_TRUNCATE_LENGTH=50

# 是否启用命令执行时间统计
ENABLE_TIME_TRACKING=true

# 是否在通知中包含当前目录信息
INCLUDE_WORKING_DIR=false
```

### 命令分类配置
可以为不同类型的命令设置不同的通知策略：

```bash
# 构建类命令（较低阈值）
BUILD_COMMANDS=("make" "npm run build" "yarn build")
BUILD_THRESHOLD=15

# 测试类命令
TEST_COMMANDS=("npm test" "yarn test" "pytest" "jest")
TEST_THRESHOLD=10

# 安装类命令（较高阈值）
INSTALL_COMMANDS=("npm install" "yarn install" "pip install")
INSTALL_THRESHOLD=60

# 部署类命令（总是通知）
DEPLOY_COMMANDS=("docker push" "kubectl apply")
DEPLOY_THRESHOLD=0
```

## iTerm2 触发器（可选）

如果你使用 iTerm2，可以配置触发器来识别特定的日志输出格式：

### 配置步骤
1. 打开 iTerm2 → Preferences → Profiles → Advanced → Triggers
2. 点击 "Edit" 按钮
3. 添加以下触发器：

| 正则表达式 | 动作 | 参数 |
|------------|------|------|
| `^\\[TERMWATCH\\] SUCCESS: (.+)$` | Run Command | `bash ~/.termwatch/termwatch.sh success "\\1"` |
| `^\\[TERMWATCH\\] ERROR: (.+)$` | Run Command | `bash ~/.termwatch/termwatch.sh error "\\1"` |
| `^Build succeeded` | Run Command | `bash ~/.termwatch/termwatch.sh success "构建成功"` |
| `^Build failed` | Run Command | `bash ~/.termwatch/termwatch.sh error "构建失败"` |

### 使用触发器
配置完成后，以下日志输出会自动触发通知：

```bash
echo "[TERMWATCH] SUCCESS: 部署完成"
echo "[TERMWATCH] ERROR: 测试失败"
echo "Build succeeded"
echo "Build failed"
```

## 故障排除

### 扩展不工作？
1. 检查扩展是否正确安装：
   ```bash
   ls ~/.termwatch/auto_notify.sh
   ls ~/.termwatch/zsh_hooks.sh
   ```

2. 检查配置是否加载：
   ```bash
   termwatch_status
   ```

3. 重新加载 shell 配置：
   ```bash
   source ~/.zshrc
   ```

### 钩子函数未生效？
1. 检查钩子函数是否加载：
   ```bash
   declare -f termwatch_preexec
   declare -f termwatch_precmd
   ```

2. 检查钩子数组：
   ```bash
   echo ${preexec_functions[@]}
   echo ${precmd_functions[@]}
   ```

3. 手动加载钩子脚本：
   ```bash
   source ~/.termwatch/zsh_hooks.sh
   ```

### 通知没有发送？
1. 测试基础通知功能：
   ```bash
   termwatch --test
   ```

2. 检查配置：
   ```bash
   grep ENABLE_AUTO_NOTIFY ~/.termwatch/config/auto_notify.conf
   ```

3. 检查命令是否在忽略列表中：
   ```bash
   grep -A 5 IGNORE_COMMANDS ~/.termwatch/config/auto_notify.conf
   ```

### 命令被误过滤？
1. 使用强制通知模式：
   ```bash
   !your_command
   ```

2. 检查时间阈值设置：
   ```bash
   grep AUTO_NOTIFY_THRESHOLD ~/.termwatch/config/auto_notify.conf
   ```

3. 将命令添加到重要命令列表：
   ```bash
   nano ~/.termwatch/config/auto_notify.conf
   # 在 IMPORTANT_COMMANDS 中添加你的命令
   ```

## 卸载

### 使用卸载脚本
```bash
bash extensions/auto-notify/scripts/uninstall.sh
```

### 或使用内置卸载脚本
```bash
bash ~/.termwatch/uninstall_auto_notify.sh
```

### 手动卸载
```bash
# 删除扩展文件
rm -f ~/.termwatch/{auto_notify.sh,zsh_hooks.sh,log_helpers.sh}
rm -f ~/.termwatch/config/auto_notify.conf
rm -rf ~/.termwatch/cache

# 从 shell 配置中移除相关行
# 编辑 ~/.zshrc，删除 "TermWatch Auto-Notify Extension" 相关行

# 重新加载配置
source ~/.zshrc
```

## 最佳实践

### 1. 合理设置阈值
- 开发环境：建议 15-30 秒
- 生产环境：建议 60-120 秒
- 个人使用：建议 30 秒

### 2. 自定义忽略列表
根据你的工作习惯，添加不需要通知的命令：
```bash
IGNORE_COMMANDS=("cd" "ls" "pwd" "echo" "cat" "grep" "find" "ps" "top")
```

### 3. 合理使用强制通知
- 用于调试时的快速命令
- 用于需要立即知道结果的操作
- 避免滥用，以免影响通知的价值

### 4. 脚本集成
在重要的自动化脚本中集成日志函数：
```bash
#!/bin/bash
source ~/.termwatch/log_helpers.sh

log_info "开始执行部署脚本"
run_with_notify "docker build -t app ." "构建镜像"
run_with_notify "docker push app:latest" "推送镜像"
log_success "部署脚本执行完成"
```

### 5. 定期清理
定期检查配置文件，移除不再使用的命令：
```bash
# 查看配置
cat ~/.termwatch/config/auto_notify.conf

# 编辑配置
nano ~/.termwatch/config/auto_notify.conf
```

## 更多信息

- [TermWatch 主文档](../../README.md)
- [配置说明](configuration.md)
- [故障排除指南](../../docs/troubleshooting.md)