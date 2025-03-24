# Scene System

The Scene System provides a comprehensive solution for managing scene transitions and states, with features like transition effects, scene stacking, and asynchronous loading.

## Features

- 🔄 **Transition Effects**: Built-in and custom scene transition effects
- 📚 **Scene Stack**: Save and restore scene states
- ⚡ **Async Loading**: Non-blocking scene loading operations
- 🔍 **Scene Preloading**: Preload scenes for faster switching
- 🎯 **Sub-Scene Management**: Add and manage sub-scenes

## Core Components

### SceneManager

Central manager for all scene operations:
- Scene transition management
- Scene state handling
- Scene stack operations

```gdscript
# Basic scene switching
scene_manager.change_scene_async(
    "res://scenes/game.tscn",    # Scene path
    {"level": 1},               # Scene data
    true,                       # Save to stack
    SceneManager.TransitionEffect.FADE  # Effect
)

# Return to previous scene
scene_manager.pop_scene_async(
    SceneManager.TransitionEffect.FADE
)
```

### BaseTransition

Base class for creating custom transition effects:

```gdscript
extends BaseTransition
class_name CustomTransition

func _do_start(duration: float) -> void:
    # Implement start transition
    pass

func _do_end(duration: float) -> void:
    # Implement end transition
    pass
```

## API Reference

### SceneManager

#### Properties

```gdscript
enum TransitionEffect {
    NONE,       # No transition effect
    FADE,       # Fade in/out transition
    SLIDE,      # Slide transition
    DISSOLVE,   # Dissolve transition
    CUSTOM      # Custom transition
}
```

#### Methods

##### Scene Management

```gdscript
# Change scene asynchronously
func change_scene_async(
    scene_path: String,              # Scene path
    scene_data: Dictionary = {},     # Scene data
    push_to_stack: bool = false,     # Save current scene
    effect: TransitionEffect = NONE, # Effect type
    duration: float = 0.5,          # Duration
    callback: Callable = Callable(), # Callback
    custom_transition: BaseTransition = null  # Custom effect
) -> void

# Return to previous scene
func pop_scene_async(
    effect: TransitionEffect = NONE,
    duration: float = 0.5,
    callback: Callable = Callable(),
    custom_transition: BaseTransition = null
) -> void

# Add a sub-scene
func add_sub_scene(
    parent_node: Node,
    scene_path: String,
    scene_data: Dictionary = {}
) -> Node

# Get current scene
func get_current_scene() -> Node
```

##### Scene Preloading

```gdscript
# Preload a scene
func preload_scene(scene_path: String) -> void

# Clear preloaded scenes
func clear_preloaded_scenes() -> void
```

##### Transition Effects

```gdscript
# Register custom transition
func register_transition(
    effect: TransitionEffect,
    transition: BaseTransition
) -> void
```

#### Signals

```gdscript
signal scene_loading_started(scene_path: String)
signal scene_changed(old_scene: Node, new_scene: Node)
signal scene_loading_finished()
signal scene_preloaded(scene_path: String)
```

### BaseTransition

#### Methods

```gdscript
# Initialize transition
func init(transition_rect: ColorRect) -> void

# Start transition
func start(duration: float) -> void

# End transition
func end(duration: float) -> void
```

#### Protected Methods

```gdscript
# Override for custom start effect
func _do_start(duration: float) -> void

# Override for custom end effect
func _do_end(duration: float) -> void
```

## Best Practices

1. Always use `change_scene_async()` for scene switching
2. Implement state management for scenes that need persistence
3. Preload frequently used scenes
4. Use appropriate transition effects
5. Handle scene loading errors gracefully

## Examples

Check the `examples/scene_demo` directory for complete examples of:
- Basic scene switching
- Custom transition effects
- Scene state management
- Scene preloading
