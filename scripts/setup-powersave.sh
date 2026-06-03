#!/bin/bash
# Multi-OS Linux - 电源管理和节能配置系统
# 兼顾低功耗与高性能的平衡设置

set -e

readonly POWERSAVE_DIR="/etc/multi-os/powersave"
mkdir -p "$POWERSAVE_DIR"

# 创建主电源管理配置
cat > "$POWERSAVE_DIR/powersave.conf" << 'EOF'
# Multi-OS Linux - 电源管理配置
# 平衡模式 - 兼顾功耗和性能

# ------------------------------
# CPU 频率调节
# ------------------------------
GOVERNOR="ondemand"         # 推荐: ondemand (平衡) / schedutil (响应)
MIN_FREQ=0                  # 最小频率 (%) 0 = 自动
MAX_FREQ=100                # 最大频率 (%)
BOOST_ENABLED=true          # CPU 睿频 (Intel) / Turbo Core (AMD)
ENERGY_PERF_BIAS="balance"  # 节能偏向: performance / normal / balance / power

# ------------------------------
# 空闲管理
# ------------------------------
CPU_IDLE_GOVERNOR="menu"    # 空闲调度: menu / ladder / teo
DEEP_IDLE_ENABLED=true      # 深度休眠
C1E_ENABLED=true            # C1E 低功耗
HWP_ENABLED=true            # Intel HWP (硬件电源管理)

# ------------------------------
# PCIe 和设备电源管理
# ------------------------------
PCIE_ASPM="performance"     # PCIe 节能: powersave / performance / default
RUNTIME_PM_ENABLED=true     # 设备运行时电源管理
WIFI_PM=true                # WiFi 电源管理
BLUETOOTH_PM=true           # 蓝牙电源管理

# ------------------------------
# 显示和图形
# ------------------------------
GPU_GOVERNOR="auto"         # GPU 调节: auto / high / low
DISPLAY_PM_TIMEOUT=300      # 显示节能超时 (秒)
BACKLIGHT_PM=true           # 背光亮度自动调节

# ------------------------------
# 存储和 IO
# ------------------------------
DISK_PM_ENABLED=true        # 硬盘休眠
DISK_SPINDOWN_TIMEOUT=1800  # 硬盘休眠超时 (秒)
IO_SCHEDULER="mq-deadline"  # IO 调度: mq-deadline / bfq / none
ALPM_POLICY="min_power"     # SATA 链路电源管理

# ------------------------------
# 内存和交换
# ------------------------------
ZRAM_ENABLED=true           # 内存压缩
SWAPPINESS=10               # 交换使用倾向 (0-100)
VFS_CACHE_PRESSURE=50       # 缓存压力 (0-100)
DIRTY_RATIO=20              # 脏页比率 (%)
DIRTY_BACKGROUND_RATIO=5    # 后台脏页比率 (%)

# ------------------------------
# 网络
# ------------------------------
TCP_WINDOW_SCALING=true     # TCP 窗口缩放
TCP_TIMESTAMPS=true         # TCP 时间戳
TCP_SACK=true               # TCP 选择确认
TCP_FACK=true               # TCP 快速转发
TCP_CUBIC_CONGESTION=y      # Cubic 拥塞控制 (默认)

# ------------------------------
# 多平台兼容性功耗设置
# ------------------------------
WINE_POWER_MODE="balance"   # Wine 电源模式: balance / high-performance
DARLING_POWER_MODE="auto"   # Darling 电源模式: auto / low / high
GAME_MODE_POWER_BOOST=true  # 游戏时自动增强性能
EOF

# 创建性能模式配置
cat > "$POWERSAVE_DIR/performance.conf" << 'EOF'
# 高性能模式 - 最大化性能
GOVERNOR="performance"
MIN_FREQ=100
MAX_FREQ=100
ENERGY_PERF_BIAS="performance"
BOOST_ENABLED=true
PCIE_ASPM="performance"
RUNTIME_PM_ENABLED=false
EOF

# 创建节能模式配置
cat > "$POWERSAVE_DIR/eco.conf" << 'EOF'
# 极端节能模式 - 最大化续航
GOVERNOR="powersave"
MIN_FREQ=0
MAX_FREQ=80
ENERGY_PERF_BIAS="power"
BOOST_ENABLED=false
PCIE_ASPM="powersave"
RUNTIME_PM_ENABLED=true
DISPLAY_PM_TIMEOUT=120
DISK_SPINDOWN_TIMEOUT=300
EOF

# 创建游戏模式配置
cat > "$POWERSAVE_DIR/gaming.conf" << 'EOF'
# 游戏模式 - 游戏专用优化
GOVERNOR="performance"
MIN_FREQ=100
MAX_FREQ=100
ENERGY_PERF_BIAS="performance"
BOOST_ENABLED=true
PCIE_ASPM="performance"
RUNTIME_PM_ENABLED=false
GPU_GOVERNOR="high"
WINE_POWER_MODE="high-performance"
EOF

