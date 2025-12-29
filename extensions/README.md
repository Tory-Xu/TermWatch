# TermWatch 扩展

这个目录包含 TermWatch 的扩展模块，用于扩展 TermWatch 的核心功能。

## 可用扩展

### 🔔 Auto-Notify 扩展
**路径**: `auto-notify/`
**功能**: 智能命令执行监控和自动通知

#### 主要特性
- 🕐 智能时间监控（超过30秒的命令自动通知）
- ✅ 自动判断命令成功/失败状态
- ⚡ 强制通知模式（`!command`）
- 🎯 重要命令自动识别
- 🔍 智能过滤无关命令
- 🏗️ 完全集成 TermWatch 基础设施

#### 快速安装
```bash
# 通过主安装脚本
./install.sh
# 选择 "4️⃣ 安装 Auto-Notify 扩展"

# 或独立安装
bash extensions/auto-notify/scripts/install.sh
```

#### 基础用法
```bash
# 普通命令（超过30秒才通知）
npm install
docker build .

# 强制通知（无论时间长短）
!git status
!echo "完成了!"

# 管理命令
termwatch_status     # 查看状态
termwatch_toggle     # 切换开关
```

详细文档: [Auto-Notify README](auto-notify/README.md)

## 扩展开发指南

### 目录结构
每个扩展应该遵循以下目录结构：

```
extensions/
└── your-extension/
    ├── README.md           # 扩展说明文档
    ├── src/                # 扩展源码
    │   ├── main.sh        # 主要功能脚本
    │   └── utils.sh       # 工具函数
    ├── config/            # 扩展配置
    │   └── config.conf    # 默认配置文件
    ├── scripts/           # 扩展脚本
    │   ├── install.sh     # 安装脚本
    │   ├── uninstall.sh   # 卸载脚本
    │   └── test.sh        # 测试脚本
    └── docs/              # 文档目录
        ├── usage.md       # 使用指南
        └── config.md      # 配置说明
```

### 开发规范

#### 1. 命名规范
- 扩展目录使用小写字母和连字符：`auto-notify`, `slack-integration`
- 脚本文件使用下划线：`auto_notify.sh`, `slack_helper.sh`
- 配置文件使用下划线：`auto_notify.conf`

#### 2. 集成要求
- 必须与 TermWatch 基础功能兼容
- 应该继承 TermWatch 的推送配置
- 配置文件应该放在 `~/.termwatch/config/` 目录
- 日志应该写入 TermWatch 统一日志系统

#### 3. 安装脚本要求
- 提供独立的安装和卸载脚本
- 支持集成到主安装脚本的配置向导
- 提供完整的备份和恢复机制
- 安装前检查依赖和环境

#### 4. 文档要求
- README.md：扩展概述和快速开始
- docs/usage.md：详细使用指南
- docs/configuration.md：配置选项说明

### 集成到主安装脚本

如果你开发了新的扩展，可以按以下步骤集成到主安装脚本：

1. **在主安装脚本中添加选项**
   编辑 `install.sh`，在 `show_menu_options()` 函数中添加新选项。

2. **添加安装逻辑**
   在相应的 case 分支中添加扩展安装逻辑。

3. **更新文档**
   在主 README.md 中添加扩展介绍。

4. **测试集成**
   确保扩展可以通过主安装脚本正确安装和卸载。

### 示例扩展模板

```bash
#!/bin/bash
# extensions/example/src/example.sh

# 扩展配置
EXTENSION_NAME="Example Extension"
EXTENSION_VERSION="1.0.0"
CONFIG_FILE="$HOME/.termwatch/config/example.conf"

# 加载配置
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# 主要功能
main_function() {
    load_config
    # 扩展的主要逻辑
    echo "Hello from $EXTENSION_NAME v$EXTENSION_VERSION"
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_function "$@"
fi
```

### 最佳实践

1. **保持简单**: 扩展应该专注于单一功能
2. **向后兼容**: 确保扩展不会破坏现有功能
3. **完善文档**: 提供清晰的安装和使用说明
4. **测试充分**: 提供测试脚本验证功能
5. **用户友好**: 提供易用的配置和管理界面

## 贡献

欢迎贡献新的扩展！请按照以下流程：

1. Fork TermWatch 仓库
2. 在 `extensions/` 目录下创建你的扩展
3. 遵循上述开发规范
4. 充分测试你的扩展
5. 提交 Pull Request

## 支持

如果在使用或开发扩展时遇到问题：
- 查看 [故障排除指南](../docs/troubleshooting.md)
- 提交 Issue 到 GitHub 仓库
- 联系项目维护者

---

**扩展让 TermWatch 更强大！** 🚀