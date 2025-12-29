#!/bin/bash

# TermWatch Auto-Notify Extension 安装脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 路径定义
EXTENSION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                TermWatch Auto-Notify Extension                ║
║                        安装程序                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 检查环境
check_environment() {
    log_info "检查安装环境..."
    
    # 检查是否已安装 TermWatch
    if [[ ! -f "$TERMWATCH_DIR/termwatch.sh" ]]; then
        log_error "未检测到 TermWatch 基础安装"
        echo "请先安装 TermWatch："
        echo "  cd /path/to/TermWatch && ./install.sh"
        exit 1
    fi
    
    # 检查 shell 环境
    if [[ -z "$ZSH_VERSION" ]] && [[ "$SHELL" != *"zsh"* ]]; then
        log_warning "当前不是 zsh 环境，扩展针对 zsh 优化"
        read -p "是否继续安装？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "安装已取消"
            exit 0
        fi
    fi
    
    log_success "环境检查完成"
}

# 创建备份
create_backup() {
    log_info "创建配置备份..."
    
    mkdir -p "$BACKUP_DIR"
    
    # 备份 shell 配置
    local shell_configs=("$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc")
    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]]; then
            cp "$config" "$BACKUP_DIR/$(basename "$config").auto_notify_backup.$TIMESTAMP"
            log_success "已备份: $(basename "$config")"
        fi
    done
    
    # 备份现有扩展文件（如果存在）
    local existing_files=("auto_notify.sh" "zsh_hooks.sh" "log_helpers.sh")
    for file in "${existing_files[@]}"; do
        if [[ -f "$TERMWATCH_DIR/$file" ]]; then
            cp "$TERMWATCH_DIR/$file" "$BACKUP_DIR/${file}.backup.$TIMESTAMP"
            log_success "已备份现有文件: $file"
        fi
    done
}

# 安装扩展文件
install_extension_files() {
    log_info "安装扩展文件..."
    
    # 复制核心文件
    cp "$EXTENSION_DIR/src/auto_notify.sh" "$TERMWATCH_DIR/"
    cp "$EXTENSION_DIR/src/zsh_hooks.sh" "$TERMWATCH_DIR/"
    cp "$EXTENSION_DIR/src/log_helpers.sh" "$TERMWATCH_DIR/"
    
    # 设置执行权限
    chmod +x "$TERMWATCH_DIR/auto_notify.sh"
    chmod +x "$TERMWATCH_DIR/zsh_hooks.sh"
    chmod +x "$TERMWATCH_DIR/log_helpers.sh"
    
    log_success "核心文件安装完成"
    
    # 复制配置文件（如果不存在）
    if [[ ! -f "$TERMWATCH_DIR/config/auto_notify.conf" ]]; then
        cp "$EXTENSION_DIR/config/auto_notify.conf" "$TERMWATCH_DIR/config/"
        log_success "配置文件安装完成"
    else
        log_info "检测到现有配置文件，保持不变"
    fi
}

# 配置 shell 集成
configure_shell_integration() {
    log_info "配置 shell 集成..."
    
    local shell_config="$HOME/.zshrc"
    
    # 检查是否已经配置
    if grep -q "TermWatch Auto-Notify Extension" "$shell_config" 2>/dev/null; then
        log_warning "检测到已有扩展配置，跳过 shell 配置"
        return
    fi
    
    # 添加扩展配置
    cat >> "$shell_config" << 'EOF'

# TermWatch Auto-Notify Extension
if [[ -f ~/.termwatch/zsh_hooks.sh ]]; then
    source ~/.termwatch/zsh_hooks.sh
fi
EOF
    
    log_success "Shell 集成配置完成"
}

