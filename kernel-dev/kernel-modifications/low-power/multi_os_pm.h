/*
 * Multi-OS Linux - 低功耗优化头文件
 * 
 * 提供深度电源管理和低功耗优化支持
 */

#ifndef _LINUX_MULTI_OS_PM_H
#define _LINUX_MULTI_OS_PM_H

#include <linux/types.h>
#include <linux/pm.h>
#include <linux/cpufreq.h>

/* 电源模式定义 */
enum multi_os_power_mode {
    MOS_PM_PERFORMANCE,    /* 高性能模式 */
    MOS_PM_BALANCED,       /* 平衡模式 */
    MOS_PM_POWERSAVE,      /* 节电模式 */
    MOS_PM_GAMING,         /* 游戏模式 */
    MOS_PM_MAX
};

/* 电源状态信息 */
struct multi_os_pm_state {
    enum multi_os_power_mode current_mode;
    unsigned long last_mode_change;
    unsigned int cpu_budget;
    unsigned int gpu_budget;
    unsigned int battery_level;
    unsigned int thermal_limit;
};

/* 自定义电源管理函数 */
extern int multi_os_set_power_mode(enum multi_os_power_mode mode);
extern enum multi_os_power_mode multi_os_get_power_mode(void);
extern int multi_os_optimize_power_management(void);
extern int multi_os_setup_cpu_powersave(void);
extern int multi_os_setup_gpu_powersave(void);

/* CPU idle 优化 */
extern int multi_os_enter_deep_idle(void);
extern int multi_os_cpu_idle_management(bool enable);

/* 热管理优化 */
extern int multi_os_thermal_balance(void);
extern int multi_os_set_thermal_limit(unsigned int limit);

/* 内存自刷新优化 */
extern int multi_os_enable_memory_self_refresh(void);
extern int multi_os_disable_memory_self_refresh(void);

/* 智能电源模式检测 */
extern enum multi_os_power_mode multi_os_auto_detect_mode(void);

/* 系统调用接口 */
#define __NR_mos_power_mode 560
#define __NR_mos_battery_info 561
#define __NR_mos_cpu_governor_set 562

asmlinkage long sys_mos_power_mode(int mode);
asmlinkage long sys_mos_battery_info(int *level);
asmlinkage long sys_mos_cpu_governor_set(const char *governor);

/* 设备电源管理 */
extern struct multi_os_pm_state *get_mos_pm_state(void);
extern void multi_os_device_suspend(const char *device_name);
extern void multi_os_device_resume(const char *device_name);

/* 定时器优化 */
extern void multi_os_optimize_timers(void);
extern void multi_os_disable_unnecessary_timers(void);

#endif /* _LINUX_MULTI_OS_PM_H */
