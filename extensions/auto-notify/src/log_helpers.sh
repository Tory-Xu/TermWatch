#!/bin/bash

# TermWatch Auto-Notify Extension - Log Helpers
# 日志辅助函数，用于在脚本中输出特定格式的日志，触发 iTerm2 通知

# 输出成功日志
log_success() {
    echo "[TERMWATCH] SUCCESS: $1"
}

# 输出错误日志  
log_error() {
    echo "[TERMWATCH] ERROR: $1"
}

# 输出警告日志
log_warning() {
    echo "[TERMWATCH] WARNING: $1"
}

# 输出信息日志
log_info() {
    echo "[TERMWATCH] INFO: $1"
}

# 命令包装器 - 自动判断成功失败
run_with_notify() {
    local command="$1"
    local description="${2:-$command}"
    
    echo "🔄 执行: $description"
    
    if eval "$command"; then
        log_success "$description 完成"
        return 0
    else
        log_error "$description 失败"
        return 1
    fi
}

# 带时间戳的命令包装器
run_with_timestamp() {
    local command="$1"
    local description="${2:-$command}"
    local start_time=$(date +%s)
    
    echo "🔄 开始执行: $description ($(date '+%H:%M:%S'))"
    
    if eval "$command"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local duration_str
        
        if [[ $duration -lt 60 ]]; then
            duration_str="${duration}秒"
        elif [[ $duration -lt 3600 ]]; then
            local minutes=$((duration / 60))
            local seconds=$((duration % 60))
            duration_str="${minutes}分${seconds}秒"
        else
            local hours=$((duration / 3600))
            local minutes=$(((duration % 3600) / 60))
            duration_str="${hours}时${minutes}分"
        fi
        
        log_success "$description 完成 (耗时: $duration_str)"
        return 0
    else
        log_error "$description 失败 ($(date '+%H:%M:%S'))"
        return 1
    fi
}

# 批量任务执行器
run_batch_with_notify() {
    local batch_name="$1"
    shift
    local commands=("$@")
    local total=${#commands[@]}
    local success_count=0
    local failed_commands=()
    
    echo "🚀 开始批量任务: $batch_name (共 $total 个任务)"
    log_info "批量任务开始: $batch_name"
    
    for i in "${!commands[@]}"; do
        local cmd="${commands[i]}"
        local task_num=$((i + 1))
        
        echo "📋 任务 $task_num/$total: $cmd"
        
        if eval "$cmd"; then
            echo "✅ 任务 $task_num 完成"
            ((success_count++))
        else
            echo "❌ 任务 $task_num 失败"
            failed_commands+=("$cmd")
        fi
    done
    
    # 发送批量任务完成通知
    if [[ $success_count -eq $total ]]; then
        log_success "$batch_name 全部完成 ($success_count/$total)"
    elif [[ $success_count -eq 0 ]]; then
        log_error "$batch_name 全部失败 ($success_count/$total)"
    else
        log_warning "$batch_name 部分完成 ($success_count/$total 成功，${#failed_commands[@]} 失败)"
    fi
    
    # 如果有失败的命令，显示详情
    if [[ ${#failed_commands[@]} -gt 0 ]]; then
        echo ""
        echo "❌ 失败的命令:"
        for failed_cmd in "${failed_commands[@]}"; do
            echo "   - $failed_cmd"
        done
    fi
    
    return $((total - success_count))
}

# 导出函数供其他脚本使用
export -f log_success log_error log_warning log_info run_with_notify run_with_timestamp run_batch_with_notify