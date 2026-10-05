# Native main-scene switching and fades

The minimal API uses Godot's current-scene lifecycle and matches the C# CoreScenes / CoreSceneTransition behavior. It is independent of the legacy CoreSceneManager, resource manager, scene stack and game-specific navigation. Existing legacy APIs remain unchanged; use one switching gateway per SceneTree and do not mix managers during an operation.

## Persistent ownership

Create one service in a persistent application node (for example, an AutoLoad), and dispose it when that owner exits:

```gdscript
var scenes: CoreScenes
var transition: CoreSceneTransition

func _ready() -> void:
    scenes = CoreScenes.new(get_tree())
    transition = CoreSceneTransition.attach_to(self)

func _exit_tree() -> void:
    scenes.dispose()
```

Callers retain explicit references to these objects. No CoreSystem module registration is needed. A normal outgoing scene must not own the service or transition. All operations run on the Godot main thread.

## Completion handles

```gdscript
var request: CoreSceneRequest = scenes.switch_to_path("res://scenes/next.tscn")
var result: Error = await request.wait()
```

switch_to_packed also accepts a PackedScene. Resource loading is synchronous; the engine switch is deferred, and OK is reported only after SceneTree.scene_changed. is_switching is true while a request is pending; a second request returns ERR_BUSY without queuing. Failure retains the original scene. Missing paths return ERR_CANT_OPEN; empty paths or non-instantiable resources return ERR_INVALID_PARAMETER. Null resources are rejected. Disposed services return ERR_UNAVAILABLE.

CoreSceneRequest stores the result, so wait works both before and after completion. Completion is emitted once. dispose is idempotent, disconnects the scene signal and settles pending requests. Disposing before deferred execution prevents that switch; once the engine starts removing the old scene, it cannot be undone.

A GDScript coroutine owned by a freed Node cannot resume. Await from a persistent owner; scene-owned buttons can connect request.completed to a bound method instead. Godot disconnects that callback when the scene is freed. The native_scenes example uses this pattern and checks is_completed before connecting, so immediate failures are also handled. Successful navigation must never access the old scene's controls.

## Optional presentation

```gdscript
transition.duration = 0.25
var request: CoreSceneRequest = transition.switch_to(scenes, "res://scenes/next.tscn")
var result: Error = await request.wait()
```

Duration is the duration of each fade in real seconds. Zero skips animation; negative or non-finite values return ERR_INVALID_PARAMETER. The persistent CanvasLayer fades to black, submits the scene request, waits for initialization, then fades in. Its request finishes after the final fade, including on failure. is_transitioning covers the entire operation; duplicates return ERR_BUSY. The animation processes while paused and ignores Engine.time_scale, without modifying either engine setting or gameplay rules.

The cover blocks pointer interaction. The component consumes input events, but outgoing gameplay _input handlers may run first and must also guard against is_transitioning. Programmatic actions need the same guard. Do not submit direct CoreScenes requests while a fade is active. Scene-owned events, sounds and time scopes remain the scene owner's responsibility.

Exiting the transition stops its Tween and settles the fade with ERR_UNAVAILABLE. A small RefCounted operation owns the completion flow so freeing the presentation node does not orphan the request. An already-submitted engine switch cannot be cancelled. This is not background loading: synchronous loading after fade-out may stall.

## Language mapping

| C# | GDScript |
|---|---|
| await scenes.SwitchToAsync(path) | await scenes.switch_to_path(path).wait() |
| await scenes.SwitchToAsync(packed) | await scenes.switch_to_packed(packed).wait() |
| scenes.IsSwitching / Dispose() | scenes.is_switching / dispose() |
| CoreSceneTransition.AttachTo(owner) | CoreSceneTransition.attach_to(owner) |
| await transition.SwitchToAsync(scenes, path) | await transition.switch_to(scenes, path).wait() |
| Duration / IsTransitioning | duration / is_transitioning |

GDScript has no C# exception mechanism: invalid parameters and unavailable services return Error codes, while C# throws documented argument/disposal exceptions. Both reject these calls without changing scenes. GDScript Node-owned awaits require the lifecycle pattern above; a Task continuation in C# must instead check native node validity. This is behavior alignment, not identical syntax or exception compatibility.

## Verification

Install the plugin under addons/godot_core_system in a Godot 4.7 host. For the standalone example, register SceneExampleHost as an AutoLoad pointing to examples/native_scenes/scene_example_host.gd, and run scene_a.tscn or scene_b.tscn.

```powershell
godot --headless --editor --path <host> --import
godot --headless --max-fps 120 --path <host> --script res://addons/godot_core_system/test/unit/scene_parity_checks.gd --quit-after 1200
```

Require a zero exit code and PASS: 24 GDScript scene parity checks. The runner swaps scenes and exits; run it in a dedicated session. It covers completion, retained scenes on failure, duplicate calls, paused real-time fades, queued disposal, presentation-node destruction, repeated zero-duration switches and actual example buttons. The host needs only this plugin and the example AutoLoad, not the legacy full framework AutoLoad.
