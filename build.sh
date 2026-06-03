#!/bin/bash

set -e

PROJECT_ROOT="/workspace/multi-os-compat"
SOURCES_DIR="$PROJECT_ROOT/sources"
BUILD_DIR="$PROJECT_ROOT/build"
LOG_FILE="$PROJECT_ROOT/build.log"

mkdir -p "$SOURCES_DIR" "$BUILD_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_download() {
    local url=$1
    local output=$2
    if [ -f "$output" ]; then
        log "✓ $output 已存在，跳过下载"
        return 0
    fi
    return 1
}

download_linux_kernel() {
    log "步骤1: 下载Linux内核"
    local kernel_file="$SOURCES_DIR/linux-6.8.12.tar.xz"
    
    if ! check_download "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.8.12.tar.xz" "$kernel_file"; then
        wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.8.12.tar.xz" \
            -O "$kernel_file" --progress=bar:force 2>&1 | tee -a "$LOG_FILE"
    fi
}

download_wine() {
    log "步骤2: 下载Wine源代码"
    local wine_dir="$SOURCES_DIR/wine"
    
    if [ ! -d "$wine_dir" ]; then
        git clone --depth 1 --branch wine-9.0 https://github.com/wine-mirror/wine.git "$wine_dir" 2>&1 | tee -a "$LOG_FILE"
    else
        log "Wine目录已存在"
    fi
}

download_darling() {
    log "步骤3: 下载Darling macOS兼容层"
    local darling_dir="$SOURCES_DIR/darling"
    
    if [ ! -d "$darling_dir" ]; then
        git clone --depth 1 https://github.com/darlinghq/darling.git "$darling_dir" 2>&1 | tee -a "$LOG_FILE"
    else
        log "Darling目录已存在"
    fi
}

download_lfs_packages() {
    log "步骤4: 下载LFS构建包"
    local lfs_dir="$SOURCES_DIR/lfs"
    mkdir -p "$lfs_dir"
    
    cd "$lfs_dir"
    wget -c -r -np -nH --cut-dirs=2 \
        https://www.linuxfromscratch.org/lfs/downloads/12.3/wget-list_sysv 2>&1 | tee -a "$LOG_FILE" || true
    
    wget --input-file=wget-list_sysv --continue --directory-prefix="$lfs_dir" 2>&1 | tail -20 | tee -a "$LOG_FILE" || true
}

check_dependencies() {
    log "检查构建依赖..."
    
    local deps=("gcc" "g++" "make" "cmake" "git" "wget" "flex" "bison" "texinfo")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log "警告: 缺少以下依赖: ${missing[*]}"
        log "请运行: sudo apt-get install ${missing[*]}"
    else
        log "✓ 所有依赖已满足"
    fi
}

extract_sources() {
    log "步骤5: 提取源代码"
    
    cd "$SOURCES_DIR"
    
    if [ -f "linux-6.8.12.tar.xz" ]; then
        tar -xf linux-6.8.12.tar.xz
        log "✓ Linux内核已提取"
    fi
}

build_tools() {
    log "步骤6: 构建交叉编译工具链"
    
    cd "$BUILD_DIR"
    
    mkdir -p cross-tools
    cd cross-tools
    
    log "配置binutils..."
    "$SOURCES_DIR"/lfs/binutils-2.42/configure --prefix=/usr/local \
        --with-sysroot=/mnt/lfs \
        --target=$LFS_TGT 2>&1 | tee -a "$LOG_FILE" || true
}

main() {
    log "========================================="
    log "多平台兼容系统构建脚本"
    log "========================================="
    
    check_dependencies
    download_linux_kernel
    download_wine
    download_darling
    download_lfs_packages
    extract_sources
    
    log "========================================="
    log "下载完成！"
    log "下一步：请阅读 docs/PROJECT_PLAN.md"
    log "========================================="
}

main "$@"
