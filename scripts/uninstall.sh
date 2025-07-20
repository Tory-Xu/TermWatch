#!/bin/bash

# TermWatch 卸载脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示卸载信息
show_uninstall_info() {
    echo
    echo "========================================"
    echo "      TermWatch 卸载程序"
    echo "========================================"
    echo
    echo "将要删除以下内容:"
    echo "  📁 配置目录: ~/.termwatch"
    echo "  📝 Shell 配置中的 TermWatch 相关行"
    echo "  🗂️ 日志和缓存文件"
    echo
    echo "注意: terminal-notifier 不会被卸载"
    echo
}

# 确认卸载
confirm_uninstall() {
    read -p "确定要卸载 TermWatch 吗? 这将删除所有配置和数据 (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "卸载已取消"
        exit 0
    fi
}

# 备份用户配置
backup_config() {
    local config_dir="$HOME/.termwatch"
    local backup_dir="$HOME/.termwatch_backup_$(date +%Y%m%d_%H%M%S)"
    
    if [[ -d "$config_dir" ]]; then
        read -p "是否备份当前配置? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp -r "$config_dir" "$backup_dir"
            log_info "配置已备份到: $backup_dir"
        fi
    fi
}

# 清理 Shell 配置
clean_shell_config() {
    log_info "清理 Shell 配置..."
    
    local shell_configs=(
        "$HOME/.zshrc"
        "$HOME/.bash_profile"
        "$HOME/.bashrc"
        "$HOME/.profile"
    )
    
    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]]; then
            # 检查是否包含 TermWatch 相关配置
            if grep -q "termwatch\|TermWatch" "$config_file"; then
                log_info "清理 $config_file"
                
                # 创建备份
                cp "$config_file" "${config_file}.termwatch_backup"
                
                # 删除 TermWatch 相关行
                if [[ "$(uname)" == "Darwin" ]]; then
                    sed -i '' '/termwatch\|TermWatch/d' "$config_file"
                else
                    sed -i '/termwatch\|TermWatch/d' "$config_file"
                fi
                
                # 清理空行
                if [[ "$(uname)" == "Darwin" ]]; then
                    sed -i '' '/^[[:space:]]*$/N;/^\n$/d' "$config_file"
                else
                    sed -i '/^[[:space:]]*$/N;/^\n$/d' "$config_file"
                fi
                
                log_info "已备份原文件为: ${config_file}.termwatch_backup"
            fi
        fi
    done
}

# 删除文件和目录
remove_files() {
    log_info "删除 TermWatch 文件..."
    
    # 删除主要安装目录
    if [[ -d "$HOME/.termwatch" ]]; then
        rm -rf "$HOME/.termwatch"
        log_info "已删除: ~/.termwatch"
    fi
    
    # 删除可能的符号链接
    local possible_links=(
        "/usr/local/bin/termwatch"
        "/usr/local/bin/notify"
        "$HOME/.local/bin/termwatch"
    )
    
    for link in "${possible_links[@]}"; do
        if [[ -L "$link" ]]; then
            rm "$link"
            log_info "已删除符号链接: $link"
        fi
    done
}

# 清理进程
clean_processes() {
    log_info "检查运行中的 TermWatch 进程..."
    
    # 查找可能的 TermWatch 相关进程
    local pids=$(pgrep -f "termwatch\|TermWatch" 2>/dev/null || true)
    
    if [[ -n "$pids" ]]; then
        log_warn "发现运行中的 TermWatch 进程: $pids"
        read -p "是否终止这些进程? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$pids" | xargs kill 2>/dev/null || true
            log_info "已终止 TermWatch 进程"
        fi
    fi
}

# 清理系统缓存
clean_system_cache() {
    log_info "清理系统缓存..."
    
    # 清理可能的 launchctl 服务
    local services=$(launchctl list | grep -i termwatch 2>/dev/null || true)
    if [[ -n "$services" ]]; then
        log_warn "发现 TermWatch 系统服务，请手动清理"
        echo "$services"
    fi
    
    # 清理通知中心缓存（如果需要的话）
    # 注意：这可能会影响其他应用的通知设置
    read -p "是否重置通知中心缓存? 这会影响所有应用的通知设置 (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        killall NotificationCenter 2>/dev/null || true
        log_info "已重置通知中心"
    fi
}

# 验证卸载
verify_uninstall() {
    log_info "验证卸载..."
    
    local issues=0
    
    # 检查目录是否已删除
    if [[ -d "$HOME/.termwatch" ]]; then
        log_error "目录仍然存在: ~/.termwatch"
        ((issues++))
    fi
    
    # 检查 shell 配置
    local shell_configs=("$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc")
    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]] && grep -q "termwatch\|TermWatch" "$config"; then
            log_error "Shell 配置未完全清理: $config"
            ((issues++))
        fi
    done
    
    # 检查命令是否仍然可用
    if command -v termwatch >/dev/null 2>&1; then
        log_error "termwatch 命令仍然可用"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_info "卸载验证通过 ✅"
        return 0
    else
        log_warn "发现 $issues 个问题，可能需要手动清理"
        return 1
    fi
}

# 显示卸载完成信息
show_completion() {
    echo
    echo "========================================"
    echo "    TermWatch 卸载完成"
    echo "========================================"
    echo
    echo "已完成以下操作:"
    echo "  ✅ 删除 TermWatch 文件和配置"
    echo "  ✅ 清理 Shell 配置"
    echo "  ✅ 清理系统进程"
    echo
    echo "注意事项:"
    echo "  • terminal-notifier 未被删除"
    echo "  • 通知权限设置保持不变"
    echo "  • Shell 配置文件已备份"
    echo
    echo "如需重新安装，请运行:"
    echo "  git clone <repository> && cd TermWatch && ./install.sh"
    echo
    echo "感谢使用 TermWatch! 👋"
    echo
}

# 主卸载流程
main() {
    # 检查是否以 root 身份运行
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要以 root 身份运行卸载脚本"
        exit 1
    fi
    
    show_uninstall_info
    confirm_uninstall
    backup_config
    clean_processes
    clean_shell_config
    remove_files
    clean_system_cache
    verify_uninstall
    show_completion
    
    log_info "卸载完成! 🎉"
}

# 运行主函数
main "$@"