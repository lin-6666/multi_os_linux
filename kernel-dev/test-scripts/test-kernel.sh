#!/bin/bash
#
# Multi-OS Linux - 内核测试脚本
#
# 测试内核的基本功能

set -e

echo "=========================================="
echo "Multi-OS Linux 内核测试脚本"
echo "=========================================="
echo ""

# 检查系统信息
echo "1. 检查系统信息..."
echo "   内核版本: $(uname -r)"
echo "   系统架构: $(uname -m)"
echo "   操作系统: $(uname -o)"
echo ""

# 检查Multi-OS Linux特性
echo "2. 检查Multi-OS Linux特性..."
if [ -f "/proc/version" ]; then
    echo "   /proc/version: $(cat /proc/version)"
fi
echo ""

# 检查系统调用
echo "3. 检查系统调用..."
if command -v strace &> /dev/null; then
    echo "   strace可用，可用于调试系统调用"
else
    echo "   strace未安装"
fi
echo ""

# 检查网络配置
echo "4. 检查网络配置..."
if command -v ip &> /dev/null; then
    echo "   网络接口:"
    ip link show | head -20
fi
echo ""

# 检查CPU信息
echo "5. 检查CPU信息..."
if [ -f "/proc/cpuinfo" ]; then
    echo "   CPU核心数: $(nproc)"
    echo "   CPU型号: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed -e 's/^ *//')"
fi
echo ""

# 检查内存信息
echo "6. 检查内存信息..."
if command -v free &> /dev/null; then
    free -h
fi
echo ""

# 检查模块加载
echo "7. 检查内核模块..."
echo "   已加载模块数: $(lsmod | wc -l)"
echo ""

# 检查挂载的文件系统
echo "8. 检查挂载的文件系统..."
df -h | head -10
echo ""

# 检查进程信息
echo "9. 检查进程信息..."
echo "   进程总数: $(ps aux | wc -l)"
echo ""

# 总结
echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "如需更详细的测试，请运行其他测试脚本"
echo ""
