extends SceneTree

var _checks: int = 0
var _failed: bool = false
var _active: CoreTrigger
var _observations: Array[int] = []
var _condition_calls: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var gate: CoreTrigger = CoreTrigger.new(_accept, 2)
	gate.triggered.connect(_observe)
	_active = gate
	_check(gate.count == 0 and gate.max_triggers == 2 and gate.enabled, "Initial state")
	_check(gate.try_fire({"allow": false}) == CoreTrigger.Result.CONDITION_FAILED, "Rejected condition")
	_check(gate.count == 0 and _observations.is_empty(), "Rejected condition has no notification")
	_check(gate.try_fire({"allow": true}) == CoreTrigger.Result.FIRED, "Accepted condition")
	_check(_observations == [1, CoreTrigger.Result.BUSY, 0], "Count committed before notification; nested fire/reset blocked")
	gate.enabled = false
	var calls: int = _condition_calls
	_check(gate.try_fire({"allow": true}) == CoreTrigger.Result.DISABLED, "Disabled gate")
	_check(_condition_calls == calls and gate.count == 1, "Disabled gate skips condition")
	_check(gate.reset() and gate.count == 0 and not gate.enabled, "Reset preserves disabled state")
	gate.enabled = true
	_check(gate.try_fire({"allow": true}) == CoreTrigger.Result.FIRED, "Re-enabled gate")
	_check(gate.try_fire({"allow": true}) == CoreTrigger.Result.FIRED, "Final permitted attempt")
	calls = _condition_calls
	_check(gate.try_fire({"allow": true}) == CoreTrigger.Result.LIMIT_REACHED, "Limit reached")
	_check(_condition_calls == calls and gate.count == 2, "Limit skips condition")
	_check(gate.reset() and gate.try_fire({"allow": true}) == CoreTrigger.Result.FIRED, "Reset restores quota")
	var zero: CoreTrigger = CoreTrigger.new(_accept, 0)
	_check(zero.try_fire({"allow": true}) == CoreTrigger.Result.LIMIT_REACHED, "Zero limit never fires")
	var unlimited: CoreTrigger = CoreTrigger.new(_accept)
	for index: int in range(10):
		unlimited.try_fire({"allow": true})
	_check(unlimited.count == 10 and unlimited.max_triggers == -1, "Unlimited attempts")
	_check(unlimited.count != gate.count, "Independent instance state")
	gate.triggered.disconnect(_observe)
	_active = CoreTrigger.new(_reentrant_condition)
	_check(_active.try_fire({}) == CoreTrigger.Result.FIRED, "Condition reentrancy is blocked")
	_check(_active.count == 1, "Condition cannot reset its current attempt")
	_active = CoreTrigger.new(_disable_condition)
	_check(_active.try_fire({}) == CoreTrigger.Result.DISABLED and _active.count == 0, "Condition disable prevents commit")
	_active = null
	var invalid: CoreTrigger = CoreTrigger.new(Callable())
	_check(invalid.try_fire({}) == CoreTrigger.Result.INVALID_CONFIGURATION, "Invalid callable rejected")
	invalid = CoreTrigger.new(_accept, -2)
	_check(invalid.try_fire({}) == CoreTrigger.Result.INVALID_CONFIGURATION, "Invalid negative limit")
	invalid = CoreTrigger.new(_invalid_result)
	_check(invalid.try_fire({}) == CoreTrigger.Result.INVALID_CONDITION and invalid.count == 0, "Invalid result has no commit")
	_check(invalid.reset(), "Invalid result clears busy guard")
	var model: CoreTriggerExampleModel = CoreTriggerExampleModel.new()
	model.try_fire()
	_check(model.trigger.count == 0, "Example starts blocked")
	model.toggle_ready()
	model.try_fire()
	_check(model.trigger.count == 1, "Example combines tags and trigger")
	var bus: CoreEventBus = CoreEventBus.new()
	var driven: CoreTrigger = CoreTrigger.new(_accept, 2)
	var subscription: CoreEventSubscription = bus.subscribe(&"attempt", func(context: Dictionary) -> void: driven.try_fire(context))
	var timer: CoreTimer = CoreTimer.new(1.0, true)
	var completions: int = timer.advance(3.25)
	for index: int in range(completions):
		bus.publish(&"attempt", {"allow": true})
	_check(completions == 3 and driven.count == 2, "Timer catch-up remains bounded by trigger quota")
	_check(is_equal_approx(timer.get_remaining(), 0.75), "Timer retains independent overshoot")
	subscription.dispose()
	driven.reset()
	bus.publish(&"attempt", {"allow": true})
	_check(driven.count == 0 and bus.subscription_count == 0, "Owner disposal stops event driving")
	if not _failed:
		print("PASS: %d trigger contract checks" % _checks)
	quit(1 if _failed else 0)

func _accept(context: Dictionary) -> bool:
	_condition_calls += 1
	return context.get("allow", false) == true

func _observe(context: Dictionary) -> void:
	_observations.append(_active.count)
	_observations.append(_active.try_fire(context))
	_observations.append(int(_active.reset()))

func _reentrant_condition(context: Dictionary) -> bool:
	return _active.try_fire(context) == CoreTrigger.Result.BUSY and not _active.reset()

func _disable_condition(_context: Dictionary) -> bool:
	_active.enabled = false
	return true

func _invalid_result(_context: Dictionary) -> String:
	return "invalid"

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
