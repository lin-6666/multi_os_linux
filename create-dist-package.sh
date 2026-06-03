#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux 完整系统包生成脚本
#  生成可在任何 Linux 环境中安装的完整系统包
#
#===============================================================================

set -euo pipefail

readonly PROJECT_ROOT="/workspace/multi-os-compat"
readonly OUTPUT_DIR="${PROJECT_ROOT}/build/dist"
readonly TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "========================================="
echo "  Multi-OS Linux 系统包生成"
echo "========================================="
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 1. 准备完整根文件系统
echo "[1/5] 准备完整根文件系统..."
ROOTFS_DIR="${OUTPUT_DIR}/rootfs"
rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"

# 复制现有根文件系统
cp -a "${PROJECT_ROOT}/build/rootfs/." "$ROOTFS_DIR/"

# 2. 使用 debootstrap 创建完整系统
echo "[2/5] 创建完整系统（需要网络）..."

if command -v debootstrap &> /dev/null; then
    echo "使用 debootstrap 创建完整 Debian 系统..."
    debootstrap stable "$ROOTFS_DIR" http://deb.debian.org/debian || {
        echo "debootstrap 失败，使用基础文件系统"
    }
else
    echo "debootstrap 未安装，添加手动安装脚本..."
fi

# 3. 添加 Multi-OS 配置
echo "[3/5] 添加 Multi-OS 配置..."

# 复制配置
mkdir -p "${ROOTFS_DIR}/opt/multi-os"
cp -r "${PROJECT_ROOT}/config/"* "${ROOTFS_DIR}/opt/multi-os/config/" 2>/dev/null || true
cp -r "${PROJECT_ROOT}/scripts/"* "${ROOTFS_DIR}/opt/multi-os/bin/" 2>/dev/null || true

# 创建版本信息
cat > "${ROOTFS_DIR}/opt/multi-os/VERSION" << 'EOF'
MULTI_OS_VERSION="1.0"
MULTI_OS_NAME="Multi-OS Linux"
BUILD_DATE="$(date -I)"
KERNEL_VERSION="6.8.12"
ARCH="x86_64"
EOF

# 设置权限
chmod +x "${ROOTFS_DIR}/opt/multi-os/bin/"*.sh 2>/dev/null || true

# 4. 创建安装脚本
echo "[4/5] 创建安装脚本..."

cat > "${ROOTFS_DIR}/install.sh" << 'INSTALLSCRIPT'
#!/bin/bash
#
# Multi-OS Linux 安装脚本
# 用于将系统安装到目标磁盘
#

