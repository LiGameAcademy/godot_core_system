# Independent timer

`CoreTimer` is a scene-independent countdown for cooldowns and periodic rules. It has no clock, callback registry, global manager or automatic processing. Its owner calls `advance(delta)` with elapsed seconds and consumes the completion count. Use Godot `Timer` / `SceneTreeTimer` for ordinary node-level waiting.

```gdscript
var cooldown: CoreTimer = CoreTimer.new(1.0, true)

func update_cooldown(delta: float) -> int:
    return cooldown.advance(delta)
```

Duration must be finite and positive. Delta must be finite and nonnegative. One-shot timers complete once and clamp elapsed time to duration. Repeating timers return all completed intervals in O(1), retaining overshoot: advancing a 1-second timer by 3.25 seconds returns 3 and keeps 0.25 seconds elapsed. Consumption policies belong to the game; avoid creating an unbounded number of effects from a large completion count.

`paused` freezes advancement. `reset` clears elapsed/completed without changing pause. Duration, repeat mode and progress are read-only through the public API. Timers are independent, single-threaded instances. Invalid input or overflow reports an English error and leaves progress unchanged, including release builds. Invalid construction creates an inert timer. Completion counts are capped at 2,147,483,647, matching C# int.

Pass the owner's Godot delta once; it is already affected by engine speed. Do not multiply it by Engine.time_scale again. An independent clock requires the owner to supply a different elapsed-time source. This helper does not change the legacy TimeManager or register named timers.

C# `CoreTimer` has matching `Advance`, `Paused`, `Reset`, `Remaining`, `Elapsed`, `Completed`, `Duration`, and `Repeating` behavior, with argument/overflow exceptions. Floating-point boundary precision is inherited from double/GDScript float; it is not a fixed-point simulation clock. Checks are in `test/unit/state_time_checks.gd`.

For exclusive SceneTree pause/speed ownership with snapshot restoration, see [CoreTime scopes](core_time_scope.md). This separate service does not add a clock to CoreTimer.
