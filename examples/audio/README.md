# Independent audio example

Entry: res://addons/godot_core_system/examples/audio/audio_example.tscn.
Requires Godot 4.7, source/audio_system core scripts/scenes and source/config_system/config_manager.gd. No CoreSystem AutoLoad or logger is required. Copy these directories into an otherwise empty project and open the scene. The example synthesizes a short WAV tone and owns a Master bus scope; do not run it concurrently with another Master scope.

Play starts looping music; repeat Play replaces it with a bounded crossfade. Stop fades out; Sound plays one bounded non-looping voice. Volume changes the live mix. Save writes user://core_audio_example.cfg explicitly; Restore applies current saved configuration values in memory. Startup explicitly loads that file. Failure appears in the status label; playback remains usable. Exit stops players and restores the original bus volume/mute.

From a host project directory:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . res://addons/godot_core_system/tests/audio_checks.tscn
godot --headless --path . res://addons/godot_core_system/tests/audio_example_checks.tscn
godot --headless --path . res://addons/godot_core_system/tests/legacy_audio_checks.tscn
```

Expected: 24 core checks, 6 real-button checks and 7 legacy checks with failed: false. Tests use unique owned files and clean them; existing example settings are not overwritten. Legacy checks also cover category gain once and preference-key collisions. See docs/systems/audio_system.md for supported music streams, ownership and failure contracts. Listening and exports remain manual acceptance items.