set -euo pipefail

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Multi-OS Linux 安装程序${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# 检查 root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误: 需要 root 权限${NC}"
    echo "请使用: sudo $0"
    exit 1
fi

# 欢迎
cat << 'WELCOME'

欢迎使用 Multi-OS Linux 安装程序！

此安装程序将帮助您在电脑上安装 Multi-OS Linux。

重要提示:
1. 此操作将修改磁盘，请提前备份重要数据
2. 需要至少 20GB 可用空间
3. 请确保网络连接正常

WELCOME

read -p "按 Enter 键继续，或 Ctrl+C 取消..."

# 显示磁盘
echo ""
echo "可用磁盘："
lsblk -d -o NAME,SIZE,TYPE | grep -E "disk|nvme"
echo ""

read -p "输入要安装的磁盘名称 (例如: sda): " DISK

if [ ! -b "/dev/$DISK" ]; then
    echo -e "${RED}错误: /dev/$DISK 不存在${NC}"
    exit 1
fi

DEVICE="/dev/$DISK"
echo ""
echo -e "${YELLOW}将使用 /dev/$DISK 进行安装${NC}"
echo "磁盘容量: $(lsblk -d -o SIZE /dev/$DISK | tail -1)"
echo ""

read -p "确认继续? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "安装已取消"
    exit 0
fi

# 分区
echo ""
echo "正在创建分区..."

# 使用 sgdisk 创建 GPT 分区表
if command -v sgdisk &> /dev/null; then
    sgdisk --zap-all "$DEVICE"
    sgdisk -n 1:1M:+512M -t 1:EF00 "$DEVICE"  # EFI 分区
    sgdisk -n 2:0:+8G -t 2:8200 "$DEVICE"     # Swap 分区
    sgdisk -n 3:0:0 -t 3:8300 "$DEVICE"       # 根分区
    partprobe "$DEVICE"
else
    # 使用 fdisk 作为备选
    echo "警告: sgdisk 未安装，使用 fdisk"
    fdisk "$DEVICE" << 'FDISK_EOF'
g
n
p
1

+512M
t
1
n
p
2

+8G
t
2
19
n
p
3


w
FDISK_EOF
fi

sleep 2

# 格式化
echo ""
echo "正在格式化分区..."

mkfs.fat -F 32 "${DEVICE}1" || mkfs.vfat -F 32 "${DEVICE}1"
mkswap "${DEVICE}2"
mkfs.ext4 -F "${DEVICE}3"

# 挂载
echo ""
echo "正在挂载分区..."

MOUNT_POINT="/mnt/multi-os"
mkdir -p "$MOUNT_POINT"
mount "${DEVICE}3" "$MOUNT_POINT"
mkdir -p "${MOUNT_POINT}/boot/efi"
mount "${DEVICE}1" "${MOUNT_POINT}/boot/efi"
swapon "${DEVICE}2"

# 复制系统
echo ""
echo "正在复制系统文件..."
echo "(这可能需要几分钟时间)..."

cp -a . "$MOUNT_POINT/" 2>/dev/null || rsync -a ./ "$MOUNT_POINT/"

# 安装引导程序
echo ""
echo "正在安装引导程序..."

if command -v grub-install &> /dev/null; then
    grub-install --target=x86_64-efi --efi-directory="${MOUNT_POINT}/boot/efi" \
                 --boot-directory="${MOUNT_POINT}/boot" "$DEVICE"
    
    # 生成 GRUB 配置
    cat > "${MOUNT_POINT}/boot/grub/grub.cfg" << 'GRUB_EOF'
set default=0
set timeout=5

menuentry "Multi-OS Linux" {
    linux /boot/vmlinuz root=/dev/sda3 ro quiet splash
    initrd /boot/initrd.img
}

menuentry "Multi-OS Linux (Recovery)" {
    linux /boot/vmlinuz root=/dev/sda3 ro single
    initrd /boot/initrd.img
}
GRUB_EOF
fi

# 更新 fstab
echo ""
echo "正在配置系统..."

UUID_ROOT=$(blkid -s UUID -o value "${DEVICE}3")
UUID_BOOT=$(blkid -s UUID -o value "${DEVICE}1")
UUID_SWAP=$(blkid -s UUID -o value "${DEVICE}2")

cat > "${MOUNT_POINT}/etc/fstab" << EOF
# /etc/fstab: static file system information
UUID=$UUID_ROOT  /        ext4  defaults,noatime  0  1
UUID=$UUID_BOOT  /boot/efi vfat defaults          0  2
UUID=$UUID_SWAP  none     swap sw                0  0
tmpfs /tmp       tmpfs defaults,noatime,mode=1777 0  0
EOF

# 设置主机名
echo "multi-os" > "${MOUNT_POINT}/etc/hostname"

# 卸载
echo ""
echo "正在清理..."

umount -R "$MOUNT_POINT"
swapoff "${DEVICE}2" 2>/dev/null || true

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  安装完成！${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "请重启电脑并从硬盘启动"
echo ""
echo "首次启动后："
echo "  1. 登录 (用户名: root 或您创建的用户)"
echo "  2. 运行: /opt/multi-os/bin/setup-wine.sh"
echo "  3. 开始使用 Multi-OS Linux！"
echo ""
INSTALLSCRIPT

chmod +x "${ROOTFS_DIR}/install.sh"

# 5. 打包
echo "[5/5] 生成系统包..."

cd "$OUTPUT_DIR"

# 主系统包
tar -czf "multi-os-linux-${TIMESTAMP}-x86_64.tar.gz" rootfs/

# MD5 校验和
md5sum "multi-os-linux-${TIMESTAMP}-x86_64.tar.gz" > "multi-os-linux-${TIMESTAMP}-x86_64.tar.gz.md5"

# 创建安装说明
cat > "INSTALL_GUIDE.txt" << 'EOF'
================================================================================
  Multi-OS Linux 安装指南
================================================================================

快速安装步骤:
1. 解压系统包:
   tar -xzf multi-os-linux-*-x86_64.tar.gz
   cd rootfs

2. 运行安装程序:
   sudo ./install.sh

3. 按照提示完成安装

4. 重启电脑

详细说明:
---------

1. 解压系统包
   $ tar -xzf multi-os-linux-20260603-x86_64.tar.gz
   $ cd rootfs

2. 检查磁盘
   $ sudo fdisk -l
   确认要安装的磁盘

3. 运行安装
   $ sudo ./install.sh
   - 选择目标磁盘
   - 等待分区和格式化完成
   - 等待文件复制完成
   - 等待引导程序安装完成

4. 重启
   $ sudo reboot

5. 首次启动
   - 从硬盘启动
   - 登录系统
   - 运行 Multi-OS 设置:
     $ /opt/multi-os/bin/setup-wine.sh

硬件要求:
---------
- CPU: 64位 x86 处理器
- 内存: 至少 2GB (推荐 4GB+)
- 磁盘: 至少 20GB 可用空间
- 显卡: 支持 VESA 模式即可
- 网络: 可选（用于下载更新）

支持的特性:
-----------
✓ Windows 应用 (Wine)
✓ macOS 应用 (Darling)
✓ Android 应用 (Waydroid)
✓ Steam 和 Wallpaper Engine
✓ 低功耗优化

故障排除:
---------
1. 安装失败
   - 检查是否有足够的磁盘空间
   - 确认磁盘没有被其他系统占用
   - 查看安装日志

2. 启动失败
   - 进入 BIOS 确保从硬盘启动
   - 检查 GRUB 配置
   - 尝试恢复模式启动

3. Wine 应用无法运行
   - 运行: winecfg
   - 安装组件: winetricks vcrun2019

更多信息:
---------
项目主页: https://github.com/multi-os-linux
文档目录: /opt/multi-os/docs/

================================================================================
EOF

# 完成
echo ""
echo "========================================="
echo "  系统包生成完成！"
echo "========================================="
echo ""
echo "生成的文件:"
ls -lh "${OUTPUT_DIR}/"*.tar.gz "${OUTPUT_DIR}/"*.md5 "${OUTPUT_DIR}/INSTALL_GUIDE.txt" 2>/dev/null
echo ""
echo "下一步:"
echo "  1. 复制系统包到目标电脑"
echo "  2. 解压: tar -xzf multi-os-linux-*-x86_64.tar.gz"
echo "  3. 进入目录: cd rootfs"
echo "  4. 运行安装: sudo ./install.sh"
echo ""
