#!/bin/bash

# TermWatch - 终端命令通知工具
# 支持 macOS 本地通知和 Apple Watch 远程通知

set -e

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 默认配置
AUTO_NOTIFY_THRESHOLD=30
ENABLE_AUTO_MONITOR=true
MAX_NOTIFICATIONS_PER_HOUR=10
NOTIFICATION_SOUND=default
NOTIFICATION_TITLE="TermWatch"

SUCCESS_TEMPLATE="✅ 任务完成"
ERROR_TEMPLATE="❌ 任务失败"
WARNING_TEMPLATE="⚠️ 注意"
INFO_TEMPLATE="ℹ️ 信息"

ENABLE_QUIET_HOURS=false
QUIET_HOURS_START=22
QUIET_HOURS_END=8

ENABLE_LOGGING=true
LOG_LEVEL=INFO
LOG_FILE="$HOME/.termwatch/logs/termwatch.log"

DUPLICATE_THRESHOLD=300
ENABLE_DEDUPLICATION=true

# 加载用户配置
load_config() {
    local config_files=(
        "$PROJECT_ROOT/config/default.conf"
        "$HOME/.termwatch/config/user.conf"
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            source "$config_file"
        fi
    done
}

# 日志函数
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$ENABLE_LOGGING" == "true" ]]; then
        echo "[$timestamp] [$level] $message" >&2
        if [[ -n "$LOG_FILE" ]]; then
            mkdir -p "$(dirname "$LOG_FILE")"
            echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
        fi
    fi
}

log_info() { log_message "INFO" "$1"; }
log_warn() { log_message "WARN" "$1"; }
log_error() { log_message "ERROR" "$1"; }

# 检查是否在静音时间
is_quiet_hours() {
    [[ "$ENABLE_QUIET_HOURS" != "true" ]] && return 1
    
    local current_hour=$(date +%H)
    if [[ $QUIET_HOURS_START -le $QUIET_HOURS_END ]]; then
        [[ $current_hour -ge $QUIET_HOURS_START && $current_hour -lt $QUIET_HOURS_END ]]
    else
        [[ $current_hour -ge $QUIET_HOURS_START || $current_hour -lt $QUIET_HOURS_END ]]
    fi
}

# 检查通知去重
check_duplicate() {
    [[ "$ENABLE_DEDUPLICATION" != "true" ]] && return 0
    
    local message="$1"
    local current_time=$(date +%s)
    local hash=$(echo "$message" | md5sum | cut -d' ' -f1 2>/dev/null || echo "$message" | md5)
    local cache_file="$HOME/.termwatch/cache/notifications"
    
    mkdir -p "$(dirname "$cache_file")"
    
    if [[ -f "$cache_file" ]]; then
        while IFS='|' read -r stored_hash stored_time; do
            if [[ "$stored_hash" == "$hash" ]]; then
                local time_diff=$((current_time - stored_time))
                if [[ $time_diff -lt $DUPLICATE_THRESHOLD ]]; then
                    return 1
                fi
            fi
        done < "$cache_file"
    fi
    
    # 清理过期记录并添加新记录
    local temp_file=$(mktemp)
    if [[ -f "$cache_file" ]]; then
        while IFS='|' read -r stored_hash stored_time; do
            local time_diff=$((current_time - stored_time))
            if [[ $time_diff -lt $DUPLICATE_THRESHOLD ]]; then
                echo "$stored_hash|$stored_time" >> "$temp_file"
            fi
        done < "$cache_file"
    fi
    echo "$hash|$current_time" >> "$temp_file"
    mv "$temp_file" "$cache_file"
    
    return 0
}

# 发送 macOS 通知
send_macos_notification() {
    local title="$1"
    local message="$2"
    local sound="$3"
    
    if command -v terminal-notifier >/dev/null 2>&1; then
        terminal-notifier -message "$message" -title "$title" ${sound:+-sound "$sound"}
    elif command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$message\" with title \"$title\""
    else
        log_error "未找到可用的通知工具"
        return 1
    fi
}


