# TermWatch 故障排除指南

## 常见问题解决方案

### 1. 通知相关问题

#### 问题：通知不出现
**可能原因和解决方案：**

1. **通知权限未授权**
   ```bash
   # 检查系统通知设置
   open "x-apple.systempreferences:com.apple.preference.notifications"
   
   # 查找"终端"并确保以下选项已启用：
   # - 允许通知
   # - 横幅
   # - 声音
   # - 在锁定屏幕上显示
   ```

2. **terminal-notifier 未安装或损坏**
   ```bash
   # 检查 terminal-notifier
   which terminal-notifier
   
   # 重新安装
   brew uninstall terminal-notifier
   brew install terminal-notifier
   
   # 测试
   terminal-notifier -message "测试" -title "TermWatch"
   ```

3. **osascript 权限问题**
   ```bash
   # 测试 osascript
   osascript -e 'display notification "测试" with title "TermWatch"'
   
   # 如果失败，检查"安全性与隐私" > "隐私" > "辅助功能"
   ```

#### 问题：通知延迟很严重
**解决方案：**

1. **检查系统负载**
   ```bash
   # 查看 CPU 使用率
   top -l 1 | grep "CPU usage"
   
   # 查看内存使用
   memory_pressure
   ```

2. **优化通知设置**
   ```bash
   # 减少通知频率
   termwatch config set MAX_NOTIFICATIONS_PER_HOUR 3
   
   # 启用去重功能
   termwatch config set ENABLE_DEDUPLICATION true
   ```

3. **重启通知中心**
   ```bash
   sudo killall NotificationCenter
   ```

### 2. Apple Watch 问题

#### 问题：Apple Watch 未收到通知
**排查步骤：**

1. **检查配对状态**
   ```bash
   # 检查 Apple Watch 应用是否存在
   ls /Applications/Watch.app
   
   # 检查配对状态（在 iPhone 上）
   # 设置 > 通用 > Apple Watch
   ```

2. **检查通知镜像设置**
   - iPhone: Watch 应用 > 通知
   - 确保"镜像我的 iPhone"已开启
   - 检查"终端"应用通知设置

3. **检查 Apple Watch 设置**
   ```bash
   # 在 Apple Watch 上
   # 设置 > 通知 > 镜像 iPhone 提醒
   ```

4. **测试连接**
   ```bash
   # 发送测试通知
   notify_info "Apple Watch 测试"
   
   # 等待几秒钟检查手表
   ```

#### 问题：通知在 iPhone 显示但 Apple Watch 不显示
**解决方案：**

1. **重新配对 Apple Watch**
   - 在 Watch 应用中取消配对
   - 重新配对设备

2. **重启设备**
   ```bash
   # 重启 iPhone 和 Apple Watch
   # 然后测试通知功能
   ```

3. **检查勿扰模式**
   - iPhone 和 Apple Watch 的勿扰模式
   - 确保都已关闭或正确配置

### 3. 安装和配置问题

#### 问题：安装脚本失败
**常见错误和解决方案：**

1. **权限错误**
   ```bash
   # 确保不是以 root 身份运行
   whoami  # 应该显示你的用户名，不是 root
   
   # 检查目录权限
   ls -la ~/
   mkdir -p ~/.termwatch && echo "权限正常"
   ```

2. **Homebrew 相关错误**
   ```bash
   # 检查 Homebrew
   brew --version
   
   # 修复 Homebrew
   brew doctor
   brew update
   
   # 重新安装 terminal-notifier
   brew install terminal-notifier
   ```

3. **shell 配置错误**
   ```bash
   # 检查当前 shell
   echo $SHELL
   
   # 手动添加配置
   echo 'source ~/.termwatch/src/shell-integration.sh' >> ~/.zshrc
   source ~/.zshrc
   ```

#### 问题：函数未定义
**错误信息：** `bash: notify: command not found`

**解决方案：**
```bash
# 1. 检查 shell 集成是否正确加载
which notify

# 2. 手动加载 shell 集成
source ~/.termwatch/src/shell-integration.sh

# 3. 检查配置文件
grep -n "termwatch" ~/.zshrc ~/.bash_profile ~/.bashrc

# 4. 重新添加配置
echo 'source ~/.termwatch/src/shell-integration.sh' >> ~/.zshrc
source ~/.zshrc
```

### 4. 性能问题

#### 问题：命令执行变慢
**可能原因：**
- 自动监控钩子影响性能
- 日志文件过大

**解决方案：**
```bash
# 1. 禁用自动监控
termwatch disable

# 2. 清理日志文件
rm ~/.termwatch/logs/*.log

# 3. 调整日志级别
termwatch config set LOG_LEVEL ERROR

# 4. 重新启用监控
termwatch enable
```

#### 问题：内存占用过高
**解决方案：**
```bash
# 1. 清理缓存
rm -rf ~/.termwatch/cache/*

# 2. 限制日志文件大小
termwatch config set LOG_LEVEL WARN

# 3. 减少通知频率
termwatch config set MAX_NOTIFICATIONS_PER_HOUR 5
```

