# CoreEntities

CoreEntities owns activations of one PackedScene. The caller supplies a valid scene and transfers an open, initially empty CoreInstancePool exclusively to the group. Do not continue using that pool or transfer it to a second group. The scene and any external CoreResources cache remain borrowed; closing a group does not evict or dispose them.

This is a Godot main-thread lifecycle service. It adds no global registry, resource cache, ECS, actor base class or required initialization interface. Game actors own their rules and reset operations. Static definition Resources are read-only by convention; health and other runtime state belong to each activation. Duplicate mutable nested Resources before changing them.

## Operations and results

| GDScript | C# | Behavior |
| --- | --- | --- |
| `create(parent, initialize)` | `Create(parent, initialize)` | Return Error + new lease after successful attachment and initialization |
| `update(lease, callback)` | `Update(lease, callback)` | Apply caller-owned update; return callback Error |
| `recycle(lease, deactivate)` | `Recycle(lease, deactivate)` | Stop/reset through callback, detach, transfer to the pool |
| `destroy(lease)` | `Destroy(lease)` | Final removal without pooling |
| `clear()` | `Clear()` | Release all active and cached nodes, retain scene for later creation |
| `close()` | `Close()` / `Dispose()` | Permanent, idempotent shutdown |
| `get_leases()` | `GetLeases()` | Snapshot of live leases, pruning externally freed/queued nodes |
| `active_count`, `cached_count`, `is_closed` | `ActiveCount`, `CachedCount`, `IsClosed` | Counts and lifecycle state |

The parent must already be inside the scene tree. Attachment runs Ready before the initialization callback on a fresh actor; scene defaults must therefore support Ready. Reuse does not rerun Ready: initialization must reset every per-activation field. A scene tree owner explicitly closes the group in _exit_tree / _ExitTree.

A lease identifies one activation, even when the pool returns the same node later. Keep the lease in deferred callbacks. Foreign, forged, duplicate or expired leases return DoesNotExist. Passing an old node alone cannot prove activation identity. Main-thread mutations during another group operation return Busy; closed groups return Unavailable. Close inside a callback marks closed immediately and drains after the operation returns.

Initialization failure never publishes a lease and releases the provisional node. Callback failure during update/recycle retains the lease if its node is still live; arbitrary callback side effects cannot be rolled back. Callbacks must validate before changing state. Nodes deleted by callbacks are pruned. Attached nodes are queued for deletion, detached nodes are freed immediately. Wait for the deletion frame when checking final release. A successful recycle into a full or zero-capacity pool can immediately free the node: do not access it afterward.

GDScript callbacks must return an integer Godot Error; missing/invalid returns produce ERR_INVALID_DATA. C# callbacks return Error; exceptions propagate after the operation guard is restored (and provisional creation is cleaned up). Invalid construction fails closed with an English engine error in GD; C# throws an argument exception. Both require main-thread use; C# throws on wrong-thread access and GD returns an unavailable/error result for mutations. GD lease node returns null after native deletion; C# callers validate GodotObject.IsInstanceValid(lease.Node) before using it.

## Explicit resource composition

Load a scene using a caller-owned CoreResources, check its result and PackedScene type, then construct CoreEntities with that scene and a new pool. The [independent example](../../examples/entities/README.md) contains the complete runnable composition, including typed definition Resources, actor initialization and owner shutdown. Resource request deduplication/cancellation stays in CoreResources; CoreEntities receives already loaded scenes.

## Legacy GDScript adapter

EntityManager.configure(resources) borrows a CoreResources; the optional CoreSystem composition root injects its ResourceManager loader. Standalone use requires explicit injection. Historical IDs, signals and load/create/update/destroy methods remain available, with last_error reporting results. Immediate and lazy load modes accept the existing integer enum values.

Each ID owns its own entity group. Several IDs can share a cached scene and threaded request. Unloading one ID disconnects only its observer, closes its group and emits entity_unloaded; it does not cancel another ID's shared request or evict the borrowed loader. Clear cancels this adapter's observations, releases active/cached entities and retains completed scene definitions. Exit closes all groups. Reload during same-ID unload and operations during clear/exit are rejected.

Create now requires an explicit in-tree parent. A missing initialize method returns MethodNotFound and releases the provisional node. Historical void initialize/update/destroy callbacks are accepted; Error returns are respected. The adapter does not promise rollback of legacy script errors. Destroy must stop the actor without freeing it when pooling is intended. Legacy Node-only callbacks cannot detect activation reuse; migrate asynchronous owners to CoreEntityLease. The entity_destroyed signal may carry null if pool overflow freed the node.

## Validation

Godot 4.7.2: both languages pass 25 core checks and 6 actual example button checks. GD also passes 11 legacy adapter checks (shared async path, unload, missing initialization, active clear and release reentry). No CoreSystem is present in these minimal hosts. Full GD plugin import reports no parsing errors. Export and visual acceptance remain deferred.
