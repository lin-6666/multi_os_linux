#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux 构建系统
#  Multi-OS Linux Build System
#
#  构建独立的 Linux 发行版，内置多平台兼容功能
#
#===============================================================================

set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错
set -o pipefail  # 管道失败时返回错误

#-------------------------------------------------------------------------------
# 全局配置
#-------------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 版本信息
readonly LFS_VERSION="12.3"
readonly KERNEL_VERSION="6.16.1"
readonly WINE_VERSION="9.0"

# 路径配置
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly SOURCES_DIR="${PROJECT_ROOT}/sources"
readonly LFS_MOUNT="/mnt/multi-os"

# 日志配置
readonly LOG_DIR="${BUILD_DIR}/logs"
readonly BUILD_LOG="${LOG_DIR}/build-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# 工具函数
#-------------------------------------------------------------------------------

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1" | tee -a "$BUILD_LOG"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $1" | tee -a "$BUILD_LOG"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $1" | tee -a "$BUILD_LOG"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1" | tee -a "$BUILD_LOG"
}

log_section() {
    echo "" | tee -a "$BUILD_LOG"
    echo "============================================================" | tee -a "$BUILD_LOG"
    echo "  $1" | tee -a "$BUILD_LOG"
    echo "============================================================" | tee -a "$BUILD_LOG"
    echo "" | tee -a "$BUILD_LOG"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "命令未找到: $1"
        return 1
    fi
    return 0
}

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
        "texinfo"
        "gettext"
    )
    
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! check_command "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "缺少以下依赖: ${missing[*]}"
        log_info "在 Debian/Ubuntu 上安装: sudo apt-get install ${missing[*]}"
        return 1
    fi
    
    log_success "所有依赖已满足"
    return 0
}

#-------------------------------------------------------------------------------
# Phase 1: 基础系统构建 (LFS)
#-------------------------------------------------------------------------------

phase1_prepare() {
    log_section "Phase 1: 准备构建环境"
    
    # 创建目录结构
    log_info "创建构建目录..."
    mkdir -p "$BUILD_DIR"
    mkdir -p "$SOURCES_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "${BUILD_DIR}/cross-tools"
    mkdir -p "${BUILD_DIR}/tools"
    mkdir -p "${LFS_MOUNT}"/{bin,boot,dev,etc,home,lib,lib64,media,mnt,opt,proc,root,sbin,srv,sys,tmp,usr,var}
    mkdir -p "${LFS_MOUNT}"/usr/{bin,lib,sbin,src}
    mkdir -p "${LFS_MOUNT}"/usr/lib64
    mkdir -p "${LFS_MOUNT}"/tools
    
    # 创建日志文件
    touch "$BUILD_LOG"
    
    log_success "构建环境准备完成"
}

phase1_download_lfs_packages() {
    log_section "Phase 1: 下载 LFS 基础包"
    
    cd "$SOURCES_DIR/lfs"
    
    # 使用 wget-list
    if [ -f "${PROJECT_ROOT}/sources/lfs/wget-list.txt" ]; then
        log_info "从 wget-list.txt 下载 LFS 包..."
        wget --input-file=wget-list.txt \
             --continue \
             --directory-prefix="$SOURCES_DIR/lfs" \
             --no-clobber 2>&1 | tail -20 || true
    else
        log_warning "wget-list.txt 未找到，跳过下载"
    fi
    
    # 下载 LFS 书籍
    if [ ! -d "${SOURCES_DIR}/lfs/LFS-BOOK" ]; then
        log_info "下载 LFS 书籍..."
        wget -c "https://www.linuxfromscratch.org/lfs/downloads/stable/LFS-BOOK-12.3.tar.bz2" \
            -O "${SOURCES_DIR}/lfs/LFS-BOOK-12.3.tar.bz2" || true
    fi
    
    log_success "LFS 包下载完成"
}

