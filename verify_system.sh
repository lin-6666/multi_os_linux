#!/bin/bash
# Multi-OS Compatibility System - Final Verification Script

set -e

PROJECT_DIR="/workspace/multi-os-compat"
cd "$PROJECT_DIR"

echo "============================================="
echo "   Multi-OS Compatibility System - Verification"
echo "============================================="
echo ""

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

all_passed=true

# Check 1: Project root directory structure
log_info "Check 1: Project root directory structure"
required_files=("setup.sh" "build.sh" "configure_wine.sh" "configure_audio.sh" "integration_test.sh" "start.sh" "README.md")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        log_success "  Found: $file"
    else
        log_error "  Missing: $file"
        all_passed=false
    fi
done
echo ""

# Check 2: Configuration files
log_info "Check 2: Configuration files"
required_configs=("config/lfs_config.env" "config/wine_config.env" "config/build_status.env" "config/wine/audio.reg" "config/wine/desktop.reg")
for config in "${required_configs[@]}"; do
    if [ -f "$config" ]; then
        log_success "  Found: $config"
    else
        log_error "  Missing: $config"
        all_passed=false
    fi
done
echo ""

# Check 3: Source code directories
log_info "Check 3: Source code directories"
required_sources=("sources/wine" "sources/darling" "sources/lfs")
for source in "${required_sources[@]}"; do
    if [ -d "$source" ]; then
        log_success "  Found: $source"
    else
        log_error "  Missing: $source"
        all_passed=false
    fi
done
echo ""

# Check 4: Documentation files
log_info "Check 4: Documentation files"
required_docs=("docs/TECHNICAL_ARCHITECTURE.md" "docs/WINDOWS_SOFTWARE_GUIDE.md" "docs/QUICK_REFERENCE.md" "README.md")
for doc in "${required_docs[@]}"; do
    if [ -f "$doc" ]; then
        log_success "  Found: $doc"
    else
        log_error "  Missing: $doc"
        all_passed=false
    fi
done
echo ""

# Check 5: Script permissions
log_info "Check 5: Script execution permissions"
executable_scripts=("setup.sh" "build.sh" "configure_wine.sh" "configure_audio.sh" "integration_test.sh" "start.sh")
for script in "${executable_scripts[@]}"; do
    if [ -x "$script" ]; then
        log_success "  Executable: $script"
    else
        log_warning "  Not executable: $script - Attempting to fix"
        chmod +x "$script"
        if [ -x "$script" ]; then
            log_success "  Fixed: $script is now executable"
        else
            log_error "  Failed to fix permissions for: $script"
            all_passed=false
        fi
    fi
done
echo ""

# Check 6: LFS download list
log_info "Check 6: LFS download list"
if [ -f "sources/lfs/wget-list.txt" ]; then
    pkg_count=$(wc -l < sources/lfs/wget-list.txt)
    log_success "  LFS packages: $pkg_count packages listed"
else
    log_error "  LFS wget-list.txt missing"
    all_passed=false
fi
echo ""

# Check 7: Wine source files
log_info "Check 7: Wine source files"
if [ -f "sources/wine/configure" ]; then
    log_success "  Wine configure script found"
else
    log_warning "  Wine source may not be fully downloaded"
fi
echo ""

# Check 8: Darling source files
log_info "Check 8: Darling source files"
if [ -f "sources/darling/CMakeLists.txt" ]; then
    log_success "  Darling CMakeLists.txt found"
else
    log_warning "  Darling source may not be fully downloaded"
fi
echo ""

# Verification summary
echo "============================================="
echo "          Verification Summary"
echo "============================================="
echo ""
if [ "$all_passed" = true ]; then
    log_success "ALL CHECKS PASSED! The Multi-OS Compatibility System is ready."
    echo ""
    echo "Next steps to continue development:"
    echo "1. Run setup.sh to initialize the environment"
    echo "2. Use configure_wine.sh to set up Wine compatibility layer"
    echo "3. Refer to docs/TECHNICAL_ARCHITECTURE.md for system design"
    echo "4. Check docs/WINDOWS_SOFTWARE_GUIDE.md for compatible software"
else
    log_error "Some checks failed! Please review the errors above."
fi
echo ""
