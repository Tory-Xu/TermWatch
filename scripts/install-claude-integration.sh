#!/bin/bash

# Claude Code 集成一键安装脚本
# 自动配置 Claude Code 钩子系统与 TermWatch 的集成

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    
    # 检查 Claude Code
    if ! command -v claude >/dev/null 2>&1; then
        log_error "Claude Code 未安装，请先安装 Claude Code"
        exit 1
    fi
    
    # 检查 jq
    if ! command -v jq >/dev/null 2>&1; then
        log_warning "jq 未安装，正在安装..."
        if command -v brew >/dev/null 2>&1; then
            brew install jq
        else
            log_error "请先安装 jq: brew install jq"
            exit 1
        fi
    fi
    
    # 检查 TermWatch
    if [[ ! -f ~/.termwatch/termwatch.sh ]]; then
        log_error "TermWatch 未正确安装，请先运行 TermWatch 安装脚本"
        exit 1
    fi
    
    log_success "所有依赖检查通过"
}

# 创建钩子目录
create_hooks_directory() {
    log_info "创建 TermWatch 专用钩子目录..."
    mkdir -p ~/.claude/hooks/termwatch
    log_success "TermWatch 钩子目录已创建: ~/.claude/hooks/termwatch"
}

# 创建通知钩子脚本
create_notify_hook() {
    log_info "创建通知钩子脚本..."
    
    cat > ~/.claude/hooks/termwatch/notify.sh << 'EOF'
#!/bin/bash

# Claude Code 通知钩子脚本
# 用于将 Claude Code 的通知发送到 TermWatch

set -e

# 读取 JSON 输入
input=$(cat)

# 解析 JSON 数据
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
message=$(echo "$input" | jq -r '.message // "Claude Code 通知"')
title=$(echo "$input" | jq -r '.title // "Claude Code"')

# 发送通知到 TermWatch
if [[ -f ~/.termwatch/termwatch.sh ]]; then
    bash ~/.termwatch/termwatch.sh info "$message" 2>/dev/null || {
        echo "警告: TermWatch 通知发送失败" >&2
    }
elif command -v termwatch >/dev/null 2>&1; then
    termwatch info "$message" 2>/dev/null || {
        echo "警告: TermWatch 通知发送失败" >&2
    }
else
    echo "信息: TermWatch 未安装，跳过通知" >&2
fi

# 记录日志
if [[ -f ~/.termwatch/termwatch.sh ]] || command -v termwatch >/dev/null 2>&1; then
    echo "通知已发送: $title - $message" >&2
else
    echo "通知钩子执行完毕: $title - $message（未发送通知）" >&2
fi

exit 0
EOF

    chmod +x ~/.claude/hooks/termwatch/notify.sh
    log_success "通知钩子脚本已创建"
}

# 创建任务完成钩子脚本
create_stop_hook() {
    log_info "创建任务完成钩子脚本..."
    
    cat > ~/.claude/hooks/termwatch/stop.sh << 'EOF'
#!/bin/bash

# Claude Code Stop 钩子脚本
# 当 Claude 完成任务时发送通知

set -e

# 读取 JSON 输入
input=$(cat)

# 解析 JSON 数据
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')

# 如果钩子已经激活，避免循环通知
if [[ "$stop_hook_active" == "true" ]]; then
    exit 0
fi

# 发送任务完成通知
if [[ -f ~/.termwatch/termwatch.sh ]]; then
    bash ~/.termwatch/termwatch.sh success "Claude Code 任务已完成" 2>/dev/null || {
        echo "警告: TermWatch 通知发送失败" >&2
    }
elif command -v termwatch >/dev/null 2>&1; then
    termwatch success "Claude Code 任务已完成" 2>/dev/null || {
        echo "警告: TermWatch 通知发送失败" >&2
    }
else
    echo "信息: TermWatch 未安装，跳过通知" >&2
fi

# 记录日志
if [[ -f ~/.termwatch/termwatch.sh ]] || command -v termwatch >/dev/null 2>&1; then
    echo "任务完成通知已发送" >&2
else
    echo "任务完成钩子执行完毕（未发送通知）" >&2
fi

exit 0
EOF

    chmod +x ~/.claude/hooks/termwatch/stop.sh
    log_success "任务完成钩子脚本已创建"
}

