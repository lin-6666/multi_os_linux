#!/bin/bash
#
# Multi-OS Linux - 自动更新脚本
#
# 功能:
# 1. 检查 GitHub 最新版本
# 2. 下载并应用更新
# 3. 不影响用户的自定义配置和文件
# 4. 自动备份重要文件
# 5. 支持回滚到旧版本
#
# 使用方式:
#   ./auto-update.sh              # 检查并安装更新
#   ./auto-update.sh --check       # 仅检查更新
#   ./auto-update.sh --rollback   # 回滚到上一个版本
#   ./auto-update.sh --backup     # 仅创建备份
#

set -euo pipefail

# =========================================
# 配置
# =========================================
REPO_OWNER="lin-6666"
REPO_NAME="multi_os_linux"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
BACKUP_DIR="$HOME/.multi-os-backup"
UPDATE_LOCK="/tmp/multi-os-update.lock"
CONFIG_DIR="$HOME/.multi-os/config"
USER_DATA_DIR="$HOME/.multi-os"

# GitHub API 获取最新版本信息
GITHUB_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"
CURRENT_VERSION="1.0.0"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =========================================
# 函数
# =========================================

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否有更新
check_for_updates() {
    log_info "正在检查更新..."
    
    # 获取当前版本
    if [ -f ".version" ]; then
        CURRENT_VERSION=$(cat .version 2>/dev/null || echo "1.0.0")
    fi
    
    # 获取 GitHub 最新版本
    log_info "正在连接 GitHub..."
    
    # 尝试使用 GitHub API 获取最新版本
    if command -v curl &> /dev/null; then
        LATEST_VERSION=$(curl -s "${GITHUB_API}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"tag_name":\s*"([^"]+)".*/\1/' || echo "")
        
        if [ -z "$LATEST_VERSION" ]; then
            # 如果 API 失败，使用 git ls-remote
            LATEST_VERSION=$(git ls-remote --tags origin 2>/dev/null | grep -E 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+' | cut -d'/' -f3 | sort -V | tail -n1 | sed 's/^v//' || echo "$CURRENT_VERSION")
        fi
    else
        # 使用 git fetch 检查更新
        git fetch origin --tags 2>/dev/null || true
        LATEST_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "$CURRENT_VERSION")
    fi
    
    log_info "当前版本: v$CURRENT_VERSION"
    log_info "最新版本: v$LATEST_VERSION"
    
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        log_success "您已经使用最新版本！"
        return 0
    else
        log_warning "发现新版本: v$LATEST_VERSION"
        return 1
    fi
}

# 备份重要文件
backup_important_files() {
    log_info "正在备份重要文件..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 备份时间戳
    BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
    BACKUP_VERSION=$(git describe --tags 2>/dev/null || echo "unknown")
    
    # 备份用户配置
    if [ -d "$USER_DATA_DIR" ]; then
        log_info "备份用户配置到: $BACKUP_DIR/user_config_${BACKUP_TIME}.tar.gz"
        tar -czf "$BACKUP_DIR/user_config_${BACKUP_TIME}.tar.gz" \
            --exclude='.git' \
            --exclude='build/*' \
            --exclude='sources/*' \
            "$USER_DATA_DIR" 2>/dev/null || true
    fi
    
    # 备份自定义脚本（如果有）
    if [ -d "scripts/custom" ]; then
        log_info "备份自定义脚本..."
        mkdir -p "$BACKUP_DIR/custom_scripts_${BACKUP_TIME}"
        cp -r scripts/custom/* "$BACKUP_DIR/custom_scripts_${BACKUP_TIME}/" 2>/dev/null || true
    fi
    
    # 备份本地配置（不会被覆盖的文件）
    BACKUP_FILES=(
        "config/wine/wallpaper_engine.reg"
        "config/user-config.yml"
        ".multi-os-local"
    )
    
    for file in "${BACKUP_FILES[@]}"; do
        if [ -f "$file" ]; then
            log_info "备份本地文件: $file"
            cp -f "$file" "$BACKUP_DIR/${BACKUP_TIME}_$(basename "$file")"
        fi
    done
    
    # 创建备份清单
    cat > "$BACKUP_DIR/backup_manifest_${BACKUP_TIME}.txt" << EOF
备份时间: $BACKUP_TIME
备份版本: $BACKUP_VERSION
备份内容:
EOF
    
    ls -la "$BACKUP_DIR" | tail -n +2 >> "$BACKUP_DIR/backup_manifest_${BACKUP_TIME}.txt"
    
    log_success "备份完成！备份保存在: $BACKUP_DIR"
    echo "$BACKUP_TIME"
}

# 保护用户文件不被覆盖
protect_user_files() {
    log_info "检查并保护用户文件..."
    
    # 用户文件白名单 - 这些文件即使在 GitHub 上被修改也不会被覆盖
    PROTECTED_FILES=(
        "config/user-config.yml"
        ".multi-os-local"
        "scripts/custom/*"
    )
    
    # 检查受保护的文件是否存在
    for pattern in "${PROTECTED_FILES[@]}"; do
        if [ -f "$pattern" ] || [ -d "$pattern" ]; then
            log_info "发现受保护的文件: $pattern"
            
            # 创建 .gitignore 风格的保护标记
            touch ".protected/$(basename "$pattern").protected" 2>/dev/null || true
        fi
    done
}

# 应用更新
apply_update() {
    log_info "正在应用更新..."
    
    # 步骤 1: 备份重要文件
    BACKUP_TIME=$(backup_important_files)
    
    # 步骤 2: 保护用户文件
    protect_user_files
    
    # 步骤 3: 拉取最新代码
    log_info "正在拉取最新代码..."
    git fetch origin --tags 2>/dev/null || {
        log_error "无法连接到 GitHub，请检查网络连接"
        return 1
    }
    
    # 步骤 4: 获取最新标签
    LATEST_TAG=$(git describe --tags --abbrev=0 origin/master 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [ -n "$LATEST_TAG" ]; then
        log_info "切换到版本: $LATEST_TAG"
        git checkout "$LATEST_TAG" 2>/dev/null || git checkout "origin/master" || {
            log_error "切换版本失败"
            return 1
        }
    else
        log_info "拉取最新主分支..."
        git pull origin master || {
            log_error "拉取更新失败"
            return 1
        }
    fi
    
    # 步骤 5: 更新子模块（如果有）
    if [ -f ".gitmodules" ]; then
        log_info "更新子模块..."
        git submodule update --init --recursive 2>/dev/null || true
    fi
    
    # 步骤 6: 恢复用户配置
    restore_user_config "$BACKUP_TIME"
    
    # 步骤 7: 更新版本文件
    echo "$LATEST_TAG" | sed 's/^v//' > .version
    
    log_success "更新完成！"
    log_info "备份保存在: $BACKUP_DIR"
}

# 恢复用户配置
restore_user_config() {
    local backup_time="$1"
    
    log_info "恢复用户配置..."
    
    # 恢复用户配置备份
    if [ -f "$BACKUP_DIR/user_config_${backup_time}.tar.gz" ]; then
        log_info "恢复用户配置..."
        tar -xzf "$BACKUP_DIR/user_config_${backup_time}.tar.gz" -C "$HOME/" 2>/dev/null || true
    fi
    
    # 恢复受保护的本地文件
    for file in "$BACKUP_DIR/${backup_time}_"*; do
        if [ -f "$file" ]; then
            local basename=$(basename "$file" | sed "s/^${backup_time}_//")
            local target=""
            
            case "$basename" in
                "wallpaper_engine.reg")
                    target="config/wine/$basename"
                    ;;
                "user-config.yml")
                    target="config/$basename"
                    ;;
                ".multi-os-local")
                    target="$basename"
                    ;;
            esac
            
            if [ -n "$target" ]; then
                log_info "恢复文件: $target"
                cp -f "$file" "$target" 2>/dev/null || true
            fi
        fi
    done
}

# 回滚到上一个版本
rollback_update() {
    log_warning "即将回滚到上一个版本..."
    
    # 查找最新的备份
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/backup_manifest_*.txt 2>/dev/null | head -1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        log_error "没有找到备份，无法回滚"
        return 1
    fi
    
    log_warning "将使用备份: $LATEST_BACKUP"
    read -p "确认回滚? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消回滚"
        return 0
    fi
    
    # 提取备份时间
    BACKUP_TIME=$(basename "$LATEST_BACKUP" | sed 's/backup_manifest_//' | sed 's/.txt//')
    
    log_info "正在回滚..."
    
    # 回滚到上一个提交
    git reset --hard HEAD~1 2>/dev/null || {
        log_error "回滚失败"
        return 1
    }
    
    # 恢复用户配置
    restore_user_config "$BACKUP_TIME"
    
    log_success "回滚完成！"
}

# 显示帮助信息
show_help() {
    cat << EOF
Multi-OS Linux 自动更新脚本

使用方法:
    $0 [选项]

选项:
    --check       仅检查更新，不安装
    --update      检查并安装更新（默认）
    --backup      仅创建备份
    --rollback    回滚到上一个版本
    --version     显示版本信息
    --help        显示此帮助信息

示例:
    $0              # 检查并安装更新
    $0 --check      # 仅检查更新
    $0 --rollback   # 回滚

更多信息请访问: https://github.com/${REPO_OWNER}/${REPO_NAME}
EOF
}

# 检查更新锁（防止同时运行多个更新）
acquire_lock() {
    if [ -f "$UPDATE_LOCK" ]; then
        log_error "检测到另一个更新进程正在运行"
        log_info "锁文件: $UPDATE_LOCK"
        log_info "如果确认没有其他更新进程，请删除锁文件后重试"
        exit 1
    fi
    
    # 创建锁文件
    echo "PID: $$" > "$UPDATE_LOCK"
    echo "Start: $(date)" >> "$UPDATE_LOCK"
    
    # 注册清理函数
    trap 'rm -f "$UPDATE_LOCK"' EXIT
}

# =========================================
# 主程序
# =========================================

main() {
    # 获取命令行参数
    local action="${1:-update}"
    
    case "$action" in
        --check|-c)
            check_for_updates
            ;;
        --update|-u|"")
            acquire_lock
            if check_for_updates; then
                log_success "无需更新"
            else
                apply_update
            fi
            ;;
        --backup|-b)
            acquire_lock
            backup_important_files
            ;;
        --rollback|-r)
            acquire_lock
            rollback_update
            ;;
        --version|-v)
            echo "Multi-OS Linux Updater v$CURRENT_VERSION"
            echo "仓库: $REPO_URL"
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "未知选项: $action"
            show_help
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"
