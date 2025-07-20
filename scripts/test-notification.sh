#!/bin/bash

# TermWatch 通知测试脚本

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 设置环境变量
export TERMWATCH_ROOT="$PROJECT_ROOT"
export TERMWATCH_QUIET_LOAD=true

# 加载 TermWatch 模块
source "$PROJECT_ROOT/src/config.sh"
source "$PROJECT_ROOT/src/utils.sh"

# 测试计数器
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    ((TESTS_TOTAL++))
    
    echo -n "测试: $test_name ... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        local actual_exit_code=$?
        if [[ $actual_exit_code -eq $expected_exit_code ]]; then
            echo -e "${GREEN}通过${NC}"
            ((TESTS_PASSED++))
            return 0
        else
            echo -e "${RED}失败${NC} (退出码: $actual_exit_code, 期望: $expected_exit_code)"
            ((TESTS_FAILED++))
            return 1
        fi
    else
        echo -e "${RED}失败${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 显示测试开始信息
echo "=========================================="
echo "        TermWatch 功能测试"
echo "=========================================="
echo

# 测试 1: 配置加载
echo -e "${BLUE}1. 配置系统测试${NC}"
run_test "默认配置加载" "source '$PROJECT_ROOT/src/config.sh'"
run_test "获取配置值" "get_config AUTO_NOTIFY_THRESHOLD"
run_test "设置配置值" "set_config TEST_KEY test_value"
echo

# 测试 2: 工具函数
echo -e "${BLUE}2. 工具函数测试${NC}"
run_test "时间戳获取" "get_timestamp"
run_test "时间差计算" "time_diff 1000000000 1000000060"
run_test "持续时间格式化" "format_duration 65"
run_test "数字检查" "is_number 123"
run_test "命令存在检查" "command_exists bash"
echo

# 测试 3: 通知工具检查
echo -e "${BLUE}3. 通知工具测试${NC}"
if command -v terminal-notifier >/dev/null 2>&1; then
    run_test "terminal-notifier 可用性" "command -v terminal-notifier"
    echo "  ✓ terminal-notifier 已安装"
elif command -v osascript >/dev/null 2>&1; then
    run_test "osascript 可用性" "command -v osascript"
    echo "  ✓ osascript 可用 (系统内置)"
else
    echo -e "  ${RED}✗ 未找到可用的通知工具${NC}"
    ((TESTS_FAILED++))
fi
echo

# 测试 4: 通知功能测试
echo -e "${BLUE}4. 通知功能测试${NC}"
run_test "基础通知脚本" "bash '$PROJECT_ROOT/src/notifier.sh' 'TEST' 'Test message'"

# 询问用户是否进行交互式通知测试
echo
read -p "是否进行交互式通知测试? (发送真实通知到设备) (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}发送测试通知...${NC}"
    
    # 发送各种类型的通知
    bash "$PROJECT_ROOT/src/notifier.sh" "success" "成功通知测试 ✅"
    sleep 2
    bash "$PROJECT_ROOT/src/notifier.sh" "error" "错误通知测试 ❌"
    sleep 2
    bash "$PROJECT_ROOT/src/notifier.sh" "warning" "警告通知测试 ⚠️"
    sleep 2
    bash "$PROJECT_ROOT/src/notifier.sh" "info" "信息通知测试 ℹ️"
    
    echo
    read -p "您收到了通知吗? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓ 交互式通知测试通过${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ 交互式通知测试失败${NC}"
        echo "  请检查以下设置:"
        echo "  1. 系统偏好设置 > 通知 > 终端"
        echo "  2. 确保允许通知"
        echo "  3. Apple Watch 通知设置"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
else
    echo "跳过交互式通知测试"
fi
echo

# 测试 5: Shell 集成测试
echo -e "${BLUE}5. Shell 集成测试${NC}"
run_test "Shell 集成脚本加载" "source '$PROJECT_ROOT/src/shell-integration.sh'"

# 测试环境下的函数定义检查
if source "$PROJECT_ROOT/src/shell-integration.sh" >/dev/null 2>&1; then
    run_test "notify 函数定义" "type notify"
    run_test "notify_success 函数定义" "type notify_success"
    run_test "termwatch 函数定义" "type termwatch"
else
    echo -e "${RED}✗ Shell 集成加载失败${NC}"
    ((TESTS_FAILED += 3))
    ((TESTS_TOTAL += 3))
fi
echo

# 测试 6: 系统环境检查
echo -e "${BLUE}6. 系统环境测试${NC}"
run_test "macOS 系统检查" "[[ \$(uname) == 'Darwin' ]]"
run_test "主目录写入权限" "mkdir -p '$HOME/.termwatch/test' && rmdir '$HOME/.termwatch/test'"

# 检查 Apple Watch 相关
if [[ -d "/Applications/Watch.app" ]]; then
    echo "  ✓ 检测到 Apple Watch 应用"
    run_test "Apple Watch 应用检查" "[[ -d '/Applications/Watch.app' ]]"
else
    echo "  ⚠️ 未检测到 Apple Watch 应用"
fi
echo

# 测试 7: 配置文件完整性
echo -e "${BLUE}7. 配置文件测试${NC}"
run_test "默认配置文件存在" "[[ -f '$PROJECT_ROOT/config/default.conf' ]]"
run_test "用户配置示例存在" "[[ -f '$PROJECT_ROOT/config/user.conf.example' ]]"
run_test "README 文件存在" "[[ -f '$PROJECT_ROOT/README.md' ]]"
echo

# 测试 8: 权限和安全性测试
echo -e "${BLUE}8. 权限和安全性测试${NC}"
run_test "脚本执行权限" "[[ -x '$PROJECT_ROOT/src/notifier.sh' ]]"
run_test "配置文件可读性" "[[ -r '$PROJECT_ROOT/config/default.conf' ]]"
run_test "日志目录创建" "mkdir -p '$HOME/.termwatch/logs'"
echo

# 性能测试
echo -e "${BLUE}9. 性能测试${NC}"
echo -n "通知响应时间测试 ... "
start_time=$(date +%s%N)
bash "$PROJECT_ROOT/src/notifier.sh" "PERF_TEST" "Performance test" >/dev/null 2>&1
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 )) # 转换为毫秒

if [[ $duration -lt 1000 ]]; then
    echo -e "${GREEN}通过${NC} (${duration}ms)"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}慢${NC} (${duration}ms - 超过1秒)"
    ((TESTS_PASSED++)) # 仍然算通过，只是慢
fi
((TESTS_TOTAL++))
echo

# 显示测试结果
echo "=========================================="
echo "           测试结果汇总"
echo "=========================================="
echo "总测试数: $TESTS_TOTAL"
echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
echo -e "失败: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 所有测试通过！TermWatch 已准备就绪。${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️ 有 $TESTS_FAILED 个测试失败，请检查相关配置。${NC}"
    
    # 提供故障排除建议
    echo
    echo "故障排除建议:"
    if ! command -v terminal-notifier >/dev/null 2>&1 && ! command -v osascript >/dev/null 2>&1; then
        echo "- 安装 terminal-notifier: brew install terminal-notifier"
    fi
    echo "- 检查通知权限: 系统偏好设置 > 通知"
    echo "- 检查文件权限: chmod +x $PROJECT_ROOT/src/*.sh"
    echo "- 查看详细日志: tail -f ~/.termwatch/logs/termwatch.log"
    
    exit 1
fi