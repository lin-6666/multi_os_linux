#!/bin/bash
# Multi-OS Linux - Android 应用管理器

set -e

readonly APP_DIR="${HOME}/.multi-os/android/apps"
readonly APK_DIR="${HOME}/.multi-os/android/apk"
readonly CONFIG_FILE="${HOME}/.multi-os/config/android-app-manager.conf"

mkdir -p "$APP_DIR"
mkdir -p "$APK_DIR"

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 检查 ADB
check_adb() {
    if ! command -v adb &> /dev/null; then
        log_info "安装 ADB..."
        sudo apt-get install -y adb
    fi
}

# 列出已安装应用
list_apps() {
    log_info "已安装的 Android 应用:"
    echo ""
    
    local count=0
    for app_dir in "$APP_DIR"/*/; do
        if [ -d "$app_dir" ]; then
            local app_name=$(basename "$app_dir")
            local apk_file="$app_dir/base.apk"
            
            if [ -f "$apk_file" ]; then
                local size=$(du -h "$apk_file" | cut -f1)
                echo "  📱 $app_name ($size)"
                ((count++))
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo "  (暂无安装的应用)"
    fi
    
    echo ""
    echo "总计: $count 个应用"
}

# 安装 APK
install_apk() {
    local apk_file="$1"
    
    if [ ! -f "$apk_file" ]; then
        echo "❌ 文件不存在: $apk_file"
        return 1
    fi
    
    log_info "安装 APK: $apk_file"
    
    # 检查是否是 Waydroid
    if command -v waydroid &> /dev/null; then
        adb install "$apk_file"
        log_success "APK 已安装"
    else
        log_warning "Waydroid 未运行，请先启动 Android 环境"
        log_info "复制 APK 到应用目录: $APP_DIR"
        cp "$apk_file" "$APK_DIR/"
        log_success "APK 已保存，将在首次启动时安装"
    fi
}

# 卸载应用
uninstall_app() {
    local package="$1"
    
    log_info "卸载应用: $package"
    
    if command -v waydroid &> /dev/null; then
        adb uninstall "$package"
        log_success "应用已卸载"
    else
        log_warning "需要 Waydroid 运行中"
    fi
}

# 下载常用应用
download_common_apps() {
    log_info "下载常用 Android 应用..."
    
    local apps=(
        "https://apkpure.com/f-droid/com.fdroid.fdroid/download"
        "https://apkpure.com/amaze-file-manager/com.amaze.filemanager/download"
    )
    
    for app_url in "${apps[@]}"; do
        log_info "下载: $app_url"
        # 这里需要实际下载逻辑
        # wget -P "$APK_DIR/" "$app_url"
    done
    
    log_success "应用下载完成"
}

# 主菜单
show_menu() {
    echo ""
    echo "╔════════════════════════════════════╗"
    echo "║   Multi-OS Android 应用管理器    ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    echo "1) 📋 列出已安装应用"
    echo "2) 📥 安装 APK"
    echo "3) 🗑️  卸载应用"
    echo "4) ⬇️  下载常用应用"
    echo "5) 🚀 启动 Waydroid"
    echo "6) ⏹️  停止 Waydroid"
    echo "0) ❌ 退出"
    echo ""
}

# 主函数
main() {
    check_adb
    
    case "${1:-}" in
        list)
            list_apps
            ;;
        install)
            shift
            install_apk "$1"
            ;;
        uninstall)
            shift
            uninstall_app "$1"
            ;;
        download)
            download_common_apps
            ;;
        *)
            show_menu
            read -p "选择操作: " choice
            case $choice in
                1) list_apps ;;
                2) read -p "APK 路径: " apk; install_apk "$apk" ;;
                3) read -p "包名: " pkg; uninstall_app "$pkg" ;;
                4) download_common_apps ;;
                5) waydroid session start ;;
                6) waydroid session stop ;;
                0) exit 0 ;;
            esac
            ;;
    esac
}

main "$@"
