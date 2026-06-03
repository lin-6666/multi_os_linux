#!/bin/bash
# Multi-OS Compatibility System - One-Click Setup Script

set -e

PROJECT_DIR="/workspace/multi-os-compat"
cd "$PROJECT_DIR"

echo "============================================="
echo "   Multi-OS Compatibility System Setup"
echo "============================================="
echo ""

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Step 1: Run integration tests
log_info "Step 1: Running integration tests..."
if [ -x "$PROJECT_DIR/integration_test.sh" ]; then
    "$PROJECT_DIR/integration_test.sh"
else
    log_warning "Integration test script not found, skipping tests"
fi
echo ""

# Step 2: Setup directories
log_info "Step 2: Preparing project directories..."
mkdir -p config/wine config/darling build/lfs build/wine build/darling patches/lfs patches/wine patches/darling tools/build
log_success "Directories ready"
echo ""

# Step 3: Create configuration files
log_info "Step 3: Creating configuration files..."

# LFS Config
cat > "$PROJECT_DIR/config/lfs_config.env" << 'EOF'
LFS_VERSION="12.3"
KERNEL_VERSION="6.8.12"
ARCH="x86_64"
LFS_MOUNT="/mnt/lfs"
EOF

# Wine Config
cat > "$PROJECT_DIR/config/wine_config.env" << 'EOF'
WINE_VERSION="9.0"
ARCH="win64"
AUDIO_DRIVER="pulse,alsa,oss"
VIDEOMEMORY_SIZE="1024"
EOF

# Build status
cat > "$PROJECT_DIR/config/build_status.env" << EOF
BUILD_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
BUILD_STATUS="PREPARED"
LFS_BASED="false"
WINE_INTEGRATED="false"
DARLING_INTEGRATED="false"
EOF

log_success "Configuration files created"
echo ""

# Step 4: Create Wine registry configs for audio support
log_info "Step 4: Creating Wine registry configurations..."
mkdir -p "$PROJECT_DIR/config/wine"

cat > "$PROJECT_DIR/config/wine/audio.reg" << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Alsa Driver]
"AutoScanCards"="Y"
"ForceMixing"="Y"

[HKEY_CURRENT_USER\Software\Wine\Pulse]
"AutoSpawn"="Y"

[HKEY_CURRENT_USER\Software\Wine\DirectSound]
"Hardware Acceleration"="Full"
EOF

cat > "$PROJECT_DIR/config/wine/desktop.reg" << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Control Panel\Desktop]
"Wallpaper"="C:\\wallpapers\\default.jpg"
"WallpaperStyle"="0"
"TileWallpaper"="0"
EOF

log_success "Registry configurations created"
echo ""

# Step 5: Make scripts executable
log_info "Step 5: Making scripts executable..."
chmod +x "$PROJECT_DIR/configure_wine.sh"
chmod +x "$PROJECT_DIR/configure_audio.sh"
chmod +x "$PROJECT_DIR/start.sh"
chmod +x "$PROJECT_DIR/build.sh"
chmod +x "$PROJECT_DIR/integration_test.sh"
log_success "All scripts ready"
echo ""

# Completion message
echo "============================================="
echo "          Setup Complete!"
echo "============================================="
echo ""
echo "Next steps:"
echo "1. To configure Wine, run: ./configure_wine.sh"
echo "2. To test audio, run: ./configure_audio.sh"
echo "3. To start development, read: docs/README.md"
echo ""
echo "Full documentation available in docs/ directory"
echo ""
