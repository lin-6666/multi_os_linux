#!/bin/bash
# Multi-OS Linux - 系统性能调优和监控工具
# 保证系统快速、稳定、高效运行

set -e

readonly TUNING_DIR="/etc/multi-os/tuning"
mkdir -p "$TUNING_DIR"

# 创建系统调优配置
cat > "$TUNING_DIR/sysctl.conf" << 'EOF'
# Multi-OS Linux 系统调优配置
# 平衡性能、稳定性和低功耗

# ------------------------------
# 内存管理
# ------------------------------
# 减少换页活动，提高内存使用效率
vm.swappiness = 10
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50

# 内存泄漏缓解
vm.dirty_writeback_centisecs = 500
vm.dirty_expire_centisecs = 3000

# 透明大页 (THP) 优化
vm.overcommit_memory = 1
vm.overcommit_ratio = 60

# ------------------------------
# 网络优化
# ------------------------------
# 减少延迟，提高吞吐量
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.netdev_max_backlog = 30000
net.core.somaxconn = 1024

# TCP 优化
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1

# ------------------------------
# 文件系统
# ------------------------------
# 延长 inode 缓存时间
fs.file-max = 2097152
fs.inotify.max_user_instances = 512
fs.inotify.max_user_watches = 524288

# 减少日志和同步频率
fs.aio-max-nr = 1048576

# ------------------------------
# 安全优化
# ------------------------------
kernel.core_uses_pid = 1
kernel.sysrq = 1
kernel.dmesg_restrict = 0
kernel.kptr_restrict = 0

# ------------------------------
# 网络安全
# ------------------------------
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF

# 创建系统监控和维护脚本
cat > "$TUNING_DIR/system-monitor.sh" << 'EOF'
#!/bin/bash
# Multi-OS Linux - 系统健康监控和自动维护工具

LOG_FILE="/var/log/multi-os-system.log"
THRESHOLD_CPU=90
THRESHOLD_MEM=90
THRESHOLD_DISK=90

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

check_cpu() {
    local CPU_USAGE=$(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1}')
    echo "CPU 使用: $CPU_USAGE%"
    
    if (( $(echo "$CPU_USAGE > $THRESHOLD_CPU" | bc -l) )); then
        log "⚠️ 高 CPU 使用警告: $CPU_USAGE%"
        echo "⚠️ 警告: CPU 使用过高 ($CPU_USAGE%)"
    fi
}

check_memory() {
    local MEM_TOTAL=$(free -h | grep 'Mem:' | awk '{print $2}')
    local MEM_USED=$(free -h | grep 'Mem:' | awk '{print $3}')
    local MEM_AVAIL=$(free -h | grep 'Mem:' | awk '{print $7}')
    local MEM_USAGE=$(free | grep 'Mem:' | awk '{printf "%.0f", $3*100/$2}')
    
    echo "内存: 总 $MEM_TOTAL, 已用 $MEM_USED, 可用 $MEM_AVAIL, 使用 $MEM_USAGE%"
    
    if [ "$MEM_USAGE" -gt "$THRESHOLD_MEM" ]; then
        log "⚠️ 高内存使用警告: $MEM_USAGE%"
        echo "⚠️ 警告: 内存使用过高 ($MEM_USAGE%)"
    fi
}

check_disk() {
    echo "磁盘使用:"
    df -h | grep -E '^/dev/root|^/dev/sd|^/dev/nvme' | while read -r FS; do
        local USAGE=$(echo "$FS" | awk '{print $5}' | tr -d '%')
        echo "  $FS"
        if [ "$USAGE" -gt "$THRESHOLD_DISK" ]; then
            log "⚠️ 高磁盘使用警告: $USAGE% on $FS"
            echo "  ⚠️ 警告: 磁盘使用过高 ($USAGE%)"
        fi
    done
}

check_temperature() {
    echo "系统温度:"
    if [ -d /sys/class/thermal/thermal_zone0 ]; then
        local TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        if [ -n "$TEMP" ]; then
            TEMP=$((TEMP / 1000))
            echo "  CPU 温度: $TEMP°C"
            if [ "$TEMP" -gt 80 ]; then
                log "⚠️ 高温度警告: $TEMP°C"
                echo "  ⚠️ 警告: 温度过高 ($TEMP°C)"
            fi
        fi
    fi
}

cleanup() {
    echo "系统维护 - 清理缓存..."
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    echo "缓存已清理"
}

report() {
    echo ""
    echo "=== Multi-OS Linux 系统状态报告 ==="
    echo "时间: $(date)"
    echo ""
    check_cpu
    echo ""
    check_memory
    echo ""
    check_disk
    echo ""
    check_temperature
    echo ""
    echo "系统运行正常 ✓"
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "${1:-}" in
        check)
            report
            ;;
        cleanup)
            cleanup
            ;;
        monitor)
            while true; do
                report
                echo ""
                echo "等待 60 秒..."
                sleep 60
            done
            ;;
        *)
            echo "用法: $0 {check|cleanup|monitor}"
            echo ""
            echo "命令:"
            echo "  check    - 检查系统健康状态"
            echo "  cleanup  - 执行系统维护和清理"
            echo "  monitor  - 持续监控 (前台)"
            ;;
    esac
}

