# Local condition triggers

CoreTrigger is an instance-owned synchronous gate. It has no AutoLoad, event subscriptions, clock, random source or condition registry. Call `try_fire` explicitly from your event handler or timer driver. Its purpose is to apply a condition and quota once without letting nested callbacks bypass that quota.

```gdscript
static func is_ready(context: Dictionary) -> bool:
    var tags: CoreTags = context.get("tags") as CoreTags
    return tags != null and tags.has("state.ready")

var trigger: CoreTrigger = CoreTrigger.new(is_ready, 2)
var result: CoreTrigger.Result = trigger.try_fire({"tags": local_tags})
```

The condition receives the original Dictionary and must return bool. Keep predicates free of gameplay side effects; payloads are not copied or serialized. `triggered(context)` is emitted after Count is committed. Notification is an accepted trigger, not a transaction guaranteeing all listeners completed their actions.

## Common contract

- Limit -1 means unlimited until the signed 32-bit count ceiling; 0 permits no attempts; positive values cap successful commits. Other negative limits are invalid. Count never wraps.
- Enabled defaults true. Disabled and exhausted gates skip condition evaluation and emit nothing. Failed conditions do not consume quota. If the condition disables its gate, no commit occurs.
- Reentrant calls during either condition evaluation or notification return Busy. Reset returns false during this period. This guard remains active until notification returns.
- Reset clears count only, preserving condition, limit and enabled state. It has no automatic execution or notification.
- Execution order is Busy, configuration, Disabled, LimitReached, condition, enabled recheck, count commit, notification. Independent gates share no runtime count.
- Calls are single-threaded and synchronous. There is no implicit activation, global scanning or periodic catch-up.

GDScript exposes `count`, `max_triggers`, `enabled`, `try_fire` and `reset`. Its result enum contains Fired/Disabled/LimitReached/ConditionFailed/Busy equivalents and GD-specific INVALID_CONFIGURATION/INVALID_CONDITION. Invalid configuration logs an English error and leaves the instance inert; invalid or released Callables and non-bool returns cannot commit. Script runtime errors are Godot diagnostics, not catchable C# exceptions. Signal listener runtime failures are not translated to a transactional rollback or a trigger error result.

C# uses CoreTrigger<T>, Func<T,bool>, Action<T>, CoreTriggerResult and PascalCase members. Invalid constructor parameters throw; condition exceptions propagate without commit; notification exceptions propagate with the count already consumed. `finally` releases the guard in either case. No cross-language message bridge is provided.

## Ownership and composition

Owners retain gates and disconnect notification handlers when those handlers reference released UI/nodes. A RefCounted model owning a trigger must avoid binding the trigger's condition back to that same model, which creates a reference cycle; use a static predicate over explicit context, as the example does. Reset does not release observers.

For events, retain and explicitly dispose the existing CoreEventSubscription in the owner. For periodic work, advance CoreTimer with the chosen delta and explicitly decide how many attempts to execute from its completion count. CoreTrigger owns neither subscription nor timer. Probability belongs in a supplied predicate with an explicit random source; no hidden global RNG is introduced.

## Legacy boundary

Old GD GameplayTrigger/TriggerManager/TriggerCondition remain separate APIs. Their activation, global condition registry, event routing, mutable Resource counters, probability and periodic behavior are not the common contract and are not ported wholesale. Do not drive one rule through both services. The old trigger_demo remains a legacy example; the new [triggers example](../../examples/triggers/README.md) runs without AutoLoad. This phase does not claim to fix all historical manager lifecycle problems.

## Verification

```powershell
godot --headless --path . --script res://addons/godot_core_system/test/unit/trigger_contract_checks.gd
godot --headless --path . --script res://addons/godot_core_system/test/unit/trigger_example_checks.gd
```

Require PASS and zero exit status. Invalid configuration/result cases intentionally log errors. Exported-build acceptance remains deferred by the user.

Verified on Godot 4.7.2: C# 31 and GD 28 rule checks, including event/timer composition; each language passes 10 real scene checks. Counts differ for language-specific error handling. Independent examples exit without retained-object warnings.
