#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux - 完整内核构建脚本
#  下载、配置、编译和安装优化内核
#
#===============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly KERNEL_VERSION="6.8.12"
readonly KERNEL_SOURCE="${PROJECT_ROOT}/sources/linux-${KERNEL_VERSION}"
readonly BUILD_DIR="${PROJECT_ROOT}/build/kernel"

# 颜色定义
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_NC='\033[0m'

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $1"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查构建依赖..."
    
    local deps=(
        "gcc"
        "make"
        "bc"
        "libelf-dev"
        "libssl-dev"
        "flex"
        "bison"
        "xz-utils"
        "cpio"
    )
    
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_warning "缺少依赖: ${missing[*]}"
        log_info "安装命令: sudo apt-get install ${missing[*]}"
        return 1
    fi
    
    log_success "所有依赖已满足"
    return 0
}

# 下载内核
download_kernel() {
    log_info "检查内核源码..."
    
    local kernel_tarball="${PROJECT_ROOT}/sources/linux-${KERNEL_VERSION}.tar.xz"
    
    if [ -f "$kernel_tarball" ]; then
        log_info "内核源码已存在: $kernel_tarball"
        log_info "文件大小: $(du -h "$kernel_tarball" | cut -f1)"
    else
        log_info "下载 Linux 内核 ${KERNEL_VERSION}..."
        wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
            -O "$kernel_tarball"
        log_success "内核下载完成"
    fi
}

# 解压内核
extract_kernel() {
    log_info "解压内核源码..."
    
    if [ -d "$KERNEL_SOURCE" ]; then
        log_warning "内核源码已解压，跳过"
        return 0
    fi
    
    cd "${PROJECT_ROOT}/sources"
    tar -xf "linux-${KERNEL_VERSION}.tar.xz"
    log_success "内核解压完成"
}

# 配置内核
configure_kernel() {
    log_info "配置内核..."
    
    cd "$KERNEL_SOURCE"
    
    # 创建构建目录
    mkdir -p "$BUILD_DIR"
    
    # 应用优化配置
    if [ -f "${PROJECT_ROOT}/config/kernel/.config" ]; then
        log_info "应用 Multi-OS 优化配置..."
        cp "${PROJECT_ROOT}/config/kernel/.config" .config
    else
        log_info "使用默认配置..."
        make defconfig
    fi
    
    # 运行配置（交互式，可选）
    # make menuconfig
    
    log_success "内核配置完成"
}

# 编译内核
compile_kernel() {
    log_info "编译内核 (这可能需要很长时间)..."
    log_info "CPU 核心数: $(nproc)"
    
    cd "$KERNEL_SOURCE"
    
    # 编译内核
    make -j"$(nproc)" 2>&1 | tee "${BUILD_DIR}/build.log"
    
    # 编译模块
    log_info "编译内核模块..."
    make modules -j"$(nproc)" 2>&1 | tee -a "${BUILD_DIR}/build.log"
    
    log_success "内核编译完成"
}

# 安装内核
install_kernel() {
    log_info "安装内核..."
    
    cd "$KERNEL_SOURCE"
    
    # 安装内核模块
    log_info "安装内核模块..."
    sudo make modules_install
    
    # 安装内核
    log_info "安装内核镜像..."
    sudo make install
    
    # 更新 GRUB
    log_info "更新引导加载器..."
    sudo update-grub
    
    log_success "内核安装完成"
}

# 创建 initramfs
create_initramfs() {
    log_info "创建 initramfs..."
    
    sudo mkinitramfs -o /boot/initrd.img-"${KERNEL_VERSION}"-"$(uname -m)" "${KERNEL_VERSION}"
    
    log_success "initramfs 创建完成"
}

# 清理
clean_kernel() {
    log_info "清理构建..."
    
    cd "$KERNEL_SOURCE"
    make clean
    make mrproper
    
    log_success "清理完成"
}

# 完整构建流程
full_build() {
    echo "========================================="
    echo "  Multi-OS Linux 内核完整构建"
    echo "  版本: ${KERNEL_VERSION}"
    echo "========================================="
    echo ""
    
    check_dependencies || {
        log_warning "依赖检查未通过，继续但可能失败"
    }
    
    download_kernel
    extract_kernel
    configure_kernel
    
    echo ""
    log_warning "即将开始编译内核，这可能需要 30-60 分钟或更长时间"
    read -p "是否继续编译? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        log_info "已取消编译"
        log_info "下一步: make -j\$(nproc) 手动编译"
        return 0
    fi
    
    compile_kernel
    
    echo ""
    log_warning "是否安装内核? (需要 root 权限)"
    read -p "是否安装? (y/n): " install_confirm
    
    if [ "$install_confirm" = "y" ]; then
        install_kernel
        create_initramfs
        
        echo ""
        log_success "========================================="
        log_success "  内核构建和安装完成！"
        log_success "========================================="
        echo ""
        echo "请重启系统以使用新内核"
        echo "在 GRUB 中选择: Multi-OS Linux"
    else
        log_info "已跳过安装"
        log_info "内核镜像位置: $KERNEL_SOURCE/arch/x86/boot/bzImage"
        log_info "构建日志: ${BUILD_DIR}/build.log"
    fi
}

# 显示帮助
show_help() {
    cat << 'EOF'
Multi-OS Linux 内核构建脚本

用法: ./build-optimized-kernel.sh [选项]

选项:
  all         - 执行完整构建（下载、配置、编译、安装）
  download    - 仅下载内核源码
  extract     - 仅解压内核源码
  configure   - 仅配置内核
  compile     - 仅编译内核
  install     - 仅安装内核
  clean       - 清理构建
  help        - 显示此帮助

示例:
  ./build-optimized-kernel.sh all      # 完整构建
  ./build-optimized-kernel.sh compile   # 仅编译

注意:
  - 完整编译需要 4GB+ 磁盘空间
  - 编译时间取决于硬件，通常 30-60 分钟
  - 安装需要 root 权限

更多信息请查看:
  - config/kernel/.config          - 内核配置
  - patches/KERNEL_PATCHES_INFO.md - 补丁说明
EOF
}

# 主函数
main() {
    case "${1:-all}" in
        all)
            full_build
            ;;
        download)
            download_kernel
            ;;
        extract)
            extract_kernel
            ;;
        configure)
            configure_kernel
            ;;
        compile)
            compile_kernel
            ;;
        install)
            install_kernel
            create_initramfs
            ;;
        clean)
            clean_kernel
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
