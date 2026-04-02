# 音频系统

音频系统为游戏音频管理提供了一个全面的解决方案，包括音效、音乐和环境音，并支持音频池和过渡等高级功能。

## 特性

- 🎵 **音频分类**：按类型组织声音（音乐、音效、语音等）
- 🔊 **音频池**：高效的声音实例管理
- 🎼 **音乐管理**：音轨之间的平滑过渡
- 📊 **音量控制**：分类和主音量控制
- 🔄 **音频状态**：支持不同的音频状态（如菜单、游戏等）
- 📱 **项目设置**：通过 Godot 的项目设置进行配置

## 核心组件

### AudioManager（音频管理器）

所有音频操作的中央管理器：

- 基于分类的音频管理
- 音量控制
- 音频状态处理

```gdscript
# 通过项目设置配置
core_system/audio_system/master_volume = 1.0
core_system/audio_system/music_volume = 0.8
core_system/audio_system/sfx_volume = 1.0
core_system/audio_system/voice_volume = 1.0

# 使用示例
func _ready() -> void:
	var audio = CoreSystem.audio_manager

	# 播放音乐（带淡入淡出）
	audio.play_music("res://assets/music/battle_theme.ogg", 2.0)

	# 播放音效
	audio.play_sound("res://assets/sfx/explosion.wav")

	# 设置分类音量
	audio.set_category_volume("music", 0.8)
```

## 使用示例

### 播放音频

```gdscript
# 播放背景音乐 默认循环播放 如果音频导入时设置为循环播放，则将一直循环，哪怕loop参数设置为false
func play_background_music() -> void:
	CoreSystem.audio_manager.play_music("res://assets/music/main_theme.ogg")

# 播放音效
func play_attack_sound() -> void:
	CoreSystem.audio_manager.play_sound("res://assets/sfx/attack.wav")

# 播放语音
func play_character_voice() -> void:
	CoreSystem.audio_manager.play_voice("res://assets/voice/greeting.ogg")
```

### 音量控制

```gdscript
# 设置背景音乐音量
func set_music_volume(volume: float) -> void:
	CoreSystem.audio_manager.set_volume(CoreSystem.AudioManager.AudioType.MUSIC,volume)

```

## 最佳实践

1. **音频组织**

   - 使用清晰的分类名称
   - 保持一致的文件命名约定
   - 在专用文件夹中组织音频资源

2. **性能**

   - 对频繁播放的声音使用音频池
   - 限制同时播放的音频流
   - 清理未使用的音频资源

3. **用户体验**
   - 实现平滑的音量过渡
   - 为不同分类提供独立的音量控制
   - 记住用户的音频偏好

## API 参考

### 音频管理器 AudioManager

- `play_music(path: String, fade_duration: float = 1.0, loop: bool = true) -> void`: 播放背景音乐 
	- 注意：默认循环播放 如果音频导入时设置为循环播放，则将一直循环，哪怕loop参数设置为false
- `play_sound(path: String, volume: float = 1.0)`: 播放音效
- `play_voice(path: String, volume: float = 1.0)`: 播放语音
- `set_volume(type: AudioType, volume: float)`: 按类型设置音量
- `stop_all() -> void`: 停止所有音频
- `preload_audio(path: String, type: AudioType) -> void`: 预加载音频资源
