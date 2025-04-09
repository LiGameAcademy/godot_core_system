# Resource System

The Resource System provides an efficient way to manage and load game resources, with features like asynchronous loading and resource caching.

## Features

- 🔄 **Async Loading**: Non-blocking resource loading
- 📦 **Resource Caching**: Smart caching for better performance
- 🎯 **Resource References**: Manage resource dependencies
- 🔍 **Resource Validation**: Verify resource integrity
- 📱 **Project Settings**: Configure through Godot's project settings
- 🗑️ **Automatic Cleanup**: Smart resource unloading

## Core Components

### ResourceManager

Central manager for all resource operations:
- Resource loading and caching
- Reference counting
- Memory management

```gdscript
# Configure through project settings
core_system/resource_system/cache_size = 100
core_system/resource_system/preload_resources = true
core_system/resource_system/cleanup_interval = 300

# Usage example
func _ready() -> void:
    var resource_manager = CoreSystem.resource_manager
    
    # Load resource
    var texture = resource_manager.load("res://assets/textures/player.png")
    
    # Async load
    resource_manager.load_async("res://assets/models/enemy.tscn",
        func(resource): setup_enemy(resource)
    )
```

## Usage Examples

### Basic Resource Loading

```gdscript
# Synchronous loading
func load_player_resources() -> void:
    var resource_manager = CoreSystem.resource_manager
    
    var texture = resource_manager.load("res://assets/textures/player.png")
    var animation = resource_manager.load("res://assets/animations/player.tres")
    var sound = resource_manager.load("res://assets/sounds/footstep.wav")
    
    setup_player(texture, animation, sound)
```

### Asynchronous Loading

```gdscript
# Async loading with callback
func load_level_async() -> void:
    var resource_manager = CoreSystem.resource_manager
    
    # Load multiple resources
    resource_manager.load_multiple_async([
        "res://assets/levels/level1.tscn",
        "res://assets/textures/background.png",
        "res://assets/music/level1_theme.ogg"
    ], func(resources): setup_level(resources))
    
    # Load single resource
    resource_manager.load_async("res://assets/models/enemy.tscn",
        func(resource): spawn_enemy(resource)
    )
```

### Resource Management

```gdscript
# Resource reference management
func manage_resources() -> void:
    var resource_manager = CoreSystem.resource_manager
    
    # Add reference
    resource_manager.add_reference("res://assets/textures/player.png")
    
    # Remove reference
    resource_manager.remove_reference("res://assets/textures/player.png")
    
    # Clear unused resources
    resource_manager.cleanup_unused()
```

## Best Practices

1. **Resource Organization**
   - Use clear folder structure
   - Follow consistent naming conventions
   - Group related resources

2. **Performance**
   - Preload frequently used resources
   - Use async loading for large resources
   - Implement proper reference counting

3. **Memory Management**
   - Clean up unused resources
   - Monitor memory usage
   - Use resource pools for frequently instantiated objects

## API Reference

### ResourceManager
- `load(path: String) -> Resource`: Load resource synchronously
- `load_async(path: String, callback: Callable) -> void`: Load resource asynchronously
- `load_multiple_async(paths: Array, callback: Callable) -> void`: Load multiple resources
- `add_reference(path: String) -> void`: Add resource reference
- `remove_reference(path: String) -> void`: Remove resource reference
- `cleanup_unused() -> void`: Clean up unreferenced resources
- `preload_resources(paths: Array) -> void`: Preload resources
- `unload_resource(path: String) -> void`: Unload specific resource
- `get_resource(path: String) -> Resource`: Get cached resource
- `has_resource(path: String) -> bool`: Check if resource is cached
- `clear_cache() -> void`: Clear resource cache
