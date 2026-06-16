#!/bin/bash
#
# Multi-OS Linux - 内核安装脚本
#
# 安装Multi-OS Linux内核

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KERNEL_DIR="/workspace/multi-os-compat/sources/linux-6.8.12"
INSTALL_DIR="$PROJECT_ROOT/build/kernel"

echo "=========================================="
echo "Multi-OS Linux 内核安装脚本"
echo "=========================================="
echo ""

# 检查内核源码目录
if [ ! -d "$KERNEL_DIR" ]; then
    echo "错误: 内核源码目录不存在: $KERNEL_DIR"
    exit 1
fi

# 检查编译结果
if [ ! -f "$KERNEL_DIR/arch/x86/boot/bzImage" ]; then
    echo "错误: 内核镜像不存在"
    echo "请先运行: 04-build-kernel.sh"
    exit 1
fi

echo "内核源码目录: $KERNEL_DIR"
echo "安装目录: $INSTALL_DIR"
echo ""

# 创建安装目录
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/boot"
mkdir -p "$INSTALL_DIR/modules"
mkdir -p "$INSTALL_DIR/headers"

# 进入内核源码目录
cd "$KERNEL_DIR"

# 获取内核版本
KERNEL_VERSION=$(make kernelversion)
echo "内核版本: $KERNEL_VERSION"
echo ""

# 安装内核镜像
echo "安装内核镜像..."
cp "$KERNEL_DIR/arch/x86/boot/bzImage" "$INSTALL_DIR/boot/vmlinuz-$KERNEL_VERSION-multi-os"

# 安装System.map
echo "安装System.map..."
cp "$KERNEL_DIR/System.map" "$INSTALL_DIR/boot/System.map-$KERNEL_VERSION-multi-os"

# 安装配置文件
echo "安装配置文件..."
cp "$KERNEL_DIR/.config" "$INSTALL_DIR/boot/config-$KERNEL_VERSION-multi-os"

# 安装模块
echo "安装内核模块..."
make modules_install INSTALL_MOD_PATH="$INSTALL_DIR"

# 安装头文件
echo "安装内核头文件..."
make headers_install INSTALL_HDR_PATH="$INSTALL_DIR/headers"

echo ""
echo "=========================================="
echo "内核安装成功!"
echo "=========================================="
echo ""
echo "安装位置:"
echo "  内核镜像: $INSTALL_DIR/boot/vmlinuz-$KERNEL_VERSION-multi-os"
echo "  模块: $INSTALL_DIR/lib/modules/"
echo "  头文件: $INSTALL_DIR/headers/"
echo ""
echo "下一步："
echo "  1. 将内核安装到系统: 运行 06-install-to-system.sh (需要root权限)"
echo "  2. 或创建ISO: 运行 07-create-iso.sh"
echo ""
