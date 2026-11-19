# trae-manager Context

## 项目定位

TRAE Manager 是用于管理 TRAE IDE 多账号切换和聊天记录备份的工具，支持 macOS 菜单栏 App 和 Windows PowerShell 脚本。

核心机制是把 TRAE 数据目录替换为指向当前 profile 的符号链接，从而隔离登录态和聊天记录。

## 关键结构

- `scripts/`: CLI 脚本、图标和 Windows 脚本。
- `swift/TraeManager/`: Swift 菜单栏应用。
- `release/`: 发布产物。
- `README.md`: 使用说明。
- `DEVELOPMENT_PLAN.md`: 技术研究和开发计划。

## 工作规则

- 切换 profile 前必须确认 TRAE 进程控制和数据目录路径，避免误删用户聊天记录。
- 修改 symlink、备份、删除 profile 逻辑时，优先做 dry run 或测试目录验证。
- Windows 和 macOS 行为尽量保持一致。
- 不要提交真实用户 profile 数据、Cookies、Local Storage 或 SQLite 聊天数据库。

## 常用命令

```bash
cd swift/TraeManager
./build.sh
open build/TraeManager.app
```

## 验证要求

- Swift 修改后运行 `swift build` 或项目 `build.sh`。
- CLI 脚本修改后用测试 profile 目录验证 `save`、`create`、`switch`、`list`、`delete`。
- 删除或备份逻辑需要额外谨慎验证。
