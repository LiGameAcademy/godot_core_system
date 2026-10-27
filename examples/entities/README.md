# Independent entities example

Open `res://addons/godot_core_system/examples/entities/entities_example.tscn` in Godot 4.7.2. No plugin activation, CoreSystem, tower assets or saved player data are required. An empty host needs source/entity_system/core_*.gd, source/resource_system/core_*.gd and this example (add entity_manager.gd and tests for legacy checks). C# hosts use Godot.NET.Sdk/4.7.2 and net10.0; when compiling the complete plugin, exclude tests/unit/**/*.cs.

1. Create A and B: separate runtime health starts at 100 and 150 using two typed definition Resources.
2. Damage A: A becomes red and health falls to 75; B stays white at 150 and definitions remain unchanged. Actor Ready duplicates the scene's mutable Gradient before modification.
3. Recycle A: the same node is reused, its health/tint reset, and an attempt with its previous lease returns DoesNotExist.
4. Clear: active and cached nodes are released. The scene definition remains available for another pair. Leaving the example permanently closes its group.

The example owns a CoreResources child, explicitly loads the actor PackedScene, and transfers a two-node pool to CoreEntities. Its owner supplies initialization/update/stop callbacks. The framework never reads game configuration or UI nodes. Failures are Error results; attached cleanup completes at the deletion frame. Arbitrary callback side effects are not rolled back.

Run in a separate host with this repository at addons/godot_core_system:

```powershell
godot --headless --path <host> res://addons/godot_core_system/tests/entities_checks.tscn
godot --headless --path <host> res://addons/godot_core_system/tests/entities_example_checks.tscn
godot --headless --path <host> res://addons/godot_core_system/tests/legacy_entities_checks.tscn
```

Expected: 25 core checks and 6 scene/button checks pass; GD has 11 additional legacy adapter checks. Export acceptance is deferred. The API's ownership, callback and compatibility details are in the entities document under docs.