# 创建钩子目录说明文档
create_hooks_readme() {
    log_info "创建钩子目录说明文档..."
    
    cat > ~/.claude/hooks/termwatch/README.md << 'EOF'
# Claude Code 钩子脚本目录

此目录包含Claude Code的钩子脚本，用于扩展Claude的功能。

## 脚本说明

### notify.sh
- **用途**: 处理Claude的通知事件
- **触发时机**: 当Claude发送系统通知时
- **功能**: 通过TermWatch发送信息类型通知到macOS、iPhone、Apple Watch

### stop.sh  
- **用途**: 处理Claude的任务完成事件
- **触发时机**: 当Claude完成任务、会话结束或使用特定工具时
- **功能**: 通过TermWatch发送成功类型通知到所有配置的推送渠道

## 推送渠道

钩子脚本通过TermWatch支持以下推送渠道：
- 📱 macOS 系统通知
- 🍎 iOS/Apple Watch (Bark) - 推荐
- 💬 微信 (Server酱) - 备选

## 配置文件

钩子配置位于: `~/.claude/settings.json`

## 依赖要求

- TermWatch 已安装并配置
- jq 已安装 (JSON解析)
- TermWatch脚本位于: `~/.termwatch/termwatch.sh`

## 维护说明

- 修改钩子脚本后需要重启Claude Code才能生效
- 钩子脚本必须具有执行权限
- 使用 `claude --debug` 可以查看钩子执行日志

---

自动生成时间: $(date)
EOF

    log_success "钩子目录说明文档已创建"
}

# 备份现有配置
backup_claude_config() {
    if [[ -f ~/.claude/settings.json ]]; then
        log_info "备份现有 Claude 配置..."
        cp ~/.claude/settings.json ~/.claude/settings.json.backup.$(date +%Y%m%d_%H%M%S)
        log_success "配置已备份"
    fi
}

# 迁移现有钩子到新目录
migrate_existing_hooks() {
    log_info "检查并迁移现有钩子..."
    
    local old_notify="$HOME/.claude/hooks/notify.sh"
    local old_stop="$HOME/.claude/hooks/stop.sh"
    local old_readme="$HOME/.claude/hooks/README.md"
    
    local new_notify="$HOME/.claude/hooks/termwatch/notify.sh"
    local new_stop="$HOME/.claude/hooks/termwatch/stop.sh"
    local new_readme="$HOME/.claude/hooks/termwatch/README.md"
    
    local migrated=false
    
    # 迁移 notify.sh
    if [[ -f "$old_notify" ]] && [[ ! -f "$new_notify" ]]; then
        log_info "迁移现有通知钩子..."
        mv "$old_notify" "$new_notify" 2>/dev/null || cp "$old_notify" "$new_notify"
        migrated=true
    fi
    
    # 迁移 stop.sh
    if [[ -f "$old_stop" ]] && [[ ! -f "$new_stop" ]]; then
        log_info "迁移现有停止钩子..."
        mv "$old_stop" "$new_stop" 2>/dev/null || cp "$old_stop" "$new_stop"
        migrated=true
    fi
    
    # 迁移 README.md
    if [[ -f "$old_readme" ]] && [[ ! -f "$new_readme" ]]; then
        log_info "迁移现有说明文档..."
        mv "$old_readme" "$new_readme" 2>/dev/null || cp "$old_readme" "$new_readme"
        migrated=true
    fi
    
    if [[ "$migrated" == "true" ]]; then
        log_success "现有钩子已迁移到 ~/.claude/hooks/termwatch/"
        log_warning "请重启 Claude Code 以使新的钩子路径生效"
    else
        log_info "无现有钩子需要迁移"
    fi
}

