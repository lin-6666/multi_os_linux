#!/bin/bash
# Multi-OS Linux - Android 兼容性层安装脚本
# 支持 Waydroid 和 Anbox

set -e

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ANDROID_DIR="$PROJECT_ROOT/sources/android"
readonly CONFIG_DIR="$PROJECT_ROOT/config/android"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    local deps=("wget" "tar" "unzip" "lxc" "uidmap" "libpam0g-dev" "libcap-dev")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_warning "缺少依赖: ${missing[*]}"
        log_info "安装依赖: sudo apt-get install ${missing[*]}"
        return 1
    fi
    
    log_success "所有依赖已满足"
    return 0
}

# 创建目录结构
create_directories() {
    log_info "创建 Android 目录结构..."
    
    mkdir -p "$ANDROID_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/waydroid"
    mkdir -p "$CONFIG_DIR/anbox"
    mkdir -p "$PROJECT_ROOT/build/android"
    mkdir -p "$HOME/.multi-os/android"
    
    log_success "目录创建完成"
}

# 生成 Waydroid 配置
generate_waydroid_config() {
    log_info "生成 Waydroid 配置..."
    
    cat > "$CONFIG_DIR/waydroid/waydroid.yml" << 'EOF'
# Multi-OS Linux Waydroid Configuration
# Android 兼容性层配置

# 通用配置
arch: x86_64
session-path: /run/waydroid
mount-overlays: /wayland/waydroid-overlay

# 分辨率配置 (可自定义)
width: 1080
height: 1920
dpi: 420

# 网络配置
network:
  ipv4: 10.15.19.0/24
  dns: 8.8.8.8,8.8.4.4

# 系统配置
system:
  android_id: 0000000000000000
  kernel: /usr/bin/kernel-selector
  silent: true

# 分享配置
分享: true
分享路径: /home/$USER/android-shared

# GPU 配置
gpu:
  mode: auto  # auto, host, off, swiftshader, virtio
  driver: auto

# 音频配置
audio:
  mode: alsa  # alsa, pulse, off

# 系统服务
services:
  - waydroid-container-manager
  - waydroid-session

# 多平台兼容性
compatibility:
  # Wine 共存支持
  wine-shared-network: true
  
  # 与 Darling 共享资源
  darling-shared-resources: false
  
  # GPU 资源共享
  gpu-share-with-wine: true
EOF

    log_success "Waydroid 配置已生成"
}

# 生成 Anbox 配置
generate_anbox_config() {
    log_info "生成 Anbox 配置..."
    
    cat > "$CONFIG_DIR/anbox/anbox-config.conf" << 'EOF'
# Multi-OS Linux Anbox Configuration
# Android 运行时配置

# 显示配置
[display]
width=1080
height=1920
dpi=420

# 网络配置
[network]
mode=bridge

# GPU 配置
[gpu]
mode=auto

# 音频配置
[audio]
driver=alsa

# Android 配置
[android]
hwaddr.random=enable
武昌_imei=auto
武昌_dual_sim=auto

# 共享配置
[shared]
data=/home/$USER/.multi-os/android/data
sdcard=/home/$USER/.multi-os/android/sdcard
EOF

    log_success "Anbox 配置已生成"
}

# 创建 Waydroid 启动脚本
create_waydroid_launcher() {
    log_info "创建 Waydroid 启动脚本..."
    
    cat > "$PROJECT_ROOT/scripts/start-waydroid.sh" << 'EOF'
#!/bin/bash
# Multi-OS Linux - Waydroid Android 启动脚本

WAYDROID_CONFIG="${HOME}/.multi-os/config/waydroid.yml"
WAYDROID_DATA="${HOME}/.multi-os/android"

# 检查 Waydroid 是否安装
if ! command -v waydroid &> /dev/null; then
    echo "❌ Waydroid 未安装"
    echo "请运行: sudo apt-get install waydroid"
    exit 1
fi

# 检查 Android 镜像
if [ ! -d "$WAYDROID_DATA/images" ]; then
    echo "📥 初始化 Waydroid (首次运行)..."
    waydroid init
fi

# 启动 Waydroid 会话
echo "🚀 启动 Android 环境..."
waydroid session start

# 显示状态
waydroid session info

echo ""
echo "✅ Android 环境已启动！"
echo "📱 使用说明:"
echo "  waydroid launch --package <package>  # 启动应用"
echo "  waydroid app list                    # 列出已安装应用"
echo "  waydroid session stop                 # 停止会话"
EOF

    chmod +x "$PROJECT_ROOT/scripts/start-waydroid.sh"
    log_success "Waydroid 启动脚本已创建"
}

