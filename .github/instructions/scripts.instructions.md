---
applyTo: "**/scripts/**/*.sh"
excludeAgent: ["coding-agent"]
---

# Shell 脚本审查规则

仅适用于 `scripts/` 目录中的 Shell 脚本

## 强制执行的安全规则

### 脚本开头必须包含以下内容

1. `#!/bin/bash` 或 `#!/usr/bin/env bash` - 清晰的 shebang
2. `set -euo pipefail` - 脚本健壮性设置
3. 简短的描述注释 - 说明脚本用途

### 必须始终检查的内容

1. 所有用户输入必须验证
2. 所有路径变量必须加引号引用
3. 所有文件删除操作必须验证路径
4. 所有外部命令执行必须检查返回值
5. 必须使用 `mktemp` 创建临时文件
6. 必须设置 `trap` 进行清理

### 禁止的做法

1. ❌ 使用 `eval` - 除非绝对必要并有详细的安全理由
2. ❌ 使用 `curl | bash` 模式 - 远程脚本执行
3. ❌ 未验证的用户输入传递给命令执行
4. ❌ `rm -rf $VARIABLE/` - 未检查 $VARIABLE 是否为空
5. ❌ `|| true` - 静默失败掩盖错误
6. ❌ 无 shebang 的 .sh 文件

### 正确的错误处理模式

```bash
# ✅ 正确: 检查每个关键操作
if ! tar -xzf "$TARBALL" -C "$EXTRACT_DIR"; then
    echo "错误: 无法解压文件 $TARBALL" >&2
    exit 1
fi

# ✅ 正确: 管道错误处理
set -o pipefail
wget -O- "$URL" | tar -xz || {
    echo "错误: 下载或解压失败" >&2
    exit 1
}
```

## 性能优化建议

### 避免的反模式

1. ❌ 循环内执行外部命令 (如多次 grep/awk/sed)
2. ❌ 重复计算相同的值而不缓存
3. ❌ 不必要的 subshell `$(command)` 调用

### 推荐的优化

1. ✅ 使用 awk/ripgrep 替代多次 grep/sed
2. ✅ 缓存耗时操作的结果
3. ✅ 用 bash 内置操作替代外部命令

## 可维护性标准

1. 单一脚本不超过 500 行
2. 单一函数不超过 80 行
3. 嵌套深度不超过 4 层
4. 所有公共函数必须有 docstring 注释

## 测试要求

1. 主函数必须有对应的测试脚本
2. 必须至少覆盖一条成功路径和一条错误路径
3. 不应该依赖网络访问（除非是网络工具脚本）

## 本项目特定的脚本规则

### 对于多平台兼容脚本

1. 检查 `uname` 输出而不是硬编码平台
2. 使用 `command -v` 而不是 `which` 检查依赖
3. 提供 Linux/macOS/BSD 的替代方案
4. 避免使用 GNU 扩展的特定语法

### 对于内核构建脚本

1. 检查 make/gcc 版本
2. 验证所需磁盘空间
3. 检查并行作业数不超过 CPU 核心数
