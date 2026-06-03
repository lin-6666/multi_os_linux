# Multi-OS Linux 使用指南
=============================

## 概述
Multi-OS Linux 是一个设计用于同时运行 Windows、macOS 和 Android 应用的 Linux 系统，具有低功耗优化特性。

## 已完成的工作
1. **Wine 配置** - 优化了 Windows 应用兼容性，包括 Steam 和 Wallpaper Engine
2. **系统构建脚本** - 创建了完整的构建和设置流程
3. **配置包** - 生成了可分发的配置包

## 文件结构
```
/workspace/multi-os-compat/
├── build/                     # 构建输出
│   ├── multi-os-config-*.tar.gz  # 配置包
│   ├── docs/
│   │   └── README.txt
│   └── SYSTEM_SUMMARY.md
├── config/
│   └── wine/                 # Wine 配置文件
│       ├── audio.reg
│       ├── desktop.reg
│       └── wallpaper_engine.reg
├── scripts/
│   ├── setup-wine.sh          # Wine 环境设置
│   ├── launch-steam.sh        # Steam 启动脚本
│   ├── build-system.sh       # 完整系统构建
│   ├── mos-launch.sh         # 统一应用启动器
│   └── ...
└── quick-build.sh            # 快速构建脚本
```

## 快速开始

### 1. 系统要求
- Debian/Ubuntu 系统
- 至少 4GB 内存
- 显卡支持 OpenGL 4.6

### 2. 安装基础依赖
```bash
sudo apt-get update
sudo apt-get install -y wine wine64 winetricks git wget
```

### 3. 设置 Wine 环境（支持 Steam 和 Wallpaper Engine）
```bash
cd /workspace/multi-os-compat
chmod +x scripts/setup-wine.sh
./scripts/setup-wine.sh
```

### 4. 启动 Steam
```bash
./scripts/launch-steam.sh
```

### 5. 安装 Wallpaper Engine
通过 Steam 购买并安装 Wallpaper Engine，然后在 Wine 中运行。

## Wine 配置说明
Wine 配置已经针对以下内容进行了优化：
- DirectX/OpenGL 渲染
- 音频 (PulseAudio)
- Steam 和 Wallpaper Engine 兼容性
- 分辨率和窗口管理

## 系统特性
1. **多平台兼容**
   - Windows (Wine)
   - macOS (Darling)
   - Android (Waydroid)
2. **低功耗优化**
   - 定制内核配置
   - 多种电源管理模式
3. **统一应用管理**
   - `mos-launch.sh` - 跨平台应用启动器

## 构建输出说明
- `build/multi-os-config-*.tar.gz` - 包含所有配置和脚本
- `build/docs/` - 系统文档
- `build/SYSTEM_SUMMARY.md` - 系统概要

## 下一步
1. 在真实硬件上测试完整系统构建
2. 根据需要优化性能
3. 集成更多应用支持
