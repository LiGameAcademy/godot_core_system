# Serialization System

The Serialization System provides a comprehensive solution for saving game state, managing configurations, and handling I/O operations in your Godot game.

## Features

- 💾 **Save System**: Easy-to-use save/load functionality with auto-save support
- ⚙️ **Config System**: Flexible configuration management with auto-save
- 🔄 **Async I/O**: Non-blocking I/O operations for better performance
- 🔐 **Data Security**: Optional compression and encryption
- 📱 **Project Settings**: Configure all options through Godot's project settings

## Core Components

### SaveManager

Handles game state persistence:
- Save/load game states
- Auto-save functionality
- Save file management

```gdscript
# Configure through project settings
core_system/save_system/save_directory = "user://saves"
core_system/save_system/save_extension = "save"
core_system/save_system/auto_save_interval = 300
core_system/save_system/max_auto_saves = 3
core_system/save_system/auto_save_enabled = true

# Usage example
func _ready() -> void:
    # Access through CoreSystem
    CoreSystem.save_manager.save("my_save")
    CoreSystem.save_manager.load("my_save")
    
    # Auto-save is handled automatically if enabled
```

### ConfigManager

Manages game configurations:
- Load/save settings
- Section-based organization
- Auto-save support

```gdscript
# Configure through project settings
core_system/config_system/config_path = "user://config.cfg"
core_system/config_system/auto_save = true

# Usage example
func _ready() -> void:
    var config = CoreSystem.config_manager
    
    # Set values
    config.set_value("audio", "volume", 0.8)
    config.set_value("graphics", "fullscreen", true)
    
    # Get values
    var volume = config.get_value("audio", "volume", 1.0)  # Default: 1.0
    var fullscreen = config.get_value("graphics", "fullscreen", false)
```

### SerializableComponent

Base class for objects that need to be saved:
- Automatic serialization of properties
- Custom serialization support
- State restoration

```gdscript
class_name MySerializableObject extends SerializableComponent

var health: int = 100
var position: Vector2 = Vector2.ZERO

func _get_state() -> Dictionary:
    return {
        "health": health,
        "position": position,
    }

func _set_state(state: Dictionary) -> void:
    health = state.get("health", 100)
    position = state.get("position", Vector2.ZERO)
```

## Usage Examples

### Basic Save/Load

```gdscript
# Save game state
func save_game() -> void:
    CoreSystem.save_manager.save("save_slot_1")

# Load game state
func load_game() -> void:
    CoreSystem.save_manager.load("save_slot_1")

# Delete save
func delete_save() -> void:
    CoreSystem.save_manager.delete_save("save_slot_1")

# Get save list
func get_saves() -> Array:
    return CoreSystem.save_manager.get_save_list()
```

### Configuration Management

```gdscript
# Save settings
func save_settings(volume: float, fullscreen: bool) -> void:
    var config = CoreSystem.config_manager
    config.set_value("audio", "volume", volume)
    config.set_value("graphics", "fullscreen", fullscreen)
    # Auto-saves if enabled

# Load settings
func load_settings() -> void:
    var config = CoreSystem.config_manager
    var volume = config.get_value("audio", "volume", 1.0)
    var fullscreen = config.get_value("graphics", "fullscreen", false)
```

## Best Practices

1. **Save Data Organization**
   - Use clear section names in config files
   - Keep save files organized with meaningful names
   - Implement save file versioning

2. **Error Handling**
   - Always check for errors when loading
   - Provide fallback values
   - Handle corrupted save files

3. **Performance**
   - Use async operations for large saves
   - Implement save data compression for large states
   - Optimize serialized data size

## API Reference

### SaveManager
- `save(save_name: String) -> void`: Save game state
- `load(save_name: String) -> void`: Load game state
- `delete_save(save_name: String) -> void`: Delete a save file
- `get_save_list() -> Array`: Get list of available saves
- `auto_save() -> void`: Trigger auto-save

### ConfigManager
- `set_value(section: String, key: String, value: Variant) -> void`: Set config value
- `get_value(section: String, key: String, default: Variant = null) -> Variant`: Get config value
- `save_config() -> void`: Save config to file
- `load_config() -> void`: Load config from file
- `clear_config() -> void`: Clear all config data

### SerializableComponent
- `_get_state() -> Dictionary`: Get object state
- `_set_state(state: Dictionary) -> void`: Set object state
- `save() -> Dictionary`: Save component state
- `load(state: Dictionary) -> void`: Load component state
