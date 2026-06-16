/*
 * Multi-OS Linux - 安全增强头文件
 * 
 * 提供深度安全增强功能
 * 包括沙箱机制、访问控制、安全审计等
 */

#ifndef _MULTI_OS_SECURITY_H
#define _MULTI_OS_SECURITY_H

#include <linux/kernel.h>
#include <linux/security.h>
#include <linux/fs.h>
#include <linux/sched.h>

/* 安全增强配置 */
#define MULTI_OS_SECURITY_ENABLED 1

/* 沙箱机制 */
#define MULTI_OS_SANDBOX_ENABLED 1
#define MULTI_OS_SANDBOX_WINDOWS 1
#define MULTI_OS_SANDBOX_MACOS 1
#define MULTI_OS_SANDBOX_ANDROID 1

/* 访问控制 */
#define MULTI_OS_MAC_ENABLED 1
#define MULTI_OS_AUDIT_ENABLED 1

/* 安全级别 */
typedef enum {
    MULTI_OS_SECURITY_LEVEL_LOW = 0,
    MULTI_OS_SECURITY_LEVEL_MEDIUM,
    MULTI_OS_SECURITY_LEVEL_HIGH,
    MULTI_OS_SECURITY_LEVEL_PARANOID
} multi_os_security_level_t;

/* 沙箱类型 */
typedef enum {
    MULTI_OS_SANDBOX_TYPE_NONE = 0,
    MULTI_OS_SANDBOX_TYPE_LINUX,
    MULTI_OS_SANDBOX_TYPE_WINDOWS,
    MULTI_OS_SANDBOX_TYPE_MACOS,
    MULTI_OS_SANDBOX_TYPE_ANDROID
} multi_os_sandbox_type_t;

/* 沙箱配置 */
struct multi_os_sandbox_config {
    int enabled;
    multi_os_sandbox_type_t type;
    int restrict_fs_access;
    int restrict_network;
    int restrict_syscalls;
    char *allowed_paths[64];
    int allowed_path_count;
};

/* 安全配置 */
struct multi_os_security_config {
    multi_os_security_level_t level;
    int sandbox_enabled;
    int mac_enabled;
    int audit_enabled;
    struct multi_os_sandbox_config sandbox[4];
};

/* 全局安全配置 */
extern struct multi_os_security_config security_config;

/* 安全增强初始化 */
int multi_os_security_init(void);
void multi_os_security_exit(void);

/* 沙箱函数 */
int multi_os_sandbox_create(struct multi_os_sandbox_config *config);
int multi_os_sandbox_destroy(int sandbox_id);
int multi_os_sandbox_attach(int sandbox_id, struct task_struct *tsk);

/* 访问控制函数 */
int multi_os_mac_check(struct task_struct *tsk, int access_type);
int multi_os_mac_set_policy(const char *policy);

/* 安全审计函数 */
void multi_os_audit_log(const char *fmt, ...);
void multi_os_audit_set_enabled(int enabled);

/* 安全级别设置 */
int multi_os_set_security_level(multi_os_security_level_t level);

#endif /* _MULTI_OS_SECURITY_H */
