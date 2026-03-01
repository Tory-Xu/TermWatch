#!/bin/bash

# TermWatch 简化安装脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="TermWatch"
INSTALL_DIR="$HOME/.termwatch"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================"
echo "  $PROJECT_NAME 安装程序"
echo -e "========================================${NC}"
echo

# 检查 macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ TermWatch 只支持 macOS 系统"
    exit 1
fi

echo "✅ macOS 系统检测通过"

# 检查通知工具
if command -v terminal-notifier >/dev/null 2>&1; then
    echo "✅ terminal-notifier 已安装"
elif command -v brew >/dev/null 2>&1; then
    echo "📦 正在安装 terminal-notifier..."
    brew install terminal-notifier
    echo "✅ terminal-notifier 安装完成"
else
    echo "⚠️ 建议安装 Homebrew 和 terminal-notifier 以获得更好体验"
    echo "   将使用系统内置的 osascript"
fi

# 询问用户确认
echo
read -p "是否继续安装到 $INSTALL_DIR? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "安装已取消"
    exit 0
fi

# 备份现有安装
if [[ -d "$INSTALL_DIR" ]]; then
    echo "📦 备份现有安装..."
    mv "$INSTALL_DIR" "$INSTALL_DIR.backup.$(date +%Y%m%d_%H%M%S)"
fi

# 创建目录结构
echo "📁 创建目录结构..."
mkdir -p "$INSTALL_DIR"/{config,logs,cache}

# 复制文件
echo "📋 复制文件..."
cp "$CURRENT_DIR/src/termwatch.sh" "$INSTALL_DIR/"
cp "$CURRENT_DIR/config/default.conf" "$INSTALL_DIR/config/"
cp "$CURRENT_DIR/config/user.conf.example" "$INSTALL_DIR/config/"
chmod +x "$INSTALL_DIR/termwatch.sh"

# 创建用户配置
if [[ ! -f "$INSTALL_DIR/config/user.conf" ]]; then
    echo "⚙️ 创建用户配置..."
    cat > "$INSTALL_DIR/config/user.conf" << EOF
# TermWatch 用户配置

# 基本设置
AUTO_NOTIFY_THRESHOLD=30
ENABLE_AUTO_MONITOR=true
NOTIFICATION_SOUND=default
NOTIFICATION_TITLE="我的终端"

# 消息模板
SUCCESS_TEMPLATE="✅ 任务完成"
ERROR_TEMPLATE="❌ 任务失败"
WARNING_TEMPLATE="⚠️ 注意"
INFO_TEMPLATE="ℹ️ 信息"

# 静音时间设置
ENABLE_QUIET_HOURS=false
QUIET_HOURS_START=22
QUIET_HOURS_END=8

# 日志设置
ENABLE_LOGGING=true
LOG_LEVEL=INFO
LOG_FILE="$HOME/.termwatch/logs/termwatch.log"

# 通知去重设置
DUPLICATE_THRESHOLD=300
ENABLE_DEDUPLICATION=false

# 远程推送服务配置
ENABLE_SERVERCHAN=false           # 是否启用 Server酱 推送
ENABLE_BARK=true                  # 是否启用 Bark 推送（推荐）
ENABLE_PARALLEL_PUSH=false        # 是否并行发送到所有服务（false=优先级模式）

# Bark 推送配置（推荐）
# 1. 从 App Store 下载 Bark 应用
# 2. 复制应用中的推送 Key
# 3. 取消注释并填写下面的配置项
# BARK_KEY=""                      # Bark 推送 Key
# BARK_SERVER="https://api.day.app" # Bark 服务器地址（默认官方服务器）
# BARK_SOUND="default"             # 推送声音
# BARK_GROUP="TermWatch"           # 推送分组名称
EOF
fi

# 配置 shell 集成
echo "🔧 配置 shell 集成..."
SHELL_CONFIG=""
case "$(basename "$SHELL")" in
    "zsh") SHELL_CONFIG="$HOME/.zshrc" ;;
    "bash") SHELL_CONFIG="$HOME/.bash_profile" ;;
esac

