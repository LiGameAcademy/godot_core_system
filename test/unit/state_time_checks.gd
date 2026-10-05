extends SceneTree

var _checks: int = 0
var _failed: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var values: Array[int] = [0, 1, 2]
	var simple: CoreStateMachine = CoreStateMachine.new(0, values, func(a: int, b: int) -> bool: return a == 0 and b == 1)
	_check(simple.current == 0, "Explicit initial value")
	_check(not simple.try_transition(0), "Repeated value rejected")
	_check(not simple.try_transition(2), "Rule rejection retains value")
	_check(simple.try_transition(1) and simple.current == 1, "Accepted value committed")
	_check(not simple.try_transition(99), "Unknown value rejected")
	var machine: BaseStateMachine = BaseStateMachine.new()
	var idle: Probe = Probe.new()
	var active: Probe = Probe.new()
	machine.add_state(&"idle", idle)
	machine.add_state(&"active", active)
	_check(machine.add_state(&"duplicate", idle) == null, "Shared instance rejected")
	_check(not machine.transition_local(&"active"), "Stopped transitions rejected")
	_check(machine.start(&"idle"), "Explicit start succeeds")
	_check(idle.prepares == 1 and active.prepares == 1, "States prepare once")
	_check(not machine.start(&"active") and idle.enters == 1, "Duplicate start rejected")
	_check(not machine.transition_local(&"idle") and idle.exits == 0, "Same state does not exit")
	machine.update(0.2)
	machine.physics_update(0.2)
	machine.handle_input(InputEventAction.new())
	_check(idle.updates == 1 and idle.physics == 1 and idle.inputs == 1, "All drivers forwarded")
	machine.pause()
	machine.update(1.0)
	machine.handle_input(InputEventAction.new())
	_check(machine.is_active and idle.is_active and idle.updates == 1 and idle.inputs == 1, "Pause retains state without driving")
	_check(not machine.transition_local(&"active"), "Paused transitions rejected")
	machine.resume()
	machine.can_transition = func(_a: StringName, _b: StringName) -> bool: return false
	_check(not machine.transition_local(&"active") and idle.exits == 0, "Behavior rule rejection")
	machine.can_transition = Callable()
	active.on_enter = func() -> void: _check(not machine.transition_local(&"idle"), "Lifecycle reentry rejected")
	_check(machine.transition_local(&"active") and idle.exits == 1 and active.enters == 1, "Exit before target entry")
	active.on_enter = Callable()
	active.on_update = func() -> void: machine.transition_local(&"idle")
	machine.update(1.0)
	_check(machine.current_state == idle, "Update may request a transition")
	_check(machine.stop() and not machine.stop(), "Stop exits once")
	_check(machine.start(&"", {}, true) and machine.current_state == idle, "Explicit history resume")
	_check(idle.prepares == 1, "Restart does not prepare again")
	machine.dispose()
	machine.dispose()
	_check(idle.disposals == 1 and active.disposals == 1 and idle.state_machine == null, "Dispose detaches and cleans once")
	var outer: BaseStateMachine = BaseStateMachine.new()
	var inner: BaseStateMachine = BaseStateMachine.new()
	var child: Probe = Probe.new()
	inner.add_state(&"child", child)
	outer.add_state(&"group", inner)
	outer.add_state(&"other", Probe.new())
	_check(inner.add_state(&"cycle", outer) == null, "Hierarchy cycles rejected")
	_check(outer.start(&"group") and inner.current_state == child and child.enters == 1, "Nested entry occurs once")
	outer.update(1.0)
	_check(child.updates == 1, "Nested update forwarded")
	outer.pause()
	outer.update(1.0)
	_check(child.updates == 1, "Outer pause freezes child")
	outer.resume()
	_check(outer.transition_local(&"other") and child.exits == 1 and not inner.is_active, "Outer exit stops child once")
	_check(outer.transition_local(&"group") and child.enters == 2, "Nested machine reenters once")
	outer.dispose()
	_check(child.disposals == 1, "Nested disposal reaches leaves")
	var manager_script: GDScript = preload("../../source/state_machine/state_machine_manager.gd")
	var manager: Node = manager_script.new()
	var registered: BaseStateMachine = BaseStateMachine.new()
	var registered_idle: Probe = Probe.new()
	registered.add_state(&"idle", registered_idle)
	registered.add_state(&"active", Probe.new())
	registered_idle.state_entered.connect(func(_msg: Dictionary) -> void:
		_check(not manager.unregister_state_machine(&"one"), "Entered callback cannot lose registration")
	)
	registered_idle.on_prepare = func() -> void:
		_check(not manager.unregister_state_machine(&"one"), "Prepare callback cannot lose registration")
	manager.register_state_machine(&"one", registered)
	manager.start_state_machine(&"one", &"idle")
	_check(manager.get_state_machine(&"one") == registered and registered.is_active, "Rejected unregister preserves running owner")
	registered.state_changed.connect(func(_a: BaseState, _b: BaseState) -> void:
		_check(not manager.unregister_state_machine(&"one"), "Changed callback cannot lose registration")
	)
	registered.transition_local(&"active")
	registered.states[&"active"].state_exited.connect(func() -> void:
		manager.register_state_machine(&"exited_revive", registered)
		_check(manager.get_state_machine(&"exited_revive") == null, "Exit callback cannot register busy machine under another ID")
	)
	manager.state_machine_stopped.connect(func(_id: StringName) -> void:
		manager.register_state_machine(&"one", registered)
		manager.register_state_machine(&"revived", registered)
		_check(manager.get_state_machine(&"one") == null and manager.get_state_machine(&"revived") == null, "Unregister notifications cannot revive disposed state")
	)
	_check(manager.unregister_state_machine(&"one") and registered.states.is_empty() and registered.disposed, "Unregister cleans after lifecycle returns")
	manager.free()
	var orphan: Array[Variant] = _make_orphan()
	_check(orphan[0].get_ref() == null and orphan[1].state_machine == null, "Weak ownership releases machine")
	var one: CoreTimer = CoreTimer.new(1.0)
	_check(one.advance(0.25) == 0 and is_equal_approx(one.get_remaining(), 0.75), "Partial timer progress")
	one.paused = true
	_check(one.advance(5.0) == 0 and is_equal_approx(one.elapsed, 0.25), "Timer pause freezes elapsed")
	one.paused = false
	_check(one.advance(2.0) == 1 and one.completed and one.elapsed == 1.0, "One-shot completes once")
	_check(one.advance(5.0) == 0, "Completed timer does not fire again")
	one.reset()
	_check(not one.completed and one.elapsed == 0.0, "Reset restarts timer")
	var periodic: CoreTimer = CoreTimer.new(1.0, true)
	_check(periodic.advance(3.25) == 3 and is_equal_approx(periodic.elapsed, 0.25), "Repeating timer preserves overshoot")
	_check(periodic.advance(0.75) == 1 and periodic.elapsed == 0.0, "Repeating timer consumes exact boundary")
	_check(one.elapsed == 0.0, "Timers are isolated")
	# Invalid-input cases intentionally emit English diagnostics.
	var invalid: CoreTimer = CoreTimer.new(0.0)
	_check(invalid.advance(1.0) == 0, "Invalid construction stays inert")
	_check(periodic.advance(-1.0) == 0 and periodic.elapsed == 0.0, "Negative delta is rejected without mutation")
	_check(periodic.advance(INF) == 0 and periodic.elapsed == 0.0, "Infinite delta is rejected")
	_check(periodic.advance(2147483648.0) == 0 and periodic.elapsed == 0.0, "Completion overflow preserves state")
	var invalid_flow: CoreStateMachine = CoreStateMachine.new(99, values, func(_a: int, _b: int) -> bool: return true)
	_check(not invalid_flow.try_transition(1), "Invalid value helper stays inert")
	periodic.paused = true
	periodic.reset()
	_check(periodic.paused, "Reset preserves pause choice")
	print("%s: %d GDScript state and timer checks" % ["FAIL" if _failed else "PASS", _checks])
	quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
	_checks += 1

func _make_orphan() -> Array[Variant]:
	var owner: BaseStateMachine = BaseStateMachine.new()
	var leaf: Probe = Probe.new()
	owner.add_state(&"leaf", leaf)
	return [weakref(owner), leaf]

class Probe extends BaseState:
	var prepares: int = 0
	var enters: int = 0
	var exits: int = 0
	var updates: int = 0
	var physics: int = 0
	var inputs: int = 0
	var disposals: int = 0
	var on_prepare: Callable
	var on_enter: Callable
	var on_update: Callable
	func _ready() -> void:
		prepares += 1
		if on_prepare.is_valid():
			on_prepare.call()
	func _enter(_msg: Dictionary = {}) -> void:
		enters += 1
		if on_enter.is_valid():
			on_enter.call()
	func _exit() -> void:
		exits += 1
	func _update(_delta: float) -> void:
		updates += 1
		if on_update.is_valid():
			on_update.call()
	func _physics_update(_delta: float) -> void:
		physics += 1
	func _handle_input(_event: InputEvent) -> void:
		inputs += 1
	func _dispose() -> void:
		disposals += 1