# 发送 Server酱 通知（微信推送）
send_serverchan_notification() {
    local title="$1"
    local message="$2"
    
    [[ -z "$SERVERCHAN_SENDKEY" ]] && return 1
    
    # Server酱 API 调用
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"title\":\"$title\",\"desp\":\"$message\"}" \
        "https://sctapi.ftqq.com/$SERVERCHAN_SENDKEY.send")
    
    # 检查返回结果
    if echo "$response" | grep -q '"code":0'; then
        return 0
    else
        return 1
    fi
}

# 发送 Bark 通知（iOS 推送）
send_bark_notification() {
    local title="$1"
    local message="$2"
    local type="$3"
    
    [[ -z "$BARK_KEY" ]] && return 1
    
    # 构建 Bark API URL
    local bark_url="${BARK_SERVER:-https://api.day.app}/$BARK_KEY"
    # URL 编码函数
    local encoded_title=$(printf "%s" "$title" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))" 2>/dev/null || printf "%s" "$title" | sed 's/ /%20/g')
    local encoded_message=$(printf "%s" "$message" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))" 2>/dev/null || printf "%s" "$message" | sed 's/ /%20/g')
    
    # 根据通知类型设置参数
    local sound="${BARK_SOUND:-default}"
    local group="${BARK_GROUP:-TermWatch}"
    local icon="${BARK_ICON:-}"
    local level="active"
    
    case "$type" in
        "error") 
            sound="multiwayinvitation"
            level="timeSensitive"
            ;;
        "warning") 
            sound="bell"
            level="timeSensitive"
            ;;
        "success") 
            sound="birdsong"
            ;;
    esac
    
    # 构建完整的 API 请求
    local full_url="$bark_url/$encoded_title/$encoded_message"
    local params="?sound=$sound&group=$group&level=$level"
    
    # 添加自定义图标（如果配置了）
    if [[ -n "$icon" ]]; then
        params="$params&icon=$icon"
    fi
    
    # 发送推送请求
    local response=$(curl -s -w "%{http_code}" "$full_url$params")
    local http_code="${response: -3}"
    
    # 检查响应状态码
    if [[ "$http_code" == "200" ]]; then
        return 0
    else
        return 1
    fi
}

# 主要通知函数
send_notification() {
    local title="${1:-$NOTIFICATION_TITLE}"
    local message="${2:-测试通知}"
    local type="${3:-info}"
    
    # 检查静音时间
    if is_quiet_hours; then
        log_info "静音时间内，跳过通知"
        return 0
    fi
    
    # 检查重复通知
    if ! check_duplicate "$title: $message"; then
        log_info "重复通知已跳过"
        return 0
    fi
    
    log_info "发送通知: $title - $message"
    
    # 发送 macOS 通知
    send_macos_notification "$title" "$message" "$NOTIFICATION_SOUND"
    
    # 发送远程通知（根据配置选择模式）
    local serverchan_sent=false
    local bark_sent=false
    local any_remote_sent=false
    
    # Server酱 通知
    if [[ "$ENABLE_SERVERCHAN" == "true" ]] && send_serverchan_notification "$title" "$message"; then
        log_info "Server酱 通知发送成功"
        serverchan_sent=true
        any_remote_sent=true
    fi
    
    # Bark 通知
    if [[ "$ENABLE_BARK" == "true" ]]; then
        # 并行模式：总是尝试发送；优先级模式：仅在前面失败时发送
        if [[ "$ENABLE_PARALLEL_PUSH" == "true" ]] || [[ "$serverchan_sent" == "false" ]]; then
            if send_bark_notification "$title" "$message" "$type"; then
                log_info "Bark 通知发送成功"
                bark_sent=true
                any_remote_sent=true
            fi
        fi
    fi
    
    # 记录发送结果
    if [[ "$any_remote_sent" == "false" ]]; then
        log_info "远程通知未配置或发送失败"
    elif [[ "$ENABLE_PARALLEL_PUSH" == "true" ]]; then
        log_info "并行推送模式 - Server酱:$serverchan_sent, Bark:$bark_sent"
    fi
}

