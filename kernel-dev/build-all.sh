#!/bin/bash
#
# Multi-OS Linux - 一键内核构建脚本
#
# 自动执行所有内核构建步骤

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_SCRIPTS_DIR="$SCRIPT_DIR/build-scripts"

echo "=========================================="
echo "Multi-OS Linux 一键内核构建脚本"
echo "=========================================="
echo ""
echo "此脚本将执行以下步骤："
echo "1. 准备内核源码"
echo "2. 应用内核补丁"
echo "3. 配置内核"
echo "4. 编译内核"
echo "5. 安装内核"
echo ""
echo "按 Ctrl+C 可以随时停止"
echo ""
read -p "是否继续? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "开始构建..."
echo ""

# 步骤 1: 准备内核源码
echo "=========================================="
echo "步骤 1/5: 准备内核源码"
echo "=========================================="
cd "$BUILD_SCRIPTS_DIR"
./01-prepare-kernel.sh
echo ""

# 步骤 2: 应用补丁
echo "=========================================="
echo "步骤 2/5: 应用内核补丁"
echo "=========================================="
./02-apply-patches.sh
echo ""

# 步骤 3: 配置内核
echo "=========================================="
echo "步骤 3/5: 配置内核"
echo "=========================================="
./03-configure-kernel.sh
echo ""

# 步骤 4: 编译内核
echo "=========================================="
echo "步骤 4/5: 编译内核"
echo "=========================================="
./04-build-kernel.sh
echo ""

# 步骤 5: 安装内核
echo "=========================================="
echo "步骤 5/5: 安装内核"
echo "=========================================="
./05-install-kernel.sh
echo ""

echo "=========================================="
echo "构建成功完成!"
echo "=========================================="
echo ""
echo "内核已安装到: $SCRIPT_DIR/../build/kernel/"
echo ""
echo "下一步选项："
echo "1. 安装到系统 (需要 root): sudo $BUILD_SCRIPTS_DIR/06-install-to-system.sh"
echo "2. 创建 ISO: $BUILD_SCRIPTS_DIR/07-create-iso.sh"
echo "3. 阅读文档: $SCRIPT_DIR/docs/"
echo "4. 运行测试: $SCRIPT_DIR/test-scripts/"
echo ""
