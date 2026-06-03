# Wine 音频调试技巧

## 音频问题排查步骤

1. 首先检查 Host 系统音频
   ```bash
   aplay /usr/share/sounds/alsa/Front_Left.wav
   paplay /usr/share/sounds/alsa/Front_Left.wav
   ```

2. 检查 Wine 音频驱动
   ```bash
   export WINEDEBUG=+alsa,+pulse
   wine sound_test.exe
   ```

3. 切换音频驱动
   ```bash
   # 编辑注册表
   wine regedit
   # 导航到: HKEY_CURRENT_USER\Software\Wine\Drivers
   # 设置 "Audio" 为 "pulse" 或 "alsa"
   ```

4. 测试音频
   ```bash
   # 运行 Wine 内置声音测试
   winecfg
   # 切换到 Audio 标签页，点击 Test Sound
   ```

## 已知音频程序兼容性

| 程序 | 推荐驱动 | 状态 |
|-----|---------|------|
| VB-CABLE | PulseAudio | ✅ |
| Voicemeeter | PulseAudio | ⚠️ |
| Foobar2000 | ALSA | ✅ |
| AIMP | ALSA | ✅ |
