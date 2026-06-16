---
applyTo: "**/*.{yml,yaml}"
---

# YAML/配置文件审查规则

适用于所有 YAML 配置文件，包括:
- GitHub Actions 工作流
- Ansible 剧本
- Kubernetes 配置
- 项目配置文件

## 安全规则

### 🔴 CRITICAL - 必须检查

1. **密钥处理**
   - 不允许在仓库中硬编码密码、API keys、tokens
   - 必须使用 `$` 或 `${{ secrets.xxx }}` 引用敏感值
   - 使用 `.env` 文件（必须在 `.gitignore` 中）

2. **GitHub Actions 安全**
   - 使用固定的提交哈希而不是标签引用外部 actions
   - ❌ `uses: actions/checkout@v4`
   - ✅ `uses: actions/checkout@a5ac7e51b41094c92402da3b243769856dedfc81 # v4.1.7`
   - `pull_request_target` 事件必须有特殊防护

3. **权限最小化**
   - 显式声明 `permissions:` 而不是依赖默认
   - Token 权限应该是完成任务所需的最小集合

## 格式和结构

1. 使用 2 空格缩进
2. 列表项对齐
3. 复杂值使用多行 YAML 而不是内联 JSON
4. 使用注释解释非显而易见的配置

### ✅ 推荐格式

```yaml
# GitHub Actions 工作流权限声明
permissions:
  contents: read        # 只需要读取代码
  packages: write       # 需要发布 Docker 镜像
  pull-requests: read   # 需要读取 PR 信息

# 使用固定 SHA 而不是标签
- uses: actions/checkout@a5ac7e51b41094c92402da3b243769856dedfc81
  name: Checkout code
  with:
    ref: ${{ github.ref }}
```

## GitHub Actions 特定规则

1. 每个 job 必须设置 `timeout-minutes:`
2. 每个 step 有清晰描述性的 `name:`
3. 缓存配置必须有合理的 key 格式
4. secrets 的使用必须记录在文档中

## YAML 常见陷阱

1. ❌ `yes/no` 可能被解析为布尔值 - 使用字符串
2. ❌ 制表符而不是空格缩进
3. ❌ 缺少空格的冒号 `key:value`
4. ❌ 特殊字符未引用 `#`, `:`, `{`, `}`

## 本项目约定

### 内核配置 YAML 文件

```yaml
# config/ 目录中的文件使用以下格式
kernel_options:
  # 必需选项
  CONFIG_MULTI_OS: y
  
  # 可选功能
  CONFIG_ANDROID_COMPAT: y  # Android 兼容层
  CONFIG_WINE_COMPAT: y     # Wine 支持
```

---

*此指令确保 YAML 配置一致且安全*