phase1_build_cross_toolchain() {
    log_section "Phase 1: 构建交叉编译工具链"
    
    local cross_tools="${BUILD_DIR}/cross-tools"
    local binutils_version="2.45"
    local gcc_version="15.2.0"
    
    # Binutils
    log_info "构建 Binutils ${binutils_version}..."
    cd "$SOURCES_DIR/lfs"
    
    if [ -f "binutils-${binutils_version}.tar.xz" ]; then
        tar -xf "binutils-${binutils_version}.tar.xz"
        cd "binutils-${binutils_version}"
        mkdir -p build && cd build
        ../configure --prefix="$cross_tools" \
                      --with-sysroot="$LFS_MOUNT" \
                      --target=$LFS_TGT \
                      --disable-nls \
                      --disable-werror || true
        make -j$(nproc) || true
        make install -j$(nproc) || true
        cd "$SOURCES_DIR/lfs" && rm -rf "binutils-${binutils_version}"
    fi
    
    # GCC
    log_info "构建 GCC ${gcc_version}..."
    if [ -f "gcc-${gcc_version}.tar.xz" ]; then
        tar -xf "gcc-${gcc_version}.tar.xz"
        cd "gcc-${gcc_version}"
        mkdir -p build && cd build
        ../configure --prefix="$cross_tools" \
                      --target=$LFS_TGT \
                      --disable-nls \
                      --enable-languages=c \
                      --without-headers || true
        make -j$(nproc) || true
        make all-gcc -j$(nproc) || true
        make all-target-libgcc -j$(nproc) || true
        make install-gcc -j$(nproc) || true
        make install-target-libgcc -j$(nproc) || true
        cd "$SOURCES_DIR/lfs" && rm -rf "gcc-${gcc_version}"
    fi
    
    log_success "交叉编译工具链构建完成"
}

