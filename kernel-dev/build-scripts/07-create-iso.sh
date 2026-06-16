#!/bin/bash
#
# Multi-OS Linux - ISO创建脚本
#
# 创建包含Multi-OS Linux内核的可启动ISO

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KERNEL_DIR="/workspace/multi-os-compat/sources/linux-6.8.12"
BUILD_DIR="$PROJECT_ROOT/build"
ISO_DIR="$BUILD_DIR/iso"
ISO_FILE="$BUILD_DIR/multi-os-linux-kernel.iso"

echo "=========================================="
echo "Multi-OS Linux ISO创建脚本"
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
echo "ISO目录: $ISO_DIR"
echo "输出文件: $ISO_FILE"
echo ""

# 创建ISO目录结构
echo "创建ISO目录结构..."
mkdir -p "$ISO_DIR/boot/grub"
mkdir -p "$ISO_DIR/boot"

# 复制内核文件
echo "复制内核文件..."
cp "$KERNEL_DIR/arch/x86/boot/bzImage" "$ISO_DIR/boot/vmlinuz"

# 创建简单的initrd（使用busybox或现有initrd）
echo "创建initrd..."
if [ -f "$PROJECT_ROOT/build/iso/boot/initrd.img" ]; then
    cp "$PROJECT_ROOT/build/iso/boot/initrd.img" "$ISO_DIR/boot/initrd.img"
else
    # 创建一个空的initrd作为占位符
    cd "$ISO_DIR/boot"
    mkdir -p initrd-tmp
    cd initrd-tmp
    mkdir -p bin dev etc proc sys newroot
    echo '#!/bin/sh' > init
    echo 'echo "Multi-OS Linux Boot"' >> init
    echo 'exec /bin/sh' >> init
    chmod +x init
    find . | cpio -o -H newc | gzip -9 > ../initrd.img
    cd ..
    rm -rf initrd-tmp
    cd "$PROJECT_ROOT"
fi

# 创建GRUB配置
echo "创建GRUB配置..."
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set default=0
set timeout=10

menuentry "Multi-OS Linux" {
    linux /boot/vmlinuz root=/dev/ram0 rw quiet
    initrd /boot/initrd.img
}

menuentry "Multi-OS Linux (Debug Mode)" {
    linux /boot/vmlinuz root=/dev/ram0 rw debug
    initrd /boot/initrd.img
}
EOF

# 创建ISO
echo "创建ISO镜像..."
if command -v grub-mkrescue &> /dev/null; then
    grub-mkrescue -o "$ISO_FILE" "$ISO_DIR"
elif command -v xorriso &> /dev/null; then
    xorriso -as mkisofs -o "$ISO_FILE" \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
        -c boot/boot.cat \
        -b boot/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        "$ISO_DIR"
else
    echo "错误: 未找到ISO创建工具"
    echo "请安装: grub2-common 或 xorriso"
    exit 1
fi

echo ""
echo "=========================================="
echo "ISO创建成功!"
echo "=========================================="
echo ""
echo "ISO文件: $ISO_FILE"
echo ""
echo "下一步："
echo "  1. 写入USB: dd if=$ISO_FILE of=/dev/sdX bs=4M"
echo "  2. 或在虚拟机中测试"
echo ""
