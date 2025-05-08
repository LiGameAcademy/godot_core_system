# Config System

The Config System provides a straightforward solution for managing game configurations using Godot's built-in `ConfigFile` format, supporting persistent storage and default values.

## Features

- ⚙️ **Simple Key-Value Storage**: Leverages Godot's `ConfigFile` for easy section/key/value management.
- 💾 **Persistent Storage**: Loads from and saves to a specified file (default: `user://config.cfg`).
- 🔄 **Default Value Handling**: `get_value` gracefully handles missing keys by returning a provided default.
- 🔌 **Project Settings Integration**: Key settings like `config_path` and `auto_save` can be configured via Project Settings (though accessed internally, not directly exposed as settable properties in the script provided).
- 📂 **Section Management**: Organizes settings into logical sections within the config file.
- ⚙️ **Synchronous Operations**: Core load, save, get, and set operations are synchronous.

## Quick Start

### 1. Access Config Manager

```gdscript
# Assuming CoreSystem singleton is set up
var config_manager = CoreSystem.config_manager
```

### 2. Basic Operations

```gdscript
# ConfigManager typically loads automatically on init/ready. Manual load example:
# var success = config_manager.load_config()
# if success:
#     print("Config loaded/reloaded.")

# Get configuration value (provide a default if the key might not exist)
var sound_volume = config_manager.get_value("audio", "sound_volume", 1.0)
print("Sound Volume: ", sound_volume)

# Set configuration value
# If auto_save is true (default), this might trigger an automatic save.
config_manager.set_value("audio", "sound_volume", 0.8)

# Check if a value was modified and potentially save manually if auto_save is off
# (The internal _modified flag handles this if auto_save is on)
# if config_manager._modified: # Note: _modified is internal, direct access not recommended practice
#    var save_success = config_manager.save_config()
#    if save_success:
#        print("Config saved manually.")

# Reset config in memory (and saves an empty file if auto_save is on)
# config_manager.reset_config()
```

### 3. Default Values

The system relies on providing default values when calling `get_value`. There isn't an explicit "default config file" mechanism shown in the script, but rather handling defaults at the point of access.

```gdscript
# If "difficulty" doesn't exist in the [gameplay] section, this returns "normal"
var difficulty = config_manager.get_value("gameplay", "difficulty", "normal")
```

## Project Settings (via `setting.gd`)

These settings control the ConfigManager's behavior and are typically defined in your plugin's `setting.gd` or similar setup script:

| Setting Name (in ProjectSettings)         | Description                     | Default in `setting.gd` Example |
| ----------------------------------------- | ------------------------------- | ------------------------------- |
| `godot_core_system/config_system/config_path` | Path to the configuration file. | `"user://config.cfg"`           |
| `godot_core_system/config_system/auto_save`   | Automatically save when `set_value` changes a value. | `true`                          |

*Note: The `@export` variables in `config_manager.gd` use `get:` only, reading these project settings.*

## API Reference

### ConfigManager (`config_manager.gd`)

Core class for managing configurations via `ConfigFile`.

#### Properties (Accessed via Project Settings)

-   `config_path: String` (Read via `ProjectSettings.get_setting(SETTING_CONFIG_PATH, ...)`): Path to the configuration file.
-   `auto_save: bool` (Read via `ProjectSettings.get_setting(SETTING_AUTO_SAVE, ...)`): Whether to automatically save when a value is modified via `set_value`.

#### Methods

-   `load_config(p_path: String = "") -> bool`: Loads configuration from the specified path (or the default `config_path` if empty). Returns `true` if loading was successful (or file not found, which is treated as success with empty config), `false` on other errors. Typically called automatically during initialization.
-   `save_config(p_path: String = "") -> bool`: Saves the current configuration to the specified path (or the default `config_path`). Ensures the directory exists. Returns `true` on success, `false` on failure. Called automatically by `set_value` if `auto_save` is true and a value was changed.
-   `reset_config() -> void`: Clears all sections and keys from the in-memory configuration. If `auto_save` is true, it will then save an empty configuration file.
-   `set_value(section: String, key: String, value: Variant) -> void`: Sets a configuration value. Marks the configuration as modified if the new value is different from the current value. Triggers `save_config` if `auto_save` is true and the value changed.
-   `get_value(section: String, key: String, p_default_value: Variant) -> Variant`: Gets a configuration value. If the section or key does not exist, returns `p_default_value`.
-   `get_section(section: String) -> Dictionary`: Returns a dictionary containing all key-value pairs *currently loaded* for the given section. Returns an empty dictionary if the section doesn't exist.
-   `set_section(section: String, value: Dictionary) -> void`: Updates a configuration section by setting or overriding keys based on the input dictionary `value`. *Note: This implementation adds or overwrites keys, it does not strictly replace the entire section by deleting old keys first.* Triggers `save_config` if `auto_save` is true and any value was changed.
-   `get_sections() -> PackedStringArray`: Returns an array of all section names currently loaded in the configuration.
-   `has_section(section: String) -> bool`: Checks if a section exists in the currently loaded configuration.
-   `has_key(section: String, key: String) -> bool`: Checks if a key exists within a given section in the currently loaded configuration.

#### Signals

-   `config_loaded`: Emitted when configuration loading (even if empty/file not found) is completed via `load_config`.
-   `config_saved`: Emitted when configuration is successfully saved via `save_config`.
-   `config_reset`: Emitted when the in-memory configuration is cleared via `reset_config`.

## Best Practices

1.  **Configuration Organization**: Use clear section and key names (e.g., `[audio] music_volume = 0.8`).
2.  **Default Values**: Always provide a default value in `get_value` calls to prevent errors if a setting is missing.
3.  **Error Handling**: Check the return values of `load_config` and `save_config` if calling them manually, especially if `auto_save` is off.
4.  **Performance**: `ConfigFile` operations involve disk I/O, which is relatively slow. Avoid calling `load_config` or `save_config` repeatedly in performance-critical loops. Rely on `auto_save` or save changes at logical points (e.g., closing settings menu, quitting game). Cache frequently accessed values in variables instead of calling `get_value` repeatedly within the same scope or frame.

## Common Issues

1.  **Configuration Not Saving**:
    *   Check file system permissions for the `user://` directory.
    *   Verify the `config_path` setting points to the correct location.
    *   Ensure `auto_save` is `true` OR you are calling `save_config()` manually after `set_value`.
    *   Check for errors logged by `save_config`.
2.  **Settings Not Loading / Defaults Returned**:
    *   Verify the `config_path` is correct and the file exists.
    *   Check file system permissions.
    *   Ensure `load_config()` is called *before* you try to access values (moving `load_config` to `_init` helps).
    *   Check for errors logged by `load_config`.
    *   Ensure section and key names in `get_value` exactly match those in the `.cfg` file (case-sensitive).

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
