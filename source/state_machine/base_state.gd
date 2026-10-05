extends RefCounted
class_name BaseState

## Behavior object owned and driven by one machine, without an Autoload dependency.
signal state_entered(msg: Dictionary)
signal state_exited

var state_id: StringName = &""
var state_machine: BaseStateMachine:
	get:
		return _machine_ref.get_ref() as BaseStateMachine if _machine_ref else null
	set(value):
		_machine_ref = weakref(value) if value else null
var agent: Object = null: set = _agent_setter
var is_active: bool = false
var is_debug: bool = false
var _is_ready: bool = false
var _preparing: bool = false
var _disposing: bool = false
var _disposed: bool = false
var disposed: bool:
	get:
		return _disposed
var _machine_ref: WeakRef = null

func ready() -> void:
	if _is_ready or _preparing or _disposed:
		return
	_preparing = true
	_ready()
	_is_ready = true
	_preparing = false

func dispose() -> void:
	if _disposing or _preparing or _disposed:
		return
	_disposing = true
	_disposed = true
	if is_active:
		exit()
	if _is_ready:
		_dispose()
	_is_ready = false
	agent = null
	_disposing = false

func enter(msg: Dictionary = {}) -> bool:
	if is_active or _preparing or _disposed:
		return false
	ready()
	is_active = true
	_enter(msg)
	state_entered.emit(msg)
	return true

func exit() -> bool:
	if not is_active:
		return false
	is_active = false
	_exit()
	state_exited.emit()
	return true

func update(delta: float) -> void:
	if is_active:
		_update(delta)

func physics_update(delta: float) -> void:
	if is_active:
		_physics_update(delta)

func handle_input(event: InputEvent) -> void:
	if is_active:
		_handle_input(event)

## Request a sibling transition in the owning machine.
func transition_to(target: StringName, msg: Dictionary = {}) -> void:
	if state_machine:
		state_machine.transition_local(target, msg)

## Compatibility alias.
func switch_to(target: StringName, msg: Dictionary = {}) -> void:
	transition_to(target, msg)

## Compatibility storage; prefer an explicitly typed context in new states.
func get_variable(key: StringName) -> Variant:
	return state_machine.get_variable(key) if state_machine else null

func set_variable(key: StringName, value: Variant) -> void:
	if state_machine:
		state_machine.set_variable(key, value)

func has_variable(key: StringName) -> bool:
	return state_machine.has_variable(key) if state_machine else false

func _ready() -> void:
	pass

func _dispose() -> void:
	pass

func _enter(_msg: Dictionary = {}) -> void:
	pass

func _exit() -> void:
	pass

func _update(_delta: float) -> void:
	pass

func _physics_update(_delta: float) -> void:
	pass

func _handle_input(_event: InputEvent) -> void:
	pass

func _debug(message: String) -> void:
	if is_debug:
		print("[State] %s: %s" % [state_id, message])

func _agent_setter(value: Object) -> void:
	agent = value