# 创建电源管理服务脚本
cat > "$POWERSAVE_DIR/powersave-service.sh" << 'EOF'
#!/bin/bash
# Multi-OS Linux - 电源管理服务

POWERSAVE_CONF="/etc/multi-os/powersave/powersave.conf"

load_config() {
    [ -f "$POWERSAVE_CONF" ] && source "$POWERSAVE_CONF"
}

# 应用配置
apply_config() {
    echo "🔋 应用电源管理配置..."
    
    # 设置 CPU 调速器
    local GOVERNOR=${GOVERNOR:-"ondemand"}
    for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
        echo "$GOVERNOR" > "$CPU/cpufreq/scaling_governor" 2>/dev/null || true
    done
    
    # 设置能量性能偏向 (Intel)
    if [ -f /sys/devices/system/cpu/intel_pstate/energy_perf_preference ]; then
        local EPP=${ENERGY_PERF_BIAS:-"balance"}
        case "$EPP" in
            performance) echo 0 > /sys/devices/system/cpu/intel_pstate/energy_perf_preference 2>/dev/null ;;
            normal)      echo 6 > /sys/devices/system/cpu/intel_pstate/energy_perf_preference 2>/dev/null ;;
            balance)     echo 12 > /sys/devices/system/cpu/intel_pstate/energy_perf_preference 2>/dev/null ;;
            power)       echo 255 > /sys/devices/system/cpu/intel_pstate/energy_perf_preference 2>/dev/null ;;
        esac
    fi
    
    # 设置 PCIe ASPM
    if [ -f /sys/module/pcie_aspm/parameters/policy ]; then
        local ASPM=${PCIE_ASPM:-"default"}
        echo "$ASPM" > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
    fi
    
    # 调整虚拟内存
    local SWAPPINESS=${SWAPPINESS:-10}
    echo "$SWAPPINESS" > /proc/sys/vm/swappiness 2>/dev/null || true
    
    local VFS=${VFS_CACHE_PRESSURE:-50}
    echo "$VFS" > /proc/sys/vm/vfs_cache_pressure 2>/dev/null || true
    
    echo "✅ 电源配置已应用"
}

# 显示当前电源状态
show_status() {
    echo "=== Multi-OS Linux 电源状态 ==="
    echo ""
    
    # CPU 信息
    echo "💻 CPU 状态:"
    for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
        local CUR_FREQ=$(cat "$CPU/cpufreq/scaling_cur_freq" 2>/dev/null || echo "N/A")
        local GOVERNOR=$(cat "$CPU/cpufreq/scaling_governor" 2>/dev/null || echo "N/A")
        echo "  $CPU: $CUR_FREQ KHz, Governor: $GOVERNOR"
    done
    
    # 温度
    echo ""
    echo "🌡️  温度 (°C):"
    for ZONE in /sys/class/thermal/thermal_zone*; do
        if [ -f "$ZONE/temp" ]; then
            local TEMP=$(cat "$ZONE/temp" 2>/dev/null)
            local TYPE=$(cat "$ZONE/type" 2>/dev/null)
            if [ -n "$TEMP" ]; then
                echo "  $TYPE: $(( TEMP / 1000 ))°C"
            fi
        fi
    done
    
    # 电池信息
    if [ -d /sys/class/power_supply/BAT0 ]; then
        echo ""
        echo "🔋 电池状态:"
        local CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "N/A")
        local STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "N/A")
        echo "  电量: $CAPACITY%"
        echo "  状态: $STATUS"
    fi
}

# 切换模式
switch_mode() {
    local MODE="$1"
    local MODE_FILE="$POWERSAVE_DIR/$MODE.conf"
    
    if [ ! -f "$MODE_FILE" ]; then
        echo "❌ 未知模式: $MODE"
        echo "可用模式: balance / performance / eco / gaming"
        return 1
    fi
    
    echo "🔄 切换到 $MODE 模式..."
    cp "$MODE_FILE" "$POWERSAVE_CONF"
    load_config
    apply_config
}

# 主函数
main() {
    load_config
    
    case "${1:-}" in
        apply)
            apply_config
            ;;
        status)
            show_status
            ;;
        mode)
            shift
            switch_mode "$1"
            ;;
        *)
            echo "用法: $0 {apply|status|mode|help}"
            echo ""
            echo "命令:"
            echo "  apply     - 应用当前配置"
            echo "  status    - 显示电源状态"
            echo "  mode MODE - 切换模式 (balance/performance/eco/gaming)"
            echo "  help      - 显示帮助"
            ;;
    esac
}

main "$@"
EOF

chmod +x "$POWERSAVE_DIR/powersave-service.sh"

echo "✅ 电源管理配置已创建: $POWERSAVE_DIR"
echo "📋 可用配置："
echo "  - 平衡模式 (默认)"
echo "  - 高性能模式"
echo "  - 极端节能模式"
echo "  - 游戏模式"
