# Module switch names (#70)

The existing editor settings are retained:

| Runtime module ID | Registered setting suffix |
| --- | --- |
| state_machine_manager | state_machine |
| tag_manager | gameplay_tag_manager |
| All other IDs | Same as runtime module ID |

All settings use godot_core_system/module_enable/. A registered setting wins
if both it and an older hand-written runtime-ID key are present. The runtime-ID
key remains a fallback when the registered key is absent. No project settings
are rewritten. Missing switches still default to enabled.

Switches control module creation and do not unload an already-created module.
Dependency disabling policy is a separate design discussion in #75.

For startup verification add these entries to the host's [godot_core_system]
section before running with CoreSystem enabled:

```ini
module_enable/state_machine=false
module_enable/gameplay_tag_manager=false
```

```sh
godot --headless --path /path/to/host res://addons/godot_core_system/test/unit/module_setting_checks.tscn
```

Expect PASS: 32 module setting checks / exit 0. It verifies initial module
absence, every registered module switch, fallback keys and canonical precedence.
