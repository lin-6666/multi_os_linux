# Multi-OS Linux 内核优化补丁说明
=========================================

## 补丁概述

这些优化补丁旨在提升 Multi-OS Linux 的性能和兼容性。

## 包含的优化

### 1. 低功耗优化

**文件:** `low-power-tweaks.patch`

- **CPU 调度器优化**
  - 启用 BORE 调度器（Burst-Oriented Response Enhancer）
  - 优化桌面响应性同时保持低功耗
  
- **电源管理增强**
  - 启用深度空闲状态
  - 优化 ACPI 电源管理
  - 增强 P-State 调度

- **内存功耗优化**
  - 启用内存自刷新技术
  - 优化内存页面回收
  - 启用 zswap 压缩缓存

### 2. 多平台兼容性优化

**文件:** `multiplatform-compat.patch`

- **Wine/Windows 兼容**
  - NTFS 读写支持
  - DirectX/D3D 优化
  - Direct Rendering 增强
  
- **Waydroid/Android 兼容**
  - 容器 cgroups v2 支持
  - binder/ashmem 驱动
  - 安卓特有的内存管理

- **音频系统优化**
  - PulseAudio/ALSA 优化
  - 低延迟音频支持
  - USB 音频增强

### 3. 虚拟化优化

**文件:** `virtualization-enhancements.patch`

- **KVM/QEMU 优化**
  - Virtio 驱动增强
  - vhost-net 优化
  - 嵌套虚拟化支持

- **性能优化**
  - vCPU 亲和性
  - 内存大页支持
  - IO 调度优化

### 4. 网络栈优化

**文件:** `network-optimizations.patch`

- **TCP 协议栈优化**
  - BBR 拥塞控制
  - TCP Fast Open
  - 高性能网络队列

- **WiFi 优化**
  - 电源管理优化
  - 漫游优化
  - 频段平衡

## 应用补丁

### 方法 1: 使用脚本自动应用

```bash
cd /workspace/multi-os-compat
./scripts/apply-kernel-patches.sh
```

### 方法 2: 手动应用

```bash
# 解压内核
cd sources
tar -xf linux-6.8.12.tar.xz
cd linux-6.8.12

# 应用补丁
patch -p1 < ../patches/low-power-tweaks.patch
patch -p1 < ../patches/multiplatform-compat.patch
patch -p1 < ../patches/virtualization-enhancements.patch
patch -p1 < ../patches/network-optimizations.patch

# 配置内核
make menuconfig

# 编译
make -j$(nproc)
```

## 补丁兼容性

- **内核版本:** 6.8.x (推荐 6.8.12)
- **架构:** x86_64 (AMD64)
- **测试状态:** 建议在虚拟机中先测试

## 注意事项

1. **备份原配置**
   ```bash
   cp .config .config.backup
   ```

2. **测试环境**
   - 建议先在虚拟机中测试
   - 验证所有硬件正常工作

3. **性能测试**
   - 使用 `perf` 工具进行基准测试
   - 监控功耗变化

## 卸载补丁

```bash
# 恢复到原始状态
cd linux-6.8.12
git checkout .
```

## 更多信息

- 内核文档: https://www.kernel.org/doc/html/latest/
- Wine HQ: https://wiki.winehq.org/
- Waydroid: https://docs.waydroid.id/

---

**创建日期:** 2026-06-04
**适用版本:** Multi-OS Linux v1.0+
