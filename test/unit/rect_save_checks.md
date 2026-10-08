# Rectangle save regression (#64)

With this branch installed at addons/godot_core_system and CoreSystem enabled:

```sh
godot --headless --path /path/to/writable/host res://addons/godot_core_system/test/unit/rect_save_checks.tscn
```

Expect PASS: 36 rectangle checks and exit code 0. The tests exercise the actual
JSON intermediate layer and disk round trips with JSON/binary strategies,
non-square Rect2/Rect2i, negative/zero sizes and nested values.
The field names and read format are unchanged. Historical files that already
lost their height cannot reconstruct it from the incorrectly saved width.
