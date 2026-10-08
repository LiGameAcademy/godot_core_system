# Pending node-state ownership (#67)

Accepting a successful save replaces all pending node states, including when
the new nodes array is empty or absent. Failed loading leaves the current
save's pending states intact. Delayed registration consumes only the most
recent accepted save's data.

With the plugin installed and CoreSystem enabled in a writable host:

```sh
godot --headless --path /path/to/host res://addons/godot_core_system/test/unit/pending_save_checks.tscn
```

Expect PASS and exit 0. The scene creates real JSON files and exercises A to B
with empty nodes, A to C with the same node, failed loading, delayed node
registration and absent nodes. Stable IDs and concurrent save-slot loading
policies are not changed here.
