# TRAE Manager 开发计划

## 📋 项目概述

TRAE Manager 是一个用于管理 TRAE IDE 多账号切换和聊天记录备份的工具，借鉴了 Antigravity Manager 的设计理念。

### 🎯 核心目标
1. **多账号切换** - 在不同 TRAE 账号间无缝切换，充分利用各账号的 Token 限额
2. **聊天记录保留** - 每个账号的聊天历史独立保存，切换时不丢失
3. **一键操作** - 简洁的菜单栏应用，一键切换

---

## 🔍 技术研究

### TRAE 数据存储结构 (macOS)
```
~/Library/Application Support/Trae/
├── Cookies                    # 登录凭证
├── Cookies-journal
├── Local Storage/             # 本地存储（包含登录状态）
├── Session Storage/           # 会话数据
├── User/
│   ├── globalStorage/
│   │   ├── state.vscdb        # SQLite 数据库（含聊天记录）
│   │   ├── state.vscdb.backup
│   │   └── storage.json
│   └── workspaceStorage/      # 工作区特定数据
├── aha/                       # AI 相关配置
├── ahanet/
├── Preferences                # 偏好设置
└── ...
```

### 关键发现
1. **登录凭证**: 存储在 `Cookies` 和 `Local Storage/` 中
2. **聊天记录**: 存储在 `User/globalStorage/state.vscdb` (SQLite 数据库)
3. **账号关联**: 通过 SQLite 中的 `ai-chat:sessionRelation:*` 键存储

### 借鉴 Antigravity Manager 的方案
| Antigravity Manager 功能 | TRAE Manager 实现方案 |
|-------------------------|---------------------|
| Profile 切换 | 软链接映射整个数据目录 |
| 账号备份 | 复制数据目录到 Profile 仓库 |
| 菜单栏操作 | 原生 Swift 或 Electron 实现 |
| 进程控制 | 检测并关闭 TRAE 进程后切换 |

---

## 📐 架构设计

### 方案选择: 原生 Swift 菜单栏应用
**选择理由**:
- 轻量级，无需 Electron 依赖
- macOS 原生体验
- 参考 [nhonn/antigravity-switcher](https://github.com/nhonn/antigravity-switcher) 的成功实现

### 数据目录结构
```
~/.trae-manager/
├── profiles/                  # Profile 仓库
│   ├── account_1/            # 账号1的完整数据
│   ├── account_2/            # 账号2的完整数据
│   └── default/              # 默认/备份数据
├── config.json               # 配置文件
└── current_profile           # 记录当前活跃 Profile
```

### 软链接映射
```
~/Library/Application Support/Trae  ->  ~/.trae-manager/profiles/<active_profile>
```

---

## 🚀 开发阶段

### Phase 1: 核心 CLI 工具 (MVP) ✅
- [x] 创建项目结构
- [x] 实现 Profile 管理（create, list, delete）
- [x] 实现账号切换（switch）
- [x] 实现当前会话备份（save）
- [x] 进程检测与控制
- [x] 推送到 GitHub

### Phase 2: 菜单栏应用 ✅
- [x] Swift 菜单栏 UI
- [x] Profile 列表展示
- [x] 一键切换功能
- [x] 状态指示器
- [x] 保存/创建 Profile 对话框

### Phase 3: 高级功能 ✅
- [x] Profile 重命名
- [x] 聊天记录计数（SQlite）
- [ ] 自动检测 Token 用尽提示切换（需进一步研究 API 响应）
- [x] 批量备份
- [x] 开机自启动

---

## 📁 项目文件结构

```
trae-manager/
├── DEVELOPMENT_PLAN.md       # 本文档
├── README.md                 # 使用说明
├── scripts/
│   └── trae-mgr              # CLI 工具 (Bash)
├── swift/                    # Swift 菜单栏应用
│   └── TraeManager/
│       ├── Package.swift     # Swift Package 配置
│       ├── build.sh          # 构建脚本
│       ├── Sources/
│       │   ├── TraeManagerApp.swift   # 主应用和 UI
│       │   └── ProfileManager.swift   # Profile 管理逻辑
│       └── build/
│           └── TraeManager.app        # 编译产物
└── test/                     # 测试脚本
```

---

## 📝 CLI 命令设计

```bash
# 列出所有 Profile
trae-mgr list

# 创建新 Profile
trae-mgr create <profile_name>

# 保存当前会话为 Profile
trae-mgr save <profile_name>

# 切换到指定 Profile
trae-mgr switch <profile_name>

# 删除 Profile
trae-mgr delete <profile_name>

# 显示当前 Profile
trae-mgr current

# 显示帮助
trae-mgr help
```

---

## ⚠️ 注意事项

1. **切换时必须关闭 TRAE** - 否则文件锁定会导致操作失败
2. **首次使用前备份** - 防止数据丢失
3. **软链接权限** - 确保有足够权限创建软链接
4. **macOS 版本** - 建议 macOS 13.0+

---

## 📅 开发日志

### 2026-02-03
- 项目初始化
- 完成技术调研
- 创建开发计划文档
- ✅ Phase 1: 完成 CLI MVP
- ✅ Phase 2: 完成 Swift 菜单栏应用
  - 实现 ProfileManager 核心逻辑
  - 实现菜单栏 UI（Profile 列表、切换、保存、创建）
  - 构建成功 TraeManager.app

---

- ✅ Phase 3: 高级功能
  - 实现 Profile 重命名、复制、删除
  - 实现开机自启动
  - 实现聊天会话计数（SQlite）
  - 实现全量备份

---

*Last Updated: 2026-02-03*
