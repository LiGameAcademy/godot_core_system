# Local character tags demo

Open `tag_demo.tscn` in a Godot host containing this plugin. No CoreSystem AutoLoad is required. This migrated scene keeps the existing move, attack and buff controls and UI layout.

Each `tag_character.tscn` instance owns a CoreTagCharacterModel with its own CoreTags and CoreTimer. The model handles movement and attack rules without nodes or UI. The character drives the timer and displays rule results; it emits signals to the demo root, which coordinates controls and status labels. Moving during an attack preserves the attack visual until completion. Freeing the scene disconnects model notifications.

Tags are explicit full paths. Classification ancestors can be queried without adding them; one actor's movement or buff does not affect another actor. This example uses no deprecated tag objects or owner registry.

```powershell
godot --headless --path . --script res://addons/godot_core_system/test/unit/tag_demo_migration_checks.gd
```

Godot 4.7.2: 17 checks cover actual scene controls, actor isolation, attack completion and release cleanup. Require PASS and zero exit status.
