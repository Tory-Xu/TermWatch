# TermWatch 设置指南

## 安装前准备

### 系统要求
- macOS 10.14 或更高版本
- 已配对的 Apple Watch（推荐）
- Homebrew（推荐）

### 检查通知权限
在安装之前，建议检查系统通知设置：

1. 打开 `系统偏好设置` > `通知`
2. 找到 `终端` 应用
3. 确保允许通知选项已开启

## 安装步骤

### 方法 1: 一键安装（推荐）

```bash
# 克隆项目
git clone https://github.com/yourusername/TermWatch.git
cd TermWatch

# 运行安装脚本
./install.sh
```

### 方法 2: 手动安装

```bash
# 1. 安装 terminal-notifier
brew install terminal-notifier

# 2. 创建配置目录
mkdir -p ~/.termwatch/{config,logs,cache}

# 3. 复制文件
cp -r src ~/.termwatch/
cp -r config ~/.termwatch/

# 4. 添加到 shell 配置
echo 'source ~/.termwatch/src/shell-integration.sh' >> ~/.zshrc

# 5. 重载配置
source ~/.zshrc
```

## Apple Watch 设置

### 启用通知同步

1. 打开 iPhone 上的 `Watch` 应用
2. 选择 `通知`
3. 确保 `镜像我的 iPhone` 已开启
4. 找到 `终端` 应用，确保通知已启用

### 自定义通知样式

在 Apple Watch 上：
1. 打开 `设置` > `通知`
2. 调整通知样式和提醒方式
3. 可以设置触觉反馈强度

## 基础配置

### 创建用户配置

```bash
# 创建用户配置文件
termwatch config init

# 编辑配置
nano ~/.termwatch/config/user.conf
```

### 常用配置选项

```bash
# 设置自动通知阈值为 60 秒
termwatch config set AUTO_NOTIFY_THRESHOLD 60

# 启用静音时间
termwatch config set ENABLE_QUIET_HOURS true
termwatch config set QUIET_HOURS_START 22
termwatch config set QUIET_HOURS_END 8

# 自定义通知声音
termwatch config set NOTIFICATION_SOUND glass

# 自定义通知消息
termwatch config set SUCCESS_TEMPLATE "🎉 任务搞定了！"
```

## 测试安装

### 基础功能测试

```bash
# 运行完整测试
./scripts/test-notification.sh

# 快速测试
termwatch test

# 发送测试通知
notify "Hello TermWatch!"
```

### 验证 Apple Watch 连接

```bash
# 发送测试通知到手表
notify_success "测试通知" && echo "请检查 Apple Watch 是否收到通知"
```

## 常见问题

### 通知未出现

1. **检查通知权限**
   ```bash
   # 系统偏好设置 > 通知 > 终端
   # 确保允许通知、横幅、声音等选项已启用
   ```

2. **检查 terminal-notifier**
   ```bash
   # 测试 terminal-notifier
   terminal-notifier -message "测试" -title "TermWatch"
   ```

3. **检查 Apple Watch 设置**
   - Watch 应用 > 通知 > 镜像我的 iPhone
   - 确保终端应用通知已启用

### Apple Watch 未收到通知

1. **检查配对状态**
   - 确保 Apple Watch 已正确配对
   - 检查蓝牙连接

2. **检查通知设置**
   ```bash
   # 在 iPhone 的 Watch 应用中
   # 通知 > 终端 > 允许通知
   ```

3. **检查距离**
   - 确保 iPhone 和 Apple Watch 在蓝牙范围内

### 性能问题

1. **通知延迟**
   ```bash
   # 检查系统负载
   top -l 1 | grep "CPU usage"
   
   # 检查通知队列
   termwatch status
   ```

2. **内存占用**
   ```bash
   # 清理日志
   rm ~/.termwatch/logs/*.log
   
   # 清理缓存
   rm -rf ~/.termwatch/cache/*
   ```

## 高级设置

### 自定义通知条件

```bash
# 只有在命令运行超过 2 分钟时才通知
termwatch config set AUTO_NOTIFY_THRESHOLD 120

# 限制每小时通知数量
termwatch config set MAX_NOTIFICATIONS_PER_HOUR 5
```

### 项目特定配置

为不同项目创建不同的配置：

```bash
# 在项目目录中创建 .termwatch.conf
echo "AUTO_NOTIFY_THRESHOLD=180" > .termwatch.conf
echo "SUCCESS_TEMPLATE='🚀 部署完成'" >> .termwatch.conf
```

### 集成到 CI/CD

```bash
# 在 CI 脚本中使用
if [[ -n "$TERMWATCH_WEBHOOK" ]]; then
    curl -X POST "$TERMWATCH_WEBHOOK" \
         -H "Content-Type: application/json" \
         -d '{"text":"构建完成"}'
fi
```

## 故障排除

### 重新安装

```bash
# 完全卸载
./scripts/uninstall.sh

# 重新安装
./install.sh
```

### 重置配置

```bash
# 重置用户配置
termwatch config reset user

# 重置所有配置
termwatch config reset all
```

### 查看日志

```bash
# 查看最新日志
tail -f ~/.termwatch/logs/termwatch.log

# 查看错误日志
grep ERROR ~/.termwatch/logs/termwatch.log
```

## 性能优化

### 减少通知频率

```bash
# 启用通知去重
termwatch config set ENABLE_DEDUPLICATION true

# 增加重复通知间隔
termwatch config set DUPLICATE_THRESHOLD 600
```

### 优化启动时间

```bash
# 禁用自动监控（如果不需要）
termwatch config set ENABLE_AUTO_MONITOR false

# 减少日志级别
termwatch config set LOG_LEVEL ERROR
```

## 更新和维护

### 更新 TermWatch

```bash
# 拉取最新代码
git pull origin main

# 重新安装
./install.sh
```

### 备份配置

```bash
# 备份用户配置
cp ~/.termwatch/config/user.conf ~/termwatch-backup.conf

# 恢复配置
cp ~/termwatch-backup.conf ~/.termwatch/config/user.conf
```

### 清理旧数据

```bash
# 清理 7 天前的日志
find ~/.termwatch/logs -name "*.log" -mtime +7 -delete

# 清理缓存
rm -rf ~/.termwatch/cache/*
```