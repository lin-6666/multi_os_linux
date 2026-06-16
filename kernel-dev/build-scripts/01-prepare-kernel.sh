#!/bin/bash
# Multi-OS Linux - 01: 准备内核源码
# 本脚本用于准备 Linux 6.8.12 内核源码

set -e

PROJECT_ROOT="/workspace/multi-os-compat"
SOURCE_DIR="$PROJECT_ROOT/sources"
KERNEL_TAR="$SOURCE_DIR/linux-6.8.12.tar.xz"
BUILD_DIR="$PROJECT_ROOT/kernel-dev/build"

echo "========================================="
echo " Multi-OS Linux 内核准备"
echo "========================================="
echo ""

# 检查源码是否存在
if [ ! -f "$KERNEL_TAR" ]; then
    echo "错误: 找不到内核源码 $KERNEL_TAR"
    echo "请下载 Linux 6.8.12 内核到 $SOURCE_DIR"
    exit 1
fi

# 解压内核
echo "正在解压内核源码..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ -d "linux-6.8.12" ]; then
    echo "内核源码已解压，删除旧目录..."
    rm -rf "linux-6.8.12"
fi

tar -xf "$KERNEL_TAR"

echo ""
echo "✓ 内核源码已解压到 $BUILD_DIR/linux-6.8.12"
echo ""
echo "下一步: 运行 02-apply-patches.sh"
echo ""
