#!/bin/bash
# Multi-OS Linux - 统一四平台应用启动器
# 同时支持 Linux、Windows、macOS 和 Android 应用

set -e

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CONFIG_DIR="$PROJECT_ROOT/config"

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Emoji
EMOJI_LINUX="🐧"
EMOJI_WINDOWS="🪟"
EMOJI_MACOS="🍎"
EMOJI_ANDROID="📱"
EMOJI_ALL="✨"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测应用类型
detect_app_type() {
    local app_path="$1"
    
    # 检查文件是否存在
    if [ ! -e "$app_path" ]; then
        echo "unknown"
        return
    fi
    
    # 通过扩展名检测
    local ext="${app_path##*.}"
    local filename=$(basename "$app_path" | tr '[:upper:]' '[:lower:]')
    
    case "$ext" in
        exe|msi|bat|cmd)
            echo "windows"
            ;;
        app|dmg|pkg)
            echo "macos"
            ;;
        apk|xapk)
            echo "android"
            ;;
        deb|rpm|snap|AppImage)
            echo "linux-native"
            ;;
    esac
    
    # 检查 ELF/Mach-O/PE 头部
    if [ -f "$app_path" ]; then
        local magic=$(head -c 4 "$app_path" 2>/dev/null | od -A n -t x1)
        
        if [[ "$magic" == *"7f 45 4c 46"* ]]; then
            echo "linux"
        elif [[ "$magic" == *"4d 5a"* ]]; then
            echo "windows"
        elif [[ "$magic" == *"ca fe ba be"* ]] || [[ "$magic" == *"cf fa ed fe"* ]]; then
            echo "macos"
        fi
    fi
    
    # 检查 Android APK
    if [ -f "$app_path" ] && unzip -l "$app_path" 2>/dev/null | grep -q "classes.dex"; then
        echo "android"
    fi
    
    echo "unknown"
}

# 启动 Linux 应用
launch_linux() {
    local app_path="$1"
    shift
    local args="$@"
    
    log_info "启动 Linux 应用: $app_path"
    
    if [ ! -x "$app_path" ]; then
        chmod +x "$app_path"
    fi
    
    "$app_path" $args
}

# 启动 Windows 应用
launch_windows() {
    local app_path="$1"
    shift
    local args="$@"
    
    log_info "启动 Windows 应用 (Wine): $app_path"
    
    if ! command -v wine &> /dev/null; then
        log_error "Wine 未安装"
        log_info "安装 Wine: sudo apt-get install wine"
        return 1
    fi
    
    wine "$app_path" $args
}

# 启动 macOS 应用
launch_macos() {
    local app_path="$1"
    shift
    local args="$@"
    
    log_info "启动 macOS 应用 (Darling): $app_path"
    
    if ! command -v darling &> /dev/null; then
        log_error "Darling 未安装"
        log_info "安装 Darling: 请参考 docs/ 目录中的安装指南"
        return 1
    fi
    
    darling "$app_path" $args
}

# 启动 Android 应用
launch_android() {
    local package="$1"
    shift
    
    log_info "启动 Android 应用 (Waydroid): $package"
    
    if ! command -v waydroid &> /dev/null; then
        log_error "Waydroid 未安装或未启动"
        log_info "启动 Waydroid: waydroid session start"
        return 1
    fi
    
    waydroid launch --package "$package"
}

# 列出应用
list_apps() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         Multi-OS 应用列表                           ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Linux 应用
    echo -e "${EMOJI_LINUX} Linux 应用:"
    if [ -d "$PROJECT_ROOT/opt/apps/linux" ]; then
        ls -1 "$PROJECT_ROOT/opt/apps/linux" 2>/dev/null | sed 's/^/  /'
    else
        echo "  (暂无)"
    fi
    
    # Windows 应用
    echo ""
    echo -e "${EMOJI_WINDOWS} Windows 应用:"
    if [ -d "$PROJECT_ROOT/opt/apps/windows" ]; then
        ls -1 "$PROJECT_ROOT/opt/apps/windows" 2>/dev/null | sed 's/^/  /'
    else
        echo "  (暂无)"
    fi
    
    # macOS 应用
    echo ""
    echo -e "${EMOJI_MACOS} macOS 应用:"
    if [ -d "$PROJECT_ROOT/opt/apps/macos" ]; then
        ls -1 "$PROJECT_ROOT/opt/apps/macos" 2>/dev/null | sed 's/^/  /'
    else
        echo "  (暂无)"
    fi
    
    # Android 应用
    echo ""
    echo -e "${EMOJI_ANDROID} Android 应用:"
    if command -v waydroid &> /dev/null; then
        waydroid app list 2>/dev/null | grep "package:" | head -20 | sed 's/package://' | sed 's/^/  /' || echo "  (运行 waydroid session start 查看)"
    else
        echo "  (未安装 Waydroid)"
    fi
    
    echo ""
}

