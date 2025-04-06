# Audio System

The Audio System provides a comprehensive solution for managing game audio, including sound effects, music, and ambient sounds with advanced features like audio pooling and transitions.

## Features

- 🎵 **Audio Categories**: Organize sounds by type (Music, SFX, Voice, etc.)
- 🔊 **Audio Pooling**: Efficient sound instance management
- 🎼 **Music Management**: Smooth transitions between tracks
- 📊 **Volume Control**: Per-category and master volume control
- 🔄 **Audio States**: Support for different audio states (e.g., Menu, Gameplay)
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
    
    # Play music with crossfade
    audio.play_music("res://assets/music/battle_theme.ogg", 2.0)
    
    # Play sound effect
    audio.play_sfx("res://assets/sfx/explosion.wav")
    
    # Set category volume
    audio.set_category_volume("music", 0.8)
```

## Usage Examples

### Playing Audio

```gdscript
# Play background music
func play_background_music() -> void:
    CoreSystem.audio_manager.play_music("res://assets/music/main_theme.ogg")

# Play sound effect
func play_attack_sound() -> void:
    CoreSystem.audio_manager.play_sfx("res://assets/sfx/attack.wav")

# Play voice line
func play_character_voice() -> void:
    CoreSystem.audio_manager.play_voice("res://assets/voice/greeting.ogg")
```

### Volume Control

```gdscript
# Set master volume
func set_master_volume(volume: float) -> void:
    CoreSystem.audio_manager.set_master_volume(volume)

# Set category volume
func set_music_volume(volume: float) -> void:
    CoreSystem.audio_manager.set_category_volume("music", volume)

# Mute/unmute category
func toggle_sfx(enabled: bool) -> void:
    CoreSystem.audio_manager.set_category_mute("sfx", !enabled)
```

### Audio State Management

```gdscript
# Change audio state (e.g., when entering battle)
func enter_battle() -> void:
    CoreSystem.audio_manager.transition_to_state("battle", 2.0)
    
# Define state behavior
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

## Best Practices

1. **Audio Organization**
   - Use clear category names
   - Keep consistent file naming conventions
   - Organize audio resources in dedicated folders

2. **Performance**
   - Use audio pooling for frequently played sounds
   - Limit simultaneous audio streams
   - Clean up unused audio resources

3. **User Experience**
   - Implement smooth volume transitions
   - Provide separate volume controls for different categories
   - Remember user audio preferences

## API Reference

### AudioManager
- `play_music(stream_path: String, fade_time: float = 0.0) -> void`: Play background music
- `play_sfx(stream_path: String, volume: float = 1.0) -> void`: Play sound effect
- `play_voice(stream_path: String, volume: float = 1.0) -> void`: Play voice line
- `set_master_volume(volume: float) -> void`: Set master volume
- `set_category_volume(category: String, volume: float) -> void`: Set category volume
- `set_category_mute(category: String, muted: bool) -> void`: Mute/unmute category
- `transition_to_state(state: String, fade_time: float = 0.0) -> void`: Change audio state
- `add_state(name: String, config: Dictionary) -> void`: Add new audio state
- `remove_state(name: String) -> void`: Remove audio state
- `get_category_volume(category: String) -> float`: Get category volume
- `is_category_muted(category: String) -> bool`: Check if category is muted
