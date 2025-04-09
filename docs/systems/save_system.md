# Save System

The Save System is a comprehensive solution for managing game saves, providing features for creating, loading, and managing save files with support for auto-saves.

## Features

- 💾 **Flexible Save Management**: Create, load, and delete save files
- 🔄 **Auto-save Support**: Configurable automatic saving
- 📁 **Custom Save Locations**: Configurable save directory and file extensions
- 🔌 **Component-based Serialization**: Easy integration with game objects
- 🛡️ **Async Operations**: Non-blocking save/load operations
- ⚙️ **Project Settings Integration**: Configurable through Godot's project settings

## Quick Start

### 1. Access Save Manager

```gdscript
var save_manager = CoreSystem.save_manager
```

### 2. Register Serializable Components

```gdscript
# Create a serializable component
class_name PlayerData
extends SerializableComponent

func serialize() -> Dictionary:
    return {
        "position": owner.position,
        "health": owner.health,
        "inventory": owner.inventory
    }

func deserialize(data: Dictionary) -> void:
    owner.position = data.position
    owner.health = data.health
    owner.inventory = data.inventory

# Register the component
save_manager.register_serializable_component($PlayerData)
```

### 3. Basic Save Operations

```gdscript
# Create a save
save_manager.create_save("save_001", func(success: bool):
    if success:
        print("Save created successfully!")
)

# Load a save
save_manager.load_save("save_001", func(success: bool):
    if success:
        print("Save loaded successfully!")
)

# Delete a save
save_manager.delete_save("save_001", func(success: bool):
    if success:
        print("Save deleted successfully!")
)
```

### 4. Auto-save Usage

```gdscript
# Enable auto-save
ProjectSettings.set_setting("save_system/auto_save_enabled", true)
ProjectSettings.set_setting("save_system/auto_save_interval", 300)  # 5 minutes
ProjectSettings.set_setting("save_system/max_auto_saves", 3)

# Create auto-save manually
save_manager.create_auto_save()
```

## Project Settings

| Setting | Description | Default |
|---------|-------------|---------|
| save_directory | Directory for save files | "user://saves" |
| save_extension | File extension for saves | "save" |
| auto_save_enabled | Enable auto-save | true |
| auto_save_interval | Interval between auto-saves (seconds) | 300 |
| max_auto_saves | Maximum number of auto-saves | 3 |

## API Reference

### SaveManager

Core class for managing save operations.

#### Properties
- `save_directory: String`: Directory where saves are stored
- `save_extension: String`: File extension for save files
- `auto_save_interval: float`: Time between auto-saves
- `max_auto_saves: int`: Maximum number of auto-saves
- `auto_save_enabled: bool`: Whether auto-save is enabled

#### Methods
- `create_save(save_name: String, callback: Callable) -> void`: Create a new save
- `load_save(save_name: String, callback: Callable) -> void`: Load an existing save
- `delete_save(save_name: String, callback: Callable) -> void`: Delete a save
- `create_auto_save() -> void`: Create an auto-save
- `register_serializable_component(component: SerializableComponent) -> void`: Register a component for serialization
- `unregister_serializable_component(component: SerializableComponent) -> void`: Unregister a component

#### Signals
- `save_created(save_name: String)`: Emitted when a save is created
- `save_loaded(save_name: String)`: Emitted when a save is loaded
- `save_deleted(save_name: String)`: Emitted when a save is deleted
- `auto_save_created`: Emitted when an auto-save is created
- `auto_save_cleaned`: Emitted when old auto-saves are cleaned up

### SerializableComponent

Base class for components that can be saved.

#### Methods
- `serialize() -> Dictionary`: Convert component state to dictionary
- `deserialize(data: Dictionary) -> void`: Restore component state from dictionary

## Best Practices

1. **Component Organization**
   - Keep serializable components focused and single-purpose
   - Use clear naming conventions for save files
   - Clean up old saves periodically

2. **Error Handling**
   - Always check callback success status
   - Provide fallback behavior for failed loads
   - Handle corrupted save files gracefully

3. **Auto-save Usage**
   - Set appropriate intervals based on game type
   - Consider player progress and checkpoint frequency
   - Clean up old auto-saves regularly

4. **Performance**
   - Use async operations for large saves
   - Optimize serialized data size
   - Batch multiple saves when possible

## Common Issues

1. **Save Fails to Create**
   - Check write permissions
   - Verify save directory exists
   - Ensure valid save name format

2. **Load Operation Fails**
   - Verify save file exists
   - Check file permissions
   - Validate save data format

3. **Auto-save Issues**
   - Check auto-save settings
   - Verify available disk space
   - Monitor auto-save performance impact
