# Config System

The legacy ConfigManager public methods remain, and the script now works independently.
See [independent configuration](configuration.md) for the full API, ownership rules, language
mapping and runnable checks, or run the [configuration example](../../examples/configuration/README.md).

```gdscript
const ConfigScript: Script = preload("res://addons/godot_core_system/source/config_system/config_manager.gd")
var settings: Node = ConfigScript.new("user://settings/player.cfg")
add_child(settings)
var volume: float = float(settings.get_value("audio", "volume", 1.0))
settings.set_value("audio", "volume", 0.8)
if not settings.save_config():
    push_error("Settings save failed: " + error_string(settings.last_error))
```

CoreSystem.config_manager remains the optional legacy entry. Independent code does not require it.
The path is now an instance export or explicit constructor argument. Project settings provide
optional constructor defaults, not live read-only properties. Parameterless construction loads
on ready after exports; explicit paths load immediately. Detached instances load explicitly.

Set/reset affects memory only. The existing auto_save setting/property is retained as metadata;
it does not automatically persist edits. Always call save_config at the desired checkpoint.
Earlier documentation suggesting automatic saving or read-only exports was inaccurate and is superseded here.

Missing files produce empty state. Other load errors preserve prior memory and modified status.
Save failures expose last_error and retain dirty status without requiring a logger. Section updates
merge keys; section snapshots duplicate nested collections. Each shared path has one writer.
ConfigFile writing is separate from the atomic JSON save store and makes no equivalent replacement guarantee.
