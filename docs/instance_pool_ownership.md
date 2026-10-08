# Instance-pool ownership (#68)

Recycling transfers a valid Node to the pool after detaching it from its parent.
The same instance can belong to only one pool. Repeated recycling and nodes
already queued for deletion are ignored. Borrowing transfers ownership back to
the caller; freed/queued cached references are skipped.

clear_instance_pool removes the selected pool(s) and queue_free()s all valid
nodes still owned by them. ResourceManager exit does the same. Borrowed nodes
are not destroyed. Destruction is deferred: wait for the frame cleanup before
checking is_instance_valid. Callers that previously cleared the pool while
retaining references must now borrow the nodes first if they intend to keep them.

Regression in a writable host with CoreSystem:

```sh
godot --headless --path /path/to/host res://addons/godot_core_system/test/unit/pool_ownership_checks.tscn
```

It covers individual/all-pool clear, duplicate/cross-pool recycling, borrowed
nodes, queued/freed references and manager exit. Expect PASS and exit 0.
