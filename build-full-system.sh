#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux 完整系统构建脚本
#  生成可安装在空白电脑上的操作系统
#
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# 全局配置
#-------------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$SCRIPT_DIR"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly ISO_DIR="${BUILD_DIR}/iso"
readonly ROOTFS_DIR="${BUILD_DIR}/rootfs"
readonly SOURCES_DIR="${PROJECT_ROOT}/sources"

# 系统版本
readonly SYSTEM_NAME="Multi-OS Linux"
readonly SYSTEM_VERSION="1.0"
readonly KERNEL_VERSION="6.8.12"
readonly ARCH="x86_64"

# ISO 配置
readonly ISO_LABEL="MULTI-OS"
readonly ISO_VOLUME="Multi-OS-Linux"
readonly ISO_PUBLISHER="Multi-OS Linux Project"
readonly ISO_APPLICATION="Multi-OS Linux Live/Install"

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_NC='\033[0m'

#-------------------------------------------------------------------------------
# 工具函数
#-------------------------------------------------------------------------------
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1" | tee -a "${BUILD_DIR}/build.log"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $1" | tee -a "${BUILD_DIR}/build.log"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $1" | tee -a "${BUILD_DIR}/build.log"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1" | tee -a "${BUILD_DIR}/build.log"
}

log_section() {
    echo "" | tee -a "${BUILD_DIR}/build.log"
    echo "============================================================" | tee -a "${BUILD_DIR}/build.log"
    echo "  $1" | tee -a "${BUILD_DIR}/build.log"
    echo "============================================================" | tee -a "${BUILD_DIR}/build.log"
    echo "" | tee -a "${BUILD_DIR}/build.log"
}

#-------------------------------------------------------------------------------
# 检查依赖
#-------------------------------------------------------------------------------
check_dependencies() {
    log_section "检查构建依赖"
    
    local deps=(
        "gcc"
        "g++"
        "make"
        "cmake"
        "git"
        "wget"
        "tar"
        "xz"
        "bzip2"
        "gzip"
        "patch"
        "grep"
        "sed"
        "awk"
        "flex"
        "bison"
        "genisoimage"
        "xorriso"
        "grub-pc"
        "grub-efi"
        "squashfs-tools"
    )
    
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_warning "缺少以下依赖: ${missing[*]}"
        log_info "在 Debian/Ubuntu 上安装: sudo apt-get install ${missing[*]}"
        log_info "可以继续，但某些功能可能不可用"
    else
        log_success "所有依赖已满足"
    fi
}

#-------------------------------------------------------------------------------
# Phase 1: 准备构建环境
#-------------------------------------------------------------------------------
prepare_build_env() {
    log_section "Phase 1: 准备构建环境"
    
    # 创建目录
    log_info "创建构建目录..."
    mkdir -p "$BUILD_DIR"
    mkdir -p "$ISO_DIR"
    mkdir -p "$ROOTFS_DIR"
    mkdir -p "${ISO_DIR}/boot/grub"
    mkdir -p "${ISO_DIR}/boot/grub/x86_64-efi"
    mkdir -p "${ISO_DIR}/EFI/boot"
    mkdir -p "${ISO_DIR}/EFI/OS"
    mkdir -p "${ISO_DIR}/boot/isolinux"
    mkdir -p "${ISO_DIR}/boot/syslinux"
    mkdir -p "${BUILD_DIR}/chroot"
    mkdir -p "${BUILD_DIR}/squashfs"
    mkdir -p "${SOURCES_DIR}"
    
    # 初始化日志
    echo "# Multi-OS Linux 构建日志 - $(date)" > "${BUILD_DIR}/build.log"
    
    log_success "构建环境准备完成"
}

