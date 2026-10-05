# State machines

Use the smallest state representation that fits the behavior. `CoreStateMachine` is a value-only enum transition helper. `BaseState` and `BaseStateMachine` are for states with independent lifecycle, update or input behavior. They do not require `CoreSystem` or a scene tree. `StateMachineManager` is an optional Godot driver, not the authoritative source of gameplay state.

## Value-only flow

```gdscript
enum Phase { IDLE, ACTIVE }
var flow: CoreStateMachine = CoreStateMachine.new(
    Phase.IDLE, [Phase.IDLE, Phase.ACTIVE],
    func(from: int, to: int) -> bool: return from == Phase.IDLE and to == Phase.ACTIVE
)

func activate() -> bool:
    return flow.try_transition(Phase.ACTIVE)
```

Use explicit enum values. Same-state, undefined-target and rejected transitions leave the current value unchanged. The rule must be a synchronous pure predicate. Reentrant transitions return false. Invalid construction reports an English error and creates an inert helper. This validation also runs in release builds.

## Behavior flow

Create state instances, add them, then call `ready()` or `start(initial_id)`. Override `_ready`, `_enter`, `_exit`, `_update`, `_physics_update`, `_handle_input`, and `_dispose` as needed. All signatures use explicit types. The complete runnable implementation is in [the example](../../examples/state_machine/example_game_state_machine.gd); it is the source of truth instead of hypothetical APIs.

- Preparation runs once before first entry. Restarting a stopped machine does not prepare again.
- Start enters once. A repeated start or same-state transition returns false.
- `transition_local` exits the old state before entering the new one. Optional `can_transition(from_id, to_id)` rejects before exit.
- `pause` suppresses update, physics and input, without exiting the active state. Paused transitions return false; resume does not enter again.
- `stop` exits once and stores `previous_state`. `start(initial_id, {}, true)` explicitly resumes it, falling back to the supplied initial ID.
- Lifecycle and predicate callbacks cannot mutate the same machine. Requests return false/no-op, without an implicit transition queue. Updates and input may request transitions.
- Registration cannot replace, add or remove states while running. A state belongs to one machine, with a weak owner reference. Cyclic nesting is rejected.
- `dispose` stops, disposes prepared states, detaches ownership and clears compatibility storage. Cleanup is idempotent and disposal is terminal. New runs create new machines and states. Disposed instances cannot be registered again.
- Owners should not write `current_state`, `states`, `is_active` or other lifecycle fields directly. These public legacy fields remain for compatibility.

Nested machines remain supported because the example uses them. `transition_local` always selects the current machine's own table. A leaf state's `transition_to` requests a sibling in its owner. To change an outer layer, explicitly call the owning machine. Child input runs first; if it changes the child state, the same input is not also passed to that machine's parent-level handler. Child-first update continues to allow parent behavior when still running.

`agent`, the variable dictionary and old `switch`/`switch_to` aliases remain compatibility conveniences. Prefer explicit typed context and `transition_local`/`transition_to` in new code. There are no built-in menu states, generic event bubbling, state factories or animation ownership.

## Optional Godot driver

The manager forwards frame, physics and input callbacks with registration flags. Unregister from the owner's `_exit_tree`; the manager also clears registrations when it exits. Registry iteration uses snapshots so update callbacks can unregister safely.

`unregister_state_machine` returns false during preparation, entry, exit or transition notification, preserving the registration. Retry after the callback returns. It does not silently detach a still-running machine. Cleanup finishes before stop/unregister notifications, and the closing ID cannot be re-registered inside those notifications. With multiple registered roots, `get_current_state` requires a root ID rather than returning an arbitrary last root.

## C# alignment

The C# plugin provides the same two use cases: `CoreStateMachine<TState>` and `CoreBehaviorStateMachine<TState,TContext,TInput>` with `CoreState<TContext,TInput>`. Behavior lifecycle, pause, driving, transition ordering, history and instance ownership align. C# nesting uses a state that owns and forwards to a child machine; different enum types may be used at each level. It does not copy the legacy global registry or untyped variable bag.

C# validates with exceptions and uses `IDisposable`. GDScript reports/rejects invalid operations; it cannot offer C# exception rollback. C# predicate exceptions preserve the old state. Entry or exit exceptions stop the behavior machine; cleanup errors propagate. Neither language can undo side effects inside user callbacks or make asynchronous behavior atomic. Cancel user-created async operations in exit/dispose and check ownership before making delayed transition requests.

## Checks

Install the plugin at `res://addons/godot_core_system` in a Godot 4 project, import it, then run:

```powershell
godot --headless --path <host> --script res://addons/godot_core_system/test/unit/state_time_checks.gd
```

The checks run without the CoreSystem Autoload. They cover value transitions, lifecycle, pause, reentry, nested driving, weak ownership, callback-time unregister and independent timers. Success requires an explicit PASS line and exit code zero.

For the real hierarchical example scene, enable CoreSystem and run test/unit/state_machine_example_checks.gd with the same --script command. It checks input consumption, nested history and owner exit. Full original CoreSystem startup currently also reports existing SingleThread leaks at shutdown; standalone state/time checks do not instantiate that module and exit without this leak. Thread utilities were outside this change. Invalid-input checks intentionally emit error diagnostics; their final PASS and exit code are the verdict.
