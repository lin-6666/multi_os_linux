#!/bin/bash
#
# Multi-OS Linux - 性能测试脚本
#
# 测试系统性能

set -e

echo "=========================================="
echo "Multi-OS Linux 性能测试脚本"
echo "=========================================="
echo ""

# 检查是否有benchmark工具
if command -v sysbench &> /dev/null; then
    echo "1. CPU性能测试..."
    sysbench --test=cpu --cpu-max-prime=2000 run
    echo ""
else
    echo "1. CPU性能测试: sysbench未安装，跳过"
    echo ""
fi

# 内存测试
echo "2. 内存带宽测试..."
if [ -f "/proc/meminfo" ]; then
    echo "   内存信息:"
    cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached)"
fi
echo ""

# 磁盘I/O测试
echo "3. 磁盘I/O测试..."
if command -v dd &> /dev/null; then
    echo "   写入测试..."
    dd if=/dev/zero of=/tmp/test bs=1M count=100 2>&1 || true
    echo "   读取测试..."
    dd if=/tmp/test of=/dev/null bs=1M 2>&1 || true
    rm -f /tmp/test
fi
echo ""

# 网络测试
echo "4. 网络延迟测试..."
if command -v ping &> /dev/null; then
    ping -c 3 8.8.8.8 2>&1 || true
fi
echo ""

echo "=========================================="
echo "性能测试完成"
echo "=========================================="
echo ""
