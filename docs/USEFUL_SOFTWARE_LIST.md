# Windows实用软件兼容性列表

## 概述

本指南列出了在Multi-OS系统（Wine）上经过验证的Windows实用软件，包含虚拟音频、壁纸工具、系统工具等。

---

## 🔊 音频类

| 软件名称 | 用途 | 兼容性 | Wine版本 | 备注 |
|---------|------|--------|---------|------|
| **VB-CABLE** | 虚拟音频线 | ✅ 完美 | Wine 7.0+ | 推荐首选 |
| **Voicemeeter Standard** | 高级音频路由 | ✅ 良好 | Wine 9.0 | |
| **Voicemeeter Banana** | 高级音频路由 | ✅ 可用 | Wine 9.0 | |
| **Voicemeeter Potato** | 高级音频路由 | ⚠️ 有限 | | |
| **Virtual Audio Cable (VAC)** | 虚拟音频线 | ⚠️ 中等 | Wine 7.0+ | 有替代品VB-CABLE更好 |
| **Voicemeeter** | 同上 | | | |
| **ASIO4ALL** | ASIO驱动 | ⚠️ 测试中 | | |
| **Audacity** | 音频编辑 | ✅ 完美 | Wine 6.0+ | |
| **Foobar2000** | 音乐播放器 | ✅ 完美 | Wine 6.0+ | |
| **AIMP** | 音乐播放器 | ✅ 完美 | Wine 7.0+ | |
| **FL Studio** | 数字音频工作站 | ✅ 可用 | Wine 8.0+ | |
| **Ableton Live** | 数字音频工作站 | ⚠️ 有限 | | |
| **Adobe Audition** | 音频编辑 | ⚠️ 测试中 | | |

### 音频工具快速参考

```bash
# 优先推荐
VB-CABLE (最推荐，免费、稳定)
    下载: https://vb-audio.com/Cable/
    安装: wine VBCABLE_Setup.exe

# 如果需要高级功能
Voicemeeter Banana (免费)
    下载: https://vb-audio.com/Voicemeeter/
```

---

## 🖼️ 壁纸/桌面类

| 软件名称 | 用途 | 兼容性 | Wine版本 | 备注 |
|---------|------|--------|---------|------|
| **Wallpaper Master** | 壁纸管理器 | ✅ 完美 | Wine 7.0+ | 轻量推荐 |
| **RainWallpaper** | 动态壁纸 | ✅ 可用 | Wine 8.0+ | |
| **Wallpaper Engine** | Steam动态壁纸 | ⚠️ 有限 | Wine 8.0+ | 需DXVK |
| **DeskScapes** | 动态壁纸 | ⚠️ 测试中 | | |
| **DisplayFusion** | 多显示器管理 | ✅ 可用 | Wine 7.0+ | |

---

## 📁 文件/系统工具类

| 软件名称 | 用途 | 兼容性 | Wine版本 |
|---------|------|--------|---------|
| **7-Zip** | 文件压缩 | ✅ 完美 | Wine 6.0+ |
| **WinRAR** | 文件压缩 | ✅ 完美 | Wine 6.0+ |
| **Total Commander** | 文件管理器 | ✅ 完美 | Wine 6.0+ |
| **Everything** | 文件搜索 | ✅ 完美 | Wine 7.0+ |
| **Listary** | 文件搜索 | ⚠️ 有限 | |
| **Process Explorer** | 进程管理 | ✅ 完美 | Wine 7.0+ |
| **Autoruns** | 启动项管理 | ✅ 可用 | Wine 7.0+ |

---

## 💬 通讯/聊天类

| 软件名称 | 兼容性 | 备注 |
|---------|--------|------|
| **Discord** | ⚠️ 中等 | 有Linux版本 |
| **Telegram** | ⚠️ 中等 | 有Linux版本 |
| **Slack** | ⚠️ 中等 | 有Linux版本 |
| **QQ** | ✅ 可用 | Wine 8.0+ |
| **微信** | ✅ 可用 | Wine 8.0+ |

---

## 📺 媒体播放器类

| 软件名称 | 兼容性 | Wine版本 |
|---------|--------|---------|
| **VLC** | ⚠️ 原生更好 | |
| **MPC-HC** | ✅ 完美 | Wine 7.0+ |
| **PotPlayer** | ✅ 可用 | Wine 7.0+ |
| **KMPlayer** | ⚠️ 有限 | |

---

## 🔧 系统工具类

| 软件名称 | 用途 | 兼容性 | Wine版本 |
|---------|------|--------|---------|
| **Wireshark** | 网络分析 | ⚠️ 有限 | |
| **Resource Hacker** | PE文件编辑 | ✅ 完美 | Wine 6.0+ |
| **OBS Studio** | 直播录制 | ⚠️ 有限 | |
| **HandBrake** | 视频转码 | ⚠️ 原生更好 | |

---

## 🎮 游戏相关工具

| 软件名称 | 用途 | 兼容性 | Wine版本 |
|---------|------|--------|---------|
| **Cheat Engine** | 游戏修改 | ✅ 完美 | Wine 7.0+ |
| **DS4Windows** | 手柄映射 | ✅ 可用 | Wine 8.0+ |

---

## 快速安装指南（Top 10）

### 1. VB-CABLE（虚拟音频线）
```bash
# 步骤
1. 访问 https://vb-audio.com/Cable/
2. 下载 VBCABLE_Setup.exe 或 VBCABLE_Setup_x64.exe
3. wine VBCABLE_Setup.exe
```

### 2. 7-Zip（压缩工具）
```bash
# 步骤
1. 访问 https://www.7-zip.org/
2. 下载 exe 安装包
3. wine 7z<version>.exe
```

### 3. Wallpaper Master
```bash
# 步骤
1. 访问 http://wallpapermaster.co.uk/
2. 下载
3. wine WallpaperMasterSetup.exe
```

### 4. Process Explorer
```bash
# 步骤
1. 访问 https://learn.microsoft.com/sysinternals/
2. 下载 Process Explorer
3. wine procexp64.exe 或 procexp.exe
```

---

## 安装前准备检查清单

在安装Windows软件前，请确保：
- ✅ 已配置Wine环境 (`./configure_wine.sh`)
- ✅ 已安装Wine核心包 (`winetricks corefonts`)
- ✅ 已安装Visual C++运行库 (`winetricks vcrun2015-2022`)
- ✅ 如需音频功能，已测试host系统音频 (`./configure_audio.sh`)
- ✅ 如需3D/DXVK功能，检查显卡驱动

---

## 通用安装命令

```bash
# 示例：安装任意软件
cd ~/Downloads
wine ./Software_Setup.exe

# 如果是.msi包
wine msiexec /i ./Software_Setup.msi

# 静默安装（如果可用）
wine ./Software_Setup.exe /s
```

---

## ⚠️ 重要提示

1. **Windows软件 ≠ Linux软件**：虽然Wine很棒，但某些功能可能受限
2. **优先选择Linux版本**：很多软件提供原生Linux版本，优先使用
3. **备份数据**：操作前先备份重要数据
4. **参考Wine AppDB**：https://appdb.winehq.org/ 查具体软件兼容性
5. **性能**：游戏/高性能软件可能需要额外优化

---

## 获取更多帮助

- Wine官方文档：https://wiki.winehq.org/
- Wine AppDB：https://appdb.winehq.org/
- Winetricks：https://github.com/Winetricks/winetricks
