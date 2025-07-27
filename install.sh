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
echo -e "${GREEN}🎉 TermWatch 安装完成！${NC}"
echo
echo -e "${YELLOW}快速开始:${NC}"
echo "  # 重载 shell 配置"
echo "  source $SHELL_CONFIG"
echo
echo "  # 发送测试通知"
echo "  notify \"Hello TermWatch!\""
echo
echo "  # 发送不同类型通知"
echo "  notify_success \"任务完成\""
echo "  notify_error \"出现错误\""
echo
echo -e "${YELLOW}iPhone/Apple Watch 通知设置:${NC}"
echo "  🚀 Bark（推荐）："
echo "    1. 从 App Store 下载 Bark 应用"
echo "    2. 运行配置脚本: bash scripts/configure-bark.sh"
echo "  📱 Server酱（备选）："
echo "    1. 运行配置脚本: bash scripts/configure-serverchan.sh"
echo
echo -e "${YELLOW}配置文件:${NC} $INSTALL_DIR/config/user.conf"
echo -e "${YELLOW}日志目录:${NC} $INSTALL_DIR/logs/"
echo
echo "需要帮助? 查看 README.md 或运行 'termwatch --help'"