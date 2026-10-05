extends Node

## Optional Godot driver. A single owner can drive its machine directly instead.
class SMRegistration:
	var state_machine: BaseStateMachine
	var run_update: bool = true
	var run_physics: bool = true
	var run_input: bool = true

signal state_machine_registered(id: StringName)
signal state_machine_unregistered(id: StringName)
signal state_machine_started(id: StringName)
signal state_machine_stopped(id: StringName)
var _registrations: Dictionary[StringName, SMRegistration] = {}
var _unregistering: Dictionary[StringName, bool] = {}

func _process(delta: float) -> void:
	for id: StringName in _registrations.keys():
		var reg: SMRegistration = _registrations.get(id)
		if reg and reg.run_update:
			reg.state_machine.update(delta)

func _physics_process(delta: float) -> void:
	for id: StringName in _registrations.keys():
		var reg: SMRegistration = _registrations.get(id)
		if reg and reg.run_physics:
			reg.state_machine.physics_update(delta)

func _input(event: InputEvent) -> void:
	for id: StringName in _registrations.keys():
		var reg: SMRegistration = _registrations.get(id)
		if reg and reg.run_input:
			reg.state_machine.handle_input(event)

func _exit_tree() -> void:
	clear_state_machines()

func register_state_machine(id: StringName, machine: BaseStateMachine, agent: Object = null,
		initial_state: StringName = &"", msg: Dictionary = {}, run_update: bool = true,
		run_physics: bool = true, run_input: bool = true) -> void:
	if id.is_empty() or machine == null or _registrations.has(id) or _unregistering.has(id) or machine.disposed or machine.is_busy() or machine.state_machine != null:
		return
	for existing: SMRegistration in _registrations.values():
		if existing.state_machine == machine:
			return
	var reg: SMRegistration = SMRegistration.new()
	reg.state_machine = machine
	reg.run_update = run_update
	reg.run_physics = run_physics
	reg.run_input = run_input
	_registrations[id] = reg
	machine.agent = agent
	machine.ready()
	state_machine_registered.emit(id)
	if _registrations.get(id) == reg and not initial_state.is_empty():
		start_state_machine(id, initial_state, msg)

func set_registration_drive_flags(id: StringName, run_update: bool = true,
		run_physics: bool = true, run_input: bool = true) -> void:
	var reg: SMRegistration = _registrations.get(id)
	if reg:
		reg.run_update = run_update
		reg.run_physics = run_physics
		reg.run_input = run_input

func unregister_state_machine(id: StringName) -> bool:
	var reg: SMRegistration = _registrations.get(id)
	if reg == null:
		return false
	if reg.state_machine.is_busy():
		return false
	_unregistering[id] = true
	_registrations.erase(id)
	var stopped: bool = reg.state_machine.stop()
	reg.state_machine.dispose()
	if stopped:
		state_machine_stopped.emit(id)
	state_machine_unregistered.emit(id)
	_unregistering.erase(id)
	return true

func get_state_machine(id: StringName) -> BaseStateMachine:
	var reg: SMRegistration = _registrations.get(id)
	return reg.state_machine if reg else null

func start_state_machine(id: StringName, initial_state: StringName, msg: Dictionary = {}) -> void:
	var machine: BaseStateMachine = get_state_machine(id)
	if machine and not initial_state.is_empty() and machine.start(initial_state, msg):
		state_machine_started.emit(id)

func stop_state_machine(id: StringName) -> void:
	var machine: BaseStateMachine = get_state_machine(id)
	if machine and machine.stop():
		state_machine_stopped.emit(id)

func get_all_state_machines() -> Array[BaseStateMachine]:
	var result: Array[BaseStateMachine] = []
	for reg: SMRegistration in _registrations.values():
		result.append(reg.state_machine)
	return result

func get_all_state_machine_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_registrations.keys())
	return result

func clear_state_machines() -> void:
	for id: StringName in _registrations.keys():
		unregister_state_machine(id)

func is_active(id: StringName) -> bool:
	for machine: BaseStateMachine in get_all_state_machines():
		var state: BaseState = machine
		while state and state.is_active:
			if state.state_id == id:
				return true
			state = (state as BaseStateMachine).current_state if state is BaseStateMachine else null
	return false

## Multiple roots require an explicit ID; there is no arbitrary last-root result.
func get_current_state(root_id: StringName = &"") -> BaseState:
	if root_id.is_empty():
		if _registrations.size() != 1:
			return null
		root_id = _registrations.keys()[0]
	var machine: BaseStateMachine = get_state_machine(root_id)
	if machine == null or not machine.is_active:
		return null
	var state: BaseState = machine
	while state is BaseStateMachine:
		var child: BaseState = (state as BaseStateMachine).current_state
		if child == null:
			break
		state = child
	return state
