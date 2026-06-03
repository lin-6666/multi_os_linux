#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux 快速构建脚本
#  准备构建环境并生成系统文件
#
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# 全局配置
#-------------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$SCRIPT_DIR"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly LOG_DIR="${BUILD_DIR}/logs"

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_NC='\033[0m'

#-------------------------------------------------------------------------------
# 工具函数
#-------------------------------------------------------------------------------
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

log_section() {
    echo ""
    echo "============================================================"
    echo "  $1"
    echo "============================================================"
    echo ""
}

#-------------------------------------------------------------------------------
# 准备目录
#-------------------------------------------------------------------------------
prepare_directories() {
    log_section "准备构建目录"
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "${BUILD_DIR}/rootfs"
    mkdir -p "${BUILD_DIR}/output"
    
    log_success "目录准备完成"
}

#-------------------------------------------------------------------------------
# 检查源码文件
#-------------------------------------------------------------------------------
verify_sources() {
    log_section "检查源码目录"
    
    local sources_dir="${PROJECT_ROOT}/sources"
    
    if [ -d "$sources_dir" ]; then
        log_success "源码目录已存在"
        ls -la "$sources_dir"
    else
        log_warning "源码目录不存在，将创建基本结构"
        mkdir -p "$sources_dir"/{lfs,wine,darling}
    fi
}

#-------------------------------------------------------------------------------
# 生成系统文档
#-------------------------------------------------------------------------------
generate_system_docs() {
    log_section "生成系统文档"
    
    local docs_dir="${BUILD_DIR}/docs"
    mkdir -p "$docs_dir"
    
    # 创建 README
    cat > "${docs_dir}/README.txt" << 'EOF'
================================================================================
  Multi-OS Linux - 多平台兼容 Linux 系统
================================================================================

概述:
  - 基础系统，集成 Windows/macOS/Android 应用支持
  - 低功耗优化内核
  - 统一的应用启动器

主要特性:
  - Wine: Windows 兼容层
  - Darling: macOS 兼容层
  - Waydroid: Android 兼容层
  - 低功耗内核配置
  - 电源管理优化

快速开始:
  1. 安装依赖:
     sudo apt-get update
     sudo apt-get install wine wine64 winetricks git wget

  2. 设置 Wine 环境:
     ./scripts/setup-wine.sh

  3. 启动 Steam/安装 Wallpaper Engine:
     ./scripts/launch-steam.sh

文件结构:
  build/          - 构建输出目录
  config/        - 配置文件
    wine/      - Wine 配置
    android/   - Android 配置
  docs/         - 文档
  scripts/      - 脚本文件
  sources/      - 源码目录
EOF
    
    log_success "系统文档生成完成"
}

#-------------------------------------------------------------------------------
# 创建配置包
#-------------------------------------------------------------------------------
create_config_package() {
    log_section "创建配置包"
    
    local config_package="${BUILD_DIR}/multi-os-config-$(date +%Y%m%d).tar.gz"
    
    cd "$PROJECT_ROOT"
    
    tar -czf "$config_package" \
        --exclude='*.pyc' \
        --exclude='__pycache__' \
        config/ \
        scripts/ \
        docs/
    
    log_success "配置包创建完成: $config_package"
}

#-------------------------------------------------------------------------------
# 创建示例系统概要
#-------------------------------------------------------------------------------
generate_system_summary() {
    log_section "生成系统概要"
    
    local summary_file="${BUILD_DIR}/SYSTEM_SUMMARY.md"
    
    cat > "$summary_file" << 'EOF'
# Multi-OS Linux 系统概要
========================

## 系统架构
-----------
- 基础: Linux From Scratch (LFS)
- 内核: 低功耗优化配置
- 架构: x86_64

## 兼容性层
-----------
1. Wine (Windows 兼容)
   - 支持 Steam, Wallpaper Engine
   - DirectX 支持
   - 音频支持 (PulseAudio)

2. Darling (macOS 兼容)
   - Mach 系统调用支持
   - macOS 应用运行

3. Waydroid (Android 兼容)
   - 基于容器化 Android 环境
   - Android 应用支持

## 性能优化
-----------
- 内核优化
- 电源管理
  - 平衡模式
  - 节能模式
  - 高性能模式
  - 游戏模式

## 使用说明
-----------

### 安装 Wine 环境设置
./scripts/setup-wine.sh

### 启动 Steam
./scripts/launch-steam.sh

### 启动 Android 环境
./scripts/start-waydroid.sh

### 统一启动器
mos-launch <应用程序>

EOF
    
    log_success "系统概要生成完成"
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------
main() {
    log_info "========================================="
    log_info "  Multi-OS Linux 快速构建"
    log_info "========================================="
    echo ""
    
    prepare_directories
    verify_sources
    generate_system_docs
    create_config_package
    generate_system_summary
    
    echo ""
    log_success "========================================="
    log_success "  系统构建准备完成！"
    log_success "========================================="
    echo ""
    echo "构建输出目录: $BUILD_DIR"
    echo "配置包: ${BUILD_DIR}/multi-os-config-*.tar.gz"
    echo ""
    echo "下一步:"
    echo "  设置 Wine 环境: ./scripts/setup-wine.sh"
    echo "  查看文档: ${BUILD_DIR}/docs/"
    echo ""
}

main "$@"
