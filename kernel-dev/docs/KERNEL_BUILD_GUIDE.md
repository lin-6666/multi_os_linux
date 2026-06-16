# Multi-OS Linux 内核构建指南

本指南将帮助您构建和安装 Multi-OS Linux 内核。

## 前置要求

- Linux 6.8.12 内核源码
- 构建工具 (gcc, make, bison, flex, bc, etc.)
- 至少 16GB 空闲磁盘空间
- 至少 4GB 内存

## 快速开始

### 1. 准备工作目录

所有内核相关文件位于：
```
/workspace/multi-os-compat/kernel-dev/
```

### 2. 一键构建

```bash
cd /workspace/multi-os-compat/kernel-dev/build-scripts
./01-prepare-kernel.sh
./02-apply-patches.sh
./03-configure-kernel.sh
./04-build-kernel.sh
./05-install-kernel.sh
```

## 详细步骤

### 步骤 1: 准备内核源码

```bash
./01-prepare-kernel.sh
```

该脚本会：
- 检查内核源码是否存在
- 如果需要，解压内核源码
- 创建必要的目录结构

### 步骤 2: 应用补丁

```bash
./02-apply-patches.sh
```

该脚本会：
- 检查补丁目录
- 应用所有 Multi-OS Linux 补丁
- 创建应用标记

### 步骤 3: 配置内核

```bash
./03-configure-kernel.sh
```

该脚本会：
- 生成默认配置
- 启用 Multi-OS Linux 功能
- 配置低功耗、性能优化、安全增强等选项

或者，您也可以手动配置：
```bash
cd /workspace/multi-os-compat/sources/linux-6.8.12
make menuconfig
```

### 步骤 4: 编译内核

```bash
./04-build-kernel.sh
```

该脚本会：
- 清理之前的构建
- 编译内核镜像
- 编译内核模块
- 显示构建时间

编译时间取决于您的硬件配置，通常需要 20 分钟到 2 小时。

### 步骤 5: 安装内核

```bash
./05-install-kernel.sh
```

该脚本会：
- 安装内核镜像
- 安装 System.map
- 安装配置文件
- 安装内核模块
- 安装内核头文件

### 步骤 6: 安装到系统（可选）

```bash
sudo ./06-install-to-system.sh
```

该脚本会：
- 将内核安装到 /boot
- 生成 initramfs
- 更新 bootloader

**注意：** 这需要 root 权限，并且会修改您的系统配置。

### 步骤 7: 创建 ISO（可选）

```bash
./07-create-iso.sh
```

该脚本会：
- 创建 ISO 目录结构
- 复制内核文件
- 创建 GRUB 配置
- 生成可启动 ISO

## 内核配置选项

Multi-OS Linux 内核包含以下配置选项：

### Multi-OS 支持
```
CONFIG_MULTI_OS=y
CONFIG_MULTI_OS_WINE=y
CONFIG_MULTI_OS_DARLING=y
CONFIG_MULTI_OS_ANDROID=y
CONFIG_MULTI_OS_LOW_POWER=y
CONFIG_MULTI_OS_PERFORMANCE=y
CONFIG_MULTI_OS_SECURITY=y
```

### 低功耗配置
```
CONFIG_HZ_250=y
CONFIG_HZ=250
CONFIG_NO_HZ=y
CONFIG_NO_HZ_IDLE=y
CONFIG_HIGH_RES_TIMERS=y
```

### 性能优化
```
CONFIG_CPU_FREQ=y
CONFIG_CPU_FREQ_GOV_SCHEDUTIL=y
CONFIG_TRANSPARENT_HUGEPAGE=y
CONFIG_KSM=y
```

## 故障排除

### 编译失败
- 确保已安装所有构建依赖
- 检查磁盘空间
- 尝试减少并行任务数量

### 补丁应用失败
- 检查内核版本是否匹配
- 尝试手动应用补丁
- 查看详细错误信息

### 内核无法启动
- 检查 initramfs 是否正确生成
- 验证 bootloader 配置
- 查看启动日志

## 下一步

1. 安装内核后，重启系统
2. 在 bootloader 中选择 Multi-OS Linux 内核
3. 运行测试脚本验证功能
4. 开始使用 Multi-OS Linux 的多平台支持功能

## 相关文档

- [KERNEL_MODIFICATION_PLAN.md](./KERNEL_MODIFICATION_PLAN.md) - 内核修改计划
- [KERNEL_FEATURES.md](./KERNEL_FEATURES.md) - 内核功能介绍
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - 测试指南
