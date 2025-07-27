#!/bin/bash

# Bark 配置脚本
# 用于配置 Bark iOS 推送服务

set -e

echo "=== TermWatch Bark 推送配置 ==="
echo ""

# 检查配置目录
CONFIG_DIR="$HOME/.termwatch/config"
CONFIG_FILE="$CONFIG_DIR/user.conf"

mkdir -p "$CONFIG_DIR"

# 如果配置文件不存在，创建基础配置
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "# TermWatch 用户配置文件" > "$CONFIG_FILE"
    echo "# 创建时间: $(date)" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
fi

echo "📱 Bark 是 iOS 上的免费推送应用，支持发送通知到 iPhone 和 Apple Watch"
echo "🔗 下载地址: https://apps.apple.com/app/bark-custom-notifications/id1403753865"
echo ""

# 检查是否已经安装 Bark
read -p "✅ 您是否已经安装了 Bark 应用？[y/N]: " has_bark
if [[ ! "$has_bark" =~ ^[Yy]$ ]]; then
    echo ""
    echo "📝 请先从 App Store 下载并安装 Bark 应用"
    echo "   下载后请重新运行此脚本"
    exit 0
fi

echo ""
echo "📋 配置 Bark 推送需要以下信息："
echo "   1. 推送 Key（从 Bark 应用中复制）"
echo "   2. 服务器地址（可选，默认使用官方服务器）"
echo "   3. 推送声音（可选）"
echo "   4. 推送分组（可选）"
echo ""

# 获取 Bark Key
echo "🔑 请从 Bark 应用中复制您的推送 Key："
echo ""
echo "📱 Key 获取步骤："
echo "   1. iPhone 打开 Bark 应用"
echo "   2. 进入 [服务器] > [☁️] 进入 \"服务器列表\""
echo "   3. 点击服务后选择 \"复制地址和Key\""
echo "   4. 从 https://api.day.app/{Key}/ 格式的 URL 中提取 Key"
echo ""
echo "   示例: https://api.day.app/a3bG27ELJkkTi3gqMWiRGi/"
echo "   Key 就是: a3bG27ELJkkTi3gqMWiRGi"
echo ""

while true; do
    read -p "请输入您的 Bark Key: " bark_key
    if [[ -n "$bark_key" ]]; then
        # 简单验证 Key 格式
        if [[ ${#bark_key} -ge 8 ]]; then
            break
        else
            echo "❌ Key 长度似乎太短，请重新输入"
        fi
    else
        echo "❌ 请输入有效的 Bark Key"
    fi
done

# 获取服务器地址（可选）
echo ""
read -p "🌐 Bark 服务器地址（默认: https://api.day.app）: " bark_server
if [[ -z "$bark_server" ]]; then
    bark_server="https://api.day.app"
fi

# 获取推送声音（可选）
echo ""
echo "🔔 可用的推送声音："
echo "   default, bell, birdsong, bloom, calypso, chime, choo, descent,"
echo "   electronic, fanfare, glass, gotosleep, healthnotification,"
echo "   horn, ladder, mailsent, minuet, multiwayinvitation, newmail,"
echo "   newsflash, noir, paymentsuccess, shake, sherwoodforest,"
echo "   silence, spell, suspense, telegraph, tiptoes, typewriters,"
echo "   update, victoryreasonablyhigh, victoryunreasonablyhigh"
echo ""
read -p "推送声音（默认: default）: " bark_sound
if [[ -z "$bark_sound" ]]; then
    bark_sound="default"
fi

# 获取推送分组（可选）
echo ""
read -p "📂 推送分组名称（默认: TermWatch）: " bark_group
if [[ -z "$bark_group" ]]; then
    bark_group="TermWatch"
fi

# 获取自定义图标（可选）
echo ""
read -p "🎨 自定义推送图标 URL（可选，留空跳过）: " bark_icon

echo ""
echo "⚙️ 正在保存配置..."

# 移除已有的 Bark 配置
sed -i.bak '/^BARK_/d' "$CONFIG_FILE"

# 添加新的 Bark 配置
cat >> "$CONFIG_FILE" << EOF

# Bark 推送配置
ENABLE_BARK=true
BARK_KEY="$bark_key"
BARK_SERVER="$bark_server"
BARK_SOUND="$bark_sound"
BARK_GROUP="$bark_group"
EOF

# 添加图标配置（如果提供了）
if [[ -n "$bark_icon" ]]; then
    echo "BARK_ICON=\"$bark_icon\"" >> "$CONFIG_FILE"
fi

echo "✅ Bark 配置已保存到: $CONFIG_FILE"
echo ""

# 测试推送
echo "🧪 正在发送测试推送..."
if bash "$(dirname "$(dirname "$0")")/src/termwatch.sh" --test; then
    echo "🎉 测试推送发送成功！请检查您的 iPhone 是否收到通知"
else
    echo "❌ 测试推送发送失败，请检查配置"
fi

echo ""
echo "📖 配置完成！您现在可以使用以下命令发送通知："
echo "   termwatch \"Hello from Bark!\""
echo "   notify_success \"任务完成\""
echo "   notify_error \"任务失败\""
echo ""
echo "🔧 如需修改配置，请编辑: $CONFIG_FILE"
echo "📊 查看状态: termwatch --status"