# Multi-OS Linux - 自动更新系统

## 概述

Multi-OS Linux 提供完整的自动更新系统，确保您始终使用最新版本，同时保护您的个人配置和自定义文件不被覆盖。

---

## 🚀 快速开始

### 检查更新

```bash
cd /workspace/multi-os-compat
./scripts/auto-update.sh --check
```

### 安装更新

```bash
./scripts/auto-update.sh
```

### 仅创建备份

```bash
./scripts/auto-update.sh --backup
```

### 回滚到上一版本

```bash
./scripts/auto-update.sh --rollback
```

---

## 📋 功能特性

### ✅ 智能更新

- **自动检查更新**: 每次运行自动检查 GitHub 最新版本
- **增量更新**: 只下载变更的文件，节省带宽
- **版本管理**: 自动记录当前版本号

### 🛡️ 配置保护

#### 用户文件白名单

以下文件/目录**永远不会被覆盖**：

| 路径 | 说明 |
|------|------|
| `config/user-config.yml` | 用户自定义配置 |
| `scripts/custom/*` | 用户自定义脚本 |
| `.multi-os-local` | 本地配置文件 |
| `~/.multi-os/` | 主用户数据目录 |

#### 自动备份

更新前自动备份：
- 用户配置目录 `~/.multi-os/`
- 自定义脚本
- 本地配置文件
- Git 提交历史

### 🔄 版本控制

- **语义化版本**: 使用 `v主版本.次版本.补丁` 格式
- **Git Tags**: 每个正式版本都有对应的 Git tag
- **完整历史**: 所有版本都可以通过 Git 回溯

---

## 📖 使用指南

### 首次使用

#### 1. 确保已连接到 GitHub

```bash
cd /workspace/multi-os-compat
git remote -v
# 应该显示: origin https://github.com/lin-6666/multi_os_linux.git
```

如果没有设置远程：

```bash
git remote add origin https://github.com/lin-6666/multi_os_linux.git
```

#### 2. 检查更新

```bash
./scripts/auto-update.sh --check
```

输出示例：

```
[INFO] 正在检查更新...
[INFO] 当前版本: v1.0.0
[INFO] 正在连接 GitHub...
[INFO] 最新版本: v1.0.1
[WARNING] 发现新版本: v1.0.1
```

#### 3. 安装更新

```bash
./scripts/auto-update.sh
```

更新过程：

```
[INFO] 正在检查更新...
[WARNING] 发现新版本: v1.0.1
[INFO] 正在备份重要文件...
[SUCCESS] 备份完成！备份保存在: ~/.multi-os-backup
[INFO] 检查并保护用户文件...
[INFO] 正在拉取最新代码...
[INFO] 切换到版本: v1.0.1
[INFO] 恢复用户配置...
[SUCCESS] 更新完成！
```

---

### 高级用法

#### 自动化更新（定时任务）

创建 cron 任务每天检查更新：

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天凌晨 3 点检查更新）
0 3 * * * cd /workspace/multi-os-compat && ./scripts/auto-update.sh --check >> ~/.multi-os-update.log 2>&1
```

#### CI/CD 集成

在 GitHub Actions 中集成更新检查：

```yaml
# .github/workflows/check-updates.yml
name: Check for Updates

on:
  schedule:
    - cron: '0 8 * * *'  # 每天早上 8 点检查
  workflow_dispatch:         # 也支持手动触发

jobs:
  check-updates:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        
      - name: Check for updates
        run: |
          ./scripts/auto-update.sh --check
```

#### 仅更新特定模块

如果您只想更新特定部分：

```bash
# 只更新内核相关文件
git pull origin master -- kernel-dev/ scripts/kernel-*.sh

# 只更新脚本
git pull origin master -- scripts/*.sh

# 只更新配置
git pull origin master -- config/
```

---

### 故障排除

#### 问题：更新失败

**症状**: 脚本报告 "无法连接到 GitHub"

**解决方案**:

1. 检查网络连接：
   ```bash
   ping github.com
   ```

2. 检查 Git 配置：
   ```bash
   git remote -v
   git fetch origin
   ```

3. 手动更新：
   ```bash
   git fetch --all
   git pull origin master
   ```

#### 问题：版本不一致

**症状**: 脚本显示的版本与实际不符

**解决方案**:

```bash
# 查看当前版本
cat .version

# 手动设置版本
echo "1.0.0" > .version

# 或从 Git tag 同步
git describe --tags > .version
```

#### 问题：备份恢复失败

**症状**: 更新后自定义配置丢失

**解决方案**:

1. 查看备份：
   ```bash
   ls -la ~/.multi-os-backup/
   ```

2. 手动恢复：
   ```bash
   cd ~/.multi-os-backup
   tar -xzf user_config_20260101_120000.tar.gz -C ~/
   ```

3. 联系支持：如果无法恢复，提交 Issue

---

## 🔒 安全说明

### Token 处理

更新脚本**不存储**任何 GitHub Token：
- 使用 HTTPS 推送，不使用 SSH
- Token 只在首次设置远程仓库时使用
- 后续更新使用 Git 的凭据缓存

### 文件权限

- 备份文件权限：`600`（仅所有者可读写）
- 配置目录权限：`700`（仅所有者可访问）
- 脚本执行权限：`755`（可执行但不可修改）

### 网络安全

- 只从官方 GitHub 仓库下载更新
- 使用 HTTPS 加密传输
- 验证 Git commit 签名（如果可用）

---

## 📊 更新日志

### v1.0.1 (2026-01-16)

**新增功能**:
- 自动更新系统
- 配置保护机制
- 增量备份
- 版本追踪

**改进**:
- 优化更新检测速度
- 改进错误处理
- 添加详细的日志输出

---

## 🤝 贡献

如果您想改进更新系统，请：

1. Fork 项目
2. 修改 `scripts/auto-update.sh`
3. 提交 Pull Request
4. 等待 AI 代码审查

---

## 📞 支持

- **问题反馈**: 提交 [GitHub Issue](https://github.com/lin-6666/multi_os_linux/issues)
- **文档**: 查看 [官方文档](docs/)
- **讨论**: [GitHub Discussions](https://github.com/lin-6666/multi_os_linux/discussions)

---

*最后更新: 2026年6月16日*
