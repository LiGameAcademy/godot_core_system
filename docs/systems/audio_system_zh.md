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
    audio.play_sfx("res://assets/sfx/explosion.wav")

    # 设置分类音量
    audio.set_category_volume("music", 0.8)
```

## 使用示例

### 播放音频

```gdscript
# 播放背景音乐
func play_background_music() -> void:
    CoreSystem.audio_manager.play_music("res://assets/music/main_theme.ogg")

# 播放音效
func play_attack_sound() -> void:
    CoreSystem.audio_manager.play_sfx("res://assets/sfx/attack.wav")

# 播放语音
func play_character_voice() -> void:
    CoreSystem.audio_manager.play_voice("res://assets/voice/greeting.ogg")
```

### 音量控制

```gdscript
# 设置主音量
func set_master_volume(volume: float) -> void:
    CoreSystem.audio_manager.set_master_volume(volume)

# 设置分类音量
func set_music_volume(volume: float) -> void:
    CoreSystem.audio_manager.set_category_volume("music", volume)

# 静音/取消静音分类
func toggle_sfx(enabled: bool) -> void:
    CoreSystem.audio_manager.set_category_mute("sfx", !enabled)
```

### 音频状态管理

```gdscript
# 改变音频状态（例如，进入战斗时）
func enter_battle() -> void:
    CoreSystem.audio_manager.transition_to_state("battle", 2.0)

# 定义状态行为
func _setup_audio_states() -> void:
    var audio = CoreSystem.audio_manager
    audio.add_state("menu", {
        "music": "res://assets/music/menu_theme.ogg",
        "ambient": "res://assets/ambient/menu_ambience.ogg"
    })
    audio.add_state("battle", {
        "music": "res://assets/music/battle_theme.ogg",
        "ambient": "res://assets/ambient/battle_ambience.ogg"
    })
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

- `play_music(stream_path: String, fade_time: float = 0.0) -> void`: 播放背景音乐
- `play_sfx(stream_path: String, volume: float = 1.0) -> void`: 播放音效
- `play_voice(stream_path: String, volume: float = 1.0) -> void`: 播放语音
- `set_master_volume(volume: float) -> void`: 设置主音量
- `set_category_volume(category: String, volume: float) -> void`: 设置分类音量
- `set_category_mute(category: String, muted: bool) -> void`: 静音/取消静音分类
- `transition_to_state(state: String, fade_time: float = 0.0) -> void`: 改变音频状态
- `add_state(name: String, config: Dictionary) -> void`: 添加新的音频状态
- `remove_state(name: String) -> void`: 移除音频状态
- `get_category_volume(category: String) -> float`: 获取分类音量
- `is_category_muted(category: String) -> bool`: 检查分类是否静音
