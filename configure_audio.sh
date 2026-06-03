#!/bin/bash
# 系统音频驱动配置脚本

echo "=== 系统音频驱动配置 ==="

# 检查系统音频状态
echo ""
echo "--- 检查系统音频 ---"

# ALSA检查
if command -v aplay &> /dev/null; then
    echo "ALSA 已安装"
    echo "ALSA 设备:"
    aplay -l | head -20
else
    echo "⚠️  ALSA 未安装"
fi

# PulseAudio检查
if command -v pactl &> /dev/null; then
    echo ""
    echo "PulseAudio 状态:"
    pactl info || true
else
    echo "⚠️  PulseAudio 未安装"
fi

# 创建音频配置目录
echo ""
echo "--- 创建配置 ---"
mkdir -p /workspace/multi-os-compat/config/audio

cat > /workspace/multi-os-compat/config/audio/alsa_config.txt << 'EOF'
# ALSA 配置建议
# /etc/asound.conf 或 ~/.asoundrc

# 默认设备配置
defaults.pcm.card 0
defaults.ctl.card 0

# Wine兼容性配置
pcm.wine {
    type plug
    slave.pcm "default"
}
EOF

cat > /workspace/multi-os-compat/config/audio/pulse_config.txt << 'EOF'
# PulseAudio 配置建议
# /etc/pulse/daemon.conf

# 低延迟优化
high-priority = yes
nice-level = -11
realtime-scheduling = yes
realtime-priority = 5

# 采样率
default-sample-rate = 48000
alternate-sample-rate = 44100

# 延迟设置
default-fragment-size-msec = 5
EOF

cat > /workspace/multi-os-compat/config/audio/wine_audio_tips.md << 'EOF'
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
EOF

echo "配置文件创建完成！"
echo "配置位置: /workspace/multi-os-compat/config/audio/"