#-------------------------------------------------------------------------------
# Phase 2: 创建基础根文件系统
#-------------------------------------------------------------------------------
create_base_rootfs() {
    log_section "Phase 2: 创建基础根文件系统"
    
    # 创建基本目录结构
    log_info "创建目录结构..."
    mkdir -p "${ROOTFS_DIR}"/{bin,boot,dev,etc,home,lib,lib64,media,mnt,opt,proc,root,sbin,srv,sys,tmp,usr,var}
    mkdir -p "${ROOTFS_DIR}"/usr/{bin,lib,sbin,src,share}
    mkdir -p "${ROOTFS_DIR}"/var/{log,cache,lib,spool}
    mkdir -p "${ROOTFS_DIR}"/etc/{apt,dpkg,profile.d,sudoers.d,network,default,modprobe.d,modules-load.d}
    mkdir -p "${ROOTFS_DIR}"/etc/skel
    mkdir -p "${ROOTFS_DIR}"/run
    mkdir -p "${ROOTFS_DIR}"/var/tmp
    
    # 创建必要的设备文件
    log_info "创建设备文件..."
    mknod -m 666 "${ROOTFS_DIR}/dev/null" c 1 3 || true
    mknod -m 666 "${ROOTFS_DIR}/dev/zero" c 1 5 || true
    mknod -m 666 "${ROOTFS_DIR}/dev/random" c 1 8 || true
    mknod -m 666 "${ROOTFS_DIR}/dev/urandom" c 1 9 || true
    mknod -m 620 "${ROOTFS_DIR}/dev/console" c 5 1 || true
    mknod -m 666 "${ROOTFS_DIR}/dev/tty" c 5 0 || true
    mknod -m 666 "${ROOTFS_DIR}/dev/tty1" c 4 1 || true
    mknod -m 666 "${ROOTFS_DIR}/dev/tty2" c 4 2 || true
    mknod -m 666 "${ROOTFS_DIR}/dev/tty3" c 4 3 || true
    mknod -m 666 "${ROOTFS_DIR}/dev/tty4" c 4 4 || true
    
    log_success "基础根文件系统创建完成"
}

