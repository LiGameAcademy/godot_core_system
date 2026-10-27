# Engine time scopes

CoreTime matches the C# engine-time ownership contract. It controls SceneTree.paused and Engine.time_scale through explicit callbacks; it does not replace the legacy TimeManager's private clock or named timers. CoreTimer still advances only when its owner supplies delta.

## Shared ownership contract

Create one service for a backend, normally owned by a persistent application node. Share that service with scenes; do not create competing services for the same SceneTree or modify engine time directly while a scope is active. All engine-adapter operations must run on the Godot main thread.

```gdscript
var time: CoreTime = CoreTime.for_scene_tree(get_tree())
var scope: CoreTimeScope = time.acquire()
if scope == null:
    push_error("Cannot acquire engine time: %s" % error_string(time.last_error))
    return
scope.set_paused(false)
scope.set_speed(2.0)
# The scene owner calls scope.dispose() in _exit_tree.
# The persistent owner calls time.dispose() before releasing its service.
```

acquire captures the existing paused/speed settings, including a non-default baseline. It does not apply new settings. Only one scope may be active; a second acquisition returns null and sets last_error to ERR_BUSY. The service stays available after a successful scope release. After service disposal, future acquisition returns null with ERR_UNAVAILABLE.

set_paused and set_speed apply the complete settings snapshot. Speed must be finite and greater than zero; use pause rather than zero speed. Invalid speeds return ERR_INVALID_PARAMETER and leave both scope state and backend unchanged. current returns a copy; changing that object cannot change internal settings. The baseline is also copied on acquisition. Current represents the last successfully applied settings, not a live engine read; out-of-band writes violate the ownership contract.

scope.dispose restores the acquired baseline, releases ownership and is idempotent. A stale released scope cannot modify or release a subsequent owner. time.dispose releases its active scope first, then becomes unavailable; it is also idempotent. A service must be kept alive until disposal. Scope uses a weak owner reference to avoid a RefCounted cycle: retaining only the scope does not retain the service and cannot guarantee restoration. Do not rely on garbage collection or dropping a variable to restore engine state.

## Explicit backend failures

A custom backend can be tested without Godot nodes:

```gdscript
var _settings: CoreTimeSettings = CoreTimeSettings.new(false, 1.0)
var time: CoreTime = CoreTime.new(read_settings, write_settings)

func read_settings() -> CoreTimeSettings:
    return _settings.copy()

func write_settings(settings: CoreTimeSettings) -> Error:
    # Commit both fields together, and return OK only after success.
    _settings = settings.copy()
    return OK
```

read must return CoreTimeSettings with valid speed. A null result or invalid Callable means ERR_UNAVAILABLE; wrong data types mean ERR_INVALID_DATA. write receives a separate copy and must return a valid Error integer. Malformed returns produce ERR_INVALID_DATA. Backend failures propagate from set/dispose and do not commit current. Failed restoration retains ownership so the caller can repair the backend and retry; acquire remains Busy. A backend must not partially mutate before returning a failure: neither implementation can roll back arbitrary callback side effects. Callbacks must not reenter or manipulate the same service.

last_error describes the most recent acquire attempt only. Mutation and disposal methods return their own Error results; always inspect failures. Low-level rejected calls return values rather than logging automatically, allowing the owner to choose how to report or retry.

## Language mapping

| C# | GDScript |
|---|---|
| new CoreTime(read, write) | CoreTime.new(read, write) |
| SceneTree adapter in CoreSystem | CoreTime.for_scene_tree(tree) |
| Acquire() | acquire(), then inspect null / last_error |
| scope.Current.Paused / Speed | scope.current.paused / speed |
| SetPaused / SetSpeed | set_paused / set_speed, returning Error |
| scope.Dispose / time.Dispose | scope.dispose / time.dispose, returning Error |

C# throws for invalid arguments, concurrent ownership, disposed objects and backend exceptions; GDScript has no exception mechanism and uses the documented results. C# settings are value records, while GDScript returns snapshot copies. Both preserve state on validation/backend failure, restore the acquired snapshot and reject stale owners. The same service must be used by all owners; the APIs do not detect competing independent service instances.

## Example and checks

In a Godot 4.7 host, install the plugin under addons/godot_core_system. Build the global class cache with an editor import, then run examples/time_scope/time_scope_example.tscn. Its Always-processing controls toggle pause/speed, release the snapshot and acquire again. Scene exit disposes its service. This standalone example is the sole time owner in its session; normal applications instead share the persistent service shown above.

```powershell
godot --headless --editor --path <host> --import
godot --headless --max-fps 120 --path <host> --script res://addons/godot_core_system/test/unit/time_scope_checks.gd --quit-after 1200
```

Require PASS: 37 independent and engine time-scope checks and zero exit code. Checks cover the C# common cases, snapshot isolation, explicit backend results, real pause/speed, actual buttons and scene exit restoration. Tests restore the original engine settings and do not save files. The host need not enable the full legacy CoreSystem; if all plugin examples are scanned, register SceneExampleHost using examples/native_scenes/scene_example_host.gd for that separate example's identifier.
