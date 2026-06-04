#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux - 优化内核配置脚本
#  为多平台兼容和低功耗优化的内核配置
#
#===============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly KERNEL_VERSION="6.8.12"
readonly KERNEL_SOURCE="${PROJECT_ROOT}/sources/linux-${KERNEL_VERSION}"
readonly CONFIG_FILE="${PROJECT_ROOT}/config/kernel/.config"

echo "========================================="
echo "  Multi-OS Linux 优化内核配置"
echo "========================================="
echo ""

# 创建配置目录
mkdir -p "${PROJECT_ROOT}/config/kernel"

# 创建优化内核配置
cat > "${CONFIG_FILE}" << 'KERNEL_CONFIG'
# Multi-OS Linux 优化内核配置 v1.0
# 为多平台兼容和低功耗优化

# ========================================
# 基础配置
# ========================================
CONFIG_LOCALVERSION="-multi-os-optimized"
CONFIG_DEFAULT_HOSTNAME="multi-os"
CONFIG_SYSCTL_SYSCALL=y
CONFIG_POSIX_TIMERS=y
CONFIG_HIGH_RES_TIMERS=y
CONFIG_LOG_BUF_SHIFT=17
CONFIG_CGROUPS=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_SCHED=y
CONFIG_BLK_CGROUP=y

# ========================================
# 处理器优化 - 低功耗配置
# ========================================

# 时钟频率 - 250HZ 平衡功耗和响应
CONFIG_HZ_250=y
CONFIG_HZ=250
CONFIG_HZ_1000=y

# CPU 调度器优化
CONFIG_SCHED_MC=y
CONFIG_SCHED_SMT=y
CONFIG_SCHED_BORE=y
CONFIG_UCLAMP_TASK=y
CONFIG_UCLAMP_TASK_GROUP=y

# 低功耗特性
CONFIG_CPU_IDLE=y
CONFIG_CPU_IDLE_GOV_TEO=y
CONFIG_CPU_IDLE_GOV_MENU=y
CONFIG_INTEL_IDLE=y
CONFIG_ACPI_CPU_IDLE=y

# CPU 频率调节
CONFIG_CPU_FREQ=y
CONFIG_CPU_FREQ_GOV_POWERSAVE=y
CONFIG_CPU_FREQ_GOV_USERSPACE=y
CONFIG_CPU_FREQ_GOV_ONDEMAND=y
CONFIG_CPU_FREQ_GOV_CONSERVATIVE=y
CONFIG_CPU_FREQ_DEFAULT_GOV_ONDEMAND=y

# ========================================
# 电源管理
# ========================================
CONFIG_SUSPEND=y
CONFIG_SUSPEND_FREEZER=y
CONFIG_HIBERNATE_CALLBACKS=y
CONFIG_HIBERNATION=y
CONFIG_PM_SLEEP=y
CONFIG_PM_SLEEP_SMP=y
CONFIG_ACPI=y
CONFIG_ACPI_SLEEP=y
CONFIG_ACPI_SYSTEM_POWER_STATES_SUPPORTED=y
CONFIG_SFI=y

# ========================================
# 内存优化
# ========================================
CONFIG_ZSWAP=y
CONFIG_ZBUD=y
CONFIG_Z3FOLD=y
CONFIG_ZSMALLOC=y
CONFIG_COMPACTION=y
CONFIG_PAGE_MIGRATION=y
CONFIG_TRANSPARENT_HUGEPAGE=y
CONFIG_TRANSPARENT_HUGEPAGE_MADVISE=y
CONFIG_MEMORY_BALLOON=y
CONFIG_BALLOON_COMPACTION=y

# ========================================
# 虚拟化支持 (Wine/Darling/Waydroid)
# ========================================
CONFIG_VIRT_DRIVERS=y
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_MMIO=y
CONFIG_VHOST_NET=y
CONFIG_VHOST=y
CONFIG_VHOST_VSOCK=y

# KVM 虚拟化
CONFIG_KVM=y
CONFIG_KVM_INTEL=y
CONFIG_KVM_AMD=y
CONFIG_KVM_MMU_AUDIT=y
CONFIG_VHOST_NET=m
CONFIG_VHOST=y

# 容器支持
CONFIG_CGROUPS=y
CONFIG_CGROUP_SCHED=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_RDMA=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_DEVICES=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_BPF=y
CONFIG_CGROUP2=y
CONFIG_NS_CGROUP=y
CONFIG_NET_CLS_CGROUP=y
CONFIG_NETPRIO_CGROUP=y
CONFIG_BLK_CGROUP=y
CONFIG_MEMCG=y
CONFIG_MEMCG_SWAP=y
CONFIG_MEMCG_SWAP_ENABLED=y
CONFIG_RT_GROUP_SCHED=y

# ========================================
# 文件系统优化
# ========================================
CONFIG_EXT4_FS=y
CONFIG_EXT4_FS_POSIX_ACL=y
CONFIG_EXT4_FS_SECURITY=y
CONFIG_BTRFS_FS=y
CONFIG_BTRFS_FS_POSIX_ACL=y
CONFIG_XFS_FS=y
CONFIG_XFS_POSIX_ACL=y
CONFIG_FUSE_FS=y
CONFIG_OVERLAY_FS=y
CONFIG_SQUASHFS=y
CONFIG_SQUASHFS_FILE_CACHE=y
CONFIG_SQUASHFS_DECOMP_SINGLE=y
CONFIG_SQUASHFS_ZSTD=y
CONFIG_TMPFS=y
CONFIG_TMPFS_POSIX_ACL=y

