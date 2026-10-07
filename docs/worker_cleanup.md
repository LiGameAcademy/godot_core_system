# Worker and save strategy ownership (#110)

The owner calls `SingleThread.stop()`, `AsyncIOManager.close()` or
`AsyncIOStrategy.close()` on the main thread before releasing the object.
Repeated calls are safe. A stopped worker rejects `add_task` with `-1`; a
closed IO manager rejects new submissions with an empty task ID. Closed save
strategies return `false` / an empty dictionary without waiting for a signal.

Stopping discards queued work and its captured objects, waits for a running
function, and suppresses queued worker completion notifications. Running
functions cannot be interrupted and must terminate for close to return.
Worker functions must not call stop/close or wait for the main thread while
their owner is joining them. These methods diagnose a call outside the main
thread without closing the object.

IO close reports each accepted, not-yet-delivered task exactly once through
`io_completed(task_id, false, null)`. It clears the ID registry before these
notifications, so a callback can safely call close again. The running file
operation may already have affected the file: cancellation is a delivery
result, not a rollback or atomic-write guarantee. Callers must not interpret
failure on shutdown as proof that the destination has not changed.

SaveManager closes its currently registered strategies when removed from the
tree or deleted, including deletion before entering the tree. Custom strategies
inherit a no-op `close`; those owning workers override it. A registered strategy
must not share a worker with another live owner. Removing a SaveManager ends its
strategy lifetime; create a new manager to resume rather than re-add a closed
manager. When replacing a custom registration, the caller remains responsible
for the previous strategy until it explicitly closes it. Broader registration
and reuse policy belongs to the independent save service work in #99.

JSON/Binary constructors explicitly run the async base constructor once and
configure its existing IO instance. Godot does not automatically invoke a
base `_init` when a derived `_init` overrides it; the previous replacement
constructors did not demonstrate a double-created base worker. The observed
retention was fixed by owner shutdown, queue release and completion cleanup.

Run in a writable imported host with CoreSystem:

```sh
godot --headless --verbose --path <host> res://addons/godot_core_system/test/unit/worker_cleanup_checks.tscn
```

Expected: PASS, exit 0, no script errors or ObjectDB/Resource retention from
these workers. Tests cover idle construction, all derived strategies, normal
IO, repeated close, post-close submission, cancellation IDs and callback
reentry, queued captures, running-task joining, deferred completion suppression,
and attached/unattached SaveManager deletion. Startup class imports must be
complete before evaluating the runtime result.

Verified with Godot 4.7.2 stable mono / Windows. Sandbox certificate, user log
directory and editor settings errors are environmental diagnostics; they are
reported separately from script and ownership failures. Other platforms and
custom long-running tasks still require acceptance.
