# Tag System

The Tag System is a lightweight, flexible tag management system for adding and managing tags on game objects. It supports hierarchical tag structures and can be used to implement various game features such as state marking, classification systems, and more.

## Features

- 🏷️ **Hierarchical Tags**: Support for multi-level tags separated by dots (e.g., "character.player.state.idle")
- 🔍 **Flexible Queries**: Support for exact and fuzzy tag matching
- 📦 **Tag Containers**: Independent tag management for game objects
- 🎯 **Event Notifications**: Signals emitted on tag changes
- 💾 **Persistence**: Support for tag serialization and deserialization

## Quick Start

### 1. Access Tag Manager

```gdscript
var tag_manager = CoreSystem.tag_manager
```

### 2. Create Tag Container

```gdscript
# Add tag container node in scene
var tag_container = GameplayTagContainer.new()
add_child(tag_container)

# Or reference existing tag container through scene tree
@onready var tag_container = $TagContainer
```

### 3. Basic Usage

```gdscript
# Add tags
tag_container.add_tag("character.player")
tag_container.add_tag("state.idle")

# Check tags
if tag_container.has_tag("character.player"):
    print("This is a player!")

# Remove tags
tag_container.remove_tag("state.idle")

# Get all tags
var all_tags = tag_container.get_tags()
print("Current tags:", all_tags)
```

### 4. Advanced Features

```gdscript
# Check multiple tags
var required_tags = ["character.player", "state.idle"]
if tag_container.has_all_tags(required_tags):
    print("Player is idle!")

# Fuzzy matching
if tag_container.has_tag("character", false):
    print("This is any character!")

# Listen for tag changes
tag_container.tag_added.connect(_on_tag_added)
tag_container.tag_removed.connect(_on_tag_removed)
```

## Examples

Check the [tag_demo](../examples/tag_demo/) directory for a complete example project.

### Player State Example

```gdscript
# Add initial tags to player
player_tags.add_tag("character.player")
player_tags.add_tag("state.idle")

# Switch player state
func _on_player_move():
    player_tags.remove_tag("state.idle")
    player_tags.add_tag("state.moving")

# Add buff
func _on_buff_acquired(buff_name: String):
    player_tags.add_tag("buff." + buff_name)
```

## API Reference

### GameplayTagManager

Global tag manager responsible for tag registration and management.

- `register_tag(tag_name: String) -> void`: Register new tag
- `get_tag(tag_name: String) -> GameplayTag`: Get tag object
- `has_tag(tag_name: String) -> bool`: Check if tag is registered

### GameplayTagContainer

Tag container node for managing a single object's tag collection.

- `add_tag(tag) -> void`: Add tag
- `remove_tag(tag) -> void`: Remove tag
- `has_tag(tag, exact: bool = true) -> bool`: Check if has specified tag
- `has_all_tags(required_tags: Array, exact: bool = true) -> bool`: Check if has all specified tags
- `has_any_tags(required_tags: Array, exact: bool = true) -> bool`: Check if has any specified tags
- `get_tags() -> Array`: Get all tag names
- `get_all_tags() -> Array[GameplayTag]`: Get all tag objects (including child tags)

### GameplayTag

Tag object representing a single tag.

- `name: StringName`: Tag name
- `parent: GameplayTag`: Parent tag
- `children: Array[GameplayTag]`: Child tags list
- `matches(other: GameplayTag, exact: bool) -> bool`: Check if matches another tag

## Best Practices

1. **Use Hierarchical Structure**
   - Use dots to separate different levels
   - Example: `character.player.state.idle`

2. **Tag Naming Conventions**
   - Use lowercase letters
   - Use dots for hierarchy
   - Avoid special characters
   - Use descriptive names

3. **Performance Considerations**
   - Avoid overusing tags
   - Remove unnecessary tags
   - Use exact matching instead of fuzzy matching

4. **Organize Tags**
   - Categorize by functionality (e.g., state, buff, character)
   - Keep hierarchy structure clear
   - Document tag purposes and meanings

## Common Issues

1. **Tag Does Not Exist**
   - Ensure tags are registered before use
   - Check tag name spelling
   - Check error messages in logs

2. **Tag Matching Fails**
   - Check if using correct matching mode (exact/fuzzy)
   - Confirm tag hierarchy structure
   - Check tag name case sensitivity

3. **Performance Issues**
   - Reduce unnecessary tags
   - Use exact matching instead of fuzzy matching
   - Avoid frequent tag addition/removal
