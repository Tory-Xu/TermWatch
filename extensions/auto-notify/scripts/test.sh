#!/bin/bash

# TermWatch Auto-Notify Extension 测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 路径定义
TERMWATCH_DIR="$HOME/.termwatch"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                TermWatch Auto-Notify Extension                ║
║                        测试程序                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 测试扩展安装
test_installation() {
    log_info "测试扩展安装状态..."
    
    local required_files=(
        "$TERMWATCH_DIR/auto_notify.sh"
        "$TERMWATCH_DIR/zsh_hooks.sh"
        "$TERMWATCH_DIR/log_helpers.sh"
        "$TERMWATCH_DIR/config/auto_notify.conf"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$(basename "$file")")
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        log_success "所有扩展文件已正确安装"
    else
        log_error "缺少以下文件: ${missing_files[*]}"
        return 1
    fi
}

# 测试配置文件
test_configuration() {
    log_info "测试配置文件..."
    
    local config_file="$TERMWATCH_DIR/config/auto_notify.conf"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在"
        return 1
    fi
    
    # 测试关键配置项
    local required_configs=(
        "ENABLE_AUTO_NOTIFY"
        "AUTO_NOTIFY_THRESHOLD"
        "IGNORE_COMMANDS"
        "IMPORTANT_COMMANDS"
    )
    
    local missing_configs=()
    
    for config in "${required_configs[@]}"; do
        if ! grep -q "^$config=" "$config_file"; then
            missing_configs+=("$config")
        fi
    done
    
    if [[ ${#missing_configs[@]} -eq 0 ]]; then
        log_success "配置文件格式正确"
    else
        log_warning "缺少以下配置项: ${missing_configs[*]}"
    fi
    
    # 显示当前配置
    echo ""
    echo "当前配置:"
    source "$config_file"
    echo "  启用状态: $ENABLE_AUTO_NOTIFY"
    echo "  通知阈值: ${AUTO_NOTIFY_THRESHOLD}秒"  
    echo "  忽略命令: ${#IGNORE_COMMANDS[@]} 个"
    echo "  重要命令: ${#IMPORTANT_COMMANDS[@]} 个"
}

# 测试钩子函数
test_hooks() {
    log_info "测试钩子函数..."
    
    # 加载钩子脚本
    if [[ -f "$TERMWATCH_DIR/zsh_hooks.sh" ]]; then
        source "$TERMWATCH_DIR/zsh_hooks.sh"
        log_success "钩子脚本加载成功"
    else
        log_error "钩子脚本不存在"
        return 1
    fi
    
    # 测试函数是否定义
    local required_functions=(
        "termwatch_preexec"
        "termwatch_precmd"
        "toggle_auto_notify"
        "show_auto_notify_status"
    )
    
    local missing_functions=()
    
    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" >/dev/null 2>&1; then
            missing_functions+=("$func")
        fi
    done
    
    if [[ ${#missing_functions[@]} -eq 0 ]]; then
        log_success "所有钩子函数已正确定义"
    else
        log_error "缺少以下函数: ${missing_functions[*]}"
        return 1
    fi
    
    # 测试钩子注册
    if [[ " ${preexec_functions[@]} " =~ " termwatch_preexec " ]]; then
        log_success "preexec 钩子已注册"
    else
        log_warning "preexec 钩子未注册"
    fi
    
    if [[ " ${precmd_functions[@]} " =~ " termwatch_precmd " ]]; then
        log_success "precmd 钩子已注册"
    else
        log_warning "precmd 钩子未注册"
    fi
}

# 测试日志辅助函数
test_log_helpers() {
    log_info "测试日志辅助函数..."
    
    if [[ -f "$TERMWATCH_DIR/log_helpers.sh" ]]; then
        source "$TERMWATCH_DIR/log_helpers.sh"
        log_success "日志辅助脚本加载成功"
    else
        log_error "日志辅助脚本不存在"
        return 1
    fi
    
    # 测试函数是否定义
    local required_functions=(
        "log_success"
        "log_error"
        "log_warning"
        "log_info"
        "run_with_notify"
    )
    
    local missing_functions=()
    
    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" >/dev/null 2>&1; then
            missing_functions+=("$func")
        fi
    done
    
    if [[ ${#missing_functions[@]} -eq 0 ]]; then
        log_success "所有日志函数已正确定义"
    else
        log_error "缺少以下函数: ${missing_functions[*]}"
        return 1
    fi
}

# 测试 TermWatch 基础功能
test_termwatch_basic() {
    log_info "测试 TermWatch 基础功能..."
    
    if [[ ! -f "$TERMWATCH_DIR/termwatch.sh" ]]; then
        log_error "TermWatch 基础脚本不存在"
        return 1
    fi
    
    # 测试基础通知功能
    if bash "$TERMWATCH_DIR/termwatch.sh" --test >/dev/null 2>&1; then
        log_success "TermWatch 基础通知功能正常"
    else
        log_warning "TermWatch 基础通知功能测试失败"
    fi
    
    # 测试命令别名
    if command -v termwatch >/dev/null 2>&1; then
        log_success "termwatch 命令别名可用"
    else
        log_warning "termwatch 命令别名未配置"
    fi
}

# 交互式功能测试
interactive_test() {
    log_info "交互式功能测试..."
    
    echo ""
    echo "=== 可用的测试选项 ==="
    echo "1. 测试强制通知 (!echo)"
    echo "2. 测试长时间命令 (sleep 10)"
    echo "3. 测试日志输出格式"
    echo "4. 测试状态显示"
    echo "5. 跳过交互式测试"
    echo ""
    
    read -p "请选择测试类型 (1-5): " -n 1 -r choice
    echo
    echo
    
    case $choice in
        1)
            log_info "测试强制通知功能..."
            echo "执行: !echo '强制通知测试'"
            echo "注意: 这需要在支持钩子的 shell 中才能看到效果"
            ;;
        2)
            log_info "测试长时间命令通知..."
            echo "执行: sleep 10"
            echo "注意: 这将等待10秒，然后可能触发通知"
            sleep 10
            echo "sleep 命令完成"
            ;;
        3)
            log_info "测试日志输出格式..."
            if [[ -f "$TERMWATCH_DIR/log_helpers.sh" ]]; then
                source "$TERMWATCH_DIR/log_helpers.sh"
                echo "测试不同类型的日志输出:"
                log_success "这是成功日志"
                log_error "这是错误日志"
                log_warning "这是警告日志"
                log_info "这是信息日志"
            fi
            ;;
        4)
            log_info "测试状态显示..."
            if declare -f show_auto_notify_status >/dev/null 2>&1; then
                show_auto_notify_status
            else
                echo "状态函数未加载，请先运行: source ~/.termwatch/zsh_hooks.sh"
            fi
            ;;
        5)
            log_info "跳过交互式测试"
            ;;
        *)
            log_warning "无效选择，跳过交互式测试"
            ;;
    esac
}

# 生成测试报告
generate_test_report() {
    log_info "生成测试报告..."
    
    local report_file="/tmp/termwatch_auto_notify_test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
TermWatch Auto-Notify Extension 测试报告
========================================

测试时间: $(date '+%Y-%m-%d %H:%M:%S')
测试环境: $(uname -s) $(uname -r)
Shell: $SHELL

文件检查:
$(for file in auto_notify.sh zsh_hooks.sh log_helpers.sh config/auto_notify.conf; do
    if [[ -f "$TERMWATCH_DIR/$file" ]]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (缺失)"
    fi
done)

配置检查:
$(if [[ -f "$TERMWATCH_DIR/config/auto_notify.conf" ]]; then
    source "$TERMWATCH_DIR/config/auto_notify.conf"
    echo "  启用状态: $ENABLE_AUTO_NOTIFY"  
    echo "  通知阈值: ${AUTO_NOTIFY_THRESHOLD}秒"
    echo "  忽略命令数: ${#IGNORE_COMMANDS[@]}"
    echo "  重要命令数: ${#IMPORTANT_COMMANDS[@]}"
else
    echo "  ❌ 配置文件不存在"
fi)

函数检查:
$(if [[ -f "$TERMWATCH_DIR/zsh_hooks.sh" ]]; then
    source "$TERMWATCH_DIR/zsh_hooks.sh"
    for func in termwatch_preexec termwatch_precmd toggle_auto_notify show_auto_notify_status; do
        if declare -f "$func" >/dev/null 2>&1; then
            echo "  ✅ $func"
        else
            echo "  ❌ $func (未定义)"
        fi
    done
else
    echo "  ❌ 钩子脚本不存在"
fi)

TermWatch 基础功能:
$(if bash "$TERMWATCH_DIR/termwatch.sh" --test >/dev/null 2>&1; then
    echo "  ✅ 基础通知功能正常"
else
    echo "  ⚠️  基础通知功能异常"
fi)

建议:
- 如果测试失败，请检查 TermWatch 基础安装
- 确保已重新加载 shell 配置: source ~/.zshrc
- 查看安装日志了解详细错误信息

EOF
    
    echo "测试报告已生成: $report_file"
    
    # 显示简要报告
    echo ""
    echo "=== 测试摘要 ==="
    cat "$report_file" | grep -E "✅|❌|⚠️"
}

# 主测试流程
main() {
    show_banner
    
    echo "这将测试 TermWatch Auto-Notify 扩展的安装和功能状态。"
    echo ""
    
    local test_results=()
    
    # 执行各项测试
    if test_installation; then
        test_results+=("安装:✅")
    else
        test_results+=("安装:❌")
    fi
    
    if test_configuration; then
        test_results+=("配置:✅")
    else
        test_results+=("配置:❌")
    fi
    
    if test_hooks; then
        test_results+=("钩子:✅")
    else
        test_results+=("钩子:❌")
    fi
    
    if test_log_helpers; then
        test_results+=("日志:✅")
    else
        test_results+=("日志:❌")
    fi
    
    if test_termwatch_basic; then
        test_results+=("基础:✅")
    else
        test_results+=("基础:❌")
    fi
    
    # 显示测试结果
    echo ""
    echo "=== 测试结果 ==="
    for result in "${test_results[@]}"; do
        echo "  $result"
    done
    
    # 询问是否进行交互式测试
    echo ""
    read -p "是否进行交互式功能测试？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        interactive_test
    fi
    
    # 生成测试报告
    echo ""
    generate_test_report
    
    echo ""
    log_success "测试完成！"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi