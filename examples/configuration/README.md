# Independent configuration example

Run `res://addons/godot_core_system/examples/configuration/configuration.tscn` in a Godot 4.7.2 host.
No CoreSystem AutoLoad or enabled plugin is required. The example owns one local configuration node.

Increment changes memory and marks it modified. Save persists and clears the flag. Increment again,
then Reload: the last saved count returns. Reset clears memory only; Save persists the empty state.
Restart the scene to read the saved value. The status shows the path and last IO result.

This example writes only `user://core_config_example/settings.cfg`. Assign a different exported path
for a second simultaneous instance: only one writer should own a shared file path. No automatic save
or arbitrary object serialization is supplied. Use the existing JSON save store when atomic replacement
is required. The two languages use Godot ConfigFile for this example.

Source behavior and migration mapping are documented in [configuration API](../../docs/systems/configuration.md).
Automated checks exercise the actual four buttons with a unique temporary path and remove only their own file.
Export verification is deferred; headless checks do not replace visual acceptance.