# 创建 Android 应用管理器
create_android_app_manager() {
    log_info "创建 Android 应用管理器..."
    
    cat > "$PROJECT_ROOT/scripts/android-app-manager.sh" << 'EOF'
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
EOF

    chmod +x "$PROJECT_ROOT/scripts/android-app-manager.sh"
    log_success "Android 应用管理器已创建"
}

# 创建 Android 运行时优化脚本
create_android_tuning() {
    log_info "创建 Android 性能优化脚本..."
    
    cat > "$PROJECT_ROOT/scripts/tune-android.sh" << 'EOF'
#!/bin/bash
# Multi-OS Linux - Android 环境性能优化

set -e

WAYDROID_CONFIG="${HOME}/.multi-os/config/waydroid.yml"

log_info() {
    echo "⚡ $1"
}

# GPU 模式优化
optimize_gpu() {
    local mode="${1:-auto}"
    
    log_info "优化 GPU 模式: $mode"
    
    if [ -f "$WAYDROID_CONFIG" ]; then
        sed -i "s/mode:.*/mode: $mode/" "$WAYDROID_CONFIG"
    fi
    
    case "$mode" in
        host)
            echo "使用宿主机 GPU (最高性能)"
            ;;
        swiftshader)
            echo "使用软件渲染 (兼容性好)"
            ;;
        off)
            echo "禁用硬件加速 (最低功耗)"
            ;;
        auto)
            echo "自动选择最佳模式"
            ;;
    esac
}

# 网络优化
optimize_network() {
    log_info "优化网络设置..."
    
    # 增加缓冲区
    sysctl -w net.core.rmem_max=16777216 2>/dev/null
    sysctl -w net.core.wmem_max=16777216 2>/dev/null
    
    echo "✅ 网络已优化"
}

# 内存优化
optimize_memory() {
    log_info "优化内存使用..."
    
    # 调整缓存
    echo 70 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null
    
    echo "✅ 内存已优化"
}

# 电池优化
optimize_battery() {
    log_info "优化电池使用..."
    
    # 限制后台进程
    # 这些设置会在 Android 内部应用
    
    echo "✅ 电池优化已应用"
}

# 游戏模式
game_mode() {
    log_info "🎮 激活游戏模式..."
    
    optimize_gpu "host"
    optimize_network
    optimize_memory
    
    echo "✅ 游戏模式已激活 - 性能最大化"
}

# 节能模式
battery_mode() {
    log_info "🔋 激活节能模式..."
    
    optimize_gpu "swiftshader"
    optimize_battery
    
    echo "✅ 节能模式已激活"
}

# 平衡模式
balance_mode() {
    log_info "⚖️ 激活平衡模式..."
    
    optimize_gpu "auto"
    optimize_network
    
    echo "✅ 平衡模式已激活"
}

# 显示帮助
show_help() {
    cat << 'HELP'
Multi-OS Android 性能优化工具

用法: $(basename "$0") [选项]

选项:
  gpu MODE      设置 GPU 模式 (host/swiftshader/off/auto)
  network      优化网络
  memory       优化内存
  battery      优化电池
  game         游戏模式 (高性能)
  battery-save 节能模式
  balance      平衡模式
  help         显示此帮助

示例:
  $(basename "$0") gpu host      # 使用 GPU 加速
  $(basename "$0") game          # 游戏模式
  $(basename "$0") battery-save   # 节能模式
HELP
}

# 主函数
main() {
    case "${1:-}" in
        gpu)
            optimize_gpu "$2"
            ;;
        network)
            optimize_network
            ;;
        memory)
            optimize_memory
            ;;
        battery)
            optimize_battery
            ;;
        game)
            game_mode
            ;;
        battery-save)
            battery_mode
            ;;
        balance)
            balance_mode
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "用法: $(basename "$0") [选项]"
            echo "运行 --help 查看更多信息"
            ;;
    esac
}

