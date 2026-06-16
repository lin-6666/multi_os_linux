#!/bin/bash
#
# Multi-OS Linux - 项目自我审查和修复脚本
#
# 自动识别项目中的潜在问题并提供修复建议

set -e

echo "=========================================="
echo "Multi-OS Linux 项目审查脚本"
echo "=========================================="
echo ""

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# 统计变量
ISSUES_FOUND=0
WARNINGS_FOUND=0
SUGGESTIONS_FOUND=0

# 创建报告文件
REPORT_FILE="$PROJECT_ROOT/AI_REVIEW_REPORT.md"
echo "# Multi-OS Linux AI 审查报告" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
echo "项目路径: $PROJECT_ROOT" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ========================================
# 1. 项目结构审查
# ========================================
echo "1. 审查项目结构..."

STRUCTURE_CHECK=$(cat >> "$REPORT_FILE" << 'EOF'
## 1. 项目结构审查

### 检查项
EOF
)

# 检查关键目录
ESSENTIAL_DIRS=(
    "scripts"
    "config"
    "docs"
    "kernel-dev"
    ".github"
)

for dir in "${ESSENTIAL_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        echo "  ✅ 目录存在: $dir" | tee -a "$REPORT_FILE"
    else
        echo "  ❌ 目录缺失: $dir" | tee -a "$REPORT_FILE"
        ((ISSUES_FOUND++))
    fi
done

# 检查关键文件
ESSENTIAL_FILES=(
    "README.md"
    "LICENSE"
    ".gitignore"
    "upload-to-github.sh"
)

for file in "${ESSENTIAL_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        echo "  ✅ 文件存在: $file" | tee -a "$REPORT_FILE"
    else
        echo "  ❌ 文件缺失: $file" | tee -a "$REPORT_FILE"
        ((ISSUES_FOUND++))
    fi
done

echo "" >> "$REPORT_FILE"

# ========================================
# 2. Shell 脚本审查
# ========================================
echo "2. 审查 Shell 脚本..."

SCRIPT_CHECK=$(cat >> "$REPORT_FILE" << 'EOF'
## 2. Shell 脚本审查

### 发现的问题
EOF
)

# 检查所有 .sh 文件
SHELL_ISSUES=0
while IFS= read -r -d '' script; do
    # 检查是否有 shebang
    if ! head -1 "$script" | grep -q '^#!'; then
        echo "  ⚠️ 缺少 shebang: $script" | tee -a "$REPORT_FILE"
        ((SHELL_ISSUES++))
    fi
    
    # 检查是否有 set -e
    if ! grep -q 'set -' "$script"; then
        echo "  ⚠️ 建议添加错误处理: $script" | tee -a "$REPORT_FILE"
        ((WARNINGS_FOUND++))
    fi
    
    # 检查文件权限
    if [ ! -x "$script" ]; then
        echo "  💡 建议添加执行权限: $script" | tee -a "$REPORT_FILE"
        ((SUGGESTIONS_FOUND++))
    fi
    
done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -print0)

if [ $SHELL_ISSUES -eq 0 ]; then
    echo "  ✅ 所有脚本都有 shebang" | tee -a "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ========================================
# 3. GitHub Actions 审查
# ========================================
echo "3. 审查 GitHub Actions..."

ACTIONS_CHECK=$(cat >> "$REPORT_FILE" << 'EOF'
## 3. GitHub Actions 审查

### 工作流文件
EOF
)

if [ -d "$PROJECT_ROOT/.github/workflows" ]; then
    WORKFLOW_COUNT=$(find "$PROJECT_ROOT/.github/workflows" -name "*.yml" -o -name "*.yaml" | wc -l)
    echo "  ✅ 发现 $WORKFLOW_COUNT 个工作流文件" | tee -a "$REPORT_FILE"
    
    # 列出工作流
    find "$PROJECT_ROOT/.github/workflows" -name "*.yml" -o -name "*.yaml" | while read workflow; do
        echo "  - $(basename "$workflow")" | tee -a "$REPORT_FILE"
    done
else
    echo "  ❌ 缺少 workflows 目录" | tee -a "$REPORT_FILE"
    ((ISSUES_FOUND++))
fi

# 检查工作流配置
if grep -rq "on:" "$PROJECT_ROOT/.github/workflows/" 2>/dev/null; then
    echo "  ✅ 工作流触发器配置正确" | tee -a "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ========================================
# 4. 文档完整性审查
# ========================================
echo "4. 审查文档完整性..."

DOCS_CHECK=$(cat >> "$REPORT_FILE" << 'EOF'
## 4. 文档完整性审查

### 必需文档
EOF
)

