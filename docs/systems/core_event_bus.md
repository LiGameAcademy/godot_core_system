# Synchronous event contract

CoreEventBus is a scene-independent RefCounted service with the C# publication and subscription lifecycle. It does not replace the legacy CoreSystem.CoreEventBus Node: priorities, filters, deferred calls and history remain separate extensions. Use an explicit shared bus; local parent/child communication still uses signals.

```gdscript
var bus: CoreEventBus = CoreEventBus.new()
var token: CoreEventSubscription = bus.subscribe(&"notice", receive_notice)
var result: Error = bus.publish(&"notice", 1)
token.dispose()

func receive_notice(value: int) -> void:
    print("Notice received: %d" % value)
```

subscribe requires a nonempty StringName and a valid one-payload Callable, with an optional once flag. It returns an independently disposable token; duplicate Callables create separate subscriptions. Rejection returns null and sets last_error to ERR_INVALID_PARAMETER. last_error describes subscribe only; publish returns its own Error. subscription_count counts active registrations and prunes freed targets. dispose is idempotent. Dropping a token variable does not unsubscribe because the bus owns its registration.

C# routes by exact generic type; GD routes by exact StringName. Event names and payload types are the application's contract. Callbacks must accept the payload type; Variant is only the dynamic routing boundary, not a substitute for typed game rules. Null payloads and empty names are rejected. Payloads are not cloned; avoid mutating shared payload objects.

## Shared dispatch behavior

| Case | Both languages |
|---|---|
| Publication | Synchronous, in registration order |
| Add during dispatch | Excluded from current snapshot; visible to later and nested publications |
| Cancel before invocation | Pending snapshot entry is skipped |
| One-shot listener | Removed before invocation, so recursion or failure cannot repeat it |
| Clear during dispatch | Invalidates remaining old entries |
| Clear and resubscribe | New registrations work on later publications; stale tokens cannot cancel them |
| Duplicate callback | Each token controls its own registration |
| Explicit failure | Stops this publication; the bus remains usable; earlier side effects are not rolled back |

Reentrant publication starts its own snapshot. Ordinary listeners can run again recursively; applications guard unbounded recursion. This single-threaded service has no priority, filter, queue, deferred delivery, history or automatic retry.

## Failure and ownership boundaries

C# Action callbacks return void; exceptions propagate. GD has no equivalent exception mechanism: ordinary void callbacks succeed, and callbacks that can fail explicitly return Error. The first non-OK stops dispatch and is returned by publish. Any non-null result outside the valid Error integer range returns ERR_INVALID_DATA; a boolean is not a filter/success result. A failing or malformed one-shot remains removed.

Unexpected GD script errors and wrong Callable signatures cannot be reliably caught or converted to Error by this service. Validate event schemas and use explicit returns for recoverable failures; do not interpret script runtime errors as successful recovery. C# null argument exceptions map to GD rejected results.

The application owns the bus; each listening scene owns a token and disposes it in _exit_tree. The bus owner calls clear on exit. Tokens weakly reference the bus, so retain the bus while using it. Callable closures may still capture the bus or other RefCounted owners and form indirect cycles; explicit cleanup is required. Freed Node targets are pruned as a fallback, which does not replace exit cleanup.

The example parent injects a bus before the event_owner scene enters the tree. The child emits a local notice_received signal for the UI; it does not find parents, globals or UI paths. Buttons publish, remove the owner and create a fresh owner. No saved files or game assets are required.

## Mapping and checks

| C# | GD |
|---|---|
| Subscribe<T>(callback, once) | subscribe(event_name, callback, once) |
| Publish<T>(payload) | publish(event_name, payload), returning Error |
| IDisposable.Dispose() | CoreEventSubscription.dispose() |
| SubscriptionCount / Clear() | subscription_count / clear() |

Install at addons/godot_core_system in a Godot 4.7 host. Import, then run examples/event_contract/event_contract_example.tscn. If all separate examples are scanned, register SceneExampleHost from examples/native_scenes/scene_example_host.gd for that separate example.

```powershell
godot --headless --editor --path <host> --import
godot --headless --path <host> --script res://addons/godot_core_system/test/unit/event_contract_checks.gd --quit-after 600
```

Require PASS: 26 event contract checks and zero exit code. C# tests/unit/EventBusChecks.csproj has 18 measured assertions for corresponding cases; GD adds dynamic validation, freed targets and real scene ownership. This proves the minimal contract, not the legacy priority/filter/deferred module's equivalence.