# 创建卸载脚本
generate_uninstall_script() {
    log_info "生成卸载脚本..."
    
    cat > "$TERMWATCH_DIR/uninstall_auto_notify.sh" << 'EOF'
#!/bin/bash

# TermWatch Auto-Notify Extension 卸载脚本

echo "=== TermWatch Auto-Notify Extension 卸载 ==="
echo ""

read -p "确定要卸载自动通知扩展吗? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "卸载已取消"
    exit 0
fi

# 清理文件
echo "清理扩展文件..."
rm -f ~/.termwatch/auto_notify.sh
rm -f ~/.termwatch/zsh_hooks.sh  
rm -f ~/.termwatch/log_helpers.sh
rm -f ~/.termwatch/config/auto_notify.conf

# 清理缓存
rm -rf ~/.termwatch/cache

# 清理 shell 配置
echo "清理 shell 配置..."
if [[ -f ~/.zshrc ]]; then
    # 创建备份
    cp ~/.zshrc ~/.zshrc.auto_notify_uninstall_backup
    
    # 删除扩展相关行
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' '/TermWatch Auto-Notify Extension/,+3d' ~/.zshrc
    else
        sed -i '/TermWatch Auto-Notify Extension/,+3d' ~/.zshrc
    fi
    
    echo "已清理 ~/.zshrc (备份为 ~/.zshrc.auto_notify_uninstall_backup)"
fi

echo ""
echo "✅ TermWatch Auto-Notify Extension 卸载完成！"
echo "注意: TermWatch 基础功能保持不变"
echo "请重新加载 shell 配置: source ~/.zshrc"
EOF
    
    chmod +x "$TERMWATCH_DIR/uninstall_auto_notify.sh"
    log_success "卸载脚本已生成: ~/.termwatch/uninstall_auto_notify.sh"
}

