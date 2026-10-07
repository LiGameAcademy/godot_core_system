# Independent configuration and diagnostics

`source/config_system/config_manager.gd` can be installed by itself. Preload the script;
there is no `CoreSystem` type, logger, setting script, plugin activation or AutoLoad dependency.

```gdscript
const Config: Script = preload("res://addons/godot_core_system/source/config_system/config_manager.gd")
var config: Node = Config.new("user://settings/player.cfg")
add_child(config)
config.set_value("game", "speed", 2.0)
if not config.save_config():
	push_error("Settings could not be saved: " + error_string(config.last_error))
```

An explicit constructor path loads immediately. Parameterless construction loads on ready,
after scene exports have been assigned. Detached consumers call `load_config` explicitly.
Optional legacy ProjectSettings supply constructor defaults; exports or explicit paths override them.
`CoreSystem.config_manager` still uses the same script and existing public methods.

## State and IO

Each instance owns its ConfigFile. One owner writes each file path; there is no cross-instance
lock, merge or automatic reload. `set_section` merges keys, rather than removing omitted keys.
`get_section` returns a deep Array/Dictionary snapshot. Values returned by `get_value`,
caller-supplied collections, and Object/Resource references still require caller ownership;
these APIs are not an arbitrary object isolation layer.

Missing files load as empty, unmodified state. Parse/IO failures retain prior memory and dirty status.
`save_config` returns bool and exposes `last_error`; only successful saving clears dirty status.
The optional `diagnostic` Callable receives English failure messages; without it, engine diagnostics
remain available. Loaded/saved/reset signals run after state commits. Diagnostics and observers
must not recursively mutate the service. C# callback exceptions propagate after any state commit.

Edits and reset require an explicit save. `auto_save` remains legacy metadata with no new behavior.
Null deletion and additional change-detection behavior tracked by #15/#40 are not claimed resolved.
ConfigFile saving retains its native behavior; it does not provide the atomic replacement guarantees
of CoreSaveStore. Existing JSON persistence and its native extension are unchanged.

## Standalone logger

`source/logger/core_logger.gd` also installs alone. Project colors are optional, with local defaults.
Its original filtering/color/context/stack methods remain. `set_file_path(path)` sets an explicit
path; `enable_file_logging(true)` opens it and exposes `last_file_error`. Parent directories are
created for that path. Disabling output, changing paths or exiting the tree closes the old handle.
Opening an existing file retains legacy WRITE/truncation behavior. One writer owns a log path.
File open failures use engine errors, never another logger getter. Output write errors are not
an atomic persistence contract. C# CoreLogger already accepts a caller sink, independent of Godot;
file output is supplied through that sink rather than a second built-in file writer.

## Language mapping and checks

| GDScript | C# CoreConfig | Meaning |
| --- | --- | --- |
| config_path | ConfigPath | Instance path |
| load_config / save_config | Load / Save | Explicit IO; optional override does not replace the instance path |
| last_error / is_modified | LastError / IsModified | IO result and dirty state |
| set_value / get_value | SetValue / GetValue | ConfigFile key/value access |
| set_section / get_section | SetSection / GetSection | Merge and deep collection snapshot |
| has_section / has_key / get_sections | HasSection / HasKey / GetSections | Queries |
| reset_config | ResetConfig | Local reset |
| diagnostic | Diagnostic | Optional failure callback |
| config_loaded / config_saved / config_reset | Loaded / Saved / Reset | Post-commit notification |

Use both implementations on the Godot main thread. Input collection graphs must be acyclic. Share only ConfigFile-supported data for
cross-language files; game-specific Resource/script types require their own compatibility tests.
Both implementations compare nested collections and approximate floats. No JSON schema is added.

Run GD with `--headless --path <host> --script res://addons/godot_core_system/test/unit/independent_config_checks.gd`.
C# uses `res://addons/godot_core_system_cs/examples/checks/config_checks.tscn` in a .NET host.
Install only the two GD scripts plus its check, or CoreConfig plus its C# check; no AutoLoad.
Corrupt fixtures intentionally print a native ConfigFile parse error before recovery assertions.
The interactive [configuration example](../../examples/configuration/README.md) demonstrates manual persistence.

2026-10-07: minimal hosts pass GD 20 / C# 18 core checks and 6 actual button checks per language. The full C# plugin host builds with zero warnings/errors and passes the same config and button checks. Existing C# logger 10 and JSON persistence 68 regressions pass. Full CoreSystem startup combinations remain tracked by #75/#102, and exports are not verified.
