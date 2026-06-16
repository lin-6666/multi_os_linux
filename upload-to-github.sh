#!/bin/bash
#
# Multi-OS Linux - GitHub 上传脚本
#
# 自动初始化仓库、提交文件、推送到 GitHub

set -e

# 配置
REPO_NAME="multi-os-linux"
DEFAULT_BRANCH="main"

echo "=========================================="
echo "Multi-OS Linux - GitHub 上传脚本"
echo "=========================================="
echo ""

# 检查是否在正确的目录
if [ ! -f "README.md" ]; then
    echo "错误：请在项目根目录运行此脚本"
    echo "当前目录: $(pwd)"
    exit 1
fi

# 检查 Git 是否已安装
if ! command -v git &> /dev/null; then
    echo "错误：Git 未安装"
    exit 1
fi

# 检查是否已初始化 Git
if [ ! -d ".git" ]; then
    echo "初始化 Git 仓库..."
    git init
    git branch -M $DEFAULT_BRANCH
else
    echo "Git 仓库已存在"
fi

# 配置 Git 用户（如果未配置）
if [ -z "$(git config --get user.name)" ]; then
    echo "请配置 Git 用户信息："
    read -p "用户名: " GIT_USERNAME
    read -p "邮箱: " GIT_EMAIL
    
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
fi

# 添加文件到暂存区
echo ""
echo "添加文件到暂存区..."
git add .

# 检查是否有修改
if git diff --staged --quiet; then
    echo "没有更改需要提交"
else
    # 创建提交
    echo ""
    echo "创建提交..."
    read -p "提交信息 [Initial commit]: " COMMIT_MSG
    COMMIT_MSG=${COMMIT_MSG:-"Initial commit: Multi-OS Linux v1.0"}
    
    git commit -m "$COMMIT_MSG"
fi

# 检查是否已有远程仓库
if git remote | grep -q "origin"; then
    echo ""
    echo "远程仓库已配置"
    CURRENT_REMOTE=$(git remote get-url origin)
    echo "当前远程: $CURRENT_REMOTE"
else
    # 询问用户信息
    echo ""
    echo "请提供 GitHub 仓库信息："
    read -p "GitHub 用户名: " GITHUB_USERNAME
    
    # 询问是否已在 GitHub 创建仓库
    echo ""
    echo "请确保已在 GitHub 创建仓库："
    echo "https://github.com/new?name=$REPO_NAME"
    echo ""
    read -p "是否已在 GitHub 创建仓库？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "请先在 GitHub 创建仓库后再继续"
        exit 1
    fi
    
    # 添加远程仓库
    echo ""
    echo "添加远程仓库..."
    git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
fi

# 推送到 GitHub
echo ""
echo "推送到 GitHub..."
echo "请确保您有访问权限（使用 Personal Access Token）"
echo ""

# 尝试推送
if git push -u origin $DEFAULT_BRANCH; then
    echo ""
    echo "=========================================="
    echo "🎉 成功推送到 GitHub！"
    echo "=========================================="
    echo ""
    echo "仓库地址: $(git remote get-url origin)"
    echo ""
    echo "下一步："
    echo "1. 访问仓库查看代码"
    echo "2. 启用 GitHub Actions（如果还没有）"
    echo "3. 创建第一个标签进行构建和发布"
    echo ""
else
    echo ""
    echo "推送失败，请检查："
    echo "1. 您是否有仓库访问权限"
    echo "2. Personal Access Token 是否正确"
    echo "3. 网络连接是否正常"
    echo ""
    echo "提示：可以使用 Personal Access Token 作为密码"
    echo "创建 Token：https://github.com/settings/tokens"
    echo ""
    exit 1
fi