# 创建安装记录
create_install_log() {
    log_info "创建安装记录..."
    
    local install_log="$BACKUP_DIR/TermWatch_AutoNotify_安装记录_$TIMESTAMP.md"
    
    cat > "$install_log" << EOF
# TermWatch Auto-Notify Extension 安装记录

## 安装时间
$(date '+%Y-%m-%d %H:%M:%S')

## 扩展信息
- **名称**: TermWatch Auto-Notify Extension
- **版本**: 1.0.0
- **类型**: TermWatch 扩展
- **功能**: 智能命令执行监控和自动通知

## 安装内容

### 新增文件
- \`~/.termwatch/auto_notify.sh\` - 自动通知核心模块
- \`~/.termwatch/zsh_hooks.sh\` - ZSH 钩子函数  
- \`~/.termwatch/log_helpers.sh\` - 日志辅助函数
- \`~/.termwatch/config/auto_notify.conf\` - 扩展配置文件
- \`~/.termwatch/uninstall_auto_notify.sh\` - 扩展卸载脚本

### 配置修改
- **文件**: \`~/.zshrc\`
- **内容**: 添加了自动通知扩展的加载配置
- **备份**: \`$BACKUP_DIR/.zshrc.auto_notify_backup.$TIMESTAMP\`

## 功能说明

### 核心功能
- 智能监控命令执行时间（默认超过30秒才通知）
- 自动判断命令成功/失败状态
- 支持强制通知模式（\`!command\`）
- 重要命令自动识别和通知
- 智能过滤短时间和无关命令

### 使用方法
\`\`\`bash
# 普通命令（超过30秒才通知）
npm install
docker build .

# 强制通知（无论时间长短）
!git status
!echo "测试"

# 管理命令
termwatch_status    # 查看状态
termwatch_toggle    # 切换开关
\`\`\`

### 配置文件
- **位置**: \`~/.termwatch/config/auto_notify.conf\`
- **内容**: 通知阈值、忽略列表、重要命令等配置

## 集成状态
- ✅ **TermWatch 基础功能**: 完全兼容，继承所有推送配置
- ✅ **Shell 集成**: 自动加载钩子函数
- ✅ **配置管理**: 统一配置目录管理
- ✅ **日志系统**: 集成到 TermWatch 日志系统

## 卸载方法
\`\`\`bash
# 运行扩展卸载脚本
bash ~/.termwatch/uninstall_auto_notify.sh

# 或手动删除
rm -f ~/.termwatch/{auto_notify.sh,zsh_hooks.sh,log_helpers.sh}
rm -f ~/.termwatch/config/auto_notify.conf
# 然后从 ~/.zshrc 中移除相关配置
\`\`\`

## 备份信息
- **备份时间**: $TIMESTAMP
- **备份位置**: $BACKUP_DIR
- **恢复方法**: 复制备份文件覆盖当前配置即可

## 注意事项
1. 安装后需要重新加载 shell 配置: \`source ~/.zshrc\`
2. 扩展功能基于 TermWatch 基础设施，不影响原有功能
3. 所有配置文件均已备份，可以安全回滚
4. 扩展支持热切换，可随时启用/禁用

## 技术支持
- **项目地址**: /Users/xuxuxu/Documents/MyGitHub/TermWatch
- **扩展文档**: extensions/auto-notify/README.md
- **问题反馈**: xuqingming@myhexin.com
EOF
    
    log_success "安装记录: $install_log"
}

# 测试安装
test_installation() {
    log_info "测试扩展安装..."
    
    # 测试核心文件
    if [[ -f "$TERMWATCH_DIR/auto_notify.sh" && -f "$TERMWATCH_DIR/zsh_hooks.sh" ]]; then
        log_success "核心文件安装正确"
    else
        log_error "核心文件安装失败"
        return 1
    fi
    
    # 测试配置文件
    if [[ -f "$TERMWATCH_DIR/config/auto_notify.conf" ]]; then
        log_success "配置文件安装正确"
    else
        log_warning "配置文件可能未正确安装"
    fi
    
    # 测试基础通知（继承 TermWatch 功能）
    if bash "$TERMWATCH_DIR/termwatch.sh" --test >/dev/null 2>&1; then
        log_success "基础通知功能正常"
    else
        log_warning "基础通知功能测试失败，但扩展应该可以正常工作"
    fi
    
    log_success "扩展安装测试完成"
}

# 显示完成信息
show_completion_info() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    🎉 安装完成！                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${BLUE}下一步操作:${NC}"
    echo "1. 重新加载 shell 配置:"
    echo -e "   ${YELLOW}source ~/.zshrc${NC}"
    echo ""
    echo "2. 查看扩展状态:"
    echo -e "   ${YELLOW}termwatch_status${NC}"
    echo ""
    echo "3. 测试功能:"
    echo -e "   ${YELLOW}sleep 35${NC}        # 测试自动通知"
    echo -e "   ${YELLOW}!echo test${NC}      # 测试强制通知"
    echo ""
    
    echo -e "${BLUE}主要功能:${NC}"
    echo "• 超过 30 秒的命令自动通知"
    echo "• 使用 !command 强制通知任何命令"
    echo "• 重要命令自动识别和通知"
    echo "• 智能过滤无关命令"
    echo ""
    
    echo -e "${BLUE}管理命令:${NC}"
    echo -e "• ${YELLOW}termwatch_status${NC}  - 查看扩展状态"
    echo -e "• ${YELLOW}termwatch_toggle${NC}  - 切换自动通知开关"
    echo ""
    
    echo -e "${BLUE}配置和日志:${NC}"
    echo -e "• 配置文件: ${YELLOW}~/.termwatch/config/auto_notify.conf${NC}"
    echo -e "• 卸载方法: ${YELLOW}bash ~/.termwatch/uninstall_auto_notify.sh${NC}"
    echo -e "• 安装记录: ${YELLOW}$BACKUP_DIR${NC}"
    echo ""
    
    log_success "TermWatch Auto-Notify Extension 安装完成！"
}

# 主安装流程
main() {
    show_banner
    
    echo "这是 TermWatch 的自动通知扩展，为 TermWatch 添加智能的命令监控功能。"
    echo ""
    
    read -p "是否继续安装 Auto-Notify 扩展？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
    
    echo ""
    check_environment
    create_backup
    install_extension_files
    configure_shell_integration
    generate_uninstall_script
    create_install_log
    test_installation
    
    echo ""
    show_completion_info
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi