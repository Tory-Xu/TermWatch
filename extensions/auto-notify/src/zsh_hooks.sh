#!/bin/bash

# TermWatch Auto-Notify Extension - ZSH Hooks
# ZSH 钩子函数，用于自动监控命令执行

# 加载自动通知模块
source "$HOME/.termwatch/auto_notify.sh"

# 全局变量
TERMWATCH_COMMAND=""
TERMWATCH_START_TIME=""
TERMWATCH_FORCE_NOTIFY=false

# preexec 钩子 - 命令执行前调用
termwatch_preexec() {
    local command="$1"
    
    # 跳过空命令或历史命令
    [[ -z "$command" || "$command" =~ ^[[:space:]]*$ ]] && return
    
    # 检查是否为强制通知命令（以 ! 开头）
    if [[ "$command" =~ ^[[:space:]]*! ]]; then
        TERMWATCH_FORCE_NOTIFY=true
        command="${command#*!}"  # 移除 ! 前缀
    else
        TERMWATCH_FORCE_NOTIFY=false
    fi
    
    # 记录命令和开始时间
    TERMWATCH_COMMAND="$command"
    TERMWATCH_START_TIME=$(date +%s)
    
    # 记录到缓存文件
    record_command_start "$command"
}

# precmd 钩子 - 命令执行后、下一个提示符显示前调用
termwatch_precmd() {
    local exit_code=$?
    
    # 如果没有记录的命令，直接返回
    [[ -z "$TERMWATCH_COMMAND" ]] && return
    
    # 计算执行时间
    local end_time=$(date +%s)
    local duration=$((end_time - TERMWATCH_START_TIME))
    
    # 检查是否需要通知
    local should_notify=false
    
    # 强制通知模式
    if [[ "$TERMWATCH_FORCE_NOTIFY" == "true" ]]; then
        should_notify=true
    # 重要命令检查
    elif is_important_command "$TERMWATCH_COMMAND"; then
        should_notify=true
    # 时间阈值检查
    elif [[ $duration -ge $AUTO_NOTIFY_THRESHOLD ]] && should_monitor_command "$TERMWATCH_COMMAND"; then
        should_notify=true
    fi
    
    # 发送通知
    if [[ "$should_notify" == "true" && "$ENABLE_AUTO_NOTIFY" == "true" ]]; then
        if [[ "$TERMWATCH_FORCE_NOTIFY" == "true" ]] || is_important_command "$TERMWATCH_COMMAND"; then
            force_notify_command "$TERMWATCH_COMMAND" "$exit_code"
        else
            send_command_notification "$TERMWATCH_COMMAND" "$exit_code" "$duration"
        fi
    fi
    
    # 清理变量
    TERMWATCH_COMMAND=""
    TERMWATCH_START_TIME=""
    TERMWATCH_FORCE_NOTIFY=false
    
    # 处理命令完成（清理缓存文件）
    handle_command_completion "$exit_code"
}

# 注册钩子函数
add_termwatch_hooks() {
    # 检查现有钩子，避免重复添加
    if [[ ! " ${preexec_functions[@]} " =~ " termwatch_preexec " ]]; then
        preexec_functions+=(termwatch_preexec)
    fi
    
    if [[ ! " ${precmd_functions[@]} " =~ " termwatch_precmd " ]]; then
        precmd_functions+=(termwatch_precmd)
    fi
}

# 移除钩子函数
remove_termwatch_hooks() {
    preexec_functions=("${preexec_functions[@]/termwatch_preexec}")
    precmd_functions=("${precmd_functions[@]/termwatch_precmd}")
}

# 切换自动通知状态
toggle_auto_notify() {
    if [[ "$ENABLE_AUTO_NOTIFY" == "true" ]]; then
        ENABLE_AUTO_NOTIFY=false
        echo "🔕 TermWatch 自动通知已禁用"
        
        # 更新配置文件
        if [[ -f "$AUTO_NOTIFY_CONFIG" ]]; then
            sed -i '' 's/ENABLE_AUTO_NOTIFY=true/ENABLE_AUTO_NOTIFY=false/' "$AUTO_NOTIFY_CONFIG" 2>/dev/null || \
            sed -i 's/ENABLE_AUTO_NOTIFY=true/ENABLE_AUTO_NOTIFY=false/' "$AUTO_NOTIFY_CONFIG"
        fi
    else
        ENABLE_AUTO_NOTIFY=true  
        echo "🔔 TermWatch 自动通知已启用"
        
        # 更新配置文件
        if [[ -f "$AUTO_NOTIFY_CONFIG" ]]; then
            sed -i '' 's/ENABLE_AUTO_NOTIFY=false/ENABLE_AUTO_NOTIFY=true/' "$AUTO_NOTIFY_CONFIG" 2>/dev/null || \
            sed -i 's/ENABLE_AUTO_NOTIFY=false/ENABLE_AUTO_NOTIFY=true/' "$AUTO_NOTIFY_CONFIG"
        fi
    fi
}

# 显示当前状态
show_auto_notify_status() {
    echo "=== TermWatch 自动通知状态 ==="
    echo "扩展版本: Auto-Notify v1.0.0"
    echo "状态: $([ "$ENABLE_AUTO_NOTIFY" == "true" ] && echo "✅ 已启用" || echo "❌ 已禁用")"
    echo "时间阈值: ${AUTO_NOTIFY_THRESHOLD}秒"
    echo "监控的钩子: preexec, precmd"
    echo ""
    echo "配置文件: $AUTO_NOTIFY_CONFIG"
    echo "缓存目录: $CACHE_DIR"
    echo ""
    echo "使用方法:"
    echo "  普通命令: command     # 超过阈值时通知"
    echo "  强制通知: !command    # 无论时间长短都通知"
    echo "  切换状态: termwatch_toggle"
    echo ""
    echo "钩子状态:"
    if declare -f termwatch_preexec >/dev/null 2>&1; then
        echo "  ✅ termwatch_preexec 已加载"
    else
        echo "  ❌ termwatch_preexec 未加载"
    fi
    
    if declare -f termwatch_precmd >/dev/null 2>&1; then
        echo "  ✅ termwatch_precmd 已加载"
    else
        echo "  ❌ termwatch_precmd 未加载"
    fi
}

# 创建便捷别名
alias termwatch_toggle='toggle_auto_notify'
alias termwatch_status='show_auto_notify_status'

# 自动注册钩子
add_termwatch_hooks