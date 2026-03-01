#!/bin/bash

# OpenCode 通知插件一键安装脚本
# 自动安装 TermWatch 通知插件到 OpenCode 插件目录

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 路径常量
PLUGIN_DIR="$HOME/.config/opencode/plugins"
PLUGIN_FILE="$PLUGIN_DIR/termwatch-notify.js"
TERMWATCH_SCRIPT="$HOME/.termwatch/termwatch.sh"

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."

    # 检查 OpenCode
    if ! command -v opencode >/dev/null 2>&1 && [[ ! -f "/Applications/OpenCode.app/Contents/MacOS/opencode-cli" ]]; then
        log_error "OpenCode 未安装，请先安装 OpenCode"
        log_error "下载地址: https://opencode.ai"
        exit 1
    fi

    # 检查 TermWatch 脚本
    if [[ ! -f "$TERMWATCH_SCRIPT" ]]; then
        log_error "TermWatch 未正确安装，请先运行 TermWatch 安装脚本"
        exit 1
    fi

    log_success "所有依赖检查通过"
}

# 创建插件目录
create_plugin_dir() {
    log_info "创建 OpenCode 插件目录..."
    mkdir -p "$PLUGIN_DIR"
    log_success "插件目录已就绪: $PLUGIN_DIR"
}

# 备份现有插件
backup_existing_plugin() {
    if [[ -f "$PLUGIN_FILE" ]]; then
        local backup_path="${PLUGIN_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "备份现有插件到 $backup_path..."
        cp "$PLUGIN_FILE" "$backup_path"
        log_success "现有插件已备份"
    fi
}

# 安装插件文件
install_plugin() {
    log_info "安装 TermWatch 通知插件..."

    cat > "$PLUGIN_FILE" << 'PLUGIN_EOF'
/**
 * TermWatch Notification Plugin for OpenCode
 *
 * 触发时机：
 *   - session.idle     → AI 完成任务，等待你输入  → 成功通知
 *   - session.error    → 出错需要处理             → 错误通知
 *   - permission.asked → AI 需要你授权危险操作    → 警告通知（最紧急）
 *
 * 通知通过本机 TermWatch 发送（Bark / Server酱 → 手机 / Apple Watch）
 */
export const TermWatchPlugin = async ({ project, $ }) => {
  // 动态获取 HOME，避免硬编码用户名，支持多机器复用
  const home = (await $`echo $HOME`.text()).trim()
  // 使用完整路径 /bin/bash，因为 Bun shell 环境里 bash 不在 PATH 中
  const TERMWATCH = `/bin/bash ${home}/.termwatch/termwatch.sh`

  // 取工程名（目录路径最后一段）
  const projectName =
    project?.path?.split("/").filter(Boolean).pop() ?? "OpenCode"

  // 防抖：5 秒内 session.idle 重复触发则跳过
  // （TermWatch 本身也有去重机制，此处是双重保障）
  let lastIdleAt = 0

  return {
    event: async ({ event }) => {
      // AI 完成当前轮次所有工具调用，等待用户输入
      if (event.type === "session.idle") {
        const now = Date.now()
        if (now - lastIdleAt < 5000) return
        lastIdleAt = now

        await $`${TERMWATCH} success ${`[${projectName}] AI 完成，等待你的输入`}`.nothrow()

      // session 出错，需要用户介入
      } else if (event.type === "session.error") {
        await $`${TERMWATCH} error ${`[${projectName}] OpenCode 出错，请检查`}`.nothrow()

      // AI 请求危险操作授权，最需要立即处理
      } else if (event.type === "permission.asked") {
        await $`${TERMWATCH} warning ${`[${projectName}] AI 请求授权，需要你确认`}`.nothrow()
      }
    },
  }
}
PLUGIN_EOF

    log_success "插件文件已安装: $PLUGIN_FILE"
}

# 验证插件安装
test_plugin() {
    log_info "验证插件文件..."

    if [[ ! -f "$PLUGIN_FILE" ]]; then
        log_error "插件文件不存在: $PLUGIN_FILE"
        return 1
    fi

    if [[ ! -s "$PLUGIN_FILE" ]]; then
        log_error "插件文件为空: $PLUGIN_FILE"
        return 1
    fi

    local missing_keywords=()

    if ! grep -q "TermWatchPlugin" "$PLUGIN_FILE"; then
        missing_keywords+=("TermWatchPlugin")
    fi

    if ! grep -q "session.idle" "$PLUGIN_FILE"; then
        missing_keywords+=("session.idle")
    fi

    if ! grep -q "termwatch.sh" "$PLUGIN_FILE"; then
        missing_keywords+=("termwatch.sh")
    fi

    if [[ ${#missing_keywords[@]} -gt 0 ]]; then
        log_error "插件文件缺少关键词: ${missing_keywords[*]}"
        return 1
    fi

    log_success "插件文件验证通过"
}

# 测试 TermWatch 推送
test_termwatch() {
    log_info "测试 TermWatch 推送..."

    if bash "$TERMWATCH_SCRIPT" success "OpenCode 集成安装成功！" 2>/dev/null; then
        log_success "TermWatch 推送测试成功"
    else
        log_warning "TermWatch 推送测试失败，请检查 Bark / Server酱 推送配置"
        log_warning "推送配置是可选的，插件功能不受影响"
        log_warning "配置方法：bash scripts/configure-bark.sh 或 bash scripts/configure-serverchan.sh"
    fi
}

# 显示完成信息
show_completion() {
    echo
    log_success "🎉 OpenCode 集成安装完成！"
    echo
    echo -e "${GREEN}已安装的功能：${NC}"
    echo "  📋 session.idle     — AI 完成任务，等待输入时推送成功通知"
    echo "  ❌ session.error    — 出错需要处理时推送错误通知"
    echo "  ⚠️  permission.asked — AI 请求危险操作授权时推送警告通知（最紧急）"
    echo
    echo -e "${YELLOW}下一步操作：${NC}"
    echo "  1. 重启 OpenCode 以加载新的插件配置"
    echo "  2. 在新的 OpenCode 会话中测试通知功能"
    echo
    echo -e "${BLUE}插件文件位置：${NC}"
    echo "  $PLUGIN_FILE"
    echo
    echo -e "${BLUE}卸载方法：${NC}"
    echo "  rm \"$PLUGIN_FILE\""
    echo "  然后重启 OpenCode"
    echo
    echo -e "${GREEN}享受智能通知功能吧！🚀${NC}"
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查上面的错误信息"' ERR

# 主函数
main() {
    echo -e "${BLUE}"
    cat << "EOF"
   ____                  ____          _      
  / __ \___  ___ ____   / ___|___   __| | ___ 
 / / / / _ \/ _ `/ _ \ | |   / _ \ / _` |/ _ \
/ /_/ /  __/ ___/ // / | |__| (_) | (_| |  __/
\____/\___/_/  /_//_/   \____\___/ \__,_|\___|

        OpenCode 通知插件安装器
EOF
    echo -e "${NC}"

    check_dependencies
    create_plugin_dir
    backup_existing_plugin
    install_plugin
    test_plugin
    test_termwatch
    show_completion
}

main "$@"