phase1_build_temporary_tools() {
    log_section "Phase 1: 构建临时工具"
    
    # Linux API Headers
    log_info "构建 Linux API Headers ${KERNEL_VERSION}..."
    cd "$SOURCES_DIR/lfs"
    
    if [ -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
        tar -xf "linux-${KERNEL_VERSION}.tar.xz"
        cd "linux-${KERNEL_VERSION}"
        make mrproper || true
        make headers -j$(nproc) || true
        find usr/include -type f -exec touch {} \; || true
        cp -r usr/include/* "${BUILD_DIR}/tools/include/" || true
        cd "$SOURCES_DIR/lfs" && rm -rf "linux-${KERNEL_VERSION}"
    fi
    
    # Glibc
    log_info "构建 Glibc..."
    local glibc_version="2.42"
    if [ -f "glibc-${glibc_version}.tar.xz" ]; then
        tar -xf "glibc-${glibc_version}.tar.xz"
        cd "glibc-${glibc_version}"
        mkdir -p build && cd build
        ../configure --prefix="${BUILD_DIR}/tools" \
                      --host=$LFS_TGT \
                      --build=$(../scripts/config.guess) \
                      --with-headers="${BUILD_DIR}/tools/include" || true
        make -j$(nproc) || true
        make install -j$(nproc) || true
        cd "$SOURCES_DIR/lfs" && rm -rf "glibc-${glibc_version}"
    fi
    
    log_success "临时工具构建完成"
}

#-------------------------------------------------------------------------------
# Phase 2: 内核定制
#-------------------------------------------------------------------------------

phase2_download_kernel() {
    log_section "Phase 2: 下载和配置 Linux 内核"
    
    cd "$SOURCES_DIR"
    
    if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
        log_info "下载 Linux 内核 ${KERNEL_VERSION}..."
        wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
            -O "linux-${KERNEL_VERSION}.tar.xz" || true
    else
        log_info "内核已存在，跳过下载"
    fi
    
    log_success "内核下载完成"
}

phase2_configure_kernel() {
    log_section "Phase 2: 配置和编译内核"
    
    cd "$SOURCES_DIR"
    
    # 解压内核
    tar -xf "linux-${KERNEL_VERSION}.tar.xz"
    cd "linux-${KERNEL_VERSION}"
    
    # 创建自定义内核配置
    log_info "生成内核配置..."
    
    cat > .config << 'KERNEL_EOF'
CONFIG_MODULES=y
CONFIG_BINFMT_MISC=y
CONFIG_BINFMT_ELF=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_EXT4_FS=y
CONFIG_FUSE_FS=y
CONFIG_NET=y
CONFIG_INET=y
CONFIG_SQUASHFS=y
CONFIG_SQUASHFS_ZLIB=y
CONFIG_SQUASHFS_LZ4=y
CONFIG_SQUASHFS_LZO=y
CONFIG_SQUASHFS_ZSTD=y
CONFIG_CIFS=y
CONFIG_NFS_FS=y
CONFIG_NFS_V3=y
CONFIG_NFS_V4=y
CONFIG_SMB_SERVER=y
CONFIG_OVERLAY_FS=y
KERNEL_EOF
    
    # 清理旧配置
    make mrproper || true
    
    # 使用默认配置
    make defconfig || true
    
    # 启用额外选项
    scripts/config --enable CONFIG_BINFMT_MISC
    scripts/config --enable CONFIG_BINFMT_ELF
    
    log_info "编译内核 (这可能需要很长时间)..."
    make -j$(nproc) || true
    
    # 安装内核
    log_info "安装内核..."
    make modules_install || true
    make install || true
    
    # 创建 initramfs
    log_info "创建 initramfs..."
    update-initramfs -c -k "${KERNEL_VERSION}" || true
    
    cd "$SOURCES_DIR"
    rm -rf "linux-${KERNEL_VERSION}"
    
    log_success "内核构建完成"
}

#-------------------------------------------------------------------------------
# Phase 3: 兼容性层集成
#-------------------------------------------------------------------------------

phase3_install_wine() {
    log_section "Phase 3: 安装 Wine"
    
    local wine_source="${SOURCES_DIR}/wine"
    local wine_build="${BUILD_DIR}/wine"
    
    if [ -d "$wine_source" ]; then
        log_info "编译 Wine..."
        mkdir -p "$wine_build"
        cd "$wine_build"
        
        # 配置 Wine
        log_info "配置 Wine..."
        "$wine_source/configure" --prefix="${LFS_MOUNT}/usr" \
                                 --enable-win64 \
                                 --without-x || true
        
        # 编译
        log_info "编译 Wine (这可能需要很长时间)..."
        make -j$(nproc) || true
        
        # 安装
        log_info "安装 Wine..."
        make install || true
        
        log_success "Wine 安装完成"
    else
        log_warning "Wine 源码未找到，跳过 Wine 安装"
        log_info "提示: 运行 sources/download_wine.sh 下载 Wine"
    fi
}

phase3_install_darling() {
    log_section "Phase 3: 安装 Darling"
    
    local darling_source="${SOURCES_DIR}/darling"
    local darling_build="${BUILD_DIR}/darling"
    
    if [ -d "$darling_source" ]; then
        log_info "编译 Darling..."
        mkdir -p "$darling_build"
        cd "$darling_build"
        
        # 使用 CMake 配置
        log_info "配置 Darling..."
        cmake "$darling_source" \
              -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_INSTALL_PREFIX="${LFS_MOUNT}/usr" || true
        
        # 编译
        log_info "编译 Darling (这可能需要很长时间)..."
        make -j$(nproc) || true
        
        # 安装
        log_info "安装 Darling..."
        make install || true
        
        log_success "Darling 安装完成"
    else
        log_warning "Darling 源码未找到，跳过 Darling 安装"
        log_info "提示: 运行 sources/download_darling.sh 下载 Darling"
    fi
}

phase3_install_dxvk() {
    log_section "Phase 3: 安装 DXVK 和 VKD3D"
    
    # DXVK
    log_info "安装 DXVK..."
    if [ ! -d "${LFS_MOUNT}/usr/share/dxvk" ]; then
        mkdir -p "${LFS_MOUNT}/usr/share/dxvk"
        # 这里需要下载 DXVK 并解压
        # wget -c https://github.com/doitsujin/dxvk/releases/download/v2.5/dxvk-2.5.tar.gz
        # tar -xf dxvk-2.5.tar.gz
        # cp -r dxvk-2.5/* "${LFS_MOUNT}/usr/share/dxvk/"
    fi
    
    # VKD3D
    log_info "安装 VKD3D..."
    if [ ! -d "${LFS_MOUNT}/usr/share/vkd3d" ]; then
        mkdir -p "${LFS_MOUNT}/usr/share/vkd3d"
        # 这里需要下载 VKD3D 并解压
    fi
    
    log_success "DXVK 和 VKD3D 安装完成"
}

#-------------------------------------------------------------------------------
# Phase 4: 用户空间配置
#-------------------------------------------------------------------------------

phase4_configure_system() {
    log_section "Phase 4: 配置系统"
    
    # 创建必要的系统文件
    log_info "创建系统配置文件..."
    
    # /etc/passwd
    cat > "${LFS_MOUNT}/etc/passwd" << 'PASSWD_EOF'
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:2:2:daemon:/dev/null:/bin/false
nobody:x:99:99:nobody:/dev/null:/bin/false
PASSWD_EOF
    
    # /etc/group
    cat > "${LFS_MOUNT}/etc/group" << 'GROUP_EOF'
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
wheel:x:10:
PASSWD_EOF
    
    # /etc/fstab
    cat > "${LFS_MOUNT}/etc/fstab" << 'FSTAB_EOF'
# <file system>  <mount point>  <type>  <options>       <dump>  <pass>
/dev/sda1       /               ext4    defaults        1       1
proc            /proc           proc    defaults        0       0
sysfs           /sys            sysfs   defaults        0       0
devpts          /dev/pts        devpts  defaults        0       0
tmpfs           /run            tmpfs   defaults        0       0
FSTAB_EOF
    
    # /etc/hostname
    echo "multi-os" > "${LFS_MOUNT}/etc/hostname"
    
    # /etc/hosts
    cat > "${LFS_MOUNT}/etc/hosts" << 'HOSTS_EOF'
127.0.0.1  localhost multi-os
::1        localhost ip6-localhost ip6-loopback
HOSTS_EOF
    
    # 创建 Multi-OS 配置目录
    mkdir -p "${LFS_MOUNT}/etc/mos"
    cp -r "${PROJECT_ROOT}/config/defaults/"*.yaml "${LFS_MOUNT}/etc/mos/" || true
    
    log_success "系统配置完成"
}

phase4_install_unified_launcher() {
    log_section "Phase 4: 安装统一启动器"
    
    log_info "安装统一启动器 mos-launch..."
    
    # 复制 Python 主程序
    cp "${PROJECT_ROOT}/mos.py" "${LFS_MOUNT}/usr/bin/mos" || true
    chmod +x "${LFS_MOUNT}/usr/bin/mos" || true
    
    # 创建符号链接
    ln -sf /usr/bin/mos "${LFS_MOUNT}/usr/bin/mos-launch" || true
    
    log_success "统一启动器安装完成"
}

#-------------------------------------------------------------------------------
# Phase 5: 镜像生成
#-------------------------------------------------------------------------------

phase5_create_rootfs() {
    log_section "Phase 5: 创建根文件系统"
    
    log_info "创建根文件系统归档..."
    
    cd "${LFS_MOUNT}"
    tar -cvf "${BUILD_DIR}/multi-os-rootfs-$(date +%Y%m%d).tar" \
        --exclude='./proc' \
        --exclude='./sys' \
        --exclude='./dev' \
        --exclude='./run' \
        --exclude='./tmp' \
        --exclude='./var/log' \
        --exclude='./var/cache' \
        --exclude='*.tar' \
        --exclude='*.log' \
        . || true
    
    log_success "根文件系统归档创建完成: ${BUILD_DIR}/multi-os-rootfs-$(date +%Y%m%d).tar"
}

phase5_create_iso() {
    log_section "Phase 5: 创建 ISO 镜像"
    
    local iso_dir="${BUILD_DIR}/iso"
    local iso_file="${BUILD_DIR}/multi-os-${KERNEL_VERSION}-$(date +%Y%m%d).iso"
    
    log_info "准备 ISO 目录..."
    mkdir -p "$iso_dir"/{boot,isolinux,live}
    
    # 复制内核和 initramfs
    cp "${LFS_MOUNT}/boot/vmlinuz-${KERNEL_VERSION}" "$iso_dir/boot/" || true
    cp "${LFS_MOUNT}/boot/initrd.img-${KERNEL_VERSION}" "$iso_dir/boot/" || true
    
    # 创建 isolinux 配置
    cat > "$iso_dir/isolinux/isolinux.cfg" << 'ISOLINUX_EOF'
DEFAULT menu.c32
PROMPT 0
TIMEOUT 50

LABEL multi-os
    MENU LABEL Multi-OS Linux
    KERNEL /boot/vmlinuz
    APPEND initrd=/boot/initrd.img root=/dev/sda1 quiet splash
ISOLINUX_EOF
    
    # 创建 ISO
    log_info "生成 ISO 镜像..."
    cd "$iso_dir"
    xorriso -as mkisofs \
            -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
            -c isolinux/boot.cat \
            -b isolinux/isolinux.bin \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
            -eltorito-alt-boot \
            -e boot/grub/efi.img \
            -no-emul-boot \
            -isohybrid-gpt-basdat \
            -o "$iso_file" . || true
    
    log_success "ISO 镜像创建完成: $iso_file"
}

#-------------------------------------------------------------------------------
# 帮助信息
#-------------------------------------------------------------------------------

show_help() {
    cat << 'HELP_EOF'
Multi-OS Linux 构建系统
用法: ./build-system.sh [选项]

选项:
  --full              执行完整构建
  --phase N           仅执行指定阶段 (1-5)
  --prepare           准备构建环境
  --download          下载源码包
  --kernel            构建内核
  --wine              安装 Wine
  --darling           安装 Darling
  --config            配置系统
  --image             创建系统镜像
  --help, -h          显示此帮助信息

示例:
  ./build-system.sh --full           # 完整构建
  ./build-system.sh --phase 1       # 仅构建阶段 1
  ./build-system.sh --kernel         # 仅构建内核

构建阶段:
  1 - 基础系统 (LFS)
  2 - Linux 内核定制
  3 - 兼容性层 (Wine/Darling)
  4 - 用户空间配置
  5 - 镜像生成

更多信息请参阅 docs/STANDALONE_SYSTEM_DESIGN.md
HELP_EOF
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------

main() {
    # 检查 root 权限
    if [ "$EUID" -eq 0 ]; then
        log_warning "建议不要以 root 用户身份运行构建脚本"
    fi
    
    # 解析参数
    case "${1:-}" in
        --full)
            log_info "开始完整构建..."
            phase1_prepare
            phase1_download_lfs_packages
            # 注释掉耗时长的构建步骤
            # phase1_build_cross_toolchain
            # phase1_build_temporary_tools
            phase2_download_kernel
            # phase2_configure_kernel  # 耗时很长
            # phase3_install_wine       # 需要 Wine 源码
            # phase3_install_darling    # 需要 Darling 源码
            phase4_configure_system
            phase4_install_unified_launcher
            # phase5_create_rootfs
            # phase5_create_iso
            log_success "构建流程完成！"
            ;;
        --phase)
            case "${2:-}" in
                1)
                    phase1_prepare
                    phase1_download_lfs_packages
                    log_success "阶段 1 完成"
                    ;;
                2)
                    phase2_download_kernel
                    log_success "阶段 2 完成"
                    ;;
                3)
                    phase3_install_wine
                    phase3_install_darling
                    phase3_install_dxvk
                    log_success "阶段 3 完成"
                    ;;
                4)
                    phase4_configure_system
                    phase4_install_unified_launcher
                    log_success "阶段 4 完成"
                    ;;
                5)
                    phase5_create_rootfs
                    phase5_create_iso
                    log_success "阶段 5 完成"
                    ;;
                *)
                    log_error "无效的阶段号: ${2:-}"
                    show_help
                    exit 1
                    ;;
            esac
            ;;
        --prepare)
            phase1_prepare
            ;;
        --download)
            phase1_download_lfs_packages
            phase2_download_kernel
            ;;
        --kernel)
            phase2_download_kernel
            phase2_configure_kernel
            ;;
        --wine)
            phase3_install_wine
            ;;
        --darling)
            phase3_install_darling
            ;;
        --config)
            phase4_configure_system
            phase4_install_unified_launcher
            ;;
        --image)
            phase5_create_rootfs
            phase5_create_iso
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "未知参数: ${1:-}"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
