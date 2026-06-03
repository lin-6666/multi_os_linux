# Multi-OS Linux 完整构建和安装指南
=========================================

## 系统概述
Multi-OS Linux 是一个完整的多平台兼容 Linux 发行版，可以在空白电脑上安装使用。它支持：
- Windows 应用（通过 Wine）
- macOS 应用（通过 Darling）
- Android 应用（通过 Waydroid）
- Steam 和 Wallpaper Engine

## 已完成的工作

### 1. 系统构建脚本
创建了完整的系统构建脚本：
- [`build-full-system.sh`](file:///workspace/multi-os-compat/build-full-system.sh) - 完整的系统构建脚本
- [`quick-build.sh`](file:///workspace/multi-os-compat/quick-build.sh) - 快速构建脚本

### 2. 根文件系统
已创建完整的根文件系统结构在 `build/rootfs/`，包括：
- 基础系统目录
- 系统配置文件
- Multi-OS 特定配置
- 用户模板

### 3. 配置文件
创建了所有必要的配置文件：
- /etc/passwd, /etc/group, /etc/shadow
- /etc/fstab, /etc/hostname, /etc/hosts
- /etc/network/interfaces
- /etc/profile, /etc/bash.bashrc
- 包管理列表
- Multi-OS 特定配置

### 4. Multi-OS 配置
- 系统版本信息
- 欢迎脚本
- 首次启动设置脚本
- 系统服务配置
- 应用菜单配置

### 5. 引导配置
- ISOLINUX 配置
- GRUB 配置
- EFI 引导配置
- 安装器脚本

## 构建输出

### 主要文件
- **构建脚本**: `build-full-system.sh`
- **根文件系统**: `build/rootfs/`
- **ISO 目录**: `build/iso/`
- **配置包**: `build/multi-os-config-*.tar.gz`

## 安装步骤

### 方式一：使用构建脚本自动构建完整 ISO

```bash
# 1. 进入项目目录
cd /workspace/multi-os-compat

# 2. 检查依赖（需要安装）
sudo apt-get install flex genisoimage xorriso grub-pc grub-efi squashfs-tools

# 3. 执行完整构建
./build-full-system.sh all

# 4. 生成的 ISO 文件
ls -lh build/multi-os-linux-*.iso
```

### 方式二：分步构建

```bash
# 1. 检查依赖
./build-full-system.sh deps

# 2. 准备根文件系统
./build-full-system.sh prepare

# 3. 下载内核源码
./build-full-system.sh kernel

# 4. 创建配置
./build-full-system.sh config

# 5. 生成 ISO
./build-full-system.sh iso
```

### 方式三：使用 Docker/Chroot 环境构建

```bash
# 1. 创建基础 Debian 环境
sudo debootstrap stable /path/to/chroot http://deb.debian.org/debian

# 2. 进入 chroot
sudo chroot /path/to/chroot

# 3. 安装构建依赖
apt-get update && apt-get install -y build-essential linux-image-amd64 grub2

# 4. 复制项目文件并运行构建
cp -r /workspace/multi-os-compat/* /path/to/chroot/root/
cd /root/multi-os-compat
./build-full-system.sh all
```

## 手动构建 ISO 的步骤

如果您想要手动完成构建过程：

### 1. 准备目录结构
```bash
mkdir -p build/iso/{boot/grub,boot/isolinux,EFI/boot}
mkdir -p build/rootfs
mkdir -p build/squashfs
```

### 2. 创建根文件系统
```bash
# 复制或解压基础系统到 build/rootfs
# 或者使用 debootstrap 创建
sudo debootstrap stable build/rootfs
```

### 3. 配置系统
```bash
# 复制 Multi-OS 配置
cp -r config/* build/rootfs/opt/multi-os/config/
cp scripts/* build/rootfs/opt/multi-os/bin/

# 设置权限
chmod +x build/rootfs/opt/multi-os/bin/*.sh
```

### 4. 创建 SquashFS
```bash
mksquashfs build/rootfs build/squashfs/filesystem.squashfs -comp xz
```

### 5. 复制启动文件
```bash
# 复制内核
cp /boot/vmlinuz-$(uname -r) build/iso/boot/vmlinuz

# 复制 initrd
cp /boot/initrd.img-$(uname -r) build/iso/boot/initrd.img

# 复制 SquashFS
cp build/squashfs/filesystem.squashfs build/iso/boot/
```

### 6. 创建引导配置
```bash
# ISOLINUX 配置
cat > build/iso/boot/isolinux/isolinux.cfg << 'EOF'
DEFAULT vesamenu.c32
MENU TITLE Multi-OS Linux
TIMEOUT 30

LABEL multi-os
    MENU LABEL Multi-OS Linux
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=live quiet splash
EOF

# GRUB 配置
cat > build/iso/boot/grub/grub.cfg << 'EOF'
set default=0
set timeout=10

menuentry "Multi-OS Linux" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd.img
}
EOF
```

### 7. 生成 ISO
```bash
# 使用 xorriso（推荐）
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "MULTI-OS-LINUX" \
    -eltorito-boot boot/isolinux/isolinux.bin \
    -eltorito-catalog boot/isolinux/boot.cat \
    -eltorito-alt-boot \
    -e EFI/boot/grub \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -isohybrid-mbr /usr/lib/syslinux/bios/gptmbr.bin \
    -o build/multi-os-linux.iso \
    build/iso/

# 或者使用 genisoimage
genisoimage \
    -o build/multi-os-linux.iso \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e EFI/boot/grub \
    -no-emul-boot \
    -volid "MULTI-OS-LINUX" \
    build/iso/
```

## 安装到电脑

### 制作启动 USB
```bash
# 使用 dd（会清除 USB 上的所有数据）
sudo dd if=build/multi-os-linux.iso of=/dev/sdX bs=4M status=progress

# 或使用etcher
sudo apt-get install etcher
sudo etcher-cli build/multi-os-linux.iso
```

### 从 USB 启动
1. 将 USB 插入电脑
2. 进入 BIOS/UEFI 设置
3. 从 USB 启动
4. 选择 "Multi-OS Linux Live" 进入试用模式
5. 运行 `mos-install` 开始安装

### 安装过程
安装程序会自动：
1. 分区和格式化磁盘
2. 复制系统文件
3. 安装引导加载程序
4. 配置基本系统

## 使用说明

### 首次启动设置
系统首次启动时会自动运行设置向导：
- 初始化 Wine 环境
- 配置 Waydroid
- 设置用户账户

### 主要命令
```bash
# Multi-OS 设置
mos-setup

# 统一启动器
mos-launch <应用>

# Wine 设置
wine-setup

# Android 环境
android-start

# 电源管理
mos-powersave
```

### Steam 和 Wallpaper Engine
1. 运行 `wine-setup` 初始化 Wine 环境
2. 运行 `launch-steam.sh` 安装 Steam
3. 在 Steam 中购买并安装 Wallpaper Engine
4. Wallpaper Engine 将自动运行并可修改壁纸

## 故障排除

### ISO 无法启动
- 检查 USB 是否正确制作
- 确认 BIOS 启动了 UEFI 或 Legacy 模式
- 尝试使用不同的 USB 端口

### 安装失败
- 确保有足够的磁盘空间（建议 50GB+）
- 检查网络连接
- 查看安装日志：`/var/log/multi-os-install.log`

### Wine 应用无法运行
- 运行 `winecfg` 检查配置
- 尝试安装必要的组件：`winetricks vcrun2019`
- 查看 Wine 日志：`~/.wine-multi-os/logs/`

## 更多信息

- 项目主页: https://github.com/multi-os-linux
- 文档目录: `docs/`
- 配置目录: `config/`
- 脚本目录: `scripts/`

## 版本信息

- **系统名称**: Multi-OS Linux
- **版本**: 1.0
- **内核**: 6.8.12
- **架构**: x86_64
- **构建日期**: $(date)