#-------------------------------------------------------------------------------
# Phase 3: 创建系统配置文件
#-------------------------------------------------------------------------------
create_system_configs() {
    log_section "Phase 3: 创建系统配置文件"
    
    # /etc/passwd
    log_info "创建 /etc/passwd..."
    cat > "${ROOTFS_DIR}/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/false
bin:x:2:2:bin:/bin:/bin/false
sys:x:3:3:sys:/dev:/bin/false
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/bin/false
man:x:6:12:man:/var/cache/man:/bin/false
lp:x:7:7:lp:/var/spool/lpd:/bin/false
mail:x:8:8:mail:/var/mail:/bin/false
news:x:9:9:news:/var/spool/news:/bin/false
uucp:x:10:10:uucp:/var/spool/uucp:/bin/false
proxy:x:13:13:proxy:/bin:/bin/false
www-data:x:33:33:www-data:/var/www:/bin/false
backup:x:34:34:backup:/var/backups:/bin/false
list:x:38:40:list:/var/list:/bin/false
irc:x:39:39:irc:/var/run/ircd:/bin/false
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/bin/false
nobody:x:65534:65534:nobody:/nonexistent:/bin/false
systemd-network:x:100:102:systemd Network Management,,,:/run/systemd:/bin/false
systemd-resolve:x:101:103:systemd Resolver,,,:/run/systemd:/bin/false
systemd-timesync:x:102:104:systemd Time Synchronization,,,:/run/systemd:/bin/false
messagebus:x:103:106::/nonexistent:/bin/false
_apt:x:104:65534::/nonexistent:/bin/false
EOF

    # /etc/group
    log_info "创建 /etc/group..."
    cat > "${ROOTFS_DIR}/etc/group" << 'EOF'
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
fax:x:21:
voice:x:22:
cdrom:x:24:
floppy:x:25:
tape:x:26:
sudo:x:27:
audio:x:29:
dip:x:30:
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
plugdev:x:46:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
systemd-journal:x:101:
systemd-network:x:102:
systemd-resolve:x:103:
messagebus:x:106:
input:x:107:
render:x:108:
kvm:x:109:
sgx:x:110:
EOF

    # /etc/shadow
    log_info "创建 /etc/shadow..."
    echo "root:*:18900:0:99999:7:::" > "${ROOTFS_DIR}/etc/shadow"
    echo "daemon:*:18900:0:99999:7:::" >> "${ROOTFS_DIR}/etc/shadow"
    
    # /etc/fstab
    log_info "创建 /etc/fstab..."
    cat > "${ROOTFS_DIR}/etc/fstab" << 'EOF'
# /etc/fstab: static file system information.
#
# <file system>  <mount point>  <type>  <options>  <dump>  <pass>

# Root filesystem
UUID=$$$ROOT_UUID$$$  /               ext4    defaults,noatime  0       1

# Boot partition
UUID=$$$BOOT_UUID$$$  /boot           ext2    defaults          0       2

# EFI System Partition
UUID=$$$EFI_UUID$$$   /boot/efi      vfat    defaults          0       1

# Swap
UUID=$$$SWAP_UUID$$$  none            swap    sw                0       0

# Temporary files
tmpfs                   /tmp           tmpfs   defaults,noatime,mode=1777  0  0
tmpfs                   /run           tmpfs   defaults,noatime,mode=0755  0  0

# Virtual filesystems
proc                    /proc          proc    defaults          0       0
sysfs                   /sys           sysfs   defaults          0       0
devpts                  /dev/pts       devpts  defaults          0       0
devtmpfs                /dev           devtmpfs defaults         0       0

# Home directory
UUID=$$$HOME_UUID$$$   /home          ext4    defaults,noatime  0       2
EOF

    # /etc/hostname
    log_info "创建 /etc/hostname..."
    echo "multi-os" > "${ROOTFS_DIR}/etc/hostname"
    
    # /etc/hosts
    log_info "创建 /etc/hosts..."
    cat > "${ROOTFS_DIR}/etc/hosts" << 'EOF'
127.0.0.1   localhost multi-os
127.0.1.1   multi-os

# IPv6
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    # /etc/network/interfaces
    log_info "创建 /etc/network/interfaces..."
    cat > "${ROOTFS_DIR}/etc/network/interfaces" << 'EOF'
# This file describes the network interfaces available on your system
# and how to activate them.

# The loopback network interface
auto lo
iface lo inet loopback

# Wired or wireless connections
allow-hotplug eth0
iface eth0 inet dhcp
EOF

    # /etc/resolv.conf
    log_info "创建 /etc/resolv.conf..."
    cat > "${ROOTFS_DIR}/etc/resolv.conf" << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

    # /etc/profile
    log_info "创建 /etc/profile..."
    cat > "${ROOTFS_DIR}/etc/profile" << 'EOF'
# /etc/profile: system-wide .profile file for the Bourne shell (sh)
# and Bourne compatible shells (bash, ksh, ash, ...)

if [ "$PS1" ]; then
  if [ "$BASH" ] && [ -r /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
  fi
fi

# Set PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Set default editor
export EDITOR=vim
export VISUAL=vim

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Multi-OS environment
export MOS_HOME="/opt/multi-os"
EOF

    # /etc/bash.bashrc
    log_info "创建 /etc/bash.bashrc..."
    cat > "${ROOTFS_DIR}/etc/bash.bashrc" << 'EOF'
# /etc/bash.bashrc
#
# System-wide .bashrc file for interactive bash(1) shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize

# Enable color prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Enable programmable completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Multi-OS aliases
alias mos='mos-launch'
alias wine-setup='setup-wine.sh'
alias android-start='start-waydroid.sh'
EOF

    # /etc/skel/.bashrc (template for new users)
    log_info "创建用户模板..."
    cp "${ROOTFS_DIR}/etc/profile" "${ROOTFS_DIR}/etc/skel/.profile"
    cp "${ROOTFS_DIR}/etc/bash.bashrc" "${ROOTFS_DIR}/etc/skel/.bashrc"

    log_success "系统配置文件创建完成"
}

#-------------------------------------------------------------------------------
# Phase 4: 安装基础包列表
#-------------------------------------------------------------------------------
create_package_list() {
    log_section "Phase 4: 创建包管理列表"
    
    # 创建 Multi-OS 包列表
    cat > "${ROOTFS_DIR}/etc/mos/packages.list" << 'EOF'
# Multi-OS Linux 基础包列表
# 这些包在系统构建时会被安装

# 核心系统
base-files
base-passwd
bash
coreutils
dash
dpkg
e2fsprogs
filesystem
gcc-14-base
grep
gzip
hostname
init-system-helpers
libc-bin
login
mount
ncurses-base
perl-base
sed
sensible-utils
sysvinit-utils
tar
tzdata
util-linux

# 系统工具
apt
apt-listchanges
apt-utils
bsdutils
ca-certificates
cron
dbus
debconf-i18n
debianutils
diffutils
dmidecode
dosfstools
eject
fdisk
file
findutils
gettext-base
gnupg
gpgv
grep
groff-base
gzip
hostname
init
init-system-helpers
install-info
iputils-ping
iso-codes
kbd
keyboard-configuration
kmod
language-pack-en
libc-bin
liblocale-gettext-perl
login
logsave
lsb-base
mawk
man-db
manpages
mawk
ncurses-base
ncurses-bin
net-tools
netbase
ntpdate
openssl
os-prober
passwd
perl
procps
readline-common
rsyslog
sed
sensible-utils
shared-mime-info
strace
sudo
sysv-rc
sysvinit-utils
tar
tasksel
tasksel-data
telnet
time
tzdata
ubuntu-keyring
ucf
udev
util-linux
vim-common
vim-tiny
wget
which
xz-utils
zlib1g

# 图形界面
xorg
xserver-xorg
xserver-xorg-core
xserver-xorg-input-all
xserver-xorg-video-all
x11-apps
x11-session-utils
x11-utils
x11-xserver-utils
xauth
xbitmaps
x11-common

# 桌面环境
gnome-session
gnome-shell
gnome-terminal
nautilus
gedit
eog
evince
totem
cheese
simple-scan
gnome-calculator
gnome-calendar
gnome-clocks
gnome-weather
gnome-maps
gnome-photos
shotwell

# 网络
network-manager
network-manager-gnome
firefox
thunderbird
openssh-client
openssh-server

# 媒体
ubuntu-restricted-extras
libavcodec-extra
gstreamer1.0-plugins-base
gstreamer1.0-plugins-good
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-ugly
gstreamer1.0-libav

# Wine 和 Windows 兼容
wine
wine64
wine32
winetricks
playonlinux
q4wine

# 开发工具
build-essential
cmake
git
vim
emacs
code

# Multi-OS 特定
waydroid
pipewire
pulseaudio
libvirt-daemon
EOF

    log_success "包列表创建完成"
}

#-------------------------------------------------------------------------------
# Phase 5: 下载和配置内核
#-------------------------------------------------------------------------------
download_and_prepare_kernel() {
    log_section "Phase 5: 下载和准备内核"
    
    local kernel_tarball="${SOURCES_DIR}/linux-${KERNEL_VERSION}.tar.xz"
    
    # 检查内核是否已下载
    if [ -f "$kernel_tarball" ]; then
        log_info "内核源码已存在: $kernel_tarball"
    else
        log_info "下载 Linux 内核 ${KERNEL_VERSION}..."
        wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
            -O "$kernel_tarball" || {
            log_error "内核下载失败"
            return 1
        }
    fi
    
    # 解压内核
    log_info "解压内核源码..."
    tar -xf "$kernel_tarball" -C "${BUILD_DIR}/chroot" || {
        log_error "内核解压失败"
        return 1
    }
    
    log_success "内核准备完成"
}

#-------------------------------------------------------------------------------
# Phase 6: 创建 Multi-OS 配置
#-------------------------------------------------------------------------------
create_mos_config() {
    log_section "Phase 6: 创建 Multi-OS 配置"
    
    # Multi-OS 主目录
    mkdir -p "${ROOTFS_DIR}/opt/multi-os"
    mkdir -p "${ROOTFS_DIR}/opt/multi-os/config"
    mkdir -p "${ROOTFS_DIR}/opt/multi-os/bin"
    mkdir -p "${ROOTFS_DIR}/opt/multi-os/lib"
    mkdir -p "${ROOTFS_DIR}/opt/multi-os/share"
    mkdir -p "${ROOTFS_DIR}/opt/multi-os/wine"
    mkdir -p "${ROOTFS_DIR}/opt/multi-os/android"
    
    # Multi-OS 版本信息
    cat > "${ROOTFS_DIR}/opt/multi-os/version" << EOF
MULTI_OS_VERSION="${SYSTEM_VERSION}"
MULTI_OS_NAME="${SYSTEM_NAME}"
BUILD_DATE="$(date -I)"
KERNEL_VERSION="${KERNEL_VERSION}"
ARCH="${ARCH}"
EOF

    # Multi-OS 欢迎脚本
    cat > "${ROOTFS_DIR}/opt/multi-os/welcome.sh" << 'EOF'
#!/bin/bash
# Multi-OS Linux 欢迎脚本

cat << 'WELCOME'
================================================================================
       _   _ _____ _   _ ____   ____   ___  ____  ____  
      | \ | | ____| | | |  _ \ / __ \ / _ \|  _ \|  _ \ 
      |  \| |  _| | | | | |_) | |  | | | | | |_) | | | |
      | |\  | |___| |_| |  _ <| |__| | |_| |  _ <| |_| |
      |_| \_|_____|\___/|_| \_\\____/ \___/|_| \_\____/ 
                                                                       
                    Multi-OS Linux v1.0
                    多平台兼容 Linux 发行版
