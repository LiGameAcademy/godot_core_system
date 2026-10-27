# Resource loading example

Install this plugin at `addons/godot_core_system/` in a Godot 4.7.2 project. Open `resource_loading_example.tscn` and press F6. No AutoLoad, game scripts or external assets are required. The scene owns a CoreResources child and a built-in Gradient template.

| Button | Expected behavior |
| --- | --- |
| Load now | Load the template synchronously and show its first color |
| Request twice | Evict the completed entry, request the template twice and share one pending handle |
| Cancel | Abandon the interested result; native work still completes and is collected |
| Clear completed cache | Release local cache references; interested requests continue |
| Request missing resource | Display the CantOpen result without modifying the template |
| Clone template | Edit a duplicate to red; the shared template and another example instance keep their colors |
| New owner | Close the old owner and create an empty cache; old callbacks cannot replace the new UI |
| Leave | Close requests before removing the example; press F6 to start again |

The small template can finish quickly, so its progress may jump from zero to complete. This is real engine progress, with no artificial delay. Automated checks register a test-only ResourceFormatLoader that delays a native worker to exercise cancellation and exit deterministically. It is never registered by the example or production service.

Run in an isolated test host, replacing `godot` with the local executable:

```powershell
godot --headless --editor --path . --import --quit
godot --headless --path . --max-fps 120 --script res://addons/godot_core_system/test/unit/resource_contract_checks.gd
godot --headless --path . --max-fps 120 --script res://addons/godot_core_system/test/unit/resource_example_checks.gd
```

Expected: `Resource contract checks: 40 PASS` and `Resource example checks: 11 PASS`, both with exit code zero. The contract failure fixture intentionally reports one native `Failed loading resource` error before validating the failure result and cleanup. A timeout is a failure. No lingering native tasks or retained-object warnings are accepted.

Checks create dedicated `user://resource_checks/` and `user://resource_example.corecheck` fixtures, never application settings or saves; shutdown fixtures can remain in the disposable test host. Build/export packages and visual acceptance remain separate. [API and legacy migration](../../docs/systems/resource_system.md).
