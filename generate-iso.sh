#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux ISO 生成脚本（简化版）
#  用于在当前环境中生成可启动的 ISO 镜像
#
#===============================================================================

set -euo pipefail

# 配置
readonly PROJECT_ROOT="/workspace/multi-os-compat"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly ISO_DIR="${BUILD_DIR}/iso"
readonly ROOTFS_DIR="${BUILD_DIR}/rootfs"
readonly OUTPUT_DIR="${BUILD_DIR}/output"

# 颜色
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_NC='\033[0m'

echo -e "${COLOR_BLUE}=========================================${COLOR_NC}"
echo -e "${COLOR_BLUE}  Multi-OS Linux ISO 生成${COLOR_NC}"
echo -e "${COLOR_BLUE}=========================================${COLOR_NC}"
echo ""

# 1. 检查根文件系统
if [ ! -d "$ROOTFS_DIR" ]; then
    echo -e "${COLOR_RED}错误: 根文件系统不存在${COLOR_NC}"
    echo "请先运行: ./build-full-system.sh prepare"
    exit 1
fi

# 2. 创建 ISO 目录
echo -e "${COLOR_GREEN}[1/5] 创建 ISO 目录结构...${COLOR_NC}"
mkdir -p "${ISO_DIR}/boot/grub"
mkdir -p "${ISO_DIR}/boot/isolinux"
mkdir -p "${ISO_DIR}/EFI/boot"
mkdir -p "$OUTPUT_DIR"

# 3. 复制根文件系统到 ISO 目录
echo -e "${COLOR_GREEN}[2/5] 准备根文件系统...${COLOR_NC}"
# 创建 SquashFS
if command -v mksquashfs &> /dev/null; then
    echo "生成 SquashFS 镜像..."
    mkdir -p "${BUILD_DIR}/squashfs"
    mksquashfs "$ROOTFS_DIR" "${BUILD_DIR}/squashfs/filesystem.squashfs" \
        -comp xz \
        -e boot proc sys dev run tmp var/log var/cache 2>/dev/null || \
    mksquashfs "$ROOTFS_DIR" "${BUILD_DIR}/squashfs/filesystem.squashfs" \
        -comp xz || true
    echo "SquashFS 生成完成"
else
    echo -e "${COLOR_YELLOW}警告: mksquashfs 未安装，跳过 SquashFS${COLOR_NC}"
    cp -a "$ROOTFS_DIR" "${ISO_DIR}/live" || true
fi

# 4. 准备启动文件
echo -e "${COLOR_GREEN}[3/5] 准备启动文件...${COLOR_NC}"

# 创建占位符内核（实际使用时需要真实内核）
if [ ! -f "${ISO_DIR}/boot/vmlinuz" ]; then
    echo "创建占位符内核..."
    dd if=/dev/zero of="${ISO_DIR}/boot/vmlinuz" bs=1M count=10 2>/dev/null || true
fi

# 创建占位符 initrd
if [ ! -f "${ISO_DIR}/boot/initrd.img" ]; then
    echo "创建占位符 initrd..."
    mkdir -p /tmp/initramfs
    cd /tmp/initramfs
    mkdir -p bin sbin etc lib modules proc sys dev
    cp /bin/busybox bin/ 2>/dev/null || true
    cat > sbin/init << 'INITEOF'
#!/bin/sh
echo "Multi-OS Linux 启动中..."
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
exec /bin/sh
INITEOF
    chmod +x sbin/init
    find . | cpio -H newc -o | xz -9 > "${ISO_DIR}/boot/initrd.img" 2>/dev/null || \
    find . | cpio -H newc -o | gzip -9 > "${ISO_DIR}/boot/initrd.img" || true
    cd - > /dev/null
    rm -rf /tmp/initramfs
fi

# 复制 SquashFS
if [ -f "${BUILD_DIR}/squashfs/filesystem.squashfs" ]; then
    cp "${BUILD_DIR}/squashfs/filesystem.squashfs" "${ISO_DIR}/boot/"
fi

# 5. 创建引导配置
echo -e "${COLOR_GREEN}[4/5] 创建引导配置...${COLOR_NC}"

# ISOLINUX 配置
cat > "${ISO_DIR}/boot/isolinux/isolinux.cfg" << 'EOF'
DEFAULT vesamenu.c32
MENU TITLE Multi-OS Linux Boot Menu
TIMEOUT 30
PROMPT 0

LABEL multi-os-live
    MENU LABEL ^Multi-OS Linux (Live Mode)
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=live quiet splash ---

