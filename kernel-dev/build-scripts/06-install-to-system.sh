#!/bin/bash
#
# Multi-OS Linux - 系统内核安装脚本
#
# 将Multi-OS Linux内核安装到系统

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KERNEL_DIR="/workspace/multi-os-compat/sources/linux-6.8.12"
INSTALL_DIR="$PROJECT_ROOT/build/kernel"

echo "=========================================="
echo "Multi-OS Linux 系统内核安装脚本"
echo "=========================================="
echo ""

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "错误: 请使用root权限运行此脚本"
    echo "使用: sudo $0"
    exit 1
fi

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
echo ""

# 进入内核源码目录
cd "$KERNEL_DIR"

# 获取内核版本
KERNEL_VERSION=$(make kernelversion)
echo "内核版本: $KERNEL_VERSION"
echo ""

# 安装内核镜像
echo "安装内核镜像到/boot..."
cp "$KERNEL_DIR/arch/x86/boot/bzImage" "/boot/vmlinuz-$KERNEL_VERSION-multi-os"

# 安装System.map
echo "安装System.map..."
cp "$KERNEL_DIR/System.map" "/boot/System.map-$KERNEL_VERSION-multi-os"

# 安装配置文件
echo "安装配置文件..."
cp "$KERNEL_DIR/.config" "/boot/config-$KERNEL_VERSION-multi-os"

# 安装模块
echo "安装内核模块..."
make modules_install

# 生成initramfs/initrd
echo "生成initramfs..."
if command -v dracut &> /dev/null; then
    dracut -f "/boot/initramfs-$KERNEL_VERSION-multi-os.img" "$KERNEL_VERSION"
elif command -v update-initramfs &> /dev/null; then
    update-initramfs -c -k "$KERNEL_VERSION"
elif command -v mkinitcpio &> /dev/null; then
    mkinitcpio -k "$KERNEL_VERSION" -g "/boot/initramfs-$KERNEL_VERSION-multi-os.img"
else
    echo "警告: 无法确定initramfs生成工具，请手动生成"
fi

# 更新bootloader
echo "更新bootloader..."
if [ -d "/boot/grub" ] || [ -d "/boot/grub2" ]; then
    if command -v grub-mkconfig &> /dev/null; then
        grub-mkconfig -o /boot/grub/grub.cfg
    elif command -v grub2-mkconfig &> /dev/null; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
elif command -v update-grub &> /dev/null; then
    update-grub
fi

echo ""
echo "=========================================="
echo "内核安装成功!"
echo "=========================================="
echo ""
echo "安装的内核: vmlinuz-$KERNEL_VERSION-multi-os"
echo ""
echo "下一步："
echo "  1. 重启系统，在bootloader中选择新内核"
echo ""
