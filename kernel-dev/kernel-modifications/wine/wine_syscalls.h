/*
 * Multi-OS Linux - Wine 系统调用优化头文件
 * 
 * 为 Wine 提供特定的系统调用和支持，提升 Windows 应用的性能
 */

#ifndef _LINUX_WINE_SYSCALLS_H
#define _LINUX_WINE_SYSCALLS_H

#include <linux/types.h>
#include <linux/sched.h>
#include <linux/kernel.h>

/* Wine 进程标记 */
#define PF_WINE_PROCESS 0x08000000

/* Wine 优化的系统调用 */
#define __NR_mos_wine_setup       550
#define __NR_mos_wine_mem_alloc   551
#define __NR_mos_wine_mem_free    552
#define __NR_mos_wine_gpu_sync    553

/* Wine 优化的结构体 */
struct wine_process_info {
    pid_t wine_pid;
    bool is_wine_process;
    bool is_game_process;
    bool high_priority;
    unsigned long wine_flags;
};

/* Wine 内存分配信息 */
struct wine_alloc_info {
    unsigned long addr;
    unsigned long size;
    unsigned int flags;
};

/* 声明系统调用原型 */
asmlinkage long sys_mos_wine_setup(pid_t pid);
asmlinkage long sys_mos_wine_mem_alloc(struct wine_alloc_info *info);
asmlinkage long sys_mos_wine_mem_free(unsigned long addr);
asmlinkage long sys_mos_wine_gpu_sync(void);

/* Wine 调度优化函数 */
extern void wine_set_process_priority(struct task_struct *task, int priority);
extern bool is_wine_process(struct task_struct *task);
extern void wine_optimize_schedule(struct task_struct *task);

/* Wine 内存优化函数 */
extern int wine_optimize_memory_management(struct task_struct *task);
extern unsigned long wine_reserve_memory(unsigned long size);

/* Wine GPU 优化函数 */
extern void wine_gpu_performance_boost(void);
extern void wine_gpu_power_save(void);

#endif /* _LINUX_WINE_SYSCALLS_H */
