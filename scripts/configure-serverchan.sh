#!/bin/bash

# Server酱 配置脚本

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="$HOME/.termwatch/config/user.conf"

echo -e "${BLUE}========================================"
echo "       Server酱 配置向导"
echo -e "========================================${NC}"
echo
echo -e "${GREEN}Server酱是免费的微信推送服务，支持以下特性：${NC}"
echo "• ✅ 完全免费（每日1000条消息额度）"
echo "• 📱 直接推送到微信"
echo "• ⌚ 支持 Apple Watch（通过微信）"
echo "• 🇨🇳 国内网络稳定"
echo "• 🚀 响应速度快"
echo

# 检查配置文件
if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    touch "$CONFIG_FILE"
fi

echo "请按照以下步骤获取 Server酱 配置信息："
echo
echo -e "${YELLOW}步骤 1: 注册 Server酱${NC}"
echo "1. 用微信扫码登录 https://sct.ftqq.com/"
echo "2. 完成微信授权"
echo
echo -e "${YELLOW}步骤 2: 获取 SendKey${NC}"
echo "1. 登录后在首页找到 'SendKey'"
echo "2. SendKey 格式：SCT + 31位字符（总共34位）"
echo "3. 示例：SCT290297To70a7SHumMCkIPfefmQCvFhB"
echo
echo -e "${YELLOW}步骤 3: 配置推送${NC}"
echo "1. 在微信中关注 'Server酱' 公众号"
echo "2. 确保能收到测试消息"
echo

# 输入 SendKey
echo -e "${GREEN}请输入你的 Server酱 SendKey:${NC}"
read -p "SendKey (SCT开头): " sendkey

# 验证 SendKey 格式
if [[ ! $sendkey =~ ^SCT[a-zA-Z0-9]{31}$ ]]; then
    echo -e "${RED}错误: SendKey 格式不正确${NC}"
    echo "正确格式: SCT + 31位字符（总共34位）"
    echo "示例: SCT290297To70a7SHumMCkIPfefmQCvFhB"
    exit 1
fi

# 备份现有配置
if [[ -f "$CONFIG_FILE" && -s "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}已备份现有配置${NC}"
fi

# 检查是否已有 Server酱 配置
if grep -q "SERVERCHAN_" "$CONFIG_FILE"; then
    echo -e "${YELLOW}检测到现有 Server酱 配置，正在更新...${NC}"
    # 删除现有的 Server酱 配置行
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' '/SERVERCHAN_/d' "$CONFIG_FILE"
    else
        sed -i '/SERVERCHAN_/d' "$CONFIG_FILE"
    fi
fi

# 添加 Server酱 配置
echo "" >> "$CONFIG_FILE"
echo "# Server酱 推送服务配置" >> "$CONFIG_FILE"
echo "# 免费微信推送服务，支持 Apple Watch" >> "$CONFIG_FILE"
echo "SERVERCHAN_SENDKEY=\"$sendkey\"" >> "$CONFIG_FILE"
echo "" >> "$CONFIG_FILE"

echo -e "${GREEN}✅ Server酱 配置已保存到: $CONFIG_FILE${NC}"
echo

# 测试配置
echo -e "${BLUE}正在测试 Server酱 连接...${NC}"

# 发送测试通知
test_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"title":"TermWatch 测试","desp":"🎉 Server酱配置成功！\n\n如果你在微信中看到这条消息，说明配置正确。\n\n- ✅ macOS 通知\n- ✅ 微信推送\n- ✅ Apple Watch 同步\n\n现在你可以愉快地使用 TermWatch 了！"}' \
    "https://sctapi.ftqq.com/$sendkey.send")

echo "测试响应: $test_response"

if echo "$test_response" | grep -q '"code":0'; then
    echo -e "${GREEN}✅ 测试通知发送成功！${NC}"
    echo -e "${GREEN}请检查你的微信是否收到通知${NC}"
    echo
    echo -e "${YELLOW}如果微信收到通知但 Apple Watch 没有，请检查：${NC}"
    echo "1. Apple Watch 与 iPhone 蓝牙连接正常"
    echo "2. iPhone 微信通知设置允许显示在 Apple Watch"
    echo "3. Apple Watch 微信 App 通知权限已开启"
    echo
    echo -e "${GREEN}✅ 配置成功！现在可以使用以下命令测试：${NC}"
    echo
    echo -e "${BLUE}# 基础测试${NC}"
    echo "bash src/termwatch.sh --test"
    echo
    echo -e "${BLUE}# 各种类型通知${NC}"
    echo "bash src/termwatch.sh success \"任务完成\""
    echo "bash src/termwatch.sh error \"出现错误\""
    echo "bash src/termwatch.sh warning \"注意事项\""
    echo "bash src/termwatch.sh info \"信息提示\""
else
    echo -e "${RED}❌ 测试失败${NC}"
    echo "错误响应: $test_response"
    echo
    echo "请检查："
    echo "1. SendKey 是否正确"
    echo "2. 网络连接是否正常"
    echo "3. 是否已关注 Server酱 公众号"
    echo "4. 微信是否允许接收该公众号消息"
    exit 1
fi

echo
echo -e "${GREEN}🎉 Server酱 配置完成！${NC}"
echo
echo -e "${YELLOW}使用提示：${NC}"
echo "• 免费版每日1000条消息，通常足够个人使用"
echo "• 消息会同时发送到微信和 Apple Watch"
echo "• 如需更多消息额度，可考虑购买 Server酱 Pro"
echo "• 配置已保存，重启终端后仍然有效"
echo
echo -e "${BLUE}更多信息：${NC}"
echo "• Server酱官网：https://sct.ftqq.com/"
echo "• TermWatch文档：README.md"
echo "• 故障排除：docs/troubleshooting.md"