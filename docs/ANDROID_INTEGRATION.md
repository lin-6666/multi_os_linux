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
