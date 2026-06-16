/*
 * Multi-OS Linux - Android兼容层内核支持头文件
 * 
 * 提供Android应用运行的内核支持
 * 包括Binder驱动、Ashmem、内存管理优化等
 */

#ifndef _MULTI_OS_ANDROID_H
#define _MULTI_OS_ANDROID_H

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/mm.h>

/* Android兼容配置 */
#define MULTI_OS_ANDROID_ENABLED 1

/* Binder驱动支持 */
#define MULTI_OS_BINDER_ENABLED 1
#define MULTI_OS_ASHMEM_ENABLED 1
#define MULTI_OS_ANDROID_LOGGER 1

/* Android内存优化 */
#define MULTI_OS_ANDROID_MEM_OPTIMIZE 1

/* Binder配置 */
struct multi_os_binder_config {
    int enabled;
    int max_threads;
    int max_procs;
    unsigned long transaction_max;
};

/* Ashmem配置 */
struct multi_os_ashmem_config {
    int enabled;
    unsigned long max_size;
};

/* Android配置 */
struct multi_os_android_config {
    int enabled;
    struct multi_os_binder_config binder;
    struct multi_os_ashmem_config ashmem;
    int logger_enabled;
};

/* 全局Android配置 */
extern struct multi_os_android_config android_config;

/* Android兼容初始化 */
int multi_os_android_init(void);
void multi_os_android_exit(void);

/* Binder函数 */
int multi_os_binder_init(void);
void multi_os_binder_exit(void);

/* Ashmem函数 */
int multi_os_ashmem_init(void);
void multi_os_ashmem_exit(void);

/* Android日志函数 */
int multi_os_android_logger_init(void);
void multi_os_android_logger_exit(void);

/* Android内存优化 */
void multi_os_android_mem_optimize(void);

#endif /* _MULTI_OS_ANDROID_H */
