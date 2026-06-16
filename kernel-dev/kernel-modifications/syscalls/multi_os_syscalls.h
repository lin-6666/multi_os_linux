/*
 * Multi-OS Linux - 自定义系统调用头文件
 * 
 * 提供自定义系统调用，支持多平台兼容
 */

#ifndef _MULTI_OS_SYSCALLS_H
#define _MULTI_OS_SYSCALLS_H

#include <linux/kernel.h>
#include <linux/syscalls.h>
#include <linux/types.h>

/* 自定义系统调用号 */
#define __NR_multi_os_base 548
#define __NR_multi_os_wine_syscall (__NR_multi_os_base + 0)
#define __NR_multi_os_darling_syscall (__NR_multi_os_base + 1)
#define __NR_multi_os_android_syscall (__NR_multi_os_base + 2)
#define __NR_multi_os_get_info (__NR_multi_os_base + 3)
#define __NR_multi_os_set_config (__NR_multi_os_base + 4)
#define __NR_multi_os_perf_stats (__NR_multi_os_base + 5)

/* Wine系统调用参数 */
struct multi_os_wine_syscall_args {
    unsigned int syscall_nr;
    unsigned long args[6];
};

/* Darling系统调用参数 */
struct multi_os_darling_syscall_args {
    unsigned int syscall_nr;
    unsigned long args[8];
};

/* Android系统调用参数 */
struct multi_os_android_syscall_args {
    unsigned int syscall_nr;
    unsigned long args[6];
};

/* 系统信息结构 */
struct multi_os_info {
    unsigned int version_major;
    unsigned int version_minor;
    unsigned int version_patch;
    char version_string[64];
    unsigned int features;
    unsigned long reserved[8];
};

/* 配置参数 */
#define MULTI_OS_FEATURE_WINE (1 << 0)
#define MULTI_OS_FEATURE_DARLING (1 << 1)
#define MULTI_OS_FEATURE_ANDROID (1 << 2)
#define MULTI_OS_FEATURE_LOW_POWER (1 << 3)
#define MULTI_OS_FEATURE_PERFORMANCE (1 << 4)
#define MULTI_OS_FEATURE_SECURITY (1 << 5)

/* 性能统计结构 */
struct multi_os_perf_stats {
    unsigned long long wine_syscalls;
    unsigned long long darling_syscalls;
    unsigned long long android_syscalls;
    unsigned long long total_syscalls;
    unsigned long long context_switches;
    unsigned long long cache_hits;
    unsigned long long cache_misses;
    unsigned long long reserved[8];
};

/* 自定义系统调用声明 */
asmlinkage long sys_multi_os_wine_syscall(struct multi_os_wine_syscall_args __user *args);
asmlinkage long sys_multi_os_darling_syscall(struct multi_os_darling_syscall_args __user *args);
asmlinkage long sys_multi_os_android_syscall(struct multi_os_android_syscall_args __user *args);
asmlinkage long sys_multi_os_get_info(struct multi_os_info __user *info);
asmlinkage long sys_multi_os_set_config(unsigned int config_type, unsigned long value);
asmlinkage long sys_multi_os_perf_stats(struct multi_os_perf_stats __user *stats);

/* 系统调用初始化 */
int multi_os_syscalls_init(void);
void multi_os_syscalls_exit(void);

#endif /* _MULTI_OS_SYSCALLS_H */
