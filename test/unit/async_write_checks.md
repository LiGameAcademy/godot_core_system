# AsyncIO write regression checks (#62)

Install this branch at `addons/godot_core_system` in a writable Godot project
with the `CoreSystem` autoload enabled. Import it once, then run:

```sh
godot --headless --editor --path /path/to/host --import
godot --headless --path /path/to/host res://addons/godot_core_system/test/unit/async_write_checks.tscn
```

The scene checks missing/failed/invalid encoding strategies, existing-file
preservation, stopping later stages, legitimate empty content, JSON null,
JSON and Gzip/XOR round trips, nested and relative paths, directory/open
failures, and a real read-only FileAccess handle for store_buffer failure.
It verifies task IDs, completion status and the existing null write result.
Test files use a unique directory under res:// and are removed on completion.
Run from a writable working directory for the relative-path case.

Exit code 0 and a final PASS line mean the assertions passed; negative cases
intentionally log errors. Each asynchronous operation has a five-second
timeout. This suite does not simulate disk exhaustion, deferred flush/close
failure, process crashes, or atomic replacement.

On the original main implementation, the missing-serializer case reports
success and clears the seeded file. The same regression passes after the fix.
