# Multi-OS Linux
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

> 一个支持运行 Windows、macOS 和 Android 应用的完整 Linux 系统

## 概述

**Multi-OS Linux** 是一个基于 Debian 的 Linux 发行版，专为运行多平台应用而设计。它集成了 Wine、Darling 和 Waydroid，让你在一个系统上就能享受到来自 Windows、macOS 和 Android 的所有应用程序。

## 特性

✨ **Windows 应用** - 通过 Wine 原生运行 Windows 程序（已优化 Steam 和 Wallpaper Engine）

🍎 **macOS 应用** - 通过 Darling 兼容层运行 macOS 程序

📱 **Android 应用** - 通过 Waydroid 容器运行 Android 应用

🎮 **游戏优化** - 内置 Steam 支持和游戏优化配置

⚡ **低功耗优化** - 定制的电源管理和内核优化

🔧 **统一启动器** - 一站式启动所有平台的应用

## 快速开始

### 1. 下载系统

```bash
# 克隆项目
git clone https://github.com/your-username/multi-os-linux.git
cd multi-os-linux
```

### 2. 安装系统

详细安装说明请参阅：[安装指南](https://github.com/your-username/multi-os-linux/blob/main/build/dist/COMPLETE_INSTALLATION_GUIDE.md)

### 3. 配置 Wine 环境

```bash
# 进入项目目录
cd multi-os-compat

# 运行 Wine 配置
./scripts/setup-wine.sh

# 启动 Steam
./scripts/launch-steam.sh
```

## 文件结构

```
multi-os-compat/
├── config/                # 系统配置
│   ├── wine/            # Wine 配置
│   ├── android/         # Android 配置
│   └── audio/           # 音频配置
├── scripts/              # 脚本文件
│   ├── setup-wine.sh    # Wine 配置脚本
│   ├── launch-steam.sh  # Steam 启动脚本
│   └── build-full-system.sh  # 完整构建脚本
├── docs/                 # 文档
├── build/                # 构建产物
│   └── dist/           # 发行包
└── sources/              # 源码目录
```

## 安装方法

### 方法 1: 使用系统包（推荐）

```bash
# 下载系统包
tar -xzf build/dist/multi-os-linux-*.tar.gz
cd rootfs

# 运行安装程序
sudo ./install.sh
```

### 方法 2: 使用 Docker/Chroot

```bash
# 使用 debootstrap 构建完整系统
sudo apt-get install debootstrap
sudo debootstrap stable /path/to/rootfs http://deb.debian.org/debian
```

详细说明请查看 [安装指南](https://github.com/your-username/multi-os-linux/blob/main/build/dist/COMPLETE_INSTALLATION_GUIDE.md)

## Steam 和 Wallpaper Engine

我们已为 Steam 和 Wallpaper Engine 进行了专门优化：

```bash
# 1. 初始化 Wine 环境
./scripts/setup-wine.sh

# 2. 启动 Steam
./scripts/launch-steam.sh

# 3. 在 Steam 中安装 Wallpaper Engine
```

配置文件：
- [wallpaper_engine.reg](config/wine/wallpaper_engine.reg) - Steam 和 Wallpaper Engine 优化配置
- [audio.reg](config/wine/audio.reg) - 音频配置
- [desktop.reg](config/wine/desktop.reg) - 桌面配置

## 系统要求

### 最低要求
- CPU: 64位 x86 处理器
- 内存: 2GB RAM
- 磁盘: 20GB 可用空间
- 显卡: VESA 2.0 支持

### 推荐配置
- CPU: 多核处理器
- 内存: 4GB+ RAM
- 磁盘: 50GB+ SSD
- 显卡: OpenGL 4.0+ 支持
- 网络: 宽带连接

## 文档

- [快速开始](docs/QUICK_START.md)
- [安装指南](build/dist/COMPLETE_INSTALLATION_GUIDE.md)
- [使用说明](USAGE_GUIDE.md)
- [项目总结](PROJECT_COMPLETION.md)
- [交付总结](build/dist/DELIVERY_SUMMARY.txt)

## 贡献

欢迎贡献！请查看项目的贡献指南（待完善）。

## 支持

有问题？请查看：
- [GitHub Issues](https://github.com/your-username/multi-os-linux/issues)
- 文档目录中的故障排除指南

## 许可证

Multi-OS Linux 采用 GPLv3 许可证。请参阅 [LICENSE](LICENSE) 文件了解详情。

## 致谢

- [Wine](https://www.winehq.org/) - Windows 兼容层
- [Darling](https://www.darlinghq.org/) - macOS 兼容层
- [Waydroid](https://waydro.id/) - Android 容器
- [Debian](https://www.debian.org/) - 基础系统
- 所有为开源项目做出贡献的人

---

**Multi-OS Linux** - 一个系统，所有应用。
