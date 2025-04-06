# Audio System

The Audio System provides a comprehensive solution for managing game audio, including sound effects, music, and ambient sounds with advanced features like audio pooling and transitions.

## Features

- 🎵 **Audio Categories**: Organize sounds by type (Music, SFX, Voice, etc.)
- 🔊 **Audio Pool**: Efficient sound instance management
- 🎼 **Music Management**: Smooth transitions between tracks
- 📊 **Volume Control**: Category and master volume control
- 🔄 **Audio States**: Support for different audio states (e.g., Menu, Game)
- 📱 **Project Settings**: Configure through Godot's project settings

## Core Components

### AudioManager

Central manager for all audio operations:
- Category-based audio management
- Volume control
- Audio state handling

```gdscript
# Configure through project settings
core_system/audio_system/master_volume = 1.0
core_system/audio_system/music_volume = 0.8
core_system/audio_system/sfx_volume = 1.0
core_system/audio_system/voice_volume = 1.0

# Usage example
func _ready() -> void:
	var audio = CoreSystem.audio_manager
	
	# Play music with fade
	audio.play_music("res://assets/music/battle_theme.ogg", 2.0)
	
	# Play sound effect
	audio.play_sound("res://assets/sfx/explosion.wav")
	
	# Set category volume
	audio.set_category_volume("music", 0.8)
```

## Usage Examples

### Playing Audio

```gdscript
# Play background music (default looping). Note: If audio is imported with loop enabled, it will always loop regardless of loop parameter
func play_background_music() -> void:
	CoreSystem.audio_manager.play_music("res://assets/music/main_theme.ogg")

# Play sound effect
func play_attack_sound() -> void:
	CoreSystem.audio_manager.play_sound("res://assets/sfx/attack.wav")

# Play voice
func play_character_voice() -> void:
	CoreSystem.audio_manager.play_voice("res://assets/voice/greeting.ogg")
```

### Volume Control

```gdscript
# Set music volume
func set_music_volume(volume: float) -> void:
	CoreSystem.audio_manager.set_volume(CoreSystem.AudioManager.AudioType.MUSIC, volume)
```

## Best Practices

1. **Audio Organization**
   - Use clear category names
   - Maintain consistent file naming conventions
   - Organize audio resources in dedicated folders

2. **Performance**
   - Use audio pool for frequently played sounds
   - Limit simultaneous audio streams
   - Clean up unused audio resources

3. **User Experience**
   - Implement smooth volume transitions
   - Provide independent volume controls per category
   - Remember user audio preferences

## API Reference

### AudioManager
- `play_music(path: String, fade_duration: float = 1.0, loop: bool = true) -> void`: Play background music 
  - Note: Default looping. If audio is imported with loop enabled, it will always loop regardless of loop parameter
- `play_sound(path: String, volume: float = 1.0)`: Play sound effect
- `play_voice(path: String, volume: float = 1.0)`: Play voice
- `set_volume(type: AudioType, volume: float)`: Set volume by type
- `stop_all() -> void`: Stop all audio
- `preload_audio(path: String, type: AudioType) -> void`: Preload audio resources
