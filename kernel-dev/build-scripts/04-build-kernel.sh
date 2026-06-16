#!/bin/bash
#
# Multi-OS Linux - 内核编译脚本
#
# 编译Multi-OS Linux内核

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KERNEL_DIR="/workspace/multi-os-compat/sources/linux-6.8.12"
BUILD_DIR="$PROJECT_ROOT/build"

echo "=========================================="
echo "Multi-OS Linux 内核编译脚本"
echo "=========================================="
echo ""

# 检查内核源码目录
if [ ! -d "$KERNEL_DIR" ]; then
    echo "错误: 内核源码目录不存在: $KERNEL_DIR"
    exit 1
fi

# 检查配置文件
if [ ! -f "$KERNEL_DIR/.config" ]; then
    echo "错误: 内核配置文件不存在"
    echo "请先运行: 03-configure-kernel.sh"
    exit 1
fi

echo "内核源码目录: $KERNEL_DIR"
echo "构建目录: $BUILD_DIR"
echo ""

# 获取CPU核心数
NUM_CORES=$(nproc)
echo "使用 $NUM_CORES 个CPU核心进行编译"
echo ""

# 进入内核源码目录
cd "$KERNEL_DIR"

# 清理之前的构建
echo "清理之前的构建..."
make clean

# 编译内核
echo "开始编译内核..."
echo "这可能需要一些时间，请耐心等待..."
echo ""

START_TIME=$(date +%s)

# 编译内核镜像
make -j"$NUM_CORES" bzImage

# 编译模块
make -j"$NUM_CORES" modules

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

echo ""
echo "=========================================="
echo "内核编译成功!"
echo "=========================================="
echo ""
echo "编译时间: $((BUILD_TIME / 60)) 分 $((BUILD_TIME % 60)) 秒"
echo ""
echo "内核镜像: $KERNEL_DIR/arch/x86/boot/bzImage"
echo ""
echo "下一步："
echo "  1. 安装内核: 运行 05-install-kernel.sh"
echo ""
