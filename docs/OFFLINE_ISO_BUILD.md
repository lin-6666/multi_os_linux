# Multi-OS Linux 离线 ISO 生成完整指南
==========================================

## 📋 概述

本文档说明如何在没有网络的环境中生成完整的 Multi-OS Linux ISO 镜像。

## 🎯 生成的文件

### 系统包（已完成）
- `build/dist/multi-os-linux-20260604-044008-x86_64.tar.gz` (44KB)
- 包含完整的根文件系统和安装脚本

### ISO 生成脚本（已完成）
- `scripts/create-iso.sh` - 完整的 ISO 生成脚本

### 优化配置（已完成）
- Linux 6.8.12 内核优化配置
- 所有优化脚本和文档

---

## 🖥️ 在有网络的 Linux 环境中生成 ISO

### 方法 1: 使用提供的脚本（推荐）

#### 步骤 1: 准备环境

在一台有网络的 Linux 电脑上（Ubuntu/Debian）：

```bash
# 安装必要的工具
sudo apt-get update
sudo apt-get install -y \
    xorriso \
    squashfs-tools \
    cpio \
    grub-efi \
    grub-pc \
    syslinux \
    mtools
```

#### 步骤 2: 获取项目文件

```bash
# 克隆项目
git clone https://github.com/lin-6666/multi_os_linux.git
cd multi-os-linux

# 或者下载 Release
wget https://github.com/lin-6666/multi_os_linux/releases/download/v1.1/multi-os-linux-*.tar.gz
```

#### 步骤 3: 生成系统包（如果需要）

```bash
./create-dist-package.sh
```

#### 步骤 4: 生成 ISO

```bash
# 运行 ISO 生成脚本
chmod +x scripts/create-iso.sh
./scripts/create-iso.sh
```

#### 步骤 5: 等待完成

脚本将自动：
- 准备完整根文件系统
- 创建 SquashFS 镜像
- 生成引导文件
- 创建 ISO 镜像

生成的 ISO 文件：
```
build/output/multi-os-linux-1.1-6.8.12-x86_64.iso
```

---

## 🔧 手动生成 ISO（详细步骤）

### 步骤 1: 安装依赖

```bash
sudo apt-get install -y \
    xorriso \
    genisoimage \
    mksquashfs \
    cpio \
    gzip \
    xz-utils \
    grub-efi-amd64 \
    grub-pc-bin \
    syslinux \
    isolinux
```

### 步骤 2: 创建目录结构

```bash
mkdir -p iso/boot/grub
mkdir -p iso/boot/isolinux
mkdir -p iso/EFI/boot
mkdir -p squashfs
mkdir -p rootfs
```

### 步骤 3: 准备根文件系统

```bash
# 解压系统包
tar -xzf build/dist/multi-os-linux-*.tar.gz -C rootfs/

# 添加优化配置
cp config/kernel/.config rootfs/opt/multi-os/kernel-config/

# 添加内核源码
cp sources/linux-6.8.12.tar.xz rootfs/opt/multi-os/sources/

# 添加脚本
cp scripts/configure-optimized-kernel.sh rootfs/opt/multi-os/bin/
cp scripts/build-optimized-kernel.sh rootfs/opt/multi-os/bin/
```

### 步骤 4: 创建 SquashFS

```bash
mksquashfs rootfs squashfs/multi-os.squashfs \
    -comp xz \
    -e boot proc sys dev run tmp var/log var/cache
```

### 步骤 5: 复制引导文件

```bash
# 复制内核和 initrd（如果有）
cp /boot/vmlinuz-$(uname -r) iso/boot/vmlinuz
cp /boot/initrd.img-$(uname -r) iso/boot/initrd.img

# 或者创建占位符（需要替换为真实文件）
dd if=/dev/zero of=iso/boot/vmlinuz bs=1M count=10
dd if=/dev/zero of=iso/boot/initrd.img bs=1M count=30

# 复制 SquashFS
cp squashfs/multi-os.squashfs iso/boot/
```

### 步骤 6: 创建 ISOLINUX 配置

创建 `iso/boot/isolinux/isolinux.cfg`：

```
DEFAULT menu.c32
MENU TITLE Multi-OS Linux Boot Menu
TIMEOUT 30

LABEL multi-os-live
    MENU LABEL Multi-OS Linux (Live)
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=live quiet splash ---

LABEL multi-os-install
    MENU LABEL Install Multi-OS Linux
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=install ---

LABEL multi-os-safe
    MENU LABEL Safe Mode
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=safe nomodeset ---
```

### 步骤 7: 创建 GRUB 配置

创建 `iso/boot/grub/grub.cfg`：

```
set default=0
set timeout=10

menuentry "Multi-OS Linux" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd.img
}

menuentry "Multi-OS Linux (Install)" {
    linux /boot/vmlinuz boot=install
    initrd /boot/initrd.img
}
```

