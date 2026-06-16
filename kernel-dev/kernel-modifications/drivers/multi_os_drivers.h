/*
 * Multi-OS Linux - 驱动优化头文件
 * 
 * 提供深度驱动优化功能
 * 包括图形驱动、音频驱动、网络驱动等优化
 */

#ifndef _MULTI_OS_DRIVERS_H
#define _MULTI_OS_DRIVERS_H

#include <linux/kernel.h>
#include <linux/device.h>
#include <linux/pci.h>
#include <linux/usb.h>

/* 驱动优化配置 */
#define MULTI_OS_DRIVERS_OPTIMIZE 1

/* 图形驱动优化 */
#define MULTI_OS_GPU_OPTIMIZE 1
#define MULTI_OS_AUDIO_OPTIMIZE 1
#define MULTI_OS_NETWORK_OPTIMIZE 1

/* 虚拟设备支持 */
#define MULTI_OS_VIRTUAL_AUDIO 1
#define MULTI_OS_VIRTUAL_GPU 1

/* 图形驱动优化配置 */
struct multi_os_gpu_config {
    int optimize_enabled;
    int power_management;
    int performance_mode;
    int vram_size;
};

/* 音频驱动优化配置 */
struct multi_os_audio_config {
    int optimize_enabled;
    int low_latency;
    int virtual_audio;
    int buffer_size;
};

/* 网络驱动优化配置 */
struct multi_os_network_config {
    int optimize_enabled;
    int offload_enabled;
    int tcp_bbr;
    int rx_copybreak;
};

/* 驱动配置 */
struct multi_os_drivers_config {
    struct multi_os_gpu_config gpu;
    struct multi_os_audio_config audio;
    struct multi_os_network_config network;
};

/* 全局驱动配置 */
extern struct multi_os_drivers_config drivers_config;

/* 驱动优化初始化 */
int multi_os_drivers_init(void);
void multi_os_drivers_exit(void);

/* 图形驱动优化函数 */
void multi_os_gpu_optimize(struct pci_dev *pdev);
void multi_os_gpu_set_performance_mode(int mode);

/* 音频驱动优化函数 */
void multi_os_audio_optimize(struct device *dev);
int multi_os_create_virtual_audio(void);

/* 网络驱动优化函数 */
void multi_os_network_optimize(struct net_device *dev);
void multi_os_set_tcp_bbr(void);

/* 虚拟设备函数 */
int multi_os_create_virtual_gpu(void);

#endif /* _MULTI_OS_DRIVERS_H */