# 显示帮助
show_help() {
    cat << 'HELP'
╔════════════════════════════════════════════════════════╗
║      Multi-OS Linux - 四平台统一启动器 🌍              ║
╠════════════════════════════════════════════════════════╣
║  支持: Linux 🐧 | Windows 🪟 | macOS 🍎 | Android 📱 ║
╚════════════════════════════════════════════════════════╝

用法: mos-launch [命令] [选项]

命令:
  launch <应用>           启动应用 (自动检测类型)
  launch --linux <应用>   启动 Linux 应用
  launch --windows <应用>  启动 Windows 应用
  launch --macos <应用>   启动 macOS 应用
  launch --android <包名>  启动 Android 应用
  
  list                    列出所有已安装的应用
  status                  显示各平台运行状态
  init [平台]             初始化指定平台的运行环境
  
  help, --help            显示此帮助信息
  version                 显示版本信息

示例:
  mos-launch app.exe                    # 自动检测并启动
  mos-launch --windows game.exe          # 指定 Windows 模式
  mos-launch --android com.example.app  # 启动 Android 应用
  mos-launch list                        # 列出所有应用
  mos-launch init android                # 初始化 Android 环境

支持的文件类型:
  .exe, .msi, .bat       → Windows 应用 (通过 Wine)
  .app, .dmg, .pkg       → macOS 应用 (通过 Darling)
  .apk, .xapk            → Android 应用 (通过 Waydroid)
  ELF 二进制              → Linux 原生应用
  .deb, .rpm, .AppImage  → Linux 安装包

配置目录:
  ~/.multi-os/           → 用户配置
  /etc/multi-os/         → 系统配置

更多信息请访问: docs/QUICK_START.md
HELP
}

# 显示状态
show_status() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         Multi-OS 平台运行状态                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Linux
    echo -ne "${EMOJI_LINUX} Linux: ${GREEN}✓ 运行中${NC}"
    echo "  (原生支持)"
    echo ""
    
    # Wine
    if command -v wine &> /dev/null; then
        local wine_version=$(wine --version 2>/dev/null || echo "未知")
        echo -ne "${EMOJI_WINDOWS} Wine: ${GREEN}✓ 已安装${NC}"
        echo "  (v$wine_version)"
    else
        echo -ne "${EMOJI_WINDOWS} Wine: ${RED}✗ 未安装${NC}"
        echo "  apt-get install wine"
    fi
    echo ""
    
    # Darling
    if command -v darling &> /dev/null; then
        echo -ne "${EMOJI_MACOS} Darling: ${GREEN}✓ 已安装${NC}"
    else
        echo -ne "${EMOJI_MACOS} Darling: ${RED}✗ 未安装${NC}"
        echo "  请参考 docs/DARLING_INSTALL.md"
    fi
    echo ""
    
    # Waydroid
    if command -v waydroid &> /dev/null; then
        if pgrep -f waydroid &> /dev/null; then
            echo -ne "${EMOJI_ANDROID} Waydroid: ${GREEN}✓ 运行中${NC}"
        else
            echo -ne "${EMOJI_ANDROID} Waydroid: ${YELLOW}⚠ 已安装 (未运行)${NC}"
            echo "  waydroid session start"
        fi
    else
        echo -ne "${EMOJI_ANDROID} Waydroid: ${RED}✗ 未安装${NC}"
        echo "  apt-get install waydroid"
    fi
    
    echo ""
}

# 初始化平台环境
init_platform() {
    local platform="$1"
    
    case "$platform" in
        windows|win)
            log_info "初始化 Windows 环境..."
            if [ -f "$PROJECT_ROOT/scripts/configure_wine.sh" ]; then
                bash "$PROJECT_ROOT/scripts/configure_wine.sh"
            else
                log_error "Wine 配置脚本不存在"
            fi
            ;;
        macos|mac)
            log_info "初始化 macOS 环境..."
            log_info "请参考 docs/DARLING_INSTALL.md"
            ;;
        android|arm)
            log_info "初始化 Android 环境..."
            if command -v waydroid &> /dev/null; then
                waydroid init
            else
                log_error "Waydroid 未安装"
            fi
            ;;
        all)
            log_info "初始化所有平台..."
            init_platform windows
            init_platform macos
            init_platform android
            ;;
        *)
            log_error "未知平台: $platform"
            echo "支持的平台: windows, macos, android, all"
            ;;
    esac
}

# 版本信息
show_version() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║      Multi-OS Linux 版本 1.0.0                       ║"
    echo "╠════════════════════════════════════════════════════════╣"
    echo "║  四平台统一启动器                                     ║"
    echo "║  支持: Linux 🐧 Windows 🪟 macOS 🍎 Android 📱       ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
}

# 主函数
main() {
    # 无参数时显示帮助
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    case "${1:-}" in
        launch)
            shift
            local app="$1"
            local type="auto"
            
            # 解析参数
            while [ $# -gt 0 ]; do
                case "$1" in
                    --linux) type="linux" ;;
                    --windows) type="windows" ;;
                    --macos) type="macos" ;;
                    --android) type="android" ;;
                    --*)
                        log_error "未知选项: $1"
                        exit 1
                        ;;
                    *)
                        if [ -z "$app" ]; then
                            app="$1"
                        fi
                        ;;
                esac
                shift
            done
            
            # 检查应用路径
            if [ -z "$app" ]; then
                log_error "请指定应用路径或包名"
                exit 1
            fi
            
            # 根据类型启动
            case "$type" in
                auto)
                    type=$(detect_app_type "$app")
                    log_info "检测到应用类型: $type"
                    ;;
            esac
            
            case "$type" in
                linux)
                    launch_linux "$app" "$@"
                    ;;
                windows)
                    launch_windows "$app" "$@"
                    ;;
                macos)
                    launch_macos "$app" "$@"
                    ;;
                android)
                    launch_android "$app"
                    ;;
                *)
                    log_error "无法处理的应用类型: $type"
                    log_info "文件: $app"
                    exit 1
                    ;;
            esac
            ;;
        
        list)
            list_apps
            ;;
        
        status)
            show_status
            ;;
        
        init)
            shift
            init_platform "${1:-all}"
            ;;
        
        help|--help|-h)
            show_help
            ;;
        
        version|--version|-v)
            show_version
            ;;
        
        *)
            log_error "未知命令: $1"
            echo "运行 'mos-launch help' 查看使用说明"
            exit 1
            ;;
    esac
}

main "$@"
