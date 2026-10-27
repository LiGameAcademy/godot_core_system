# CoreGameSession

Caller-owned, local session lifecycle. This is a RefCounted rule object, not an AutoLoad, scene manager, game mode or save file. It composes CoreStateMachine and stores only a fixed identity and phase. The caller supplies a non-empty String; identities are not normalized or globally registered.

## API and transitions

| API | Behavior |
| --- | --- |
| new(id) / id / phase | Starts PREPARING; identity and phase expose queries |
| snapshot() | New Dictionary[String, Variant] containing id and phase; modifying it does not alter the session |
| start() | PREPARING → RUNNING |
| pause(before_commit = Callable()) | RUNNING → PAUSED; optional synchronous adapter runs first |
| resume(before_commit = Callable()) | PAUSED → RUNNING; optional synchronous adapter runs first |
| end() | RUNNING / PAUSED → ENDED; the project owns success/failure information |
| close() | Any non-CLOSED phase → CLOSED; no reset or restart |
| changed(previous, current) | Typed phase signal, emitted after state commits |

Commands return bool. Repeated/illegal commands and all lifecycle reentry during adapters or notifications return false without another notification. Invalid construction reports an English error and leaves a non-operational object. A static state predicate avoids retaining the session through its internal state machine.

```gdscript
var session: CoreGameSession = CoreGameSession.new("round-1")
session.start()
session.pause()
session.resume()
session.end()
session.close()
```

## External pause adapter

An optional Callable must return Error; only OK allows the phase to commit. Expired callables, non-integer results and errors reject the command and release the reentry guard. Illegal commands never invoke the adapter. The adapter must preserve external state on failure or restore its own partial changes; the session cannot roll back arbitrary side effects.

An already-owned CoreTimeScope can adapt Godot global pause:

```gdscript
var accepted: bool = session.pause(scope.set_paused.bind(true))
```

The caller still owns and disposes scope. Closing a session does not restore engine settings or cancel external tasks. changed observes committed facts; do not use its duration or sound callbacks to decide rule outcomes.

GD signals do not provide C# exception propagation or transactional rollback. Arbitrary script runtime errors are reported by Godot; only an explicit Error return participates in the adapter failure contract. C# adapters use Action/exception and its observer exception retains the committed phase; this language difference is intentional.

## Ownership and validation

For a new round, disconnect old observers, close the old instance, create a new identity/instance and bind observers again. Closed instances stay closed. The owner cancels old timers/tasks and filters late callbacks by identity; the identity does not perform cancellation itself. Game data remains in the project's rule object, never in this service.

See the [standalone count/timer example](../../examples/game_session/README.md). In a host with the required scripts imported:

```powershell
godot --headless --path . --script res://addons/godot_core_system/test/unit/session_contract_checks.gd
godot --headless --path . --script res://addons/godot_core_system/test/unit/session_example_checks.gd
```

Godot 4.7.2 checks pass: 63 rule checks and 13 actual example checks. The empty-identity case deliberately reports one error before PASS. Coverage includes the full command matrix, snapshot isolation, notification/adapter reentry, failed CoreTimeScope pause/resume, two end conditions, old instance closure and UI cleanup. These checks use an isolated host with this module's necessary dependencies, without legacy full-module AutoLoad; they do not clear the existing legacy-entry retention or deferred export acceptance.
