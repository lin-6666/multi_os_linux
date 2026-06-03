# GitHub 上传指南

## 准备上传

此指南将帮助你将 Multi-OS Linux 项目上传到 GitHub。

### 前置条件

1. GitHub 账户
2. Git 已安装（已确认：`/usr/bin/git`）

## 步骤

### 1. 创建 GitHub 仓库

1. 登录 GitHub (https://github.com)
2. 点击右上角的 "+" 号 → "New repository"
3. 填写仓库信息：
   - Repository name: `multi-os-linux` (或你喜欢的名称)
   - Description: "一个支持运行 Windows、macOS 和 Android 应用的完整 Linux 系统"
   - Public/Private: 选择 Public（推荐）
   - **不要**勾选 "Initialize this repository with a README"
4. 点击 "Create repository"

### 2. 初始化本地 Git 仓库

```bash
# 进入项目目录
cd /workspace/multi-os-compat

# 初始化 Git 仓库
git init

# 配置用户信息（如果还没有配置）
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. 添加文件并提交

```bash
# 添加所有文件到暂存区
git add .

# 查看状态
git status

# 提交文件
git commit -m "Initial commit: Multi-OS Linux v1.0"
```

### 4. 添加远程仓库

从 GitHub 复制你的仓库 URL（应该是这样的格式：`https://github.com/你的用户名/multi-os-linux.git`）

```bash
# 添加远程仓库
git remote add origin https://github.com/你的用户名/multi-os-linux.git

# 验证远程仓库配置
git remote -v
```

### 5. 推送到 GitHub

```bash
# 推送到远程仓库
git push -u origin main

# 如果 main 分支有问题，尝试 master
git push -u origin master
```

## 使用 Personal Access Token (推荐)

GitHub 不再支持密码验证，你需要使用 Personal Access Token：

### 创建 Personal Access Token

1. 访问: https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 勾选以下权限：
   - repo (Full control of private repositories)
4. 点击 "Generate token"
5. **立即复制 token**（之后不会再显示）

### 使用 Token 推送

```bash
# 推送到 GitHub
git push -u origin main

# 当提示输入密码时，粘贴 Personal Access Token
```

## 使用 SSH (可选，更安全)

### 设置 SSH Key

```bash
# 检查是否已有 SSH key
ls -la ~/.ssh/

# 如果没有，创建一个
ssh-keygen -t ed25519 -C "your.email@example.com"

# 添加 SSH key 到 ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 复制公钥
cat ~/.ssh/id_ed25519.pub
```

### 添加 SSH Key 到 GitHub

1. 访问: https://github.com/settings/keys
2. 点击 "New SSH key"
3. 粘贴公钥
4. 点击 "Add SSH key"

### 使用 SSH URL

```bash
# 更新远程仓库 URL
git remote set-url origin git@github.com:你的用户名/multi-os-linux.git

# 推送
git push -u origin main
```

## 项目文件

此项目包含以下关键文件：

```
multi-os-compat/
├── README.md                  # 项目说明 ⭐
├── LICENSE                    # 许可证
├── .gitignore                 # Git 忽略文件
├── build-full-system.sh      # 完整构建脚本
├── create-dist-package.sh     # 发行包生成
├── generate-iso.sh           # ISO 生成脚本
├── quick-build.sh            # 快速构建
├── scripts/                  # 脚本目录
│   ├── setup-wine.sh        # Wine 配置 ⭐
│   ├── launch-steam.sh      # Steam 启动 ⭐
│   └── ...
├── config/                   # 配置文件
│   └── wine/                # Wine 配置 ⭐
├── docs/                     # 文档
├── build/                    # 构建产物
│   └── dist/               # 发行包 ⭐
└── sources/                  # 源码
```

## 发布发行版 (Releases)

### 创建发行版

1. 在 GitHub 仓库页面，点击 "Releases"
2. 点击 "Create a new release"
3. 选择或创建标签：
   - 标签: `v1.0.0`
   - 标题: "Multi-OS Linux v1.0.0"
4. 填写发布说明
5. 上传文件：
   - `build/dist/multi-os-linux-*.tar.gz`
   - `build/dist/COMPLETE_INSTALLATION_GUIDE.md`
6. 点击 "Publish release"

## 上传后

项目上传成功后，可以：

1. **编写 Wiki**: 添加详细的使用文档
2. **设置 Issues**: 让用户报告问题
3. **添加标签**: 标记项目特性
4. **创建 Pull Requests**: 接受社区贡献
5. **设置 CI/CD**: 自动化构建和测试

## 故障排除

### Git 推送失败

```bash
# 查看状态
git status
git log

# 强制推送（谨慎使用）
git push -f origin main
```

### 权限被拒绝

确保使用正确的认证方式（Personal Access Token 或 SSH）

### 大文件问题

GitHub 对单个文件限制为 100MB。如果你的系统包很大：
- 使用 Git LFS (Large File Storage)
- 或者只上传源码，提供构建说明

## 其他有用的命令

```bash
# 查看提交历史
git log

# 查看修改
git diff

# 创建分支
git branch feature-name
git checkout feature-name

# 合并分支
git checkout main
git merge feature-name
```

---

祝你上传顺利！如有问题请查看 GitHub 文档或提交 Issue。
