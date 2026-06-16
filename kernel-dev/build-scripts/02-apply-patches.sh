#!/bin/bash
#
# Multi-OS Linux - 内核补丁应用脚本
#
# 应用所有Multi-OS Linux内核补丁

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KERNEL_DIR="/workspace/multi-os-compat/sources/linux-6.8.12"
PATCH_DIR="$PROJECT_ROOT/patches"

echo "=========================================="
echo "Multi-OS Linux 内核补丁应用脚本"
echo "=========================================="
echo ""

# 检查内核源码目录
if [ ! -d "$KERNEL_DIR" ]; then
    echo "错误: 内核源码目录不存在: $KERNEL_DIR"
    exit 1
fi

# 检查补丁目录
if [ ! -d "$PATCH_DIR" ]; then
    echo "错误: 补丁目录不存在: $PATCH_DIR"
    exit 1
fi

echo "内核源码目录: $KERNEL_DIR"
echo "补丁目录: $PATCH_DIR"
echo ""

# 进入内核源码目录
cd "$KERNEL_DIR"

# 检查是否已经应用过补丁
if [ -f ".multi-os-patches-applied" ]; then
    echo "警告: 补丁已经应用过，跳过应用"
    echo "如需重新应用，请先运行: git reset --hard HEAD"
    exit 0
fi

# 应用所有补丁
echo "开始应用补丁..."
echo ""

for patch_file in "$PATCH_DIR"/*.patch; do
    if [ -f "$patch_file" ]; then
        echo "应用补丁: $(basename "$patch_file")"
        if patch -p1 < "$patch_file"; then
            echo "  ✓ 补丁应用成功"
        else
            echo "  ✗ 补丁应用失败: $patch_file"
            exit 1
        fi
    fi
done

echo ""
echo "=========================================="
echo "所有补丁应用成功!"
echo "=========================================="

# 创建标记文件
touch .multi-os-patches-applied

echo ""
echo "下一步："
echo "  1. 配置内核: cd $KERNEL_DIR && make menuconfig"
echo "  2. 或使用预配置: 运行 03-configure-kernel.sh"
echo ""