if [[ -n "$SHELL_CONFIG" ]]; then
    # 移除旧配置
    if [[ -f "$SHELL_CONFIG" ]]; then
        grep -v "termwatch\|TermWatch" "$SHELL_CONFIG" > "$SHELL_CONFIG.tmp" || true
        mv "$SHELL_CONFIG.tmp" "$SHELL_CONFIG"
    fi
    
    # 添加新配置
    cat >> "$SHELL_CONFIG" << EOF

# TermWatch 通知工具
alias termwatch='bash $INSTALL_DIR/termwatch.sh'
alias notify='bash $INSTALL_DIR/termwatch.sh'
alias notify_success='bash $INSTALL_DIR/termwatch.sh success'
alias notify_error='bash $INSTALL_DIR/termwatch.sh error'
alias notify_warning='bash $INSTALL_DIR/termwatch.sh warning'
alias notify_info='bash $INSTALL_DIR/termwatch.sh info'
EOF
    
    echo "✅ 已配置 shell 别名到 $SHELL_CONFIG"
fi

# 测试安装
echo "🧪 测试安装..."
if bash "$INSTALL_DIR/termwatch.sh" --test; then
    echo "✅ 安装测试通过"
else
    echo "⚠️ 安装测试失败，但基本功能应该可用"
fi

echo
echo -e "${GREEN}🎉 TermWatch 基础安装完成！${NC}"
echo
echo -e "${BLUE}==============================================="
echo "  立即体验 TermWatch"
echo -e "===============================================${NC}"
echo -e "${YELLOW}1. 重载 shell 配置:${NC}"
echo "   source $SHELL_CONFIG"
echo
echo -e "${YELLOW}2. 发送测试通知:${NC}"
echo "   notify \"Hello TermWatch!\""
echo "   notify_success \"任务完成\""
echo "   notify_error \"出现错误\""
echo
echo -e "${BLUE}==============================================="
echo "  📱 配置远程推送服务 (推荐)"
echo -e "===============================================${NC}"
echo -e "${GREEN}🚀 Bark - iOS/Apple Watch 原生推送${NC} (强烈推荐)"
echo "   优势: 免费、开源、Apple Watch 完美支持、响应快速"
echo "   配置: ${YELLOW}bash scripts/configure-bark.sh${NC}"
echo
echo -e "${GREEN}💬 Server酱 - 微信推送${NC} (备选)"
echo "   优势: 免费、微信接收、支持 Apple Watch"
echo "   配置: ${YELLOW}bash scripts/configure-serverchan.sh${NC}"
echo
echo -e "${BLUE}==============================================="
echo "  🤖 Claude Code 智能集成 (可选)"
echo -e "===============================================${NC}"
echo "如果你使用 Claude Code，可以启用智能通知功能："
echo "• 📋 任务完成自动通知"
echo "• 🔔 等待输入智能提醒"
echo "• 🌐 多渠道推送 (macOS + 手机 + Apple Watch)"
echo
echo -e "${YELLOW}一键安装 Claude 集成:${NC}"
echo "   ${YELLOW}bash scripts/install-claude-integration.sh${NC}"
echo
echo -e "${BLUE}==============================================="
echo "  ⚙️ Auto-Notify 扩展 (可选)"
echo -e "===============================================${NC}"
echo "智能命令执行监控和自动通知扩展："
echo "• 🕐 智能时间监控 (超过30秒的命令自动通知)"
echo "• ✅ 自动判断命令成功/失败状态"
echo "• ⚡ 强制通知模式 (!command)"
echo "• 🎯 重要命令自动识别"
echo "• 🔍 智能过滤无关命令"
echo
echo -e "${YELLOW}一键安装 Auto-Notify 扩展:${NC}"
echo "   ${YELLOW}bash extensions/auto-notify/scripts/install.sh${NC}"
echo
echo -e "${BLUE}==============================================="
echo "  📚 更多信息"
echo -e "===============================================${NC}"
echo -e "${YELLOW}配置文件:${NC} $INSTALL_DIR/config/user.conf"
echo -e "${YELLOW}日志目录:${NC} $INSTALL_DIR/logs/"
echo -e "${YELLOW}完整文档:${NC} README.md"
echo -e "${YELLOW}获取帮助:${NC} termwatch --help"
echo
echo -e "${GREEN}💡 推荐配置流程:${NC}"
echo "   1️⃣  先配置远程推送服务 (Bark 或 Server酱)"
   echo "   2️⃣  然后安装 AI 工具集成 (Claude Code / OpenCode)"
