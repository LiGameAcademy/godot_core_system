# Concurrent save/load regression (#63)

In a writable host project with this plugin at addons/godot_core_system and
the CoreSystem autoload enabled, run:

```sh
godot --headless --path /path/to/host res://addons/godot_core_system/test/unit/async_task_checks.tscn
```

The test covers JSON and binary concurrent writes/reads, mixed success/failure,
read/write overlap, and same-path submission order. Expect PASS and exit 0.
Missing files and invalid write targets intentionally log errors.

Requests using one AsyncIOStrategy share one FIFO worker. Same-path requests
are processed in submission order, so a read submitted after two writes sees
the second write. Different strategy instances have separate workers and no
cross-instance same-path ordering guarantee. Keep the strategy alive until
all its requests finish; cancellation/shutdown semantics are outside #63.