REQUIRED_DOCS=(
    "README.md:项目主页"
    "LICENSE:许可证"
    "docs/QUICK_START.md:快速开始"
    "docs/GITHUB_AI_GUIDE.md:GitHub AI指南"
)

for doc_info in "${REQUIRED_DOCS[@]}"; do
    IFS=':' read -r doc_path doc_name <<< "$doc_info"
    if [ -f "$PROJECT_ROOT/$doc_path" ]; then
        # 检查文档是否为空
        if [ -s "$PROJECT_ROOT/$doc_path" ]; then
            echo "  ✅ $doc_name ($doc_path)" | tee -a "$REPORT_FILE"
        else
            echo "  ❌ $doc_name 为空 ($doc_path)" | tee -a "$REPORT_FILE"
            ((ISSUES_FOUND++))
        fi
    else
        echo "  ⚠️ 缺少 $doc_name ($doc_path)" | tee -a "$REPORT_FILE"
        ((WARNINGS_FOUND++))
    fi
done

echo "" >> "$REPORT_FILE"

# ========================================
# 5. 代码质量审查
# ========================================
echo "5. 审查代码质量..."

CODE_CHECK=$(cat >> "$REPORT_FILE" << 'EOF'
## 5. 代码质量审查

### 潜在问题
EOF
)

# 检查硬编码路径
HARDCODED_PATHS=$(find "$PROJECT_ROOT" -type f \( -name "*.sh" -o -name "*.py" \) -exec grep -l "/home/" {} \; 2>/dev/null || true)
if [ -n "$HARDCODED_PATHS" ]; then
    echo "  ⚠️ 发现硬编码路径:" | tee -a "$REPORT_FILE"
    echo "$HARDCODED_PATHS" | while read file; do
        echo "    - $file" | tee -a "$REPORT_FILE"
    done
    ((WARNINGS_FOUND++))
else
    echo "  ✅ 没有硬编码路径" | tee -a "$REPORT_FILE"
fi

# 检查 TODO 注释
TODO_COUNT=$(grep -r "TODO\|FIXME\|XXX" "$PROJECT_ROOT" --include="*.sh" --include="*.py" --include="*.c" --include="*.h" 2>/dev/null | wc -l)
if [ $TODO_COUNT -gt 0 ]; then
    echo "  📝 发现 $TODO_COUNT 个 TODO/FIXME 注释" | tee -a "$REPORT_FILE"
    ((SUGGESTIONS_FOUND++))
fi

# 检查调试代码
DEBUG_CODE=$(grep -r "echo.*debug\|console.log\|print.*debug" "$PROJECT_ROOT" --include="*.sh" --include="*.py" 2>/dev/null || true)
if [ -n "$DEBUG_CODE" ]; then
    echo "  💡 建议移除调试代码或使用日志框架" | tee -a "$REPORT_FILE"
    ((SUGGESTIONS_FOUND++))
fi

echo "" >> "$REPORT_FILE"

# ========================================
# 6. 安全性审查
# ========================================
echo "6. 审查安全性..."

SECURITY_CHECK=$(cat >> "$REPORT_FILE" << 'EOF'
## 6. 安全性审查

### 安全检查
EOF
)

# 检查是否有敏感信息
SENSITIVE_PATTERNS=(
    "password="
    "token="
    "secret="
    "api_key="
    "PRIVATE KEY"
)

SECURITY_ISSUES=0
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -rq "$pattern" "$PROJECT_ROOT" --include="*.sh" --include="*.py" --include="*.yml" --include="*.yaml" 2>/dev/null; then
        echo "  ⚠️ 发现可能的敏感信息: $pattern" | tee -a "$REPORT_FILE"
        ((SECURITY_ISSUES++))
    fi
done

if [ $SECURITY_ISSUES -eq 0 ]; then
    echo "  ✅ 没有发现明显的敏感信息泄露" | tee -a "$REPORT_FILE"
fi

# 检查 .gitignore
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    if grep -q "\.env" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
        echo "  ✅ .gitignore 已包含 .env" | tee -a "$REPORT_FILE"
    else
        echo "  💡 建议在 .gitignore 中添加 .env" | tee -a "$REPORT_FILE"
        ((SUGGESTIONS_FOUND++))
    fi
fi

echo "" >> "$REPORT_FILE"

# ========================================
# 7. 依赖审查
# ========================================
echo "7. 审查依赖..."

DEPS_CHECK=$(cat >> "$REPORT_FILE" << 'EOF'
## 7. 依赖审查

### 外部依赖
EOF
)

