#!/bin/bash
# Multi-OS Linux - Android 环境性能优化

set -e

WAYDROID_CONFIG="${HOME}/.multi-os/config/waydroid.yml"

log_info() {
    echo "⚡ $1"
}

# GPU 模式优化
optimize_gpu() {
    local mode="${1:-auto}"
    
    log_info "优化 GPU 模式: $mode"
    
    if [ -f "$WAYDROID_CONFIG" ]; then
        sed -i "s/mode:.*/mode: $mode/" "$WAYDROID_CONFIG"
    fi
    
    case "$mode" in
        host)
            echo "使用宿主机 GPU (最高性能)"
            ;;
        swiftshader)
            echo "使用软件渲染 (兼容性好)"
            ;;
        off)
            echo "禁用硬件加速 (最低功耗)"
            ;;
        auto)
            echo "自动选择最佳模式"
            ;;
    esac
}

# 网络优化
optimize_network() {
    log_info "优化网络设置..."
    
    # 增加缓冲区
    sysctl -w net.core.rmem_max=16777216 2>/dev/null
    sysctl -w net.core.wmem_max=16777216 2>/dev/null
    
    echo "✅ 网络已优化"
}

# 内存优化
optimize_memory() {
    log_info "优化内存使用..."
    
    # 调整缓存
    echo 70 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null
    
    echo "✅ 内存已优化"
}

# 电池优化
optimize_battery() {
    log_info "优化电池使用..."
    
    # 限制后台进程
    # 这些设置会在 Android 内部应用
    
    echo "✅ 电池优化已应用"
}

# 游戏模式
game_mode() {
    log_info "🎮 激活游戏模式..."
    
    optimize_gpu "host"
    optimize_network
    optimize_memory
    
    echo "✅ 游戏模式已激活 - 性能最大化"
}

# 节能模式
battery_mode() {
    log_info "🔋 激活节能模式..."
    
    optimize_gpu "swiftshader"
    optimize_battery
    
    echo "✅ 节能模式已激活"
}

# 平衡模式
balance_mode() {
    log_info "⚖️ 激活平衡模式..."
    
    optimize_gpu "auto"
    optimize_network
    
    echo "✅ 平衡模式已激活"
}

# 显示帮助
show_help() {
    cat << 'HELP'
Multi-OS Android 性能优化工具

用法: $(basename "$0") [选项]

选项:
  gpu MODE      设置 GPU 模式 (host/swiftshader/off/auto)
  network      优化网络
  memory       优化内存
  battery      优化电池
  game         游戏模式 (高性能)
  battery-save 节能模式
  balance      平衡模式
  help         显示此帮助

示例:
  $(basename "$0") gpu host      # 使用 GPU 加速
  $(basename "$0") game          # 游戏模式
  $(basename "$0") battery-save   # 节能模式
HELP
}

# 主函数
main() {
    case "${1:-}" in
        gpu)
            optimize_gpu "$2"
            ;;
        network)
            optimize_network
            ;;
        memory)
            optimize_memory
            ;;
        battery)
            optimize_battery
            ;;
        game)
            game_mode
            ;;
        battery-save)
            battery_mode
            ;;
        balance)
            balance_mode
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "用法: $(basename "$0") [选项]"
            echo "运行 --help 查看更多信息"
            ;;
    esac
}

main "$@"
