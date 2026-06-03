# Windows实用软件支持指南

## 概述

本指南详细说明如何在Multi-OS系统中配置和运行各种Windows实用软件，包括：
- **虚拟声卡**（VB-Cable、Voicemeeter）
- **桌面壁纸软件**（Wallpaper Engine等）
- **系统托盘应用**
- **音频/视频处理工具**

---

## 1. 虚拟声卡配置

### 1.1 支持的虚拟声卡

| 软件名称 | 支持状态 | Wine推荐 | 备注 |
|---------|---------|----------|------|
| VB-CABLE (CABLE Input/Output) | ✅ 良好 | Wine 8.0+ | 最稳定的选择 |
| Voicemeeter (Banana/Standard) | ✅ 可用 | Wine 9.0 | 高级音频路由 |
| Virtual Audio Cable (VAC) | ⚠️ 有限 | Wine 7.0+ | 需要测试 |

### 1.2 安装配置步骤

#### 方法1：使用VB-CABLE（推荐）

```bash
# 1. 先配置Wine环境
cd /workspace/multi-os-compat
./configure_wine.sh
cd config/wine
./apply_config.sh

# 2. 下载VB-CABLE
# 官方下载：https://vb-audio.com/Cable/
# 下载后放入 prefix/drive_c/downloads/

# 3. 安装
wine VBCABLE_Setup.exe

# 4. 验证安装
wine control mmsys.cpl
```

#### 方法2：使用Voicemeeter

```bash
# 1. 下载Voicemeeter
# 官方：https://vb-audio.com/Voicemeeter/

# 2. 安装
wine VoicemeeterSetup.exe

# 3. 配置（在Wine注册表中）
# 确保winealsa.drv和winepulse.drv正确加载
```

### 1.3 注册表配置优化

```reg
Windows Registry Editor Version 5.00

; VB-CABLE优化配置
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceClasses\{53F56307-B6BF-11D0-94F2-00A0C91EFB8B}]

; Voicemeeter额外优化
[HKEY_CURRENT_USER\Software\VB-Audio\Voicemeeter]
"DefaultIn"="CABLE Output"
"DefaultOut"="CABLE Input"
```

---

## 2. 桌面壁纸软件

### 2.1 支持的壁纸软件

| 软件 | 支持状态 | 备注 |
|------|---------|------|
| Wallpaper Engine | ⚠️ 有限 | 需要DXVK，音频壁纸可能有问题 |
| Wallpaper Master | ✅ 良好 | 简单稳定 |
| DeskScapes | ⚠️ 测试中 | 部分功能可用 |
| RainWallpaper | ✅ 可用 | 推荐选择 |

### 2.2 安装和配置

#### Wallpaper Master（推荐）

```bash
# 1. 创建壁纸目录
mkdir -p $WINEPREFIX/drive_c/wallpapers

# 2. 下载并安装Wallpaper Master
# 官方：http://wallpapermaster.co.uk/
wine WallpaperMasterSetup.exe

# 3. 设置壁纸目录
# 在软件中设置壁纸路径为：C:\wallpapers

# 4. 使用提供的管理脚本
cd /workspace/multi-os-compat/config/wine
./manage_wallpaper.sh set /path/to/wallpaper.jpg
```

#### Wallpaper Engine（高级用户）

```bash
# 1. 安装DXVK（必须）
winetricks dxvk

# 2. 安装Wallpaper Engine
# Steam版本：wine steamcmd +login <账号> +app_update 431960 +quit

# 3. 配置性能参数
cat > wallpaper_config.txt << EOF
export WINEESYNC=1
export WINEFSYNC=1
export WINEDEBUG=-all
wine ~/.wine/drive_c/Program\ Files\ \(x86\)/Steam/steamapps/common/Wallpaper\ Engine/wallpaper32.exe
EOF
chmod +x wallpaper_config.txt
```

---

## 3. 系统托盘应用

### 3.1 配置系统托盘

```bash
# 确保winex11.drv已正确配置
wine regedit /workspace/multi-os-compat/config/wine/systray_reg.reg

# 测试托盘
# 启动有托盘图标的Windows程序
wine some_program_with_tray.exe
```

### 3.2 常见托盘应用

| 应用 | 状态 |
|------|------|
| 音量控制器 | ✅ |
| 网络管理 | ⚠️ 有限 |
| 输入法切换 | ✅ |

---

## 4. 完整安装流程

### 4.1 10步快速配置

```bash
#!/bin/bash
# 完整安装脚本（示例）

# 1. 设置项目目录
PROJECT_DIR="/workspace/multi-os-compat"
cd "$PROJECT_DIR"

# 2. 配置Wine
./configure_wine.sh

# 3. 应用配置
cd config/wine
./apply_config.sh

# 4. 安装基础组件
winetricks corefonts
winetricks vcrun2015

# 5. 安装音频组件
winetricks directmusic
winetricks gstreamer

# 6. 安装DXVK（如果需要3D）
winetricks dxvk

# 7. 安装VB-CABLE
# 手动下载并运行VBCABLE_Setup.exe
echo "请手动下载VB-CABLE并运行安装"

# 8. 配置壁纸目录
mkdir -p $WINEPREFIX/drive_c/wallpapers

# 9. 测试音频
wine control mmsys.cpl

# 10. 完成
echo "配置完成！"
```

---

## 5. 故障排除

### 5.1 音频问题

| 问题 | 解决方案 |
|------|---------|
| 没有声音 | 检查WINEPULSE=1是否设置，检查host系统PulseAudio/ALSA |
| 音频延迟 | 设置WINEESYNC=1，禁用其他音频程序 |
| 虚拟声卡不显示 | 检查VB-CABLE是否正确安装，重新运行安装程序 |

### 5.2 壁纸问题

| 问题 | 解决方案 |
|------|---------|
| 视频壁纸无声音 | 检查音频配置，使用wallpaper32.exe而非64位 |
| 高CPU占用 | 使用更简单的壁纸，禁用不必要的功能 |

### 5.3 常见错误日志

```bash
# 启用Wine调试信息
export WINEDEBUG=+alsa,+pulse
wine your_program.exe

# 禁用所有调试
export WINEDEBUG=-all
```

---

## 6. 性能优化建议

### 6.1 Wine环境变量

```bash
# 性能优化参数
export WINEESYNC=1       # 更好的同步性能
export WINEFSYNC=1       # 更快的文件系统
export WINEDEBUG=-all    # 禁用调试
export MESA_NO_ERROR=1   # OpenGL优化
```

### 6.2 图形优化

```bash
# 如果使用DXVK
export DXVK_ASYNC=1       # 异步编译
export DXVK_HUD=1         # 显示FPS
```

---

## 附录

### A. 完整注册表配置文件

所有配置文件位于：
```
/workspace/multi-os-compat/config/wine/
├── audio_reg.reg         # 音频
├── desktop_reg.reg       # 桌面
├── virtual_audio_reg.reg # 虚拟声卡
├── systray_reg.reg       # 系统托盘
└── winetricks_guide.md   # Winetricks指南
```

### B. 常用命令速查

```bash
# Wine控制面板
wine control

# 音频设置
wine control mmsys.cpl

# 注册表编辑器
wine regedit

# Wine配置
winecfg

# 使用特定Wine版本
WINE=wine-staging your_command.exe
```
