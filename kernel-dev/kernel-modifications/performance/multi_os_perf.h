/*
 * Multi-OS Linux - 性能优化头文件
 * 
 * 提供深度性能优化功能
 * 包括调度器优化、内存管理优化、I/O优化等
 */

#ifndef _MULTI_OS_PERF_H
#define _MULTI_OS_PERF_H

#include <linux/kernel.h>
#include <linux/sched.h>
#include <linux/mm.h>
#include <linux/blkdev.h>

/* 性能优化配置 */
#define MULTI_OS_PERF_ENABLED 1

/* 调度器优化配置 */
#define MULTI_OS_SCHED_BOOST_ENABLE 1
#define MULTI_OS_SCHED_LATENCY_OPTIMIZE 1
#define MULTI_OS_CACHE_OPTIMIZE 1

/* 内存管理优化配置 */
#define MULTI_OS_MEM_COMPRESS_ENABLED 1
#define MULTI_OS_KSM_ENABLED 1
#define MULTI_OS_TRANSPARENT_HUGEPAGE_ALWAYS 1

/* I/O优化配置 */
#define MULTI_OS_IO_SCHEDULER "mq-deadline"
#define MULTI_OS_WRITEBACK_OPTIMIZE 1

/* 多核调度器优化 */
struct multi_os_sched_config {
    int latency_optimize;
    int cache_optimize;
    int sched_boost;
    unsigned long latency_target;
};

/* 内存管理优化 */
struct multi_os_mem_config {
    int mem_compress_enabled;
    int ksm_enabled;
    int thp_always;
    unsigned long watermark_scale_factor;
};

/* I/O优化配置 */
struct multi_os_io_config {
    char io_scheduler[32];
    int writeback_optimize;
    int nr_requests;
    unsigned int read_ahead_kb;
};

/* 全局性能配置 */
extern struct multi_os_sched_config sched_config;
extern struct multi_os_mem_config mem_config;
extern struct multi_os_io_config io_config;

/* 性能优化初始化 */
int multi_os_perf_init(void);
void multi_os_perf_exit(void);

/* 调度器优化函数 */
void multi_os_sched_optimize(void);
void multi_os_sched_boost_task(struct task_struct *tsk);

/* 内存管理优化函数 */
void multi_os_mem_optimize(void);
void multi_os_mem_compress_enable(int enable);
void multi_os_ksm_enable(int enable);

/* I/O优化函数 */
void multi_os_io_optimize(struct request_queue *q);
void multi_os_set_io_scheduler(const char *scheduler);

/* 缓存优化函数 */
void multi_os_cache_optimize(void);

#endif /* _MULTI_OS_PERF_H */
