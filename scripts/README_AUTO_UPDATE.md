# 自动更新脚本

## 📋 快速参考

| 命令 | 说明 |
|------|------|
| `./auto-update.sh` | 检查并安装更新 |
| `./auto-update.sh --check` | 仅检查更新 |
| `./auto-update.sh --backup` | 仅创建备份 |
| `./auto-update.sh --rollback` | 回滚到上一版本 |
| `./auto-update.sh --help` | 显示帮助信息 |

## 🔧 配置

编辑 `config/user-config.yml` 自定义更新行为（不会被更新覆盖）。

## 📂 备份位置

默认备份保存在 `~/.multi-os-backup/`

## ⚙️ 工作原理

1. **检查更新**: 从 GitHub 获取最新版本
2. **备份**: 自动备份用户配置和自定义文件
3. **拉取**: 使用 Git 下载最新代码
4. **保护**: 恢复用户配置文件
5. **验证**: 确认更新成功

## 🔒 安全特性

- Token 不存储在脚本中
- 用户文件白名单保护
- 自动备份所有重要数据
- 支持完整回滚

详细文档请查看: `../docs/AUTO_UPDATE_GUIDE.md`