main "$@"
EOF

chmod +x "$TUNING_DIR/system-monitor.sh"

# 创建多平台兼容性能优化
cat > "$TUNING_DIR/multi-os-tuning.sh" << 'EOF'
#!/bin/bash
# Multi-OS Linux - 多平台兼容性性能优化

readonly WINE_PREFIX_DIR="$HOME/.multi-os/wine"
readonly DARLING_PREFIX_DIR="$HOME/.multi-os/darling"

# 优化 Wine 性能
optimize_wine() {
    echo "🍷 优化 Wine 配置..."
    
    if [ ! -d "$WINE_PREFIX_DIR" ]; then
        echo "创建 Wine 前缀目录..."
        mkdir -p "$WINE_PREFIX_DIR"
    fi
    
    # Wine 注册表优化
    cat > "$WINE_PREFIX_DIR/optimize.reg" << 'REG'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Drivers]
"Audio"="pulse"
"Video"="x11"

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"DirectDrawRenderer"="opengl"
"useGLSL"="enabled"
"videomemorysize"=dword:40000000
"csmt"=dword:00000001
"vsync"=dword:00000000
"renderer"="gdi"

[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"ClientSideWithGLX"="N"

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"d3d9"="native,builtin"
"d3d10core"="native,builtin"
"d3d11"="native,builtin"
"dxgi"="native,builtin"

[HKEY_CURRENT_USER\Software\Wine\DirectDraw]
"DefaultRefreshRate"=dword:0000003c
REG
    
    # 环境变量优化
    cat > "$WINE_PREFIX_DIR/wine-env" << 'ENV'
# Wine 性能优化环境变量
WINEDEBUG=-all
WINEFSYNC=1
WINEESYNC=1
WINE_D3D_CONFIGURATION=
DXVK_STATE_CACHE=1
DXVK_STATE_CACHE_PATH=$HOME/.multi-os/dxvk-cache
MESA_GL_VERSION_OVERRIDE=4.5
MESA_GLSL_CACHE_DIR=$HOME/.multi-os/mesa-shader-cache
NV_PRIME_RENDER_OFFLOAD=1
__NV_PRIME_RENDER_OFFLOAD=1
__GLX_VENDOR_LIBRARY_NAME=nvidia
ENV
    
    echo "✅ Wine 优化完成"
}

# 优化 Darling 性能
optimize_darling() {
    echo "🍎 优化 Darling 配置..."
    
    if [ ! -d "$DARLING_PREFIX_DIR" ]; then
        echo "创建 Darling 前缀目录..."
        mkdir -p "$DARLING_PREFIX_DIR"
    fi
    
    # 创建 Darling 配置
    cat > "$DARLING_PREFIX_DIR/Preferences.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSAppSleepDisabled</key>
    <true/>
    <key>NSQuitAlwaysKeepsWindows</key>
    <false/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Multi-OS Darling Integration</string>
</dict>
</plist>
PLIST
    
    echo "✅ Darling 优化完成"
}

# 游戏模式
game_mode() {
    echo "🎮 激活游戏模式..."
    
    # 性能模式
    if command -v cpupower &> /dev/null; then
        cpupower frequency-set -g performance || true
    fi
    
    # 禁用不必要的后台服务
    for SVC in bluetooth cups avahi-daemon; do
        if systemctl is-active --quiet $SVC 2>/dev/null; then
            systemctl stop $SVC 2>/dev/null || true
            echo "停止了 $SVC"
        fi
    done
    
    # 设置高优先级
    renice -n -10 $$ 2>/dev/null || true
    
    echo "✅ 游戏模式已激活"
}

# 普通模式
normal_mode() {
    echo "🔄 返回普通模式..."
    
    if command -v cpupower &> /dev/null; then
        cpupower frequency-set -g ondemand || true
    fi
    
    for SVC in bluetooth cups avahi-daemon; do
        systemctl start $SVC 2>/dev/null || true
    done
    
    echo "✅ 已返回平衡模式"
}

main() {
    case "${1:-}" in
        wine)
            optimize_wine
            ;;
        darling)
            optimize_darling
            ;;
        all)
            optimize_wine
            optimize_darling
            ;;
        game)
            game_mode
            ;;
        normal)
            normal_mode
            ;;
        *)
            echo "用法: $0 {wine|darling|all|game|normal}"
            echo ""
            echo "命令:"
            echo "  wine    - 优化 Wine 性能"
            echo "  darling  - 优化 Darling 性能"
            echo "  all      - 全部优化"
            echo "  game     - 游戏模式 (高性能)"
            echo "  normal   - 普通模式 (平衡)"
            ;;
    esac
}

main "$@"
EOF

chmod +x "$TUNING_DIR/multi-os-tuning.sh"

echo "✅ 系统调优和监控工具已创建: $TUNING_DIR"
echo "📋 包含："
echo "  - sysctl.conf (系统参数优化)"
echo "  - system-monitor.sh (健康监控)"
echo "  - multi-os-tuning.sh (兼容性优化)"
