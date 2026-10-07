# Logger System

Preload `source/logger/core_logger.gd` directly; neither CoreSystem nor setting.gd is required.
CoreSystem.logger remains an optional legacy entry. See [configuration and diagnostics](configuration.md)
for the independent installation contract and GD/C# boundaries.

```gdscript
const LogScript: Script = preload("res://addons/godot_core_system/source/logger/core_logger.gd")
var log_node: Node = LogScript.new()
add_child(log_node)
log_node.set_level(LogScript.LogLevel.INFO)
log_node.set_file_path("user://logs/example.log")
log_node.enable_file_logging(true)
if log_node.last_file_error != OK:
    push_error("File logging unavailable: " + error_string(log_node.last_file_error))
log_node.info("Settings loaded")
```

Levels are DEBUG, INFO, WARNING, ERROR and FATAL. debug/info/warning/error/fatal accept a String
message and optional Dictionary context. set_level filters the formatted console/file output;
warning/error/fatal also retain their legacy engine diagnostics, independent of that threshold.
error/fatal print a stack. set_color, set_colors, reset_colors and get_colors configure local colors;
optional `godot_core_system/logger/color_*` project values seed defaults.

File output is disabled initially. Set the path before enabling. Parent directories are created;
set_file_path returns the current open result and last_file_error exposes errors. Opening uses
WRITE, retaining legacy truncation behavior. Changing path, disabling output or tree exit closes
the previous handle; close_file is also explicit. One writer owns a shared path. There is no
log rotation, configure_file_logging or generic log(level) public method in this implementation.
Older examples using those nonexistent APIs are superseded by this page.

C# CoreLogger is a pure filtering class with an explicit sink; engine formatting, contexts,
stack printing and file writing are GD extensions, not a claim of identical logger APIs. File
output is not atomic game persistence. The [independent checks](../../test/unit/independent_config_checks.gd)
cover installing without the settings script, explicit nested log paths, filtering and close/flush.