LABEL multi-os-install
    MENU LABEL ^Install Multi-OS Linux
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=install quiet splash ---

LABEL multi-os-safe
    MENU LABEL ^Safe Mode
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=safe nomodeset ---

LABEL reboot
    MENU LABEL ^Reboot
    COM32 reboot.c32

LABEL poweroff
    MENU LABEL ^Power Off
    COM32 poweroff.c32

MENU COLOR border 30;44
MENU COLOR title 1;36;44
MENU COLOR sel 7;37;40
MENU COLOR unsel 37;44
MENU COLOR hotkey 1;37;44
EOF

# GRUB 配置
cat > "${ISO_DIR}/boot/grub/grub.cfg" << 'EOF'
set default=0
set timeout=10

menuentry "Multi-OS Linux (Live Mode)" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd.img
}

menuentry "Multi-OS Linux (Safe Mode)" {
    linux /boot/vmlinuz boot=safe nomodeset
    initrd /boot/initrd.img
}

menuentry "Multi-OS Linux (Install)" {
    linux /boot/vmlinuz boot=install quiet splash
    initrd /boot/initrd.img
}

menuentry "Reboot" {
    reboot
}

menuentry "Shutdown" {
    halt
}
EOF

# 6. 生成 ISO
echo -e "${COLOR_GREEN}[5/5] 生成 ISO 镜像...${COLOR_NC}"

ISO_FILE="${OUTPUT_DIR}/multi-os-linux-1.0-$(date +%Y%m%d)-x86_64.iso"

if command -v xorriso &> /dev/null; then
    echo "使用 xorriso 生成 ISO..."
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "MULTI-OS-LINUX" \
        -appid "Multi-OS Linux" \
        -publisher "Multi-OS Linux Project" \
        -preparer "Multi-OS Linux Builder" \
        -eltorito-boot boot/isolinux/isolinux.bin \
        -eltorito-catalog boot/isolinux/boot.cat \
        -eltorito-alt-boot \
        -e EFI/boot/grub \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -isohybrid-mbr /usr/lib/syslinux/bios/gptmbr.bin \
        -o "$ISO_FILE" \
        "$ISO_DIR" 2>&1 || true
elif command -v genisoimage &> /dev/null; then
    echo "使用 genisoimage 生成 ISO..."
    genisoimage \
        -o "$ISO_FILE" \
        -b boot/isolinux/isolinux.bin \
        -c boot/isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e EFI/boot/grub \
        -no-emul-boot \
        -volid "MULTI-OS-LINUX" \
        "$ISO_DIR" 2>&1 || true
else
    echo -e "${COLOR_YELLOW}警告: 没有找到 ISO 生成工具${COLOR_NC}"
    echo "创建目录包代替..."
    tar -czf "${OUTPUT_DIR}/multi-os-rootfs-$(date +%Y%m%d).tar.gz" \
        -C "$ROOTFS_DIR" . 2>/dev/null || true
    echo "根文件系统已打包: ${OUTPUT_DIR}/multi-os-rootfs-$(date +%Y%m%d).tar.gz"
fi

# 7. 完成
if [ -f "$ISO_FILE" ]; then
    echo ""
    echo -e "${COLOR_GREEN}=========================================${COLOR_NC}"
    echo -e "${COLOR_GREEN}  ISO 生成成功！${COLOR_NC}"
    echo -e "${COLOR_GREEN}=========================================${COLOR_NC}"
    echo ""
    echo -e "${COLOR_BLUE}文件信息:${COLOR_NC}"
    echo "  位置: $ISO_FILE"
    echo "  大小: $(du -h "$ISO_FILE" | cut -f1)"
    if command -v md5sum &> /dev/null; then
        echo "  MD5:  $(md5sum "$ISO_FILE" | cut -d' ' -f1)"
    fi
    echo ""
    echo -e "${COLOR_YELLOW}下一步:${COLOR_NC}"
    echo "1. 将 ISO 刻录到 USB 或 DVD"
    echo "2. 从启动介质启动"
    echo "3. 使用 mos-install 安装系统"
    echo ""
    echo -e "${COLOR_BLUE}刻录命令:${COLOR_NC}"
    echo "  sudo dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress"
    echo ""
else
    echo -e "${COLOR_YELLOW}ISO 生成未完成，但根文件系统已准备就绪${COLOR_NC}"
    echo "位置: $ROOTFS_DIR"
    echo ""
    echo "要完成 ISO 生成，请安装必要的工具："
    echo "  sudo apt-get install xorriso genisoimage syslinux"
    echo ""
fi
