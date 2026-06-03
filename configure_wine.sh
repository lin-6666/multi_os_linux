#!/bin/bash
# Wine高级配置脚本
# 专门针对Windows桌面壁纸、虚拟声卡等实用软件

PROJECT_DIR="/workspace/multi-os-compat"
WINE_CONFIG_DIR="$PROJECT_DIR/config/wine"
WINE_PREFIX="$WINE_CONFIG_DIR/prefix"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 创建配置目录
setup_directories() {
    log_info "创建配置目录..."
    mkdir -p "$WINE_CONFIG_DIR"
    mkdir -p "$WINE_PREFIX/drive_c/wallpapers"
    mkdir -p "$WINE_PREFIX/drive_c/Program Files"
    log_success "配置目录创建完成"
}

# 音频配置（虚拟声卡支持）
setup_audio() {
    log_info "配置音频系统..."
    
    # 设置音频驱动
    cat > "$WINE_CONFIG_DIR/audio_reg.reg" << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Drivers]
"Audio"="pulse,alsa,oss,coreaudio"

[HKEY_CURRENT_USER\Software\Wine\Alsa Driver]
"AutoScanCards"="Y"
"UseDirectHW"="N"
"ForceMixing"="Y"

[HKEY_CURRENT_USER\Software\Wine\Pulse]
"Server"=""
"AutoSpawn"="Y"

[HKEY_CURRENT_USER\Software\Wine\WineCfg]
"Driver"="pulse"

EOF

    log_success "音频配置创建完成"
}

# 桌面壁纸设置
setup_wallpaper_support() {
    log_info "配置桌面壁纸支持..."
    
    cat > "$WINE_CONFIG_DIR/desktop_reg.reg" << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"

[HKEY_CURRENT_USER\Control Panel\Desktop]
"Wallpaper"="C:\\wallpapers\\default.jpg"
"WallpaperStyle"="0"
"TileWallpaper"="0"
"ScreenSaveActive"="1"
"ScreenSaverIsSecure"="0"
"ScreenSaveTimeOut"="900"

[HKEY_CURRENT_USER\Software\Wine\Drivers]
"Graphics"="x11,wayland"

[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"ShowFPS"="N"
"UseXVidMode"="N"
"DesktopDoubleBuffer"="Y"
"VideoMemorySize"="1024"

EOF

    # 创建壁纸管理脚本
    cat > "$WINE_CONFIG_DIR/manage_wallpaper.sh" << 'EOF'
#!/bin/bash
# Windows壁纸管理脚本

WALLPAPER_DIR="$WINEPREFIX/drive_c/wallpapers"

set_wallpaper() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$WALLPAPER_DIR/"
        echo "壁纸已设置"
    else
        echo "文件不存在: $file"
    fi
}

list_wallpapers() {
    ls -1 "$WALLPAPER_DIR"
}

case "$1" in
    set)
        set_wallpaper "$2"
        ;;
    list)
        list_wallpapers
        ;;
    *)
        echo "用法: $0 {set|list}"
        ;;
esac
EOF
    chmod +x "$WINE_CONFIG_DIR/manage_wallpaper.sh"
    
    log_success "桌面壁纸配置完成"
}

# 虚拟声卡配置
setup_virtual_audio() {
    log_info "配置虚拟声卡支持..."
    
    cat > "$WINE_CONFIG_DIR/virtual_audio_reg.reg" << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Drivers32]
"wave"="wdmaud.drv"
"wave1"="wdmaud.drv"
"wave2"="wdmaud.drv"
"wave3"="wdmaud.drv"
"aux"="wdmaud.drv"
"mixer"="wdmaud.drv"
"midi"="wdmaud.drv"
"midimapper"="midimap.dll"
"wavemapper"="msacm32.drv"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceClasses\{53F56307-B6BF-11D0-94F2-00A0C91EFB8B}]
@="Volume"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wdmaud]
"ImagePath"="C:\\windows\\system32\\drivers\\wdmaud.drv"
"Start"=dword:00000003
"Type"=dword:00000001

EOF

    log_success "虚拟声卡配置完成"
}

# 系统托盘支持
setup_systray() {
    log_info "配置系统托盘支持..."
    
    cat > "$WINE_CONFIG_DIR/systray_reg.reg" << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Drivers]
"Shell"="x11,winemenubuilder,explorer"

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"

[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="Default"

[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops\Default]
"Title"="Desktop"
"Size"="1920 1080"
"Managed"="Y"

[HKEY_CURRENT_USER\Software\Wine\WineBrowser]
"Browsers"="xdg-open"

EOF

    log_success "系统托盘配置完成"
}

# 安装Winetricks（可选）
setup_winetricks() {
    log_info "配置Winetricks支持..."
    
    cat > "$WINE_CONFIG_DIR/winetricks_guide.md" << 'EOF'
# Winetricks 使用指南

## 常用组件

### 音频组件
```bash
# 安装音频相关
winetricks directplay directmusic
winetricks dxvk
```

### 桌面组件
```bash
# 安装.NET框架
winetricks dotnet35 dotnet40 dotnet45

# 安装Visual C++运行库
winetricks vcrun2010 vcrun2012 vcrun2013 vcrun2015
```

### 实用软件推荐
- 虚拟声卡：VB-Cable, Voicemeeter
- 壁纸软件：Wallpaper Engine, Wallpaper Master
- 系统工具：Process Explorer, Autoruns

EOF

    log_success "Winetricks配置指南完成"
}

# 主配置函数
main_configure() {
    log_info "开始Wine高级配置..."
    setup_directories
    setup_audio
    setup_wallpaper_support
    setup_virtual_audio
    setup_systray
    setup_winetricks
    log_success "Wine高级配置完成！"
}

# 导出配置
export_config() {
    log_info "导出配置..."
    cat > "$WINE_CONFIG_DIR/apply_config.sh" << 'EOF'
#!/bin/bash
# 应用Wine配置

WINE_CONFIG_DIR="$(dirname "$0")"
WINE_PREFIX="$WINE_CONFIG_DIR/prefix"

export WINEPREFIX="$WINE_PREFIX"

# 导入注册表
echo "导入注册表配置..."
wine regedit "$WINE_CONFIG_DIR/audio_reg.reg"
wine regedit "$WINE_CONFIG_DIR/desktop_reg.reg"
wine regedit "$WINE_CONFIG_DIR/virtual_audio_reg.reg"
wine regedit "$WINE_CONFIG_DIR/systray_reg.reg"

echo "配置导入完成！"
EOF
    chmod +x "$WINE_CONFIG_DIR/apply_config.sh"
    log_success "配置导出脚本创建完成"
}

# 主函数
main() {
    log_info "=== Multi-OS Wine 配置工具 ==="
    main_configure
    export_config
    echo ""
    log_success "配置流程完成！"
    echo "下一步:"
    echo "  1. 进入配置目录: cd $WINE_CONFIG_DIR"
    echo "  2. 运行配置脚本: ./apply_config.sh"
    echo "  3. 查看指南: cat $WINE_CONFIG_DIR/winetricks_guide.md"
}

main
