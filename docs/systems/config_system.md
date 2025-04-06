# Config System

The Config System provides a robust solution for managing game configurations, supporting both runtime settings and persistent storage.

## Features

- ⚙️ **Flexible Configuration**: Easy to use key-value storage
- 💾 **Persistent Storage**: Automatic save and load of settings
- 🔄 **Default Values**: Built-in default configuration support
- 🔌 **Project Settings Integration**: Configurable through Godot's project settings
- 🛡️ **Async Operations**: Non-blocking save/load operations
- 📦 **Section Management**: Organize settings in logical sections

## Quick Start

### 1. Access Config Manager

```gdscript
var config_manager = CoreSystem.config_manager
```

### 2. Basic Operations

```gdscript
# Load configuration
config_manager.load_config(func(success: bool):
    if success:
        print("Config loaded successfully!")
)

# Get configuration value
var sound_volume = config_manager.get_value("audio", "sound_volume", 1.0)

# Set configuration value
config_manager.set_value("audio", "sound_volume", 0.8)

# Save configuration
config_manager.save_config(func(success: bool):
    if success:
        print("Config saved successfully!")
)

# Reset to defaults
config_manager.reset_config(func(success: bool):
    if success:
        print("Config reset to defaults!")
)
```

### 3. Default Configuration

```gdscript
# Define default configuration in default_config.gd
static func get_default_config() -> Dictionary:
    return {
        "audio": {
            "master_volume": 1.0,
            "music_volume": 0.8,
            "sound_volume": 1.0,
            "voice_volume": 1.0
        },
        "graphics": {
            "fullscreen": false,
            "vsync": true,
            "resolution": "1920x1080"
        },
        "gameplay": {
            "difficulty": "normal",
            "language": "en"
        }
    }
```

## Project Settings

| Setting     | Description          | Default             |
| ----------- | -------------------- | ------------------- |
| config_path | Path to config file  | "user://config.cfg" |
| auto_save   | Auto-save on changes | true                |

## API Reference

### ConfigManager

Core class for managing configurations.

#### Properties

- `config_path: String`: Path to configuration file
- `auto_save: bool`: Whether to auto-save changes

#### Methods

- `load_config(callback: Callable) -> void`: Load configuration from file
- `save_config(callback: Callable) -> void`: Save configuration to file
- `reset_config(callback: Callable) -> void`: Reset to default configuration
- `get_value(section: String, key: String, default: Variant) -> Variant`: Get configuration value
- `set_value(section: String, key: String, value: Variant) -> void`: Set configuration value
- `has_section(section: String) -> bool`: Check if section exists
- `has_key(section: String, key: String) -> bool`: Check if key exists in section
- `get_section(section: String) -> Dictionary`: Get entire section
- `set_section(section: String, data: Dictionary) -> void`: Set entire section

#### Signals

- `config_loaded`: Emitted when configuration is loaded
- `config_saved`: Emitted when configuration is saved
- `config_reset`: Emitted when configuration is reset

## Best Practices

1. **Configuration Organization**

   - Use logical section names
   - Keep related settings together
   - Use consistent naming conventions

2. **Default Values**

   - Always provide sensible defaults
   - Document default values
   - Consider platform differences

3. **Error Handling**

   - Check callback success status
   - Provide fallback values
   - Handle missing sections/keys gracefully

4. **Performance**
   - Use auto-save judiciously
   - Cache frequently accessed values
   - Batch multiple changes

## Common Issues

1. **Configuration Not Saving**

   - Check write permissions
   - Verify config path is valid
   - Ensure auto-save is enabled if needed

2. **Default Values Not Loading**

   - Check default configuration format
   - Verify section and key names
   - Debug merge conflicts with saved data

3. **Missing Settings**
   - Always use get_value with defaults
   - Check section existence
   - Validate configuration structure

## Examples

### Audio Configuration

```gdscript
# Load audio settings
func load_audio_settings():
    var master = config_manager.get_value("audio", "master_volume", 1.0)
    var music = config_manager.get_value("audio", "music_volume", 0.8)
    var sound = config_manager.get_value("audio", "sound_volume", 1.0)

    AudioServer.set_bus_volume_db(0, linear_to_db(master))
    AudioServer.set_bus_volume_db(1, linear_to_db(music))
    AudioServer.set_bus_volume_db(2, linear_to_db(sound))

# Save audio settings
func save_audio_settings():
    var master = db_to_linear(AudioServer.get_bus_volume_db(0))
    var music = db_to_linear(AudioServer.get_bus_volume_db(1))
    var sound = db_to_linear(AudioServer.get_bus_volume_db(2))

    config_manager.set_value("audio", "master_volume", master)
    config_manager.set_value("audio", "music_volume", music)
    config_manager.set_value("audio", "sound_volume", sound)
```

### Graphics Configuration

```gdscript
# Apply graphics settings
func apply_graphics_settings():
    var fullscreen = config_manager.get_value("graphics", "fullscreen", false)
    var vsync = config_manager.get_value("graphics", "vsync", true)
    var resolution = config_manager.get_value("graphics", "resolution", "1920x1080")

    if fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

    DisplayServer.window_set_vsync_mode(vsync)
    var res = resolution.split("x")
    DisplayServer.window_set_size(Vector2i(int(res[0]), int(res[1])))
```
