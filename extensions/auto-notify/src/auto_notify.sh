#!/bin/bash

# TermWatch Auto-Notify Extension
# 智能监控命令执行并自动发送通知

# 配置文件路径
CONFIG_DIR="$HOME/.termwatch"
CACHE_DIR="$CONFIG_DIR/cache"
AUTO_NOTIFY_CONFIG="$CONFIG_DIR/config/auto_notify.conf"

# 确保目录存在
mkdir -p "$CACHE_DIR"

# 默认配置
AUTO_NOTIFY_THRESHOLD=30  # 超过30秒的命令才通知
ENABLE_AUTO_NOTIFY=true
IGNORE_COMMANDS=("cd" "ls" "pwd" "echo" "cat" "less" "more" "vi" "vim" "nano" "man" "help" "history" "clear" "exit")
IMPORTANT_COMMANDS=("make" "npm" "yarn" "cargo" "docker" "kubectl" "git" "pytest" "jest" "gradle" "mvn" "bundle" "pip" "composer")

# 加载用户配置
if [[ -f "$AUTO_NOTIFY_CONFIG" ]]; then
    source "$AUTO_NOTIFY_CONFIG"
fi

# 记录命令开始时间
record_command_start() {
    local command="$1"
    local start_time=$(date +%s)
    
    # 检查是否应该监控此命令
    if should_monitor_command "$command"; then
        echo "$command|$start_time" > "$CACHE_DIR/current_command"
    fi
}

# 处理命令完成
handle_command_completion() {
    local exit_code="$1"
    local cache_file="$CACHE_DIR/current_command"
    
    [[ ! -f "$cache_file" ]] && return
    
    local line=$(cat "$cache_file")
    local command=$(echo "$line" | cut -d'|' -f1)
    local start_time=$(echo "$line" | cut -d'|' -f2)
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # 清除缓存
    rm -f "$cache_file"
    
    # 检查是否达到通知阈值
    if [[ $duration -ge $AUTO_NOTIFY_THRESHOLD ]]; then
        send_command_notification "$command" "$exit_code" "$duration"
    fi
}

# 判断是否应该监控命令
should_monitor_command() {
    local command="$1"
    local cmd_name=$(echo "$command" | awk '{print $1}')
    
    # 移除路径，只保留命令名
    cmd_name=$(basename "$cmd_name")
    
    # 检查忽略列表
    for ignore_cmd in "${IGNORE_COMMANDS[@]}"; do
        if [[ "$cmd_name" == "$ignore_cmd" ]]; then
            return 1
        fi
    done
    
    # 如果命令很短，可能不值得监控
    if [[ ${#command} -lt 5 ]]; then
        return 1
    fi
    
    return 0
}

# 发送命令完成通知
send_command_notification() {
    local command="$1"
    local exit_code="$2"
    local duration="$3"
    
    local duration_str=$(format_duration "$duration")
    local cmd_short=$(echo "$command" | cut -c1-50)
    [[ ${#command} -gt 50 ]] && cmd_short="${cmd_short}..."
    
    if [[ $exit_code -eq 0 ]]; then
        local message="命令: $cmd_short\n耗时: $duration_str"
        bash "$HOME/.termwatch/termwatch.sh" success "$message"
    else
        local message="命令: $cmd_short\n耗时: $duration_str\n退出码: $exit_code"
        bash "$HOME/.termwatch/termwatch.sh" error "$message"
    fi
}

# 格式化持续时间
format_duration() {
    local duration="$1"
    
    if [[ $duration -lt 60 ]]; then
        echo "${duration}秒"
    elif [[ $duration -lt 3600 ]]; then
        local minutes=$((duration / 60))
        local seconds=$((duration % 60))
        echo "${minutes}分${seconds}秒"
    else
        local hours=$((duration / 3600))
        local minutes=$(((duration % 3600) / 60))
        local seconds=$((duration % 60))
        echo "${hours}时${minutes}分${seconds}秒"
    fi
}

# 检查是否为重要命令（强制通知）
is_important_command() {
    local command="$1"
    local cmd_name=$(echo "$command" | awk '{print $1}' | xargs basename)
    
    for important_cmd in "${IMPORTANT_COMMANDS[@]}"; do
        if [[ "$cmd_name" == *"$important_cmd"* ]]; then
            return 0
        fi
    done
    
    return 1
}

# 强制通知（用于重要命令，无论时间长短）
force_notify_command() {
    local command="$1"
    local exit_code="$2"
    
    local cmd_short=$(echo "$command" | cut -c1-50)
    [[ ${#command} -gt 50 ]] && cmd_short="${cmd_short}..."
    
    if [[ $exit_code -eq 0 ]]; then
        bash "$HOME/.termwatch/termwatch.sh" success "重要命令完成: $cmd_short"
    else
        bash "$HOME/.termwatch/termwatch.sh" error "重要命令失败: $cmd_short (退出码: $exit_code)"
    fi
}

# 生成默认配置文件
generate_default_config() {
    mkdir -p "$(dirname "$AUTO_NOTIFY_CONFIG")"
    cat > "$AUTO_NOTIFY_CONFIG" << 'EOF'
# TermWatch Auto-Notify Extension 配置

# 是否启用自动通知
ENABLE_AUTO_NOTIFY=true

# 通知阈值（秒）- 只有执行时间超过此值的命令才会通知
AUTO_NOTIFY_THRESHOLD=30

# 忽略的命令列表（不会触发通知）
IGNORE_COMMANDS=("cd" "ls" "pwd" "echo" "cat" "less" "more" "vi" "vim" "nano" "man" "help" "history" "clear" "exit" "which" "whereis" "whoami" "date" "uptime")

# 重要命令列表（无论执行时间都会通知）
IMPORTANT_COMMANDS=("make" "npm" "yarn" "pnpm" "cargo" "docker" "kubectl" "git push" "git pull" "pytest" "jest" "gradle" "mvn" "bundle" "pip install" "composer" "brew install" "apt install" "yum install")

# 强制通知的命令前缀（以 ! 开头的命令总是通知）
FORCE_NOTIFY_PREFIX="!"
EOF
}

# 如果配置文件不存在，创建默认配置
if [[ ! -f "$AUTO_NOTIFY_CONFIG" ]]; then
    generate_default_config
fi