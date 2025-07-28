#!/bin/bash

# TermWatch Auto-Notify Extension 卸载脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 路径定义
TERMWATCH_DIR="$HOME/.termwatch"
BACKUP_DIR="/Users/xuxuxu/Documents/文档/电脑配置变更记录"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示横幅
show_banner() {
    echo -e "${RED}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                TermWatch Auto-Notify Extension                ║
║                        卸载程序                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 检查扩展是否已安装
check_installation() {
    log_info "检查扩展安装状态..."
    
    local extension_files=("auto_notify.sh" "zsh_hooks.sh" "log_helpers.sh")
    local found_files=0
    
    for file in "${extension_files[@]}"; do
        if [[ -f "$TERMWATCH_DIR/$file" ]]; then
            ((found_files++))
        fi
    done
    
    if [[ $found_files -eq 0 ]]; then
        log_warning "未检测到 Auto-Notify 扩展安装"
        echo "可能已经卸载或未安装扩展"
        echo ""
        read -p "是否继续执行清理操作？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "卸载已取消"
            exit 0
        fi
    else
        log_info "检测到 $found_files 个扩展文件"
    fi
}

# 显示卸载信息
show_uninstall_info() {
    echo -e "${YELLOW}即将卸载以下内容:${NC}"
    echo ""
    
    echo "📁 扩展文件:"
    echo "  • ~/.termwatch/auto_notify.sh"
    echo "  • ~/.termwatch/zsh_hooks.sh"
    echo "  • ~/.termwatch/log_helpers.sh"
    echo "  • ~/.termwatch/config/auto_notify.conf"
    echo "  • ~/.termwatch/uninstall_auto_notify.sh"
    echo ""
    
    echo "📝 Shell 配置修改:"
    echo "  • ~/.zshrc 中的 Auto-Notify 扩展配置"
    echo ""
    
    echo "📦 缓存和临时文件:"
    echo "  • ~/.termwatch/cache/ (命令监控缓存)"
    echo ""
    
    echo -e "${GREEN}保留内容:${NC}"
    echo "  • TermWatch 基础功能完全保留"
    echo "  • 用户自定义配置保留"
    echo "  • 推送服务配置保留"
    echo ""
    
    echo -e "${BLUE}备份信息:${NC}"
    echo "  • 所有修改的配置文件都会先备份"
    echo "  • 备份位置: $BACKUP_DIR"
    echo ""
}

# 确认卸载
confirm_uninstall() {
    show_uninstall_info
    
    read -p "确定要卸载 Auto-Notify 扩展吗? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "卸载已取消"
        exit 0
    fi
    
    echo ""
    log_warning "开始卸载过程，将在 3 秒后开始..."
    sleep 3
}

# 备份配置文件
backup_configs() {
    log_info "备份当前配置文件..."
    
    mkdir -p "$BACKUP_DIR"
    
    # 备份 shell 配置
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$BACKUP_DIR/.zshrc.auto_notify_uninstall_backup.$TIMESTAMP"
        log_success "已备份: .zshrc"
    fi
    
    # 备份扩展配置
    if [[ -f "$TERMWATCH_DIR/config/auto_notify.conf" ]]; then
        cp "$TERMWATCH_DIR/config/auto_notify.conf" "$BACKUP_DIR/auto_notify.conf.backup.$TIMESTAMP"
        log_success "已备份扩展配置文件"
    fi
}

# 清理扩展文件
remove_extension_files() {
    log_info "删除扩展文件..."
    
    # 要删除的文件列表
    local files_to_remove=(
        "$TERMWATCH_DIR/auto_notify.sh"
        "$TERMWATCH_DIR/zsh_hooks.sh"
        "$TERMWATCH_DIR/log_helpers.sh"
        "$TERMWATCH_DIR/config/auto_notify.conf"
        "$TERMWATCH_DIR/uninstall_auto_notify.sh"
    )
    
    for file in "${files_to_remove[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_success "已删除: $(basename "$file")"
        fi
    done
    
    # 清理缓存目录
    if [[ -d "$TERMWATCH_DIR/cache" ]]; then
        rm -rf "$TERMWATCH_DIR/cache"
        log_success "已删除缓存目录"
    fi
}

# 清理 shell 配置
clean_shell_config() {
    log_info "清理 shell 配置..."
    
    local shell_config="$HOME/.zshrc"
    
    if [[ -f "$shell_config" ]]; then
        # 检查是否包含扩展配置
        if grep -q "TermWatch Auto-Notify Extension" "$shell_config"; then
            # 创建临时文件
            local temp_file=$(mktemp)
            
            # 逐行处理，移除扩展相关配置
            local skip_lines=false
            while IFS= read -r line || [[ -n "$line" ]]; do
                if [[ "$line" =~ "TermWatch Auto-Notify Extension" ]]; then
                    skip_lines=true
                    continue
                elif [[ "$skip_lines" == "true" ]]; then
                    # 跳过扩展配置块中的行
                    if [[ "$line" =~ ^[[:space:]]*fi[[:space:]]*$ ]] || [[ -z "${line// }" ]]; then
                        skip_lines=false
                        continue
                    elif [[ "$line" =~ source.*zsh_hooks.sh ]]; then
                        continue
                    elif [[ "$line" =~ ^[[:space:]]*if.*zsh_hooks.sh ]]; then
                        continue
                    fi
                fi
                
                if [[ "$skip_lines" == "false" ]]; then
                    echo "$line" >> "$temp_file"
                fi
            done < "$shell_config"
            
            # 替换原文件
            mv "$temp_file" "$shell_config"
            log_success "已清理 shell 配置"
        else
            log_info "shell 配置中未找到扩展相关内容"
        fi
    fi
}

# 清理运行时状态
clean_runtime_state() {
    log_info "清理运行时状态..."
    
    # 清理钩子函数（如果当前 session 中已加载）
    if declare -f termwatch_preexec >/dev/null 2>&1; then
        unset -f termwatch_preexec
        log_success "已清理: termwatch_preexec 函数"
    fi
    
    if declare -f termwatch_precmd >/dev/null 2>&1; then
        unset -f termwatch_precmd
        log_success "已清理: termwatch_precmd 函数"
    fi
    
    # 清理钩子数组
    if [[ -n "${preexec_functions[@]}" ]]; then
        preexec_functions=("${preexec_functions[@]/termwatch_preexec}")
    fi
    
    if [[ -n "${precmd_functions[@]}" ]]; then
        precmd_functions=("${precmd_functions[@]/termwatch_precmd}")
    fi
    
    # 清理环境变量
    unset TERMWATCH_COMMAND TERMWATCH_START_TIME TERMWATCH_FORCE_NOTIFY 2>/dev/null || true
    
    # 清理别名
    unalias termwatch_toggle 2>/dev/null || true
    unalias termwatch_status 2>/dev/null || true
    
    log_success "运行时状态清理完成"
}

# 创建卸载记录
create_uninstall_log() {
    log_info "创建卸载记录..."
    
    local uninstall_log="$BACKUP_DIR/TermWatch_AutoNotify_卸载记录_$TIMESTAMP.md"
    
    cat > "$uninstall_log" << EOF
# TermWatch Auto-Notify Extension 卸载记录

## 卸载时间
$(date '+%Y-%m-%d %H:%M:%S')

## 卸载内容

### 已删除的文件
- \`~/.termwatch/auto_notify.sh\` - 自动通知核心模块
- \`~/.termwatch/zsh_hooks.sh\` - ZSH 钩子函数
- \`~/.termwatch/log_helpers.sh\` - 日志辅助函数
- \`~/.termwatch/config/auto_notify.conf\` - 扩展配置文件
- \`~/.termwatch/cache/\` - 命令监控缓存目录
- \`~/.termwatch/uninstall_auto_notify.sh\` - 扩展卸载脚本

### 已清理的配置
- \`~/.zshrc\` 中的 Auto-Notify 扩展配置

### 保留的内容
- TermWatch 基础功能完全保留
- \`~/.termwatch/termwatch.sh\` - 基础通知工具
- \`~/.termwatch/config/user.conf\` - 用户配置
- 所有推送服务配置

### 备份信息
- 备份时间戳: \`$TIMESTAMP\`
- 备份位置: \`$BACKUP_DIR\`
- 备份文件:
  - \`.zshrc.auto_notify_uninstall_backup.$TIMESTAMP\`
  - \`auto_notify.conf.backup.$TIMESTAMP\`

## 恢复方法

如需重新安装扩展：

### 方法1: 使用安装脚本
\`\`\`bash
cd /Users/xuxuxu/Documents/MyGitHub/TermWatch
bash extensions/auto-notify/scripts/install.sh
\`\`\`

### 方法2: 恢复备份配置
\`\`\`bash
# 恢复 shell 配置
cp "$BACKUP_DIR/.zshrc.auto_notify_uninstall_backup.$TIMESTAMP" ~/.zshrc

# 恢复扩展配置
cp "$BACKUP_DIR/auto_notify.conf.backup.$TIMESTAMP" ~/.termwatch/config/auto_notify.conf

# 重新加载配置
source ~/.zshrc
\`\`\`

## 验证卸载

运行以下命令验证卸载是否完成：

\`\`\`bash
# 检查扩展文件是否删除
ls ~/.termwatch/auto_notify.sh 2>/dev/null && echo "未删除" || echo "已删除"

# 检查钩子函数是否清理
declare -f termwatch_preexec >/dev/null && echo "未清理" || echo "已清理"

# 检查 shell 配置是否清理
grep "Auto-Notify Extension" ~/.zshrc && echo "未清理" || echo "已清理"

# 验证 TermWatch 基础功能
termwatch --test
\`\`\`

## 注意事项
1. 卸载后需要重新加载 shell 配置: \`source ~/.zshrc\`
2. TermWatch 基础功能不受影响
3. 所有配置文件均已备份，可以安全恢复
4. 如需完全删除 TermWatch，请使用 TermWatch 主卸载脚本

## 技术支持
- **项目地址**: /Users/xuxuxu/Documents/MyGitHub/TermWatch
- **问题反馈**: xuqingming@myhexin.com
EOF
    
    log_success "卸载记录: $uninstall_log"
}

# 显示完成信息
show_completion_info() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                      🎉 卸载完成！                            ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${BLUE}卸载结果:${NC}"
    echo "✅ Auto-Notify 扩展已完全移除"
    echo "✅ Shell 配置已清理"
    echo "✅ 扩展文件已删除"
    echo "✅ 运行时状态已清理"
    echo ""
    
    echo -e "${BLUE}下一步操作:${NC}"
    echo "1. 重新加载 shell 配置:"
    echo -e "   ${YELLOW}source ~/.zshrc${NC}"
    echo ""
    echo "2. 验证卸载结果:"
    echo -e "   ${YELLOW}ls ~/.termwatch/auto_notify.sh 2>/dev/null && echo '未删除' || echo '已删除'${NC}"
    echo ""
    
    echo -e "${BLUE}保留的功能:${NC}"
    echo "• TermWatch 基础通知工具仍然可用"
    echo "• 所有推送服务配置保持不变"
    echo "• 手动通知命令 (notify, termwatch 等) 正常工作"
    echo ""
    
    echo -e "${BLUE}备份信息:${NC}"
    echo -e "• 备份位置: ${YELLOW}$BACKUP_DIR${NC}"
    echo -e "• 重新安装: ${YELLOW}bash extensions/auto-notify/scripts/install.sh${NC}"
    echo ""
    
    log_success "TermWatch Auto-Notify Extension 卸载完成！"
}

# 主卸载流程  
main() {
    show_banner
    
    echo "这将卸载 TermWatch 的 Auto-Notify 扩展，但保留 TermWatch 基础功能。"
    echo ""
    
    check_installation
    confirm_uninstall
    backup_configs
    remove_extension_files
    clean_shell_config
    clean_runtime_state
    create_uninstall_log
    
    echo ""
    show_completion_info
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi