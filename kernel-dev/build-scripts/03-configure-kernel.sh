#!/bin/bash
#
# Multi-OS Linux - 内核配置脚本
#
# 配置内核，启用Multi-OS Linux功能

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KERNEL_DIR="/workspace/multi-os-compat/sources/linux-6.8.12"
CONFIG_DIR="$PROJECT_ROOT/config"

echo "=========================================="
echo "Multi-OS Linux 内核配置脚本"
echo "=========================================="
echo ""

# 检查内核源码目录
if [ ! -d "$KERNEL_DIR" ]; then
    echo "错误: 内核源码目录不存在: $KERNEL_DIR"
    exit 1
fi

echo "内核源码目录: $KERNEL_DIR"
echo ""

# 进入内核源码目录
cd "$KERNEL_DIR"

# 生成默认配置
echo "生成默认配置..."
make defconfig

# 启用Multi-OS Linux功能
echo "启用Multi-OS Linux功能..."

./scripts/config --set-val MULTI_OS y
./scripts/config --set-val MULTI_OS_WINE y
./scripts/config --set-val MULTI_OS_DARLING y
./scripts/config --set-val MULTI_OS_ANDROID y
./scripts/config --set-val MULTI_OS_LOW_POWER y
./scripts/config --set-val MULTI_OS_PERFORMANCE y
./scripts/config --set-val MULTI_OS_SECURITY y

# 启用必要的内核功能
echo "启用必要的内核功能..."

# 低功耗配置
./scripts/config --set-val CONFIG_HZ_250 y
./scripts/config --set-val CONFIG_HZ 250
./scripts/config --set-val CONFIG_NO_HZ y
./scripts/config --set-val CONFIG_NO_HZ_IDLE y
./scripts/config --set-val CONFIG_HIGH_RES_TIMERS y

# 性能配置
./scripts/config --set-val CONFIG_CPU_FREQ y
./scripts/config --set-val CONFIG_CPU_FREQ_GOV_SCHEDUTIL y
./scripts/config --set-val CONFIG_TRANSPARENT_HUGEPAGE y
./scripts/config --set-val CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS y
./scripts/config --set-val CONFIG_KSM y

# 安全配置
./scripts/config --set-val CONFIG_SECURITY y
./scripts/config --set-val CONFIG_SECURITY_YAMA y

# Android支持
./scripts/config --set-val CONFIG_ANDROID y
./scripts/config --set-val CONFIG_ANDROID_BINDER_IPC y
./scripts/config --set-val CONFIG_ASHMEM y

# 文件系统支持
./scripts/config --set-val CONFIG_FUSE y
./scripts/config --set-val CONFIG_OVERLAY_FS y

# 网络配置
./scripts/config --set-val CONFIG_TCP_CONG_BBR y
./scripts/config --set-val CONFIG_DEFAULT_BBR y

echo ""
echo "=========================================="
echo "内核配置完成!"
echo "=========================================="
echo ""
echo "配置文件: $KERNEL_DIR/.config"
echo ""
echo "下一步："
echo "  1. 编译内核: 运行 04-build-kernel.sh"
echo "  2. 或手动编译: cd $KERNEL_DIR && make -j$(nproc)"
echo ""