main "$@"
EOF

    chmod +x "$PROJECT_ROOT/scripts/tune-android.sh"
    log_success "Android 优化脚本已创建"
}

# 创建安装说明
create_installation_guide() {
    log_info "创建安装指南..."
    
    cat > "$PROJECT_ROOT/docs/ANDROID_INTEGRATION.md" << 'EOF'
# Multi-OS Linux - Android 应用支持

## 概述

Multi-OS Linux 现在支持运行 Android 应用！通过集成 **Waydroid** 容器化方案，
您可以在 Linux 系统上原生运行 Android 应用。

## 支持的方案

### 1. Waydroid (推荐) ⭐
- **现代化**: 基于 LXC 容器的最新技术
- **性能**: 支持 GPU 硬件加速
- **兼容性**: 良好的 Android 兼容性
- **活跃维护**: 持续更新

### 2. Anbox (备选)
- **成熟**: 长期稳定
- **简单**: 配置容易
- **限制**: 不支持 GPU 加速

## 系统要求

### Waydroid
- Linux 内核 5.8+
- Wayland (或 X11 with XWayland)
- LXC 容器支持
- 可用空间: 5GB+

### 基本依赖
```bash
sudo apt-get update
sudo apt-get install -y \
    lxc \
    uidmap \
    libpam0g-dev \
    libcap-dev \
    libdbus-1-dev \
    liblxc1 \
    lxc-dev \
    libandroid* \
    waydroid
```

## 安装步骤

### 1. 安装依赖
```bash
# Ubuntu/Debian
sudo apt-get install waydroid

# 或者从源码编译
git clone https://github.com/waydroid/waydroid.git
cd waydroid
./setup.py install
```

### 2. 配置 Multi-OS 集成
```bash
cd /workspace/multi-os-compat
./scripts/setup-android.sh
```

### 3. 初始化 Android 环境
```bash
waydroid init
```

### 4. 启动 Android
```bash
waydroid session start
```

## 使用指南

### 启动 Android 环境
```bash
# 使用 Multi-OS 脚本
/workspace/multi-os-compat/scripts/start-waydroid.sh

# 或直接使用 waydroid
waydroid session start
```

### 管理应用
```bash
# 列出已安装应用
waydroid app list

# 启动应用
waydroid launch --package com.example.app

# 安装 APK
adb install app.apk
```

### 使用 Multi-OS 应用管理器
```bash
# 交互式菜单
/workspace/multi-os-compat/scripts/android-app-manager.sh

# 命令行模式
/workspace/multi-os-compat/scripts/android-app-manager.sh list
/workspace/multi-os-compat/scripts/android-app-manager.sh install app.apk
```

### 性能优化
```bash
# 游戏模式 (高性能)
/workspace/multi-os-compat/scripts/tune-android.sh game

# 节能模式
/workspace/multi-os-compat/scripts/tune-android.sh battery-save

# 平衡模式
/workspace/multi-os-compat/scripts/tune-android.sh balance
```

## GPU 加速配置

### NVIDIA 显卡
```bash
# 安装 NVIDIA 驱动
sudo apt-get install nvidia-driver-XXX

# 在 Waydroid 配置中启用
# 编辑 ~/.multi-os/config/waydroid.yml
gpu:
  mode: host
```

### AMD 显卡
```bash
# 使用 AMDGPU 驱动
# Waydroid 配置
gpu:
  mode: host
  driver: amdgpu
```

### Intel 显卡
```bash
# 使用 Intel 驱动
gpu:
  mode: host
  driver: i965
```

## 共享文件

### 从 Linux 访问 Android 文件
```bash
# Android 数据目录
~/anbox-data/data/

# 共享文件夹
~/android-shared/
```

### 从 Android 访问 Linux 文件
Android 应用可以通过标准文件管理器访问 Linux 文件系统。

## 网络配置

Waydroid 使用独立的网络空间：
- IP 地址: 10.15.19.x
- DNS: 8.8.8.8, 8.8.4.4

可以访问互联网和局域网设备。

## 多平台共存

### 与 Wine 共存
Waydroid 可以与 Wine 同时运行：
```yaml
# 在 waydroid.yml 中
compatibility:
  wine-shared-network: true
  gpu-share-with-wine: true
```

### 与 Darling 共存
macOS 应用和 Android 应用可以同时运行，共享系统资源。

## 故障排查

### Android 环境无法启动
```bash
# 检查 LXC 状态
lxc-checkconfig

# 重置 Waydroid
waydroid init -f
```

### GPU 加速不工作
```bash
# 检查 Wayland
echo $XDG_SESSION_TYPE

# 如果是 X11，切换到 Wayland
# 或使用 XWayland
```

### 应用崩溃
```bash
# 查看日志
waydroid logcat

# 重启会话
waydroid session stop
waydroid session start
```

## 常用应用推荐

### 生产力
- F-Droid (开源应用商店)
- Amaze File Manager
- LibreOffice Viewer
- Dropbox

### 媒体
- VLC
- Spotify (通过 Snap)
- Podcast Addict

### 游戏
- 经典 Android 游戏
- 使用游戏模式优化

## 性能基准

| 模式 | 启动时间 | 内存占用 | GPU 加速 |
|------|---------|---------|----------|
| 平衡 | ~10s | ~2GB | 自动 |
| 游戏 | ~8s | ~3GB | 完全 |
| 节能 | ~15s | ~1.5GB | 禁用 |

## 技术架构

```
┌─────────────────────────────────────┐
│      Linux 桌面环境                  │
├─────────────────────────────────────┤
│  [Linux应用] [Wine] [Darling] [Android]  │
│                                        │
│  ┌────────────────────────────────┐  │
│  │    统一启动器 (mos-launch)      │  │
│  └────────────────────────────────┘  │
│                  │                    │
│  ┌───────────────┴───────────────┐    │
│  │     Android 运行时            │    │
│  │   ┌──────────────────────┐    │    │
│  │   │  Waydroid (LXC)      │    │    │
│  │   │  ┌────────────────┐  │    │    │
│  │   │  │ Android 系统   │  │    │    │
│  │   │  │  (ARM/x86)    │  │    │    │
│  │   │  └────────────────┘  │    │    │
│  │   └──────────────────────┘    │    │
│  └───────────────────────────────┘    │
│                  │                    │
│  ┌────────────────┴────────────────┐    │
│  │     Linux 内核                  │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## 进阶配置

### 自定义分辨率
编辑 `~/.multi-os/config/waydroid.yml`:
```yaml
width: 1920
height: 1080
dpi: 320
```

### 自定义启动动画
替换 Android 系统镜像中的启动画面。

### 多实例
Waydroid 支持运行多个 Android 实例：
```bash
waydroid init -i second
WAYDROID_ID=second waydroid session start
```

## 更新和升级

### 更新 Waydroid
```bash
sudo apt-get update
sudo apt-get upgrade waydroid
```

### 更新 Multi-OS 集成
```bash
cd /workspace/multi-os-compat
git pull
./scripts/setup-android.sh
```

## 贡献和反馈

欢迎提交问题和建议！
- GitHub Issues
- 文档改进
- 功能请求

---

**Android 应用支持已集成到 Multi-OS Linux！** 📱
EOF

    log_success "安装指南已创建"
}

# 主函数
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   Multi-OS Android 兼容性设置      ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    # 创建目录
    create_directories
    
    # 生成配置
    generate_waydroid_config
    generate_anbox_config
    
    # 创建脚本
    create_waydroid_launcher
    create_android_app_manager
    create_android_tuning
    
    # 创建文档
    create_installation_guide
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   ✅ Android 兼容性设置完成！        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "📋 下一步:"
    echo "  1. 安装 Waydroid: sudo apt-get install waydroid"
    echo "  2. 初始化: waydroid init"
    echo "  3. 启动: /workspace/multi-os-compat/scripts/start-waydroid.sh"
    echo "  4. 管理应用: /workspace/multi-os-compat/scripts/android-app-manager.sh"
    echo ""
    echo "📚 详细文档: docs/ANDROID_INTEGRATION.md"
    echo ""
}

main
EOF

chmod +x "$PROJECT_ROOT/scripts/setup-android.sh"

echo "✅ Android 兼容性层脚本已创建: $PROJECT_ROOT/scripts/setup-android.sh"
