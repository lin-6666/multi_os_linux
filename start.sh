#!/bin/bash

echo "======================================"
echo "多平台兼容系统 - 快速开始脚本"
echo "======================================"
echo ""

# 检查环境
echo "[1/5] 检查系统环境..."
if [ ! -d "/workspace/multi-os-compat" ]; then
    echo "错误: 项目目录不存在！"
    exit 1
fi

echo "✓ 项目目录存在"

# 检查依赖
echo ""
echo "[2/5] 检查编译依赖..."
DEPS=("gcc" "g++" "make" "cmake" "git" "wget")
MISSING=""

for dep in "${DEPS[@]}"; do
    if ! command -v $dep &> /dev/null; then
        MISSING="$MISSING $dep"
    fi
done

if [ -n "$MISSING" ]; then
    echo "⚠ 缺少依赖:$MISSING"
    echo "  安装命令: sudo apt-get update && sudo apt-get install$MISSING"
else
    echo "✓ 所有依赖已安装"
fi

# 检查源码
echo ""
echo "[3/5] 检查源码状态..."
SOURCES_DIR="/workspace/multi-os-compat/sources"

if [ -d "$SOURCES_DIR/wine" ]; then
    echo "✓ Wine源码: 已下载"
else
    echo "✗ Wine源码: 未下载"
fi

if [ -d "$SOURCES_DIR/darling" ]; then
    echo "✓ Darling源码: 已下载"
else
    echo "✗ Darling源码: 未下载"
fi

if [ -f "$SOURCES_DIR/linux-6.8.12.tar.xz" ]; then
    echo "✓ Linux内核: 已下载"
elif [ -d "$SOURCES_DIR/linux-6.8.12" ]; then
    echo "✓ Linux内核: 已提取"
else
    echo "⚠ Linux内核: 下载中..."
fi

# 显示文档
echo ""
echo "[4/5] 项目文档..."
echo ""
echo "主要文档:"
echo "  - 项目规划: /workspace/multi-os-compat/docs/PROJECT_PLAN.md"
echo "  - 技术架构: /workspace/multi-os-compat/docs/TECHNICAL_ARCHITECTURE.md"
echo "  - 项目说明: /workspace/multi-os-compat/README.md"
echo ""

# 下一步
echo "[5/5] 下一步操作..."
echo ""
echo "Phase 1: LFS基础系统构建"
echo "  1. 准备目标分区"
echo "  2. 安装临时工具链"
echo "  3. 构建最终系统"
echo "  4. 编译Linux内核"
echo "  5. 配置引导程序"
echo ""
echo "Phase 2: Wine集成"
echo "  1. 安装Wine依赖"
echo "  2. 编译Wine源码"
echo "  3. 配置Windows DLL"
echo ""
echo "Phase 3: Darling集成"
echo "  1. 安装Darling依赖"
echo "  2. 编译Darling内核模块"
echo "  3. 编译Darling用户空间"
echo ""
echo "Phase 4: 系统集成"
echo "  1. 创建统一启动器"
echo "  2. 配置库路径"
echo "  3. 桌面集成"
echo "  4. 测试和优化"
echo ""

echo "======================================"
echo "准备就绪！可以开始构建了。"
echo "======================================"
