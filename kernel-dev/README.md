# Multi-OS Linux 内核开发

欢迎来到 Multi-OS Linux 内核开发项目！

## 概述

Multi-OS Linux 是一个深度修改的 Linux 内核，支持同时运行 Windows、macOS、Linux 和 Android 应用程序。

本项目包含：
- 内核修改框架
- 内核补丁
- 构建脚本
- 测试工具
- 完整文档

## 快速开始

### 一键构建

```bash
cd /workspace/multi-os-compat/kernel-dev
./build-all.sh
```

### 分步构建

请参考 [KERNEL_BUILD_GUIDE.md](./docs/KERNEL_BUILD_GUIDE.md)。

## 目录结构

```
kernel-dev/
├── build-scripts/          # 构建脚本
│   ├── 01-prepare-kernel.sh
│   ├── 02-apply-patches.sh
│   ├── 03-configure-kernel.sh
│   ├── 04-build-kernel.sh
│   ├── 05-install-kernel.sh
│   ├── 06-install-to-system.sh
│   └── 07-create-iso.sh
├── kernel-modifications/    # 内核修改框架
│   ├── wine/              # Wine 支持
│   ├── darling/           # Darling 支持
│   ├── android/           # Android 支持
│   ├── low-power/         # 低功耗优化
│   ├── performance/       # 性能优化
│   ├── security/          # 安全增强
│   ├── drivers/           # 驱动优化
│   └── syscalls/          # 自定义系统调用
├── patches/               # 内核补丁
│   ├── 0001-Multi-OS-Linux-base-patch.patch
│   ├── 0002-Add-multi-os-kernel-config.patch
│   └── 0003-Add-multi-os-syscalls.patch
├── test-scripts/          # 测试脚本
│   ├── test-kernel.sh
│   └── test-performance.sh
├── docs/                  # 文档
│   ├── KERNEL_MODIFICATION_PLAN.md
│   ├── KERNEL_BUILD_GUIDE.md
│   └── KERNEL_FEATURES.md
├── build-all.sh           # 一键构建脚本
└── README.md              # 本文件
```

## 核心功能

### 多平台应用支持
- **Windows 应用** - 通过 Wine 兼容层
- **macOS 应用** - 通过 Darling 兼容层
- **Android 应用** - 通过 Waydroid
- **Linux 应用** - 原生支持

### 低功耗优化
- 250Hz 时钟频率
- NO_HZ 动态时钟
- 智能电源管理
- 四种电源模式

### 性能优化
- KSM 内存共享
- 透明大页
- TCP BBR 拥塞控制
- I/O 调度优化

### 安全增强
- 应用沙箱
- 强制访问控制
- 安全审计
- 系统调用过滤

详细内容请参考 [KERNEL_FEATURES.md](./docs/KERNEL_FEATURES.md)。

## 文档

- [KERNEL_MODIFICATION_PLAN.md](./docs/KERNEL_MODIFICATION_PLAN.md) - 内核深度修改计划
- [KERNEL_BUILD_GUIDE.md](./docs/KERNEL_BUILD_GUIDE.md) - 内核构建指南
- [KERNEL_FEATURES.md](./docs/KERNEL_FEATURES.md) - 内核功能介绍

## 系统要求

### 开发环境
- Linux 6.8.12 内核源码
- GCC 11+
- Make 4.0+
- 至少 16GB 磁盘空间
- 至少 8GB 内存

### 运行环境
- Intel/AMD x86_64 处理器
- 4GB+ 内存 (推荐 8GB+)
- 32GB+ 存储空间 (推荐 64GB+ SSD)

## 许可证

本项目采用 GPL v2 许可证。

## 贡献

欢迎贡献！请查看我们的贡献指南。

## 相关项目

- [Wine](https://www.winehq.org/) - Windows 兼容层
- [Darling](https://www.darlinghq.org/) - macOS 兼容层
- [Waydroid](https://waydro.id/) - Android 兼容层
- [Linux 内核](https://www.kernel.org/) - Linux 官方内核

## 联系方式

如有问题或建议，请通过以下方式联系：
- 项目主页：待添加
- 问题反馈：待添加

## 更新日志

### v1.0.0 (2026-06-04)
- 初始版本
- 基础内核框架
- Wine、Darling、Android 支持
- 低功耗和性能优化
- 安全增强功能
