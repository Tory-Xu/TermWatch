#!/bin/bash

# Pushover 配置脚本

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="$HOME/.termwatch/config/user.conf"

echo -e "${BLUE}========================================"
echo "       Pushover 配置向导"
echo -e "========================================${NC}"
echo

# 检查配置文件
if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    touch "$CONFIG_FILE"
fi

echo "请按照以下步骤获取 Pushover 配置信息："
echo
echo -e "${YELLOW}1. 访问 https://pushover.net/ 并登录${NC}"
echo -e "${YELLOW}2. 找到 'Your User Key' (30字符，以 u 开头)${NC}"
echo -e "${YELLOW}3. 创建应用获取 'API Token' (30字符，以 a 开头)${NC}"
echo

# 输入 User Key
echo -e "${GREEN}请输入你的 Pushover User Key:${NC}"
read -p "User Key (u开头): " user_key

if [[ ! $user_key =~ ^u[a-zA-Z0-9]{29}$ ]]; then
    echo -e "${RED}错误: User Key 格式不正确，应该是 30 字符且以 u 开头${NC}"
    echo "示例: u1234567890abcdef1234567890abc"
    exit 1
fi

# 输入 API Token
echo -e "${GREEN}请输入你的 Pushover API Token:${NC}"
read -p "API Token (a开头): " api_token

if [[ ! $api_token =~ ^a[a-zA-Z0-9]{29}$ ]]; then
    echo -e "${RED}错误: API Token 格式不正确，应该是 30 字符且以 a 开头${NC}"
    echo "示例: a1234567890abcdef1234567890abc"
    exit 1
fi

# 备份现有配置
if [[ -f "$CONFIG_FILE" && -s "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}已备份现有配置${NC}"
fi

# 检查是否已有 Pushover 配置
if grep -q "PUSHOVER_" "$CONFIG_FILE"; then
    echo -e "${YELLOW}检测到现有 Pushover 配置，正在更新...${NC}"
    # 删除现有的 Pushover 配置行
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' '/PUSHOVER_/d' "$CONFIG_FILE"
    else
        sed -i '/PUSHOVER_/d' "$CONFIG_FILE"
    fi
fi

# 添加 Pushover 配置
echo "" >> "$CONFIG_FILE"
echo "# Pushover 推送服务配置" >> "$CONFIG_FILE"
echo "# 用于将通知发送到 iPhone 和 Apple Watch" >> "$CONFIG_FILE"
echo "PUSHOVER_USER=\"$user_key\"" >> "$CONFIG_FILE"
echo "PUSHOVER_TOKEN=\"$api_token\"" >> "$CONFIG_FILE"
echo "" >> "$CONFIG_FILE"

echo -e "${GREEN}✅ Pushover 配置已保存到: $CONFIG_FILE${NC}"
echo

# 测试配置
echo -e "${BLUE}正在测试 Pushover 连接...${NC}"

# 发送测试通知
test_response=$(curl -s \
    --form-string "token=$api_token" \
    --form-string "user=$user_key" \
    --form-string "title=TermWatch 测试" \
    --form-string "message=🎉 Pushover 配置成功！你应该能在 iPhone 和 Apple Watch 上看到这条通知。" \
    --form-string "priority=1" \
    --form-string "sound=pushover" \
    https://api.pushover.net/1/messages.json)

if echo "$test_response" | grep -q '"status":1'; then
    echo -e "${GREEN}✅ 测试通知发送成功！${NC}"
    echo -e "${GREEN}请检查你的 iPhone 和 Apple Watch 是否收到通知${NC}"
    echo
    echo -e "${YELLOW}如果 Apple Watch 没收到通知，请检查：${NC}"
    echo "1. iPhone 上的 Pushover 应用是否已登录"
    echo "2. Apple Watch 是否已安装 Pushover 应用"
    echo "3. iPhone 设置 > 通知 > Pushover > 允许通知"
    echo "4. Watch 应用 > 通知 > Pushover > 允许通知"
else
    echo -e "${RED}❌ 测试失败${NC}"
    echo "错误响应: $test_response"
    echo
    echo "请检查："
    echo "1. User Key 和 API Token 是否正确"
    echo "2. 网络连接是否正常"
    echo "3. Pushover 账号是否已验证"
    exit 1
fi

echo
echo -e "${GREEN}🎉 Pushover 配置完成！${NC}"
echo
echo "现在你可以使用以下命令发送 Apple Watch 通知："
echo
echo -e "${BLUE}# 基础通知${NC}"
echo "bash ~/.termwatch/src/watch-notifier.sh \"标题\" \"消息内容\""
echo
echo -e "${BLUE}# 快捷通知${NC}"
echo "bash ~/.termwatch/src/watch-notifier.sh success \"任务完成\""
echo "bash ~/.termwatch/src/watch-notifier.sh error \"出现错误\""
echo "bash ~/.termwatch/src/watch-notifier.sh warning \"注意事项\""
echo "bash ~/.termwatch/src/watch-notifier.sh info \"信息提示\""
echo
echo -e "${BLUE}# 替换原有通知函数${NC}"
echo "你也可以修改 ~/.zshrc，将原来的 notify 函数指向新的 watch-notifier:"
echo "alias notify='bash ~/.termwatch/src/watch-notifier.sh'"
echo "alias notify_success='bash ~/.termwatch/src/watch-notifier.sh success'"
echo "alias notify_error='bash ~/.termwatch/src/watch-notifier.sh error'"
echo
echo -e "${YELLOW}重要提示：${NC}"
echo "• 免费版 Pushover 每月有 10,000 条消息限制"
echo "• 如果需要更多消息，可考虑购买 Pushover 应用（一次性购买）"
echo "• 配置已保存，重启终端后仍然有效"