# 配置 Claude Code 钩子
configure_claude_hooks() {
    log_info "配置 Claude Code 钩子..."
    
    # 创建或更新 settings.json
    local settings_file=~/.claude/settings.json
    local hooks_config='{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'$HOME'/.claude/hooks/termwatch/notify.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'$HOME'/.claude/hooks/termwatch/stop.sh"
          }
        ]
      }
    ]
  }
}'

    if [[ -f "$settings_file" ]]; then
        # 合并现有配置
        local existing_config=$(cat "$settings_file")
        echo "$existing_config" | jq ". + $hooks_config" > "$settings_file"
    else
        # 创建新的配置文件
        echo '{"model": "sonnet"}' | jq ". + $hooks_config" > "$settings_file"
    fi
    
    log_success "Claude Code 钩子配置已更新"
}

# 测试钩子脚本
test_hooks() {
    log_info "测试钩子脚本..."
    
    # 测试通知钩子
    log_info "测试通知钩子..."
    if echo '{"session_id": "install_test", "message": "Claude Code 集成测试", "title": "安装脚本"}' | ~/.claude/hooks/termwatch/notify.sh; then
        log_success "通知钩子测试成功"
    else
        log_error "通知钩子测试失败"
        return 1
    fi
    
    # 测试任务完成钩子
    log_info "测试任务完成钩子..."
    if echo '{"session_id": "install_test", "stop_hook_active": false}' | ~/.claude/hooks/termwatch/stop.sh; then
        log_success "任务完成钩子测试成功"
    else
        log_error "任务完成钩子测试失败"
        return 1
    fi
}

# 显示安装完成信息
show_completion_info() {
    echo
    log_success "🎉 Claude Code 集成安装完成！"
    echo
    echo -e "${GREEN}已安装的功能：${NC}"
    echo "  📋 任务完成通知"
    echo "  🔔 等待输入提醒"
    echo "  🌐 多渠道推送（macOS + 微信 + Apple Watch）"
    echo "  ⚙️ 自动化钩子配置"
    echo
    echo -e "${YELLOW}下一步操作：${NC}"
    echo "  1. 重启 Claude Code 以加载新的钩子配置"
    echo "  2. 在新的 Claude 会话中测试通知功能"
    echo "  3. 如需配置远程推送，请参考："
    echo "     - Bark（iOS/Apple Watch）：bash scripts/configure-bark.sh"
    echo "     - Server酱（微信）：bash scripts/configure-serverchan.sh"
    echo
    echo -e "${BLUE}钩子脚本位置：${NC}"
    echo "  ~/.claude/hooks/termwatch/notify.sh"
    echo "  ~/.claude/hooks/termwatch/stop.sh"
    echo "  ~/.claude/hooks/termwatch/README.md"
    echo
    echo -e "${BLUE}配置文件位置：${NC}"
    echo "  ~/.claude/settings.json"
    echo
    echo -e "${GREEN}安装完成！享受智能通知功能吧！🚀${NC}"
}

# 主函数
main() {
    echo -e "${BLUE}"
    cat << "EOF"
   ____ _                 _        ____          _      
  / ___| | __ _ _   _  __| | ___  / ___|___   __| | ___ 
 | |   | |/ _` | | | |/ _` |/ _ \| |   / _ \ / _` |/ _ \
 | |___| | (_| | |_| | (_| |  __/| |__| (_) | (_| |  __/
  \____|_|\__,_|\__,_|\__,_|\___| \____\___/ \__,_|\___|
                                                       
        TermWatch 集成安装器
EOF
    echo -e "${NC}"
    
    check_dependencies
    backup_claude_config
    create_hooks_directory
    migrate_existing_hooks
    create_notify_hook
    create_stop_hook
    create_hooks_readme
    configure_claude_hooks
    test_hooks
    show_completion_info
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查上面的错误信息"; exit 1' ERR

# 运行主函数
main "$@"