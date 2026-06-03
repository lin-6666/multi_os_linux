#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux - 源码下载脚本
#  Download source packages for Multi-OS Linux
#
#===============================================================================

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly SOURCES_DIR="${PROJECT_ROOT}/sources"
readonly LOG_FILE="${PROJECT_ROOT}/build.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

create_dirs() {
    mkdir -p "$SOURCES_DIR"
    mkdir -p "$SOURCES_DIR/lfs"
    mkdir -p "$SOURCES_DIR/wine"
    mkdir -p "$SOURCES_DIR/darling"
    mkdir -p "$SOURCES_DIR/linux"
}

download_linux_kernel() {
    log_info "下载 Linux 内核..."
    
    local kernel_version="6.16.1"
    local kernel_file="linux-${kernel_version}.tar.xz"
    local kernel_url="https://cdn.kernel.org/pub/linux/kernel/v6.x/${kernel_file}"
    
    cd "$SOURCES_DIR/linux"
    
    if [ -f "$kernel_file" ]; then
        log_info "内核已存在: $kernel_file"
    else
        log_info "下载 Linux 内核 ${kernel_version}..."
        wget -c "$kernel_url" -O "$kernel_file" || {
            log_info "尝试备用 URL..."
            wget -c "https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/${kernel_file}" \
                   -O "$kernel_file" || true
        }
    fi
    
    log_success "Linux 内核下载完成"
}

download_wine() {
    log_info "下载 Wine 源码..."
    
    local wine_version="wine-9.0"
    local wine_url="https://github.com/wine-mirror/wine/archive/refs/tags/${wine_version}.tar.gz"
    
    cd "$SOURCES_DIR/wine"
    
    if [ -d "$wine_version" ]; then
        log_info "Wine 源码已存在: $wine_version"
    else
        log_info "克隆 Wine ${wine_version}..."
        git clone --depth 1 --branch "$wine_version" "$wine_url" "$wine_version" || {
            log_info "尝试从 GitHub 克隆..."
            git clone --depth 1 https://github.com/wine-mirror/wine.git "$wine_version" || true
        }
    fi
    
    log_success "Wine 下载完成"
}

download_darling() {
    log_info "下载 Darling 源码..."
    
    local darling_url="https://github.com/darlinghq/darling.git"
    
    cd "$SOURCES_DIR/darling"
    
    if [ -d "darling" ]; then
        log_info "Darling 源码已存在"
    else
        log_info "克隆 Darling..."
        git clone --depth 1 "$darling_url" darling || true
    fi
    
    log_success "Darling 下载完成"
}

download_lfs_packages() {
    log_info "下载 LFS 构建包..."
    
    cd "$SOURCES_DIR/lfs"
    
    # 检查是否有 wget-list
    if [ -f "wget-list.txt" ]; then
        log_info "从 wget-list.txt 下载包..."
        wget --input-file=wget-list.txt \
             --continue \
             --no-clobber \
             --directory-prefix="$SOURCES_DIR/lfs" 2>&1 | tail -20 || true
    else
        log_info "下载 LFS wget-list..."
        wget -c "https://www.linuxfromscratch.org/lfs/downloads/stable/wget-list-sysv" \
            -O "wget-list.txt" || {
            log_info "尝试备用 URL..."
            wget -c "https://www.linuxfromscratch.org/lfs/downloads/12.3/wget-list_sysv" \
                -O "wget-list.txt" || true
        }
        
        if [ -f "wget-list.txt" ]; then
            log_info "从下载的列表下载包..."
            wget --input-file=wget-list.txt \
                 --continue \
                 --no-clobber \
                 --directory-prefix="$SOURCES_DIR/lfs" 2>&1 | tail -20 || true
        fi
    fi
    
    log_success "LFS 包下载完成"
}

download_dxvk() {
    log_info "下载 DXVK..."
    
    cd "$SOURCES_DIR"
    
    local dxvk_version="2.5.1"
    local dxvk_file="dxvk-${dxvk_version}.tar.gz"
    local dxvk_url="https://github.com/doitsujin/dxvk/releases/download/v${dxvk_version}/${dxvk_file}"
    
    if [ -f "$dxvk_file" ]; then
        log_info "DXVK 已存在: $dxvk_file"
    else
        wget -c "$dxvk_url" -O "$dxvk_file" || true
    fi
    
    log_success "DXVK 下载完成"
}

download_vkd3d() {
    log_info "下载 VKD3D..."
    
    cd "$SOURCES_DIR"
    
    local vkd3d_version="v2.14"
    local vkd3d_file="vkd3d-${vkd3d_version}.tar.gz"
    local vkd3d_url="https://github.com/lutris/vkd3d-proton/releases/download/${vkd3d_version}/${vkd3d_file}"
    
    if [ -f "$vkd3d_file" ]; then
        log_info "VKD3D 已存在: $vkd3d_file"
    else
        wget -c "$vkd3d_url" -O "$vkd3d_file" || true
    fi
    
    log_success "VKD3D 下载完成"
}

show_help() {
    cat << 'EOF'
Multi-OS Linux 源码下载工具

用法: ./download_sources.sh [选项]

选项:
  --all           下载所有源码
  --linux         仅下载 Linux 内核
  --wine          仅下载 Wine
  --darling       仅下载 Darling
  --lfs           仅下载 LFS 包
  --dxvk          仅下载 DXVK 和 VKD3D
  --help, -h      显示帮助

示例:
  ./download_sources.sh --all       # 下载所有
  ./download_sources.sh --linux    # 仅内核
EOF
}

main() {
    echo ""
    echo "========================================"
    echo "  Multi-OS Linux 源码下载"
    echo "========================================"
    echo ""
    
    create_dirs
    
    case "${1:-}" in
        --all)
            download_linux_kernel
            download_wine
            download_darling
            download_lfs_packages
            download_dxvk
            download_vkd3d
            ;;
        --linux)
            download_linux_kernel
            ;;
        --wine)
            download_wine
            ;;
        --darling)
            download_darling
            ;;
        --lfs)
            download_lfs_packages
            ;;
        --dxvk)
            download_dxvk
            download_vkd3d
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_info "使用 --all 下载所有，或使用 --help 查看选项"
            download_linux_kernel
            ;;
    esac
    
    echo ""
    log_success "下载完成！"
    echo ""
}

main "$@"