echo "   3️⃣  安装 Auto-Notify 扩展 (命令监控)"
echo "   4️⃣  享受全方位的智能通知体验!"
echo
echo -e "${GREEN}🎯 现在就开始配置吧！${NC}"
echo

# 交互式配置引导
show_interactive_setup() {
    echo -e "${BLUE}==============================================="
    echo "  🚀 一键配置向导"
    echo -e "===============================================${NC}"
    
    local configured_services=()
    
    # 显示选项的函数
    show_menu_options() {
        echo "请选择要配置的服务："
        echo
        echo "1️⃣  配置 Bark 推送 (iOS/Apple Watch 推荐)"
        echo "2️⃣  配置 Server酱 推送 (微信接收)"
        echo "3️⃣  安装 Claude Code 集成 (智能通知)"
        echo "4️⃣  安装 OpenCode 集成 (AI 任务通知)"
        echo "5️⃣  安装 Auto-Notify 扩展 (命令执行监控)"
        echo "6️⃣  完成配置"
        echo
        
        # 显示已配置的服务
        if [[ ${#configured_services[@]} -gt 0 ]]; then
            echo -e "${GREEN}✅ 已配置服务: ${configured_services[*]}${NC}"
            echo
        fi
    }
    
    while true; do
        show_menu_options
        
        read -p "请选择 (1-6): " -n 1 -r choice
        echo
        
        case $choice in
            1)
                echo -e "${GREEN}正在启动 Bark 配置...${NC}"
                if [[ -f "scripts/configure-bark.sh" ]]; then
                    if bash scripts/configure-bark.sh; then
                        configured_services+=("Bark")
                        echo -e "${GREEN}✅ Bark 配置完成！${NC}"
                    else
                        echo -e "${YELLOW}⚠️ Bark 配置未完成${NC}"
                    fi
                else
                    echo -e "${YELLOW}Bark 配置脚本未找到，请手动运行: bash scripts/configure-bark.sh${NC}"
                fi
                echo
                echo "按任意键继续..."
                read -n 1 -s
                echo
                ;;
            2)
                echo -e "${GREEN}正在启动 Server酱 配置...${NC}"
                if [[ -f "scripts/configure-serverchan.sh" ]]; then
                    if bash scripts/configure-serverchan.sh; then
                        configured_services+=("Server酱")
                        echo -e "${GREEN}✅ Server酱 配置完成！${NC}"
                    else
                        echo -e "${YELLOW}⚠️ Server酱 配置未完成${NC}"
                    fi
                else
                    echo -e "${YELLOW}Server酱 配置脚本未找到，请手动运行: bash scripts/configure-serverchan.sh${NC}"
                fi
                echo
                echo "按任意键继续..."
                read -n 1 -s
                echo
                ;;
            3)
                echo -e "${GREEN}正在启动 Claude Code 集成安装...${NC}"
                if [[ -f "scripts/install-claude-integration.sh" ]]; then
                    if bash scripts/install-claude-integration.sh; then
                        configured_services+=("Claude集成")
                        echo -e "${GREEN}✅ Claude Code 集成安装完成！${NC}"
                    else
                        echo -e "${YELLOW}⚠️ Claude Code 集成安装未完成${NC}"
                    fi
                else
                    echo -e "${YELLOW}Claude 集成脚本未找到，请手动运行: bash scripts/install-claude-integration.sh${NC}"
                fi
                echo
                echo "按任意键继续..."
                read -n 1 -s
                echo
                ;;
            4)
                echo -e "${GREEN}正在启动 OpenCode 集成安装...${NC}"
                if [[ -f "scripts/configure-opencode-integration.sh" ]]; then
                    if bash scripts/configure-opencode-integration.sh; then
                        configured_services+=("OpenCode集成")
                        echo -e "${GREEN}✅ OpenCode 集成安装完成！${NC}"
                    else
                        echo -e "${YELLOW}⚠️ OpenCode 集成安装未完成${NC}"
                    fi
                else
                    echo -e "${YELLOW}OpenCode 集成脚本未找到，请手动运行: bash scripts/configure-opencode-integration.sh${NC}"
                fi
                echo
                echo "按任意键继续..."
                read -n 1 -s
                echo
                ;;
            5)
                echo -e "${GREEN}正在安装 Auto-Notify 扩展...${NC}"
                if [[ -f "extensions/auto-notify/scripts/install.sh" ]]; then
                    if bash extensions/auto-notify/scripts/install.sh; then
                        configured_services+=("Auto-Notify扩展")
                        echo -e "${GREEN}✅ Auto-Notify 扩展安装完成！${NC}"
                    else
                        echo -e "${YELLOW}⚠️ Auto-Notify 扩展安装未完成${NC}"
                    fi
                else
                    echo -e "${YELLOW}Auto-Notify 扩展脚本未找到，请手动运行: bash extensions/auto-notify/scripts/install.sh${NC}"
                fi
                echo
                echo "按任意键继续..."
                read -n 1 -s
                echo
                ;;
            6)
                echo -e "${GREEN}配置完成！${NC}"
                if [[ ${#configured_services[@]} -gt 0 ]]; then
                    echo -e "${GREEN}已成功配置: ${configured_services[*]}${NC}"
                else
                    echo -e "${YELLOW}未配置任何服务，你可以稍后手动配置：${NC}"
                    echo "  • Bark: bash scripts/configure-bark.sh"
                    echo "  • Server酱: bash scripts/configure-serverchan.sh"
                    echo "  • Claude 集成: bash scripts/install-claude-integration.sh"
                    echo "  • Auto-Notify 扩展: bash extensions/auto-notify/scripts/install.sh"
                fi
                break
                ;;
            *)
                echo -e "${YELLOW}无效选项 '$choice'，请重新选择：${NC}"
                echo
                echo "1️⃣  配置 Bark 推送 (iOS/Apple Watch 推荐)"
                echo "2️⃣  配置 Server酱 推送 (微信接收)"  
                echo "3️⃣  安装 Claude Code 集成 (智能通知)"
                echo "4️⃣  安装 OpenCode 集成 (AI 任务通知)"
                echo "5️⃣  安装 Auto-Notify 扩展 (命令执行监控)"
                echo "6️⃣  完成配置"
                echo
                ;;
        esac
    done
}

# 智能检测和配置建议
detect_and_suggest() {
    local suggestions=()
    
    # 检测 Claude Code
    if command -v claude >/dev/null 2>&1; then
        suggestions+=("检测到 Claude Code，强烈建议安装 Claude 集成功能！")
    fi
    
    # 检测 OpenCode
    if command -v opencode >/dev/null 2>&1 || [[ -f "/Applications/OpenCode.app/Contents/MacOS/opencode-cli" ]]; then
        suggestions+=("检测到 OpenCode，建议安装 OpenCode 集成功能！")
    fi
    
    # 检测 Bark 应用相关
    if [[ -d "/Applications/Bark.app" ]] || defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "Bark"; then
        suggestions+=("检测到 Bark 应用，推荐配置 Bark 推送！")
    fi
    
    # 显示智能建议
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        echo -e "${BLUE}🔍 智能检测结果:${NC}"
        for suggestion in "${suggestions[@]}"; do
            echo -e "   ${GREEN}• $suggestion${NC}"
        done
        echo
    fi
}

# 运行智能检测
detect_and_suggest

# 询问用户是否要配置
echo -e "${YELLOW}💡 提示: 推荐先配置远程推送，再安装 Claude 集成以获得最佳体验${NC}"
read -p "是否现在就配置推送服务和集成功能？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    show_interactive_setup
fi

echo
echo -e "${GREEN}🎉 安装完成！感谢使用 TermWatch！${NC}"