### 5. 配置问题

#### 问题：配置更改未生效
**排查步骤：**

1. **检查配置文件优先级**
   ```bash
   # 配置加载顺序：用户 > 系统 > 默认
   ls -la ~/.termwatch/config/
   
   # 查看当前配置
   termwatch config show
   ```

2. **重新加载配置**
   ```bash
   # 重新加载 shell 集成
   source ~/.termwatch/src/shell-integration.sh
   
   # 或重启终端
   ```

3. **验证配置语法**
   ```bash
   # 检查配置文件语法
   bash -n ~/.termwatch/config/user.conf
   ```

#### 问题：配置文件损坏
**解决方案：**
```bash
# 1. 备份当前配置
cp ~/.termwatch/config/user.conf ~/.termwatch/config/user.conf.backup

# 2. 重置配置
termwatch config reset user

# 3. 重新创建配置
termwatch config init

# 4. 手动恢复重要设置
nano ~/.termwatch/config/user.conf
```

### 6. 兼容性问题

#### 问题：在特定 shell 中不工作
**不同 shell 的解决方案：**

1. **zsh 问题**
   ```bash
   # 检查 zsh 配置
   echo $ZSH_VERSION
   
   # 确保函数数组支持
   setopt FUNCTION_ARGZERO
   
   # 手动添加钩子
   autoload -U add-zsh-hook
   add-zsh-hook preexec _termwatch_preexec
   add-zsh-hook precmd _termwatch_precmd
   ```

2. **bash 版本问题**
   ```bash
   # 检查 bash 版本
   echo $BASH_VERSION
   
   # bash < 4.0 不支持某些功能
   if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
       echo "建议升级到 bash 4.0+"
       brew install bash
   fi
   ```

3. **fish shell**
   ```bash
   # fish 不直接支持，需要特殊配置
   # 创建 ~/.config/fish/config.fish
   echo 'source ~/.termwatch/src/shell-integration.sh' >> ~/.config/fish/config.fish
   ```

### 7. 调试技巧

#### 启用详细日志
```bash
# 设置调试级别
termwatch config set LOG_LEVEL DEBUG

# 实时查看日志
tail -f ~/.termwatch/logs/termwatch.log
```

#### 手动测试组件
```bash
# 测试配置加载
source ~/.termwatch/src/config.sh && echo "配置加载成功"

# 测试通知核心
bash ~/.termwatch/src/notifier.sh "TEST" "测试消息"

# 测试 shell 集成
source ~/.termwatch/src/shell-integration.sh && echo "集成加载成功"
```

#### 检查系统状态
```bash
# 完整系统检查
termwatch status

# 运行所有测试
~/.termwatch/scripts/test-notification.sh

# 检查进程
ps aux | grep termwatch
```

### 8. 高级故障排除

#### 完全重新安装
```bash
# 1. 完全卸载
./scripts/uninstall.sh

# 2. 清理残留文件
rm -rf ~/.termwatch*
grep -v termwatch ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc

# 3. 重新安装
./install.sh
```

#### 手动修复权限
```bash
# 修复文件权限
find ~/.termwatch -type f -name "*.sh" -exec chmod +x {} \;

# 修复目录权限
find ~/.termwatch -type d -exec chmod 755 {} \;

# 修复配置文件权限
chmod 644 ~/.termwatch/config/*.conf
```

#### 网络相关问题
```bash
# 如果使用 webhook 或远程功能
# 检查网络连接
ping github.com

# 检查防火墙设置
sudo pfctl -s rules | grep block

# 测试 curl
curl -I https://api.github.com
```

## 获取帮助

如果以上解决方案都无法解决问题，请：

1. **收集诊断信息**
   ```bash
   # 生成诊断报告
   {
       echo "=== 系统信息 ==="
       sw_vers
       echo
       echo "=== TermWatch 状态 ==="
       termwatch status
       echo
       echo "=== 配置信息 ==="
       termwatch config show
       echo
       echo "=== 最近日志 ==="
       tail -20 ~/.termwatch/logs/termwatch.log
   } > termwatch-diagnosis.txt
   ```

2. **在 GitHub 提交 Issue**
   - 附上诊断报告
   - 详细描述问题现象
   - 说明重现步骤

3. **社区求助**
   - 搜索已有的 Issues
   - 查看 Wiki 文档
   - 参与社区讨论

## 预防措施

1. **定期更新**
   ```bash
   # 每月更新一次
   git pull origin main && ./install.sh
   ```

2. **定期清理**
   ```bash
   # 每周清理日志
   find ~/.termwatch/logs -name "*.log" -mtime +7 -delete
   ```

3. **备份配置**
   ```bash
   # 在重要更改前备份
   cp ~/.termwatch/config/user.conf ~/termwatch-backup-$(date +%Y%m%d).conf
   ```