# 检查 requirements.txt
if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    echo "  ✅ requirements.txt 存在" | tee -a "$REPORT_FILE"
    DEP_COUNT=$(wc -l < "$PROJECT_ROOT/requirements.txt")
    echo "    包含 $DEP_COUNT 个依赖" | tee -a "$REPORT_FILE"
else
    echo "  💡 建议添加 requirements.txt（如果使用 Python）" | tee -a "$REPORT_FILE"
    ((SUGGESTIONS_FOUND++))
fi

# 检查 package.json
if [ -f "$PROJECT_ROOT/package.json" ]; then
    echo "  ✅ package.json 存在" | tee -a "$REPORT_FILE"
else
    echo "  ℹ️ 未使用 npm（正常）" | tee -a "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ========================================
# 8. Git 配置审查
# ========================================
echo "8. 审查 Git 配置..."

GIT_CHECK=$(cat >> "$REPORT_FILE" << 'EOF'
## 8. Git 配置审查

### Git 状态
EOF
)

if [ -d "$PROJECT_ROOT/.git" ]; then
    echo "  ✅ Git 仓库已初始化" | tee -a "$REPORT_FILE"
    
    # 检查远程仓库
    REMOTE=$(git remote get-url origin 2>/dev/null || echo "未设置")
    echo "  远程仓库: $REMOTE" | tee -a "$REPORT_FILE"
    
    # 检查未提交的更改
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l)
    if [ $UNCOMMITTED -gt 0 ]; then
        echo "  ⚠️ 有 $UNCOMMITTED 个未提交的更改" | tee -a "$REPORT_FILE"
        ((WARNINGS_FOUND++))
    else
        echo "  ✅ 所有更改已提交" | tee -a "$REPORT_FILE"
    fi
else
    echo "  ❌ Git 仓库未初始化" | tee -a "$REPORT_FILE"
    ((ISSUES_FOUND++))
fi

echo "" >> "$REPORT_FILE"

# ========================================
# 生成 AI 审查提示
# ========================================
echo "9. 生成 AI 审查提示..." >> "$REPORT_FILE"

AI_PROMPTS=$(cat >> "$REPORT_FILE" << 'EOF'
## 9. GitHub AI 审查提示

### 发送给 GitHub Copilot 的问题

上传到 GitHub 后，可以在 Issue 或 Discussion 中使用以下提示：

#### 安全问题审查
```
@github-cotributor 请审查这个项目的安全性，特别关注：
1. Shell 脚本中的命令注入风险
2. 敏感信息处理
3. 权限要求
4. 文件操作安全
```

#### 代码质量审查
```
@github-cotributor 请审查代码质量：
1. 代码结构和组织
2. 错误处理
3. 性能考虑
4. 可维护性
```

#### 文档审查
```
@github-cotributor 请审查文档：
1. 完整性
2. 清晰度
3. 准确性
4. 示例是否充分
```

#### 架构审查
```
@github-cotributor 请审查项目架构：
1. 模块化设计
2. 依赖关系
3. 可扩展性
4. 最佳实践
```

EOF
)

echo "" >> "$REPORT_FILE"

# ========================================
# 总结
# ========================================
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## 审查总结" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| 类型 | 数量 |" >> "$REPORT_FILE"
echo "|------|------|" >> "$REPORT_FILE"
echo "| 🔴 问题 | $ISSUES_FOUND |" >> "$REPORT_FILE"
echo "| 🟡 警告 | $WARNINGS_FOUND |" >> "$REPORT_FILE"
echo "| 💡 建议 | $SUGGESTIONS_FOUND |" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo "✅ **状态：项目可以上传！**" >> "$REPORT_FILE"
else
    echo "⚠️ **建议：修复 $ISSUES_FOUND 个问题后再上传**" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "*此报告由 audit-and-fix.sh 自动生成*" >> "$REPORT_FILE"

# 显示报告
cat "$REPORT_FILE"

echo ""
echo "=========================================="
echo "审查完成！"
echo "=========================================="
echo ""
echo "报告已保存到: $REPORT_FILE"
echo ""
echo "审查结果："
echo "  🔴 问题: $ISSUES_FOUND"
echo "  🟡 警告: $WARNINGS_FOUND"
echo "  💡 建议: $SUGGESTIONS_FOUND"
echo ""

if [ $ISSUES_FOUND -gt 0 ]; then
    echo "建议修复上述问题后再上传到 GitHub。"
    exit 1
else
    echo "✅ 项目已准备好上传！"
    exit 0
fi