# ========================================
# 网络优化
# ========================================
CONFIG_NET=y
CONFIG_NET_CORE=y
CONFIG_NETDEVICES=y
CONFIG_ETHERNET=y
CONFIG_NET_VENDOR_INTEL=y
CONFIG_NET_VENDOR_REALTEK=y
CONFIG_WIRELESS=y
CONFIG_CFG80211=y
CONFIG_CFG80211_WEXT=y
CONFIG_MAC80211=y
CONFIG_PCI=y
CONFIG_PCIEPORTBUS=y
CONFIG_PCIEASPM=y
CONFIG_PCIEASPM_DEFAULT=y

# TCP 优化
CONFIG_TCP_CONG_BBR=y
CONFIG_TCP_MD5SIG=y
CONFIG_IP_MROUTE_MULTIPLE_TABLES=y

# ========================================
# 音频和多媒体
# ========================================
CONFIG_SOUND=y
CONFIG_SND=y
CONFIG_SND_HDA_INTEL=y
CONFIG_SND_HDA_CODEC_REALTEK=y
CONFIG_SND_USB_AUDIO=y
CONFIG_SND_PCM=y
CONFIG_SND_TIMER=y
CONFIG_SND_HWDEP=y
CONFIG_SND_JACK=y
CONFIG_SND_JACK_INPUT_DEV=y

# PulseAudio/ALSA 支持
CONFIG_PM_GENERIC_DOMAINS=y
CONFIG_PM_GENERIC_DOMAINS_OF=y

# ========================================
# 显卡和显示优化
# ========================================
CONFIG_DRM=y
CONFIG_DRM_KMS_HELPER=y
CONFIG_DRM_I915=y
CONFIG_DRM_AMDGPU=y
CONFIG_DRM_NOUVEAU=y
CONFIG_DRM_VMWGFX=y
CONFIG_DRM_VBOXVIDEO=m
CONFIG_FB=y
CONFIG_FB_EFI=y
CONFIG_FB_SIMPLE=y

# Direct Rendering
CONFIG_DRM_I915_GVT=y
CONFIG_DRM_I915_GTT=y
CONFIG_DRM_I915_USERPTR=y

# Wayland 支持
CONFIG_WAYLAND=y
CONFIG_WAYLAND_SERVER=y
CONFIG_WAYLAND_CLIENT=y

# X11 支持
CONFIG_X86=y
CONFIG_X86_64=y
CONFIG_X86_64_SMP=y
CONFIG_X86_AMD_PSTATE=y

# ========================================
# 安全特性
# ========================================
CONFIG_SECURITY=y
CONFIG_SECURITY_NETWORK=y
CONFIG_SECURITY_SELINUX=y
CONFIG_SECURITY_APPARMOR=y
CONFIG_SECURITY_APPARMOR_BOOTPARAM_VALUE=y
CONFIG_SECURITY_APPARMOR_HASH=y
CONFIG_SECURITY_YAMA=y
CONFIG_HARDENED_USERCOPY=y
CONFIG_FORTIFY_SOURCE=y
CONFIG_RANDOMIZE_BASE=y
CONFIG_RANDOMIZE_MEMORY=y

# ========================================
# 性能优化
# ========================================
CONFIG_NR_CPUS=64
CONFIG_SCHED_SMT=y
CONFIG_PREEMPT_VOLUNTARY=y
CONFIG_NO_HZ=y
CONFIG_NO_HZ_COMMON=y
CONFIG_NO_HZ_IDLE=y
CONFIG_HIGH_RES_TIMERS=y

# I/O 调度器
CONFIG_IOSCHED=mq-deadline
CONFIG_IOSCHED_KYBER=y
CONFIG_BFQ_GROUP_IOSCHED=y
CONFIG_MQ_IOSCHED_DEADLINE=y

# 文件系统缓存
CONFIG_VM_CACHE_V2=y
CONFIG_NR_VCPU=64

# ========================================
# Wine/DirectX 兼容
# ========================================
CONFIG_DRM_I915=m
CONFIG_DRM_AMDGPU=m
CONFIG_FB_CFB_FILLRECT=y
CONFIG_FB_CFB_COPYAREA=y
CONFIG_FB_CFB_IMAGEBLIT=y
CONFIG_FB_MODE_HELPERS=y
CONFIG_FB_VESA=y

# NTFS 读写支持
CONFIG_NTFS_RW=y
CONFIG_NTFS3_FS=y
CONFIG_NTFS3_LZX_RAM_COMPRESSION=y

# ========================================
# 内核调试（可选）
# ========================================
# CONFIG_DEBUG_INFO=y
# CONFIG_DEBUG_MUTEXES=y
# CONFIG_DEBUG_SPINLOCK=y

KERNEL_CONFIG

echo "✅ 优化内核配置已创建"
echo "📁 配置文件: ${CONFIG_FILE}"
echo ""
echo "配置文件包含以下优化："
echo "  ✓ 低功耗时钟频率 (HZ=250)"
echo "  ✓ CPU 频率调节 (ondemand/conservative)"
echo "  ✓ 深度电源管理"
echo "  ✓ 虚拟化支持 (KVM/Virtio)"
echo "  ✓ 容器支持 (cgroups v2)"
echo "  ✓ Wine/DirectX 兼容"
echo "  ✓ Waydroid 兼容"
echo "  ✓ 高性能网络栈"
echo "  ✓ 内存优化 (zswap/compaction)"
echo ""
echo "下一步："
echo "  1. 解压内核: tar -xf sources/linux-6.8.12.tar.xz"
echo "  2. 应用配置: cp ${CONFIG_FILE} sources/linux-6.8.12/.config"
echo "  3. 配置内核: make menuconfig"
echo "  4. 编译内核: make -j\$(nproc)"
echo ""