# 便捷通知函数
notify_success() {
    send_notification "$SUCCESS_TEMPLATE" "${1:-任务完成}" "success"
}

notify_error() {
    send_notification "$ERROR_TEMPLATE" "${1:-任务失败}" "error"
}

notify_warning() {
    send_notification "$WARNING_TEMPLATE" "${1:-警告}" "warning"
}

notify_info() {
    send_notification "$INFO_TEMPLATE" "${1:-信息}" "info"
}

# 显示帮助信息
show_help() {
    cat << EOF
TermWatch - 终端命令通知工具

用法:
  $0 [选项] [消息]
  $0 <类型> <消息>

类型:
  success     发送成功通知
  error       发送错误通知
  warning     发送警告通知
  info        发送信息通知

选项:
  -t, --title <标题>    设置通知标题
  -h, --help            显示此帮助信息
  --test                发送测试通知
  --status              显示状态信息

示例:
  $0 "Hello TermWatch!"
  $0 success "构建完成"
  $0 error "构建失败"
  $0 -t "自定义标题" "自定义消息"

配置:
  配置文件: ~/.termwatch/config/user.conf
  日志文件: ~/.termwatch/logs/termwatch.log
EOF
}

# 显示状态信息
show_status() {
    echo "=== TermWatch 状态 ==="
    echo "版本: 1.0.0"
    echo "安装路径: $PROJECT_ROOT"
    echo "配置文件: $HOME/.termwatch/config/user.conf"
    echo ""
    echo "通知设置:"
    echo "  自动监控: $ENABLE_AUTO_MONITOR"
    echo "  通知阈值: $AUTO_NOTIFY_THRESHOLD 秒"
    echo "  静音时间: $ENABLE_QUIET_HOURS"
    echo ""
    echo "通知工具:"
    if command -v terminal-notifier >/dev/null 2>&1; then
        echo "  ✅ terminal-notifier"
    elif command -v osascript >/dev/null 2>&1; then
        echo "  ✅ osascript"
    else
        echo "  ❌ 无可用通知工具"
    fi
    
    echo ""
    echo "远程推送:"
    echo "  推送模式: $([ "$ENABLE_PARALLEL_PUSH" == "true" ] && echo "并行发送" || echo "优先级模式")"
    
    # Server酱 状态
    if [[ "$ENABLE_SERVERCHAN" == "true" ]]; then
        if [[ -n "$SERVERCHAN_SENDKEY" ]]; then
            echo "  ✅ Server酱 (已启用，已配置)"
        else
            echo "  ⚠️ Server酱 (已启用，未配置)"
        fi
    else
        echo "  ❌ Server酱 (已禁用)"
    fi
    
    # Bark 状态
    if [[ "$ENABLE_BARK" == "true" ]]; then
        if [[ -n "$BARK_KEY" ]]; then
            echo "  ✅ Bark (已启用，已配置)"
        else
            echo "  ⚠️ Bark (已启用，未配置)"
        fi
    else
        echo "  ❌ Bark (已禁用)"
    fi
}

# 主函数
main() {
    load_config
    
    local title=""
    local message=""
    local type="info"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--title)
                title="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --test)
                send_notification "TermWatch 测试" "测试通知功能"
                exit 0
                ;;
            --status)
                show_status
                exit 0
                ;;
            success|error|warning|info)
                type="$1"
                message="$2"
                shift 2
                ;;
            *)
                if [[ -z "$message" ]]; then
                    message="$1"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$message" ]]; then
        message="TermWatch 通知"
    fi
    
    case "$type" in
        success) notify_success "$message" ;;
        error) notify_error "$message" ;;
        warning) notify_warning "$message" ;;
        info) notify_info "$message" ;;
        *) send_notification "$title" "$message" ;;
    esac
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi