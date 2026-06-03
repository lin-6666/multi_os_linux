# Multi-OS Linux - 独立定制发行版架构

## 1. 系统概述

### 1.1 核心理念
构建一个**独立的、定制化的 Linux 发行版**，从内核层开始就支持 Windows 和 macOS 应用程序的原生运行。

### 1.2 关键特点
- **独立发行版**: 从源码构建，不是基于现有发行版
- **多平台支持**: 内核和用户空间深度集成 Wine/Darling
- **最小化设计**: 只包含必要组件，优化性能
- **可定制性**: 用户可以轻松添加/移除功能

## 2. 系统架构

### 2.1 层级结构
```
┌─────────────────────────────────────────┐
│     用户空间 (User Space)                │
├─────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │ Windows │ │  macOS  │ │  Linux   │  │
│  │  应用   │ │  应用   │ │   应用   │  │
│  └────┬────┘ └────┬────┘ └────┬─────┘  │
│       │           │           │         │
│  ┌────┴───────────┴───────────┴─────┐  │
│  │      Unified Launcher (mos-launch)│  │
│  └──────────────────┬──────────────────┘  │
│                     │                     │
├─────────────────────┼─────────────────────┤
│     Wine DLLs       │    Darling Frameworks│
├─────────────────────┼─────────────────────┤
│     Windows API     │      macOS API       │
│     Emulation      │      Emulation      │
└─────────────────────┴─────────────────────┘
                      ↓
┌─────────────────────────────────────────┐
│     系统库层 (glibc, musl-libc)          │
├─────────────────────────────────────────┤
│     Wine (ntdll, kernel32, etc.)        │
├─────────────────────────────────────────┤
│     Darling (libdispatch, etc.)          │
└─────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────┐
│     定制 Linux 内核                      │
│  ┌──────────┬──────────┬──────────────┐ │
│  │ Extended │   Wine   │   Mach-O    │ │
│  │    ELF   │   PE     │   Loader    │ │
│  │  Loader  │  Parser  │   Support   │ │
│  └──────────┴──────────┴──────────────┘ │
└─────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────┐
│     硬件抽象层 (Hardware)                │
└─────────────────────────────────────────┘
```

### 2.2 目录结构
```
/
├── bin/                      # 可执行文件
│   ├── bash
│   ├── coreutils
│   ├── mos-launch            # 统一启动器
│   ├── wine                  # Wine 可执行文件
│   └── darling               # Darling 可执行文件
├── sbin/                     # 系统管理程序
├── lib/                      # 32位库 (可选)
├── lib64/                    # 64位系统库
│   ├── libc.so.6
│   ├── libpthread.so.0
│   └── ...
├── usr/
│   ├── bin/
│   ├── lib/
│   │   ├── wine/            # Wine DLLs
│   │   │   ├── x86_64-windows/
│   │   │   │   ├── ntdll.dll
│   │   │   │   ├── kernel32.dll
│   │   │   │   ├── user32.dll
│   │   │   │   └── ...
│   │   │   └── i386-windows/
│   │   └── darling/         # Darling 框架
│   │       └── System/
│   │           └── Library/
│   │               └── Frameworks/
│   └── share/
├── etc/
│   ├── mos/                 # Multi-OS 配置
│   │   ├── config.yaml
│   │   ├── platforms/
│   │   └── themes/
│   ├── wine/
│   └── darling/
├── var/
│   ├── lib/
│   │   ├── wine/           # Wine 数据
│   │   └── darling/        # Darling 数据
│   └── cache/
├── opt/                      # 可选应用
│   ├── apps/
│   │   ├── windows/        # Windows 应用
│   │   └── macos/          # macOS 应用
│   └── drivers/            # 驱动
└── home/
    └── user/
        ├── Desktop/
        └── Applications/
```

## 3. 内核定制

### 3.1 必要的内核配置
```bash
# 基础配置
CONFIG_BINFMT_MISC=y              # 支持可执行格式
CONFIG_BINFMT_ELF=y               # ELF 支持
CONFIG_KERNELSUPPORT_WINE=y      # Wine PE 支持
CONFIG_KERNELSUPPORT_MACHO=y     # Mach-O 支持

# 文件系统
CONFIG_EXT4_FS=y                 # ext4 文件系统
CONFIG_FUSE_FS=y                 # FUSE 支持

# 网络
CONFIG_NET=y                     # 网络支持
CONFIG_INET=y                    # TCP/IP

# 虚拟化 (可选)
CONFIG_KVM=y                      # KVM 支持
```

### 3.2 内核模块支持
```
kernel/
├── wine/
│   ├── pe_parser.c             # PE 文件解析
│   ├── syscall_bridge.c        # Windows 系统调用桥接
│   └── reg_interface.c         # 注册表接口
└── mach/
    ├── macho_loader.c          # Mach-O 加载器
    ├── mach_syscalls.c         # Mach 系统调用
    └── xnu_compat.c            # XNU 兼容性
```

## 4. 关键组件

### 4.1 统一启动器 (mos-launch)
```bash
# 使用方式
mos-launch notepad.exe           # 自动检测并运行
mos-launch --windows app.exe     # 强制 Windows 模式
mos-launch --macos App.app       # 强制 macOS 模式
mos-launch --native app          # 原生 Linux 模式
```

### 4.2 Wine 集成
- 预编译的 Wine 二进制
- 优化的 DLL 集合
- 预配置的 WinePrefix
- DXVK 和 VKD3D 集成

### 4.3 Darling 集成
- 预编译的 Darling
- 必要的 macOS 框架
- 预配置的 DPrefix

## 5. 构建流程

### 5.1 阶段划分
```
Phase 1: 基础系统
  - 构建临时工具链
  - 构建最终工具链
  - 构建系统基础 (LFS 7-10章)

Phase 2: 内核定制
  - 配置和编译 Linux 内核
  - 添加多平台支持补丁

Phase 3: 兼容性层
  - 编译和安装 Wine
  - 编译和安装 Darling
  - 配置集成

Phase 4: 用户空间
  - 统一启动器
  - 桌面环境
  - 预装应用

Phase 5: 镜像生成
  - 创建根文件系统
  - 生成 ISO 镜像
  - 制作启动介质
```

### 5.2 构建命令
```bash
# 完整构建
./build-system.sh --full

# 分阶段构建
./build-system.sh --phase 1  # 基础系统
./build-system.sh --phase 2  # 内核
./build-system.sh --phase 3  # 兼容性层

# 创建镜像
./build-system.sh --image --format iso
```

## 6. 系统要求

### 6.1 构建环境
- **CPU**: x86_64 (推荐 8+ 核心)
- **内存**: 16GB+ (编译需要)
- **磁盘**: 100GB+ 可用空间
- **系统**: Linux (推荐 Debian/Ubuntu)

### 6.2 目标环境
- **CPU**: x86_64
- **内存**: 4GB+ (8GB+ 推荐)
- **磁盘**: 20GB+
- **引导**: BIOS/UEFI

## 7. 预装功能

### 7.1 系统工具
- 包管理器 (pacman-style)
- 系统配置工具
- 硬件驱动管理
- 网络配置

### 7.2 兼容层
- Wine 9.x (最新稳定版)
- Darling (最新稳定版)
- DXVK (DirectX 12 支持)
- VKD3D (Vulkan for Windows games)

### 7.3 桌面环境
- 轻量级桌面 (XFCE/LXQt)
- 窗口管理器 (i3/Sway 可选)
- 统一应用启动器

## 8. 后续计划

### 8.1 短期
- 完成基础构建系统
- 测试 Wine/Darling 集成
- 创建最小可启动镜像

### 8.2 中期
- 图形化安装程序
- 应用商店
- 自动更新机制

### 8.3 长期
- 多架构支持 (ARM64)
- 性能优化
- 社区版本