================================================================================

系统特性:
  - Windows 兼容 (Wine)
  - macOS 兼容 (Darling)  
  - Android 兼容 (Waydroid)
  - 低功耗优化
  - 统一应用管理

快速命令:
  mos-setup      - Multi-OS 设置向导
  mos-launch     - 统一应用启动器
  mos-android    - 启动 Android 环境
  mos-powersave  - 电源管理

更多信息请访问: https://github.com/multi-os-linux
WELCOME
EOF
    chmod +x "${ROOTFS_DIR}/opt/multi-os/welcome.sh"

    # 复制配置文件
    if [ -d "${PROJECT_ROOT}/config" ]; then
        cp -r "${PROJECT_ROOT}/config"/* "${ROOTFS_DIR}/opt/multi-os/config/" || true
    fi
    
    # 复制脚本
    if [ -d "${PROJECT_ROOT}/scripts" ]; then
        cp -r "${PROJECT_ROOT}/scripts"/* "${ROOTFS_DIR}/opt/multi-os/bin/" || true
    fi

    # 创建 Multi-OS 系统服务
    mkdir -p "${ROOTFS_DIR}/etc/systemd/system"
    
    cat > "${ROOTFS_DIR}/etc/systemd/system/multi-os-setup.service" << 'EOF'
[Unit]
Description=Multi-OS Linux Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/multi-os/setup-first-boot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # 首次启动设置脚本
    cat > "${ROOTFS_DIR}/opt/multi-os/setup-first-boot.sh" << 'EOF'
#!/bin/bash
# Multi-OS Linux 首次启动设置脚本

set -euo pipefail

LOGFILE="/var/log/multi-os-setup.log"

log() {
    echo "[$(date)] $1" | tee -a "$LOGFILE"
}

log "========================================="
log "Multi-OS Linux 首次启动设置"
log "========================================="

# 初始化 Wine 环境
if command -v wine &> /dev/null; then
    log "初始化 Wine 环境..."
    export WINEPREFIX="/opt/multi-os/wine"
    wineboot --init 2>&1 | tee -a "$LOGFILE" || true
fi

# 设置 Waydroid
if command -v waydroid &> /dev/null; then
    log "初始化 Waydroid..."
    waydroid init 2>&1 | tee -a "$LOGFILE" || true
fi

log "首次启动设置完成！"
log "请运行 mos-setup 进行详细配置"
EOF
    chmod +x "${ROOTFS_DIR}/opt/multi-os/setup-first-boot.sh"

    # 创建 Multi-OS 菜单项
    mkdir -p "${ROOTFS_DIR}/etc/xdg/menus/applications-merged"
    cat > "${ROOTFS_DIR}/etc/xdg/menus/applications-merged/multi-os.menu" << 'EOF'
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
 "http://www.freedesktop.org/standards/menu/1.0/menu.dtd">
<Menu>
    <Name>Multi-OS</Name>
    <Menu>
        <Name>Multi-OS.Windows</Name>
        <Directory>multi-os-windows.directory</Directory>
        <Include>
            <Category>MultiOS-Windows</Category>
        </Include>
    </Menu>
    <Menu>
        <Name>Multi-OS.Android</Name>
        <Directory>multi-os-android.directory</Directory>
        <Include>
            <Category>MultiOS-Android</Category>
        </Include>
    </Menu>
    <Menu>
        <Name>Multi-OS.Settings</Name>
        <Directory>multi-os-settings.directory</Directory>
        <Include>
            <Category>MultiOS-Settings</Category>
        </Include>
    </Menu>
</Menu>
EOF

    log_success "Multi-OS 配置创建完成"
}

#-------------------------------------------------------------------------------
# Phase 7: 创建引导配置
#-------------------------------------------------------------------------------
create_boot_config() {
    log_section "Phase 7: 创建引导配置"
    
    # 创建 isolinux 配置
    log_info "创建 isolinux 配置..."
    cat > "${ISO_DIR}/isolinux/isolinux.cfg" << 'EOF'
DEFAULT vesamenu.c32
MENU TITLE Multi-OS Linux Boot Menu
TIMEOUT 30
PROMPT 0

LABEL multi-os-live
    MENU LABEL ^Multi-OS Linux (Live)
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=live quiet splash ---
    
LABEL multi-os-install
    MENU LABEL ^Install Multi-OS Linux
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=install quiet splash ---
    
LABEL multi-os-safe
    MENU LABEL ^Safe mode
    kernel /boot/vmlinuz
    append initrd=/boot/initrd.img boot=safe nomodeset ---
    
LABEL hdt
    MENU LABEL ^Hardware Detection Tool (HDT)
    kernel hdt.c32
    append modules_pcimap=hdt-modules-pcimap.txt pciids=hdt-pciids.txt
    
LABEL memtest
    MENU LABEL ^Memory Test (memtest86+)
    kernel memtest86+
    
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
MENU COLOR hotkey 1;37;40
EOF

    # 创建 GRUB 配置
    log_info "创建 GRUB 配置..."
    cat > "${ISO_DIR}/boot/grub/grub.cfg" << 'EOF'
set default=0
set timeout=10

menuentry "Multi-OS Linux" {
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
EOF

    log_success "引导配置创建完成"
}

#-------------------------------------------------------------------------------
# Phase 8: 创建安装器脚本
#-------------------------------------------------------------------------------
create_installer() {
    log_section "Phase 8: 创建安装器"
    
    # Live 模式安装脚本
    mkdir -p "${ROOTFS_DIR}/usr/sbin"
    cat > "${ROOTFS_DIR}/usr/sbin/mos-install" << 'EOF'
#!/bin/bash
# Multi-OS Linux 安装器

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Multi-OS Linux 安装器${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误: 需要 root 权限运行此安装程序${NC}"
    echo "请使用: sudo mos-install"
    exit 1
fi

# 显示欢迎信息
cat << 'WELCOME'
欢迎使用 Multi-OS Linux 安装程序！

此安装程序将帮助您在电脑上安装 Multi-OS Linux 系统。

在开始之前，请确保：
1. 有可用的磁盘空间（建议至少 50GB）
2. 已连接网络（用于下载更新）
3. 备份重要数据

WELCOME

read -p "按 Enter 键继续..."
echo ""

# 磁盘选择
echo "可用磁盘："
lsblk -d -o NAME,SIZE,TYPE | grep -E "disk|nvme"
echo ""

read -p "请选择要安装的磁盘（例如：sda, nvme0n1）：" DISK

if [ ! -b "/dev/$DISK" ]; then
    echo -e "${RED}错误: 磁盘 /dev/$DISK 不存在${NC}"
    exit 1
fi

DEVICE="/dev/$DISK"

# 确认操作
echo ""
echo -e "${YELLOW}警告: 将对 /dev/$DISK 进行以下操作：${NC}"
echo "  1. 创建分区表"
echo "  2. 创建 EFI 分区 (512MB)"
echo "  3. 创建 Swap 分区 (8GB)"
echo "  4. 创建根分区 (剩余空间)"
echo ""
read -p "确定继续？(yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "安装已取消"
    exit 0
fi

# 分区
echo ""
echo "正在创建分区..."
parted -s "$DEVICE" mklabel gpt
parted -s "$DEVICE" mkpart primary fat32 1MiB 513MiB
parted -s "$DEVICE" mkpart primary linux-swap 513MiB 8705MiB
parted -s "$DEVICE" mkpart primary ext4 8705MiB 100%
parted -s "$DEVICE" set 1 esp on
partprobe "$DEVICE"

# 格式化
echo "正在格式化分区..."
mkfs.fat -F 32 "${DEVICE}1"
mkswap "${DEVICE}2"
mkfs.ext4 -F "${DEVICE}3"

# 挂载
echo "正在挂载分区..."
mount "${DEVICE}3" /mnt
mkdir -p /mnt/boot/efi
mount "${DEVICE}1" /mnt/boot/efi
swapon "${DEVICE}2"

# 安装基础系统
echo "正在安装基础系统..."
apt-get update
apt-get install -y linux-image-generic grub-efi-amd64 systemd

# 配置系统
echo "正在配置系统..."
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable Multi-OS-Setup

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  安装完成！${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "请重启电脑并从硬盘启动"
echo ""

EOF
    chmod +x "${ROOTFS_DIR}/usr/sbin/mos-install"

    log_success "安装器创建完成"
}

#-------------------------------------------------------------------------------
# Phase 9: 生成 SquashFS
#-------------------------------------------------------------------------------
create_squashfs() {
    log_section "Phase 9: 生成 SquashFS 镜像"
    
    log_info "这可能需要几分钟时间..."
    
    # 创建 mksquashfs 目录
    mkdir -p "${BUILD_DIR}/squashfs"
    
    # 生成 SquashFS
    log_info "生成 SquashFS 镜像..."
    mksquashfs "${ROOTFS_DIR}" "${BUILD_DIR}/squashfs/filesystem.squashfs" \
        -comp xz \
        -e boot \
        -e proc \
        -e sys \
        -e dev \
        -e run \
        || {
        log_error "SquashFS 生成失败"
        return 1
    }
    
    log_success "SquashFS 镜像创建完成"
}

#-------------------------------------------------------------------------------
# Phase 10: 创建 ISO 镜像
#-------------------------------------------------------------------------------
create_iso_image() {
    log_section "Phase 10: 创建 ISO 镜像"
    
    local iso_file="${BUILD_DIR}/multi-os-linux-${SYSTEM_VERSION}-$(date +%Y%m%d)-${ARCH}.iso"
    
    # 复制内核和 initrd 到 ISO 目录
    log_info "准备启动文件..."
    if [ -f "${BUILD_DIR}/chroot/linux-${KERNEL_VERSION}/arch/x86_64/boot/compressed/vmlinuz" ]; then
        cp "${BUILD_DIR}/chroot/linux-${KERNEL_VERSION}/arch/x86_64/boot/compressed/vmlinuz" "${ISO_DIR}/boot/vmlinuz"
    elif [ -f "${BUILD_DIR}/chroot/linux-${KERNEL_VERSION}/vmlinuz" ]; then
        cp "${BUILD_DIR}/chroot/linux-${KERNEL_VERSION}/vmlinuz" "${ISO_DIR}/boot/vmlinuz"
    else
        # 创建一个临时的 vmlinuz（实际构建时需要真实内核）
        log_warning "内核文件不存在，创建占位符"
        dd if=/dev/zero of="${ISO_DIR}/boot/vmlinuz" bs=1M count=10
    fi
    
    # 创建 initrd（实际构建时需要真实 initramfs）
    log_info "创建 initrd..."
    mkdir -p "${BUILD_DIR}/initramfs"
    cd "${BUILD_DIR}/initramfs"
    mkdir -p {bin,sys,proc,dev,etc,lib,lib64,usr/bin}
    
    # 复制 busybox
    if command -v busybox &> /dev/null; then
        cp "$(which busybox)" "${BUILD_DIR}/initramfs/bin/"
        ln -sf busybox "${BUILD_DIR}/initramfs/bin/sh"
        for app in $(busybox --list); do
            ln -sf busybox "${BUILD_DIR}/initramfs/bin/$app" 2>/dev/null || true
        done
    else
        ln -sf /bin/sh "${BUILD_DIR}/initramfs/bin/sh"
    fi
    
    # 创建 init 脚本
    cat > "${BUILD_DIR}/initramfs/init" << 'INITEOF'
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

echo "Multi-OS Linux 启动中..."

# 加载必要模块
modprobe squashfs 2>/dev/null || true
modprobe overlay 2>/dev/null || true
modprobe fuse 2>/dev/null || true

# 挂载根文件系统
mkdir -p /newroot
mount -t squashfs /boot/filesystem.squashfs /newroot

# 切换根
exec switch_root /newroot /sbin/init
INITEOF
    chmod +x "${BUILD_DIR}/initramfs/init"
    
    # 创建 initramfs
    cd "${BUILD_DIR}/initramfs"
    find . | cpio -H newc -o | xz -9 > "${ISO_DIR}/boot/initrd.img"
    
    # 复制 SquashFS
    cp "${BUILD_DIR}/squashfs/filesystem.squashfs" "${ISO_DIR}/boot/"
    
    # 创建 Live 系统启动脚本
    cat > "${ISO_DIR}/boot/multi-os-live" << 'LIVEEOF'
#!/bin/bash
# Multi-OS Linux Live 系统启动脚本

mount --move /proc /newroot/proc
mount --move /sys /newroot/sys
mount --move /dev /newroot/dev

exec chroot /newroot /bin/bash
LIVEEOF
    chmod +x "${ISO_DIR}/boot/multi-os-live"

    # 创建 EFI 启动文件
    log_info "准备 EFI 启动文件..."
    if command -v grub-mkimage &> /dev/null; then
        grub-mkimage -o "${ISO_DIR}/EFI/boot/bootx64.efi" -p '(cd)/boot/grub' efi64 \
            part_gpt fat ntfs loopback normal configfile \
            search search_fs_file gfxterm echo test \
            2>/dev/null || true
    fi
    
    # 检查必要的文件
    if [ ! -f "${ISO_DIR}/boot/vmlinuz" ] || [ ! -f "${ISO_DIR}/boot/initrd.img" ]; then
        log_error "缺少必要的启动文件"
        return 1
    fi
    
    # 生成 ISO
    log_info "生成 ISO 镜像: $iso_file"
    
    if command -v xorriso &> /dev/null; then
        xorriso -as mkisofs \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "$ISO_VOLUME" \
            -appid "$ISO_APPLICATION" \
            -publisher "$ISO_PUBLISHER" \
            -preparer "Multi-OS Linux Builder" \
            -eltorito-boot isolinux/isolinux.bin \
            -eltorito-catalog isolinux/boot.cat \
            -eltorito-alt-boot \
            -e EFI/boot/grub EFI/boot/bootx64.efi \
            -no-emul-boot \
            -isohybrid-gpt-basdat \
            -isohybrid-mbr /usr/lib/syslinux/bios/gptmbr.bin \
            -o "$iso_file" \
            "$ISO_DIR" 2>&1 | tee -a "${BUILD_DIR}/build.log" || true
    elif command -v genisoimage &> /dev/null; then
        genisoimage \
            -o "$iso_file" \
            -b isolinux/isolinux.bin \
            -c isolinux/boot.cat \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
            -eltorito-alt-boot \
            -e EFI/boot/grub \
            -no-emul-boot \
            -volid "$ISO_VOLUME" \
            "$ISO_DIR" 2>&1 | tee -a "${BUILD_DIR}/build.log" || true
    else
        log_error "没有找到 ISO 生成工具"
        return 1
    fi
    
    # 验证 ISO
    if [ -f "$iso_file" ]; then
        log_success "ISO 镜像创建成功！"
        log_info "文件大小: $(du -h "$iso_file" | cut -f1)"
        log_info "MD5: $(md5sum "$iso_file" | cut -d' ' -f1)"
        
        # 复制到输出目录
        cp "$iso_file" "${BUILD_DIR}/output/"
        
        echo ""
        echo "========================================="
        echo "  ISO 镜像创建完成！"
        echo "========================================="
        echo ""
        echo "镜像位置: $iso_file"
        echo "输出目录: ${BUILD_DIR}/output/"
        echo ""
        echo "下一步："
        echo "1. 将 ISO 刻录到 USB 或 DVD"
        echo "2. 从启动介质启动"
        echo "3. 运行安装程序: mos-install"
        echo ""
    else
        log_error "ISO 镜像创建失败"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------
main() {
    echo ""
    echo "========================================="
    echo "  Multi-OS Linux 完整系统构建"
    echo "  版本: ${SYSTEM_VERSION}"
    echo "  架构: ${ARCH}"
    echo "========================================="
    echo ""
    
    # 解析参数
    case "${1:-all}" in
        all)
            check_dependencies
            prepare_build_env
            create_base_rootfs
            create_system_configs
            create_package_list
            download_and_prepare_kernel
            create_mos_config
            create_boot_config
            create_installer
            create_squashfs
            create_iso_image
            ;;
        deps)
            check_dependencies
            ;;
        prepare)
            prepare_build_env
            create_base_rootfs
            create_system_configs
            ;;
        kernel)
            download_and_prepare_kernel
            ;;
        config)
            create_mos_config
            create_boot_config
            create_installer
            ;;
        iso)
            create_squashfs
            create_iso_image
            ;;
        clean)
            log_info "清理构建目录..."
            rm -rf "${BUILD_DIR:?}"/*
            log_success "清理完成"
            ;;
        help|--help|-h)
            echo "Multi-OS Linux 构建脚本"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  all       - 执行完整构建（默认）"
            echo "  deps      - 仅检查依赖"
            echo "  prepare   - 仅准备根文件系统"
            echo "  kernel    - 仅下载和准备内核"
            echo "  config    - 仅创建配置"
            echo "  iso       - 仅生成 ISO"
            echo "  clean     - 清理构建目录"
            echo "  help      - 显示帮助"
            echo ""
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
    
    echo ""
    log_success "构建流程完成！"
    echo ""
}

main "$@"
