extends BaseState
class_name BaseStateMachine

## Optional nested behavior machine. Registration is fixed while running.
signal state_changed(from_state: BaseState, to_state: BaseState)

var current_state: BaseState = null
var states: Dictionary[StringName, BaseState] = {}
var values: Dictionary = {}
var previous_state: StringName = &""
## Optional pure predicate: (from_id, to_id) -> bool.
var can_transition: Callable = Callable()
var _changing: bool = false
var _driving: bool = false
var _paused: bool = false

func ready() -> void:
	if _is_ready or _preparing or _disposed:
		return
	super()
	_preparing = true
	for state: BaseState in states.values():
		state.ready()
	_preparing = false

func dispose() -> void:
	if _changing or _preparing or _disposed:
		return
	stop()
	_changing = true
	for state: BaseState in states.values():
		state.dispose()
		state.state_machine = null
	super()
	states.clear()
	values.clear()
	previous_state = &""
	_changing = false

## A nested state may select its initial child in _enter.
func enter(msg: Dictionary = {}) -> bool:
	if is_active or _changing or _disposed:
		return false
	ready()
	is_active = true
	_paused = false
	_enter(msg)
	if current_state == null:
		start(&"", msg)
	if current_state == null:
		is_active = false
		return false
	state_entered.emit(msg)
	return true

func exit() -> bool:
	if not is_active or _changing:
		return false
	stop()
	_changing = true
	_exit()
	state_exited.emit()
	_changing = false
	return true

func update(delta: float) -> void:
	if not _can_drive() or not is_finite(delta) or delta < 0.0:
		return
	_driving = true
	current_state.update(delta)
	if _can_continue():
		_update(delta)
	_driving = false

func physics_update(delta: float) -> void:
	if not _can_drive() or not is_finite(delta) or delta < 0.0:
		return
	_driving = true
	current_state.physics_update(delta)
	if _can_continue():
		_physics_update(delta)
	_driving = false

func handle_input(event: InputEvent) -> void:
	if not _can_drive() or event == null:
		return
	_driving = true
	var original: BaseState = current_state
	current_state.handle_input(event)
	if _can_continue() and current_state == original:
		_handle_input(event)
	_driving = false

func start(initial_state: StringName = &"", msg: Dictionary = {}, resume_previous: bool = false) -> bool:
	if current_state != null or _changing or _preparing or _disposed:
		return false
	ready()
	var target: StringName = initial_state
	if resume_previous and not previous_state.is_empty():
		target = previous_state
	if target.is_empty() and not states.is_empty():
		target = states.keys()[0]
	if not states.has(target):
		return false
	_changing = true
	current_state = states[target]
	is_active = true
	_paused = false
	var entered: bool = current_state.enter(msg)
	if not entered:
		current_state = null
		is_active = false
	_changing = false
	return entered

func stop() -> bool:
	if _changing or current_state == null:
		return false
	_changing = true
	var old: BaseState = current_state
	previous_state = old.state_id
	current_state = null
	is_active = false
	_paused = false
	old.exit()
	_changing = false
	return true

## Pause only suppresses driving; it does not exit the active state.
func pause() -> void:
	if current_state != null and not _changing:
		_paused = true

func resume() -> void:
	if current_state != null and not _changing:
		_paused = false

func is_paused() -> bool:
	return _paused

func add_state(id: StringName, new_state: BaseState) -> BaseState:
	if _disposed or _changing or (_preparing and _is_ready) or current_state != null or id.is_empty() or new_state == null or states.has(id):
		return null
	if new_state == self or new_state.state_machine != null or new_state.is_active or new_state.disposed:
		return null
	var ancestor: BaseStateMachine = state_machine
	while ancestor != null:
		if ancestor == new_state:
			return null
		ancestor = ancestor.state_machine
	states[id] = new_state
	new_state.state_machine = self
	new_state.agent = agent
	new_state.is_debug = is_debug
	new_state.state_id = id
	if _is_ready:
		new_state.ready()
	return new_state

func remove_state(id: StringName) -> void:
	if _changing or current_state != null or not states.has(id):
		return
	var removed: BaseState = states[id]
	states.erase(id)
	removed.dispose()
	removed.state_machine = null

func has_state(id: StringName) -> bool:
	return states.has(id)

## Explicitly uses this machine's table, including on nested machines.
func transition_local(target: StringName, msg: Dictionary = {}) -> bool:
	if _changing or not is_active or _paused or current_state == null or not states.has(target):
		return false
	if current_state == states[target]:
		return false
	_changing = true
	var old: BaseState = current_state
	if can_transition.is_valid() and not can_transition.call(old.state_id, target):
		_changing = false
		return false
	previous_state = old.state_id
	current_state = null
	old.exit()
	current_state = states[target]
	var entered: bool = current_state.enter(msg)
	if entered:
		state_changed.emit(old, current_state)
	else:
		current_state = null
		is_active = false
	_changing = false
	return entered

func transition_to(target: StringName, msg: Dictionary = {}) -> void:
	transition_local(target, msg)

## Compatibility alias.
func switch(target: StringName, msg: Dictionary = {}) -> void:
	transition_local(target, msg)

func get_variable(key: StringName) -> Variant:
	return values.get(key)

func set_variable(key: StringName, value: Variant) -> void:
	values[key] = value

func has_variable(key: StringName) -> bool:
	return values.has(key)

func erase_variable(key: StringName) -> void:
	values.erase(key)

func get_current_state_name() -> StringName:
	return current_state.state_id if current_state else &""

func _agent_setter(value: Object) -> void:
	agent = value
	for state: BaseState in states.values():
		state.agent = value

func _can_continue() -> bool:
	return is_active and not _paused and current_state != null

func _can_drive() -> bool:
	return _can_continue() and not _changing and not _driving


## Lifecycle mutation is rejected while callbacks are running.
func is_busy() -> bool:
	return _changing or _preparing
