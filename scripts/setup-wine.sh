#!/bin/bash
#===============================================================================
#
#  Multi-OS Linux - Wine 环境设置脚本
#  配置 Wine 环境以支持 Windows 应用（如 Steam、Wallpaper Engine）
#
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# 全局配置
#-------------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly WINE_CONFIG_DIR="${PROJECT_ROOT}/config/wine"
readonly WINEPREFIX="${HOME}/.wine-multi-os"

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

check_wine() {
    if ! command -v wine &> /dev/null; then
        log_error "Wine 未安装"
        echo "请先安装 Wine: sudo apt-get install wine wine64 winetricks"
        return 1
    fi
    return 0
}

#-------------------------------------------------------------------------------
# 初始化 Wine 前缀
#-------------------------------------------------------------------------------
init_wine_prefix() {
    log_info "初始化 Wine 前缀..."
    
    export WINEPREFIX="$WINEPREFIX"
    export WINEARCH="win64"
    
    if [ ! -d "$WINEPREFIX" ]; then
        log_info "创建新的 Wine 前缀..."
        wineboot --init
        sleep 5
    else
        log_info "Wine 前缀已存在，跳过初始化"
    fi
    
    log_success "Wine 前缀就绪"
}

#-------------------------------------------------------------------------------
# 应用注册表配置
#-------------------------------------------------------------------------------
apply_registry_configs() {
    log_info "应用 Wine 注册表配置..."
    
    export WINEPREFIX="$WINEPREFIX"
    
    local reg_files=(
        "${WINE_CONFIG_DIR}/audio.reg"
        "${WINE_CONFIG_DIR}/desktop.reg"
        "${WINE_CONFIG_DIR}/wallpaper_engine.reg"
    )
    
    for reg_file in "${reg_files[@]}"; do
        if [ -f "$reg_file" ]; then
            log_info "应用: $(basename "$reg_file")"
            wine regedit "$reg_file" 2>/dev/null || true
        fi
    done
    
    log_success "注册表配置应用完成"
}

#-------------------------------------------------------------------------------
# 创建必要的目录
#-------------------------------------------------------------------------------
create_directories() {
    log_info "创建必要的目录..."
    
    local wine_dosdevices="${WINEPREFIX}/dosdevices"
    local wallpapers_dir="${WINEPREFIX}/drive_c/wallpapers"
    
    mkdir -p "$wine_dosdevices"
    mkdir -p "$wallpapers_dir"
    
    # 创建示例壁纸
    if [ ! -f "${wallpapers_dir}/default.jpg" ]; then
        # 创建一个简单的占位壁纸（纯色）
        convert -size 1920x1080 xc:#2c3e50 "${wallpapers_dir}/default.jpg" 2>/dev/null || true
    fi
    
    log_success "目录创建完成"
}

#-------------------------------------------------------------------------------
# 安装必要的组件
#-------------------------------------------------------------------------------
install_components() {
    log_info "安装 Wine 组件（可选，需要 winetricks）..."
    
    if command -v winetricks &> /dev/null; then
        export WINEPREFIX="$WINEPREFIX"
        export WINEARCH="win64"
        
        # 静默安装常用组件
        winetricks -q corefonts 2>/dev/null || true
        winetricks -q d3dx9 2>/dev/null || true
        winetricks -q dotnet48 2>/dev/null || true
    else
        log_warning "winetricks 未找到，跳过组件安装"
    fi
}

#-------------------------------------------------------------------------------
# 创建启动脚本
#-------------------------------------------------------------------------------
create_launch_scripts() {
    log_info "创建启动脚本..."
    
    # Steam 启动脚本
    cat > "${PROJECT_ROOT}/scripts/launch-steam.sh" << 'EOF'
#!/bin/bash
# Multi-OS Linux - Steam 启动脚本

export WINEPREFIX="${HOME}/.wine-multi-os"
export WINEARCH="win64"
export WINEDLLOVERRIDES="mscoree,mshtml="

if [ ! -d "$WINEPREFIX" ]; then
    echo "Wine 前缀未设置，请先运行: ./setup-wine.sh"
    exit 1
fi

# 下载 Steam 安装程序（如果需要）
STEAM_INSTALLER="${WINEPREFIX}/drive_c/SteamSetup.exe"
if [ ! -f "$STEAM_INSTALLER" ]; then
    echo "下载 Steam 安装程序..."
    wget -c "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe" -O "$STEAM_INSTALLER"
    echo "安装 Steam..."
    wine "$STEAM_INSTALLER"
fi

# 启动 Steam
STEAM_PATH="${WINEPREFIX}/drive_c/Program Files (x86)/Steam/Steam.exe"
if [ -f "$STEAM_PATH" ]; then
    echo "启动 Steam..."
    wine "$STEAM_PATH"
else
    echo "Steam 未找到，请先安装"
    echo "运行: wine $STEAM_INSTALLER"
fi
EOF

    chmod +x "${PROJECT_ROOT}/scripts/launch-steam.sh"
    
    log_success "启动脚本创建完成"
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------
main() {
    log_info "========================================="
    log_info "  Multi-OS Linux Wine 环境设置"
    log_info "========================================="
    echo ""
    
    if ! check_wine; then
        exit 1
    fi
    
    init_wine_prefix
    create_directories
    apply_registry_configs
    create_launch_scripts
    
    echo ""
    log_success "========================================="
    log_success "  Wine 环境设置完成！"
    log_success "========================================="
    echo ""
    echo "Wine 前缀: $WINEPREFIX"
    echo "启动 Steam: ./scripts/launch-steam.sh"
    echo ""
}

main "$@"