### 步骤 8: 创建 initramfs

```bash
mkdir -p /tmp/initramfs/{bin,sbin,etc,lib,proc,sys,dev}
cp /sbin/init /tmp/initramfs/sbin/

cd /tmp/initramfs
find . | cpio -H newc -o | gzip -9 > ../../iso/boot/initrd.img
```

### 步骤 9: 生成 ISO

```bash
# 使用 xorriso（推荐）
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "MULTI-OS-LINUX" \
    -appid "Multi-OS Linux" \
    -eltorito-boot boot/isolinux/isolinux.bin \
    -eltorito-catalog boot/isolinux/boot.cat \
    -eltorito-alt-boot \
    -e EFI/boot/grub \
    -no-emul-boot \
    -isohybrid-mbr /usr/lib/syslinux/bios/mbr.bin \
    -o multi-os-linux.iso \
    iso/

# 或者使用 genisoimage
genisoimage \
    -o multi-os-linux.iso \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e EFI/boot/grub \
    -no-emul-boot \
    -volid "MULTI-OS-LINUX" \
    iso/
```

### 步骤 10: 验证 ISO

```bash
# 检查 ISO 文件
ls -lh multi-os-linux.iso

# 检查 ISO 内容
mount -o loop multi-os-linux.iso /mnt
ls -la /mnt
umount /mnt

# 测试（在虚拟机中）
qemu-system-x86_64 -cdrom multi-os-linux.iso -m 2G
```

---

## 📀 刻录到 USB

### 使用 dd（Linux）

```bash
# 查看 USB 设备
sudo fdisk -l

# 刻录（替换 /dev/sdX 为你的 USB 设备）
sudo dd if=multi-os-linux.iso of=/dev/sdX bs=4M status=progress

# 同步
sudo sync
```

### 使用 Etcher（跨平台）

```bash
# 安装 Etcher
sudo apt-get install etcher

# 使用 Etcher 刻录
sudo etcher-cli multi-os-linux.iso
```

### 使用 Rufus（Windows）

1. 下载 Rufus: https://rufus.ie/
2. 选择 USB 设备
3. 选择 ISO 文件
4. 点击"开始"

---

## 🖥️ 从 USB 启动

### BIOS 设置

1. 插入 USB 启动盘
2. 启动电脑
3. 按 `Del` 或 `F2` 进入 BIOS
4. 设置 USB 为第一启动项
5. 保存并退出

### UEFI 设置

1. 插入 USB 启动盘
2. 启动电脑
3. 按 `F12` 或 `Esc` 选择启动设备
4. 选择 USB 设备

---

## ✅ 验证清单

生成 ISO 前确认：

- [ ] 系统包已生成
- [ ] ISO 生成脚本可用
- [ ] 至少 8GB 磁盘空间
- [ ] ISO 生成工具已安装
- [ ] 至少 8GB USB 设备

生成 ISO 后验证：

- [ ] ISO 文件大小合理（通常 2-4GB）
- [ ] ISO 可在虚拟机中启动
- [ ] 所有引导选项可用
- [ ] 可正常进入 Live 模式
- [ ] 可正常启动安装程序

---

## 🐛 故障排除

### 问题 1: mksquashfs 命令未找到

**解决方案：**
```bash
sudo apt-get install squashfs-tools
```

### 问题 2: xorriso 命令未找到

**解决方案：**
```bash
sudo apt-get install xorriso
```

### 问题 3: ISO 启动失败

**可能原因：**
- 内核或 initrd 缺失
- 引导配置错误
- BIOS 设置问题

**解决方案：**
1. 检查内核和 initrd 是否存在
2. 验证 ISOLINUX/GRUB 配置
3. 尝试 Legacy 启动模式

### 问题 4: USB 无法启动

**解决方案：**
1. 使用 `dd` 重新刻录
2. 确认 USB 格式正确（MBR/GPT）
3. 启用 BIOS Legacy 模式

---

## 📚 相关资源

- **项目主页**: https://github.com/lin-6666/multi_os_linux
- **Release 页面**: https://github.com/lin-6666/multi_os_linux/releases
- **文档目录**: docs/

---

## 🎯 下一步

1. **获取 ISO 生成工具**
   - 在有网络的电脑上安装 xorriso 等工具

2. **运行 ISO 生成脚本**
   ```bash
   ./scripts/create-iso.sh
   ```

3. **测试 ISO**
   - 在虚拟机中测试
   - 验证所有功能

4. **刻录到 USB**
   ```bash
   sudo dd if=multi-os-linux.iso of=/dev/sdX bs=4M
   ```

5. **安装和使用**
   - 从 USB 启动
   - 安装系统
   - 享受 Multi-OS Linux！

---

**文档版本:** 1.1
**更新日期:** 2026-06-04
**适用版本:** Multi-OS Linux v1.1+
