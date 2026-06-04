#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux - 完整 ISO 生成脚本 v1.1
#  生成可启动的完整安装 ISO 镜像
#
#===============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly ISO_DIR="${BUILD_DIR}/iso"
readonly ROOTFS_DIR="${BUILD_DIR}/rootfs-complete"
readonly OUTPUT_DIR="${BUILD_DIR}/output"

# 版本信息
readonly VERSION="1.1"
readonly KERNEL_VERSION="6.8.12"
readonly ARCH="x86_64"
readonly ISO_LABEL="MULTI-OS-LINUX-${VERSION}"

# 颜色
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_NC='\033[0m'

log_info() { echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1"; }
log_success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $1"; }
log_warning() { echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $1"; }
log_error() { echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"; }

# 检查依赖
check_dependencies() {
    log_info "检查 ISO 生成依赖..."
    
    local deps=(
        "xorriso"
        "mksquashfs"
        "cpio"
        "gzip"
        "xz"
        "grub-mkimage"
        "mkfs.fat"
        "mkfs.ext4"
    )
    
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_warning "缺少依赖: ${missing[*]}"
        log_info "安装命令: sudo apt-get install xorriso squashfs-tools cpio grub-efi"
        return 1
    fi
    
    log_success "所有依赖已满足"
    return 0
}

# 准备根文件系统
prepare_rootfs() {
    log_info "准备完整根文件系统..."
    
    # 检查系统包
    local system_pkg=$(ls -t "${BUILD_DIR}"/dist/multi-os-linux-*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$system_pkg" ]; then
        log_error "未找到系统包，请先运行 create-dist-package.sh"
        return 1
    fi
    
    log_info "使用系统包: $system_pkg"
    
    # 创建根文件系统目录
    mkdir -p "$ROOTFS_DIR"
    
    # 解压系统
    log_info "解压系统文件..."
    tar -xzf "$system_pkg" -C "$ROOTFS_DIR"
    
    # 添加优化配置
    if [ -f "${PROJECT_ROOT}/config/kernel/.config" ]; then
        mkdir -p "${ROOTFS_DIR}/opt/multi-os/kernel-config"
        cp "${PROJECT_ROOT}/config/kernel/.config" "${ROOTFS_DIR}/opt/multi-os/kernel-config/"
    fi
    
    # 添加内核源码（如果存在）
    if [ -f "${PROJECT_ROOT}/sources/linux-${KERNEL_VERSION}.tar.xz" ]; then
        mkdir -p "${ROOTFS_DIR}/opt/multi-os/sources"
        cp "${PROJECT_ROOT}/sources/linux-${KERNEL_VERSION}.tar.xz" "${ROOTFS_DIR}/opt/multi-os/sources/"
    fi
    
    # 添加优化脚本
    cp "${PROJECT_ROOT}/scripts/configure-optimized-kernel.sh" "${ROOTFS_DIR}/opt/multi-os/bin/" 2>/dev/null || true
    cp "${PROJECT_ROOT}/scripts/build-optimized-kernel.sh" "${ROOTFS_DIR}/opt/multi-os/bin/" 2>/dev/null || true
    
    # 设置权限
    chmod +x "${ROOTFS_DIR}/opt/multi-os/bin/"*.sh 2>/dev/null || true
    
    log_success "根文件系统准备完成"
}

# 创建 ISO 目录结构
create_iso_structure() {
    log_info "创建 ISO 目录结构..."
    
    mkdir -p "${ISO_DIR}/boot/grub"
    mkdir -p "${ISO_DIR}/boot/isolinux"
    mkdir -p "${ISO_DIR}/EFI/boot"
    mkdir -p "${ISO_DIR}/EFI/boot/grub"
    mkdir -p "${ISO_DIR}/boot/kernel"
    mkdir -p "${ISO_DIR}/live"
    
    # 复制根文件系统为 SquashFS
    log_info "创建 SquashFS 镜像..."
    mkdir -p "${BUILD_DIR}/squashfs"
    mksquashfs "$ROOTFS_DIR" "${BUILD_DIR}/squashfs/multi-os.squashfs" \
        -comp xz \
        -e boot \
        -e proc \
        -e sys \
        -e dev \
        -e run \
        -e tmp \
        -e var/log \
        -e var/cache
    
    log_success "SquashFS 镜像创建完成"
}

# 创建引导文件
create_boot_files() {
    log_info "创建引导文件..."
    
    # 检查是否有真实内核
    if [ -f "/boot/vmlinuz-$(uname -r)" ]; then
        log_info "使用系统内核..."
        cp "/boot/vmlinuz-$(uname -r)" "${ISO_DIR}/boot/kernel/vmlinuz"
        cp "/boot/initrd.img-$(uname -r)" "${ISO_DIR}/boot/kernel/initrd.img"
    else
        log_warning "未找到系统内核，创建占位符..."
        # 创建占位符（需要替换为真实内核）
        dd if=/dev/zero of="${ISO_DIR}/boot/kernel/vmlinuz" bs=1M count=10
        dd if=/dev/zero of="${ISO_DIR}/boot/kernel/initrd.img" bs=1M count=30
    fi
    
    # 复制 SquashFS
    cp "${BUILD_DIR}/squashfs/multi-os.squashfs" "${ISO_DIR}/boot/"
    
    # 创建 ISOLINUX 配置
    cat > "${ISO_DIR}/boot/isolinux/isolinux.cfg" << 'EOF'
DEFAULT menu.c32
MENU TITLE Multi-OS Linux Boot Menu
TIMEOUT 30
PROMPT 0

LABEL multi-os-live
    MENU LABEL ^Multi-OS Linux (Live Mode)
    MENU DEFAULT
    kernel /boot/kernel/vmlinuz
    append initrd=/boot/kernel/initrd.img boot=live persist quiet splash ---

LABEL multi-os-install
    MENU LABEL ^Install Multi-OS Linux
    kernel /boot/kernel/vmlinuz
    append initrd=/boot/kernel/initrd.img boot=install quiet splash ---

LABEL multi-os-safe
    MENU LABEL ^Safe Mode (No Graphics)
    kernel /boot/kernel/vmlinuz
    append initrd=/boot/kernel/initrd.img boot=safe nomodeset ---

LABEL multi-os-memtest
    MENU LABEL ^Memory Test (memtest86+)
    kernel /boot/memtest86+

LABEL reboot
    MENU LABEL ^Reboot
    COM32 reboot.c32

LABEL poweroff
    MENU LABEL ^Shutdown
    COM32 poweroff.c32

MENU COLOR border 30;44
MENU COLOR title 1;36;44
MENU COLOR sel 7;37;40
MENU COLOR unsel 37;44
MENU COLOR hotkey 1;37;44
EOF

    # 创建 GRUB 配置
    cat > "${ISO_DIR}/boot/grub/grub.cfg" << 'EOF'
set default=0
set timeout=10

menuentry "Multi-OS Linux (Live Mode)" {
    linux /boot/kernel/vmlinuz boot=live persist quiet splash
    initrd /boot/kernel/initrd.img
}

menuentry "Multi-OS Linux (Install)" {
    linux /boot/kernel/vmlinuz boot=install quiet splash
    initrd /boot/kernel/initrd.img
}

menuentry "Multi-OS Linux (Safe Mode)" {
    linux /boot/kernel/vmlinuz boot=safe nomodeset
    initrd /boot/kernel/initrd.img
}

menuentry "Memory Test (memtest86+)" {
    linux16 /boot/memtest86+
}

menuentry "Reboot" {
    reboot
}

menuentry "Shutdown" {
    halt
}
EOF

    # 创建 EFI GRUB 配置
    cat > "${ISO_DIR}/EFI/boot/grub.cfg" << 'EOF'
set default=0
set timeout=10

menuentry "Multi-OS Linux" {
    linux /boot/kernel/vmlinuz boot=live quiet splash
    initrd /boot/kernel/initrd.img
}

menuentry "Multi-OS Linux (Install)" {
    linux /boot/kernel/vmlinuz boot=install quiet splash
    initrd /boot/kernel/initrd.img
}
EOF

    log_success "引导文件创建完成"
}

# 创建 initramfs
create_initramfs() {
    log_info "创建 initramfs..."
    
    # 创建临时目录
    local initramfs_dir="${BUILD_DIR}/initramfs-temp"
    mkdir -p "$initramfs_dir"/{bin,sbin,etc,lib,usr/bin,proc,sys,dev}
    
    # 复制 busybox
    if command -v busybox &> /dev/null; then
        cp "$(which busybox)" "${initramfs_dir}/bin/"
        
        # 创建 busybox 符号链接
        for app in $(busybox --list 2>/dev/null); do
            ln -sf busybox "${initramfs_dir}/bin/$app" 2>/dev/null || true
        done
    fi
    
    # 创建 init 脚本
    cat > "${initramfs_dir}/init" << 'INITEOF'
#!/bin/sh

# 挂载基本文件系统
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# 显示启动信息
echo "========================================="
echo "  Multi-OS Linux 启动中..."
echo "========================================="

# 加载必要模块
modprobe squashfs 2>/dev/null || true
modprobe overlay 2>/dev/null || true
modprobe fuse 2>/dev/null || true

# 等待设备
echo "等待设备..."
sleep 2

# 挂载根文件系统
echo "挂载根文件系统..."
mkdir -p /newroot
mount -t squashfs /boot/multi-os.squashfs /newroot || {
    echo "错误: 无法挂载根文件系统"
    echo "进入紧急shell..."
    exec /bin/sh
}

# 移动挂载点
mount --move /proc /newroot/proc
mount --move /sys /newroot/sys
mount --move /dev /newroot/dev

# 切换到新根
echo "切换到新根文件系统..."
exec switch_root /newroot /sbin/init
INITEOF

    chmod +x "${initramfs_dir}/init"
    
    # 创建 initramfs
    cd "$initramfs_dir"
    find . | cpio -H newc -o | gzip -9 > "${ISO_DIR}/boot/kernel/initrd.img" 2>/dev/null
    
    # 清理
    cd /
    rm -rf "$initramfs_dir"
    
    log_success "initramfs 创建完成"
}

# 生成 ISO 镜像
generate_iso() {
    log_info "生成 ISO 镜像..."
    
    local iso_file="${OUTPUT_DIR}/multi-os-linux-${VERSION}-${KERNEL_VERSION}-${ARCH}.iso"
    
    mkdir -p "$OUTPUT_DIR"
    
    # 复制 GRUB EFI 文件
    if command -v grub-mkimage &> /dev/null; then
        log_info "创建 GRUB EFI 镜像..."
        grub-mkimage -o "${ISO_DIR}/EFI/boot/bootx64.efi" \
            -p '(cd)/boot/grub' \
            efi64 part_gpt fat ntfs \
            normal boot linux search search_fs_file \
            configfile echo test gfxterm menu ls \
            true sleepReboot halt 2>/dev/null || true
    fi
    
    # 使用 xorriso 生成 ISO
    if command -v xorriso &> /dev/null; then
        log_info "使用 xorriso 生成 ISO..."
        
        xorriso -as mkisofs \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "$ISO_LABEL" \
            -appid "Multi-OS Linux" \
            -publisher "Multi-OS Linux Project" \
            -preparer "Multi-OS Linux Builder v${VERSION}" \
            -eltorito-boot boot/isolinux/isolinux.bin \
            -eltorito-catalog boot/isolinux/boot.cat \
            -eltorito-alt-boot \
            -e EFI/boot/grub \
            -no-emul-boot \
            -isohybrid-mbr /usr/lib/syslinux/bios/mbr.bin \
            -append_partition 2 0xef EFI/boot/grub \
            -appended_part_as_gpt \
            -o "$iso_file" \
            "$ISO_DIR" 2>&1 | tail -20
        
        log_success "ISO 生成完成"
    elif command -v genisoimage &> /dev/null; then
        log_info "使用 genisoimage 生成 ISO..."
        
        genisoimage \
            -o "$iso_file" \
            -b boot/isolinux/isolinux.bin \
            -c boot/isolinux/boot.cat \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
            -eltorito-alt-boot \
            -e EFI/boot/grub \
            -no-emul-boot \
            -volid "$ISO_LABEL" \
            "$ISO_DIR" 2>&1 | tail -20
        
        log_success "ISO 生成完成"
    else
        log_error "未找到 ISO 生成工具 (xorriso 或 genisoimage)"
        return 1
    fi
    
    # 验证 ISO
    if [ -f "$iso_file" ]; then
        log_success "========================================="
        log_success "  ISO 镜像创建成功！"
        log_success "========================================="
        echo ""
        echo "文件信息:"
        echo "  位置: $iso_file"
        echo "  大小: $(du -h "$iso_file" | cut -f1)"
        echo "  MD5: $(md5sum "$iso_file" | cut -d' ' -f1)"
        echo ""
        
        # 复制到 dist 目录
        cp "$iso_file" "${BUILD_DIR}/dist/"
        log_info "ISO 已复制到: ${BUILD_DIR}/dist/"
    else
        log_error "ISO 生成失败"
        return 1
    fi
}

# 创建 UEFI 混合模式
create_hybrid_iso() {
    log_info "创建 UEFI 混合模式 ISO..."
    
    local iso_file="${OUTPUT_DIR}/multi-os-linux-${VERSION}-${KERNEL_VERSION}-${ARCH}-hybrid.iso"
    
    # 使用 isohybrid
    if command -v isohybrid &> /dev/null; then
        isohybrid --uefi "${OUTPUT_DIR}/multi-os-linux-${VERSION}-${KERNEL_VERSION}-${ARCH}.iso" \
            2>&1 | tail -5
        log_success "混合模式 ISO 创建完成"
    else
        log_warning "isohybrid 未安装，跳过混合模式"
    fi
}

# 主函数
main() {
    echo "========================================="
    echo "  Multi-OS Linux ISO 生成脚本 v${VERSION}"
    echo "  内核版本: ${KERNEL_VERSION}"
    echo "  架构: ${ARCH}"
    echo "========================================="
    echo ""
    
    # 检查依赖
    check_dependencies || {
        log_warning "依赖检查未通过，尝试继续..."
    }
    
    # 确认操作
    log_warning "此操作将创建完整的 ISO 镜像"
    log_warning "需要足够的磁盘空间（约 2-4GB）"
    read -p "是否继续? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        log_info "已取消"
        exit 0
    fi
    
    echo ""
    
    # 执行各阶段
    prepare_rootfs
    create_iso_structure
    create_boot_files
    create_initramfs
    generate_iso
    create_hybrid_iso
    
    echo ""
    log_success "========================================="
    log_success "  ISO 生成完成！"
    log_success "========================================="
    echo ""
    echo "下一步："
    echo "  1. 测试 ISO (在虚拟机中)"
    echo "  2. 刻录到 USB: sudo dd if=*.iso of=/dev/sdX bs=4M"
    echo "  3. 从 USB 启动并安装"
    echo ""
}

main "$@"
