#!/bin/bash
# Multi-OS Linux - Waydroid Android 启动脚本

WAYDROID_CONFIG="${HOME}/.multi-os/config/waydroid.yml"
WAYDROID_DATA="${HOME}/.multi-os/android"

# 检查 Waydroid 是否安装
if ! command -v waydroid &> /dev/null; then
    echo "❌ Waydroid 未安装"
    echo "请运行: sudo apt-get install waydroid"
    exit 1
fi

# 检查 Android 镜像
if [ ! -d "$WAYDROID_DATA/images" ]; then
    echo "📥 初始化 Waydroid (首次运行)..."
    waydroid init
fi

# 启动 Waydroid 会话
echo "🚀 启动 Android 环境..."
waydroid session start

# 显示状态
waydroid session info

echo ""
echo "✅ Android 环境已启动！"
echo "📱 使用说明:"
echo "  waydroid launch --package <package>  # 启动应用"
echo "  waydroid app list                    # 列出已安装应用"
echo "  waydroid session stop                 # 停止会话"
