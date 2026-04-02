extends Node

## 状态机管理器（可选组件）
## 用于集中注册多台 BaseStateMachine 并由本节点统一驱动 update / physics / input。
## 若只需单台状态机，也可在持有者脚本里 _process 中直接调用 state_machine.update(delta)，不必注册到本管理器。

# 单条注册：状态机实例 + 是否由本管理器驱动各类回调（默认全开，与旧版行为一致）
class SMRegistration:
	var state_machine: BaseStateMachine
	var run_update: bool = true
	var run_physics: bool = true
	var run_input: bool = true

# 信号

## 状态机注册
signal state_machine_registered(id: StringName)
## 状态机注销
signal state_machine_unregistered(id: StringName)
## 状态机启动
signal state_machine_started(id: StringName)
## 状态机停止
signal state_machine_stopped(id: StringName)

## key: 状态机 ID；value: SMRegistration
var _registrations: Dictionary[StringName, SMRegistration] = {}

func _process(delta: float) -> void:
	for id in _registrations:
		var reg: SMRegistration = _registrations[id]
		if reg.run_update and reg.state_machine.is_active:
			reg.state_machine.update(delta)

func _physics_process(delta: float) -> void:
	for id in _registrations:
		var reg: SMRegistration = _registrations[id]
		if reg.run_physics and reg.state_machine.is_active:
			reg.state_machine.physics_update(delta)

func _input(event: InputEvent) -> void:
	for id in _registrations:
		var reg: SMRegistration = _registrations[id]
		if reg.run_input and reg.state_machine.is_active:
			reg.state_machine.handle_input(event)

## 注册状态机
## [param id] 状态机ID
## [param agent] 状态机所属节点
## [param initial_state] 初始状态, 非空字符串表示自动启动
## [param msg] 传递给状态机的消息
## [param run_update] 是否由本管理器在 _process 中调用状态机的 update（纯逻辑机可设 false 并自行在持有者 _process 中驱动）
## [param run_physics] 是否由本管理器在 _physics_process 中调用 physics_update
## [param run_input] 是否由本管理器在 _input 中调用 handle_input
func register_state_machine(
		id: StringName,
		state_machine: BaseStateMachine,
		agent: Object = null,
		initial_state: StringName = &"",
		msg: Dictionary = {},
		run_update: bool = true,
		run_physics: bool = true,
		run_input: bool = true
	) -> void:
	if _registrations.has(id):
		push_warning("State machine %s already registered" % id)
		return

	var reg := SMRegistration.new()
	reg.state_machine = state_machine
	reg.run_update = run_update
	reg.run_physics = run_physics
	reg.run_input = run_input
	_registrations[id] = reg

	if is_instance_valid(agent):
		state_machine.agent = agent
	# 避免与 Node.ready（信号）同名解析冲突，显式按方法名调用 BaseState.ready()
	state_machine.call("ready")
	if not initial_state.is_empty():
		start_state_machine(id, initial_state, msg)
	state_machine_registered.emit(id)

## 运行时修改由管理器驱动的回调类型（无需重新注册）
func set_registration_drive_flags(
		id: StringName,
		run_update: bool = true,
		run_physics: bool = true,
		run_input: bool = true
	) -> void:
	if not _registrations.has(id):
		push_warning("State machine %s is not registered" % id)
		return
	var reg: SMRegistration = _registrations[id]
	reg.run_update = run_update
	reg.run_physics = run_physics
	reg.run_input = run_input

## 注销状态机
## [param id] 状态机ID
func unregister_state_machine(id: StringName) -> void:
	if not _registrations.has(id):
		return

	stop_state_machine(id)
	var reg: SMRegistration = _registrations[id]
	_registrations.erase(id)
	reg.state_machine.dispose()
	state_machine_unregistered.emit(id)

## 获取状态机
## [param id] 状态机ID
func get_state_machine(id: StringName) -> BaseStateMachine:
	var reg: Variant = _registrations.get(id)
	if reg:
		return (reg as SMRegistration).state_machine
	return null

## 启动状态机
## [param id] 状态机ID
## [param initial_state] 初始状态
## [param msg] 传递给状态机的消息
func start_state_machine(
		id: StringName,
		initial_state: StringName,
		msg: Dictionary = {}
	) -> void:
	var state_machine = get_state_machine(id)
	if not state_machine:
		push_error("State machine %s does not exist" % id)
		return
	if initial_state.is_empty():
		push_error("Initial state cannot be empty")
		return

	state_machine.start(initial_state, msg)
	state_machine_started.emit(id)


## 将已注册状态机切换到 [param state_id]（任意代码可通过管理器跳转，#14）。
## 若该机尚未 [method BaseStateMachine.start]，则等价于 [method start_state_machine]。
func transition_state_machine(
		id: StringName,
		state_id: StringName,
		msg: Dictionary = {}
	) -> bool:
	var state_machine: BaseStateMachine = get_state_machine(id)
	if not state_machine:
		push_error("State machine %s does not exist" % id)
		return false
	if not state_machine.has_state(state_id):
		push_error("State %s is not registered on state machine %s" % [state_id, id])
		return false
	if state_machine.current_state == null:
		start_state_machine(id, state_id, msg)
		return true
	state_machine.transition_local(state_id, msg)
	return true

## 停止状态机
## [param id] 状态机ID
func stop_state_machine(id: StringName) -> void:
	var state_machine = get_state_machine(id)
	if not state_machine:
		push_error("State machine %s does not exist" % id)
		return

	state_machine.stop()
	state_machine_stopped.emit(id)

## 获取所有状态机
## [return] 所有状态机的数组
func get_all_state_machines() -> Array[BaseStateMachine]:
	var out: Array[BaseStateMachine] = []
	for reg_id in _registrations:
		out.append(_registrations[reg_id].state_machine)
	return out

## 获取所有状态机ID
## [return] 所有状态机ID的数组
func get_all_state_machine_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_registrations.keys())
	return out

## 清除所有状态机
func clear_state_machines() -> void:
	var ids: Array[StringName] = []
	ids.assign(_registrations.keys())
	for rid in ids:
		unregister_state_machine(rid)

func _get_current_state_linked_tree(root_id: StringName = &"") -> Array[BaseState]:
	var current_state_linked_tree: Array[BaseState] = []
	var machines: Array[BaseStateMachine] = []
	if root_id.is_empty():
		machines.assign(get_all_state_machines())
	else:
		var sm := get_state_machine(root_id)
		if sm:
			machines.append(sm)
	for each in machines:
		if each.is_active:
			_recursive_get_active_state_id(each, current_state_linked_tree)
	return current_state_linked_tree

func _recursive_get_active_state_id(state_machine: BaseStateMachine, state_linked_tree: Array[BaseState]) -> void:
	if not state_machine.is_active:
		return
	state_linked_tree.append(state_machine)
	# current_state 静态类型为 BaseState，嵌套子状态机需用 Variant 才能通过 is 收窄
	var cur: Variant = state_machine.current_state
	if cur == null:
		return
	if cur is BaseStateMachine:
		_recursive_get_active_state_id(cur, state_linked_tree)
	else:
		state_linked_tree.append(cur as BaseState)

## 调试/监控：判断当前是否处于某状态或子状态机（多根时建议配合 [param root_id] 使用 [method get_current_state]）
func is_active(state_id: StringName) -> bool:
	for each in _get_current_state_linked_tree():
		if each.state_id == state_id:
			return true
	return false

## 获取「叶子」当前状态（嵌套状态机时取最内层）
## [param root_id] 若指定，只遍历该 ID 对应的状态机链；否则合并所有已注册且活跃根状态机的链并取最后一项（多根时语义模糊，建议传 root_id）
func get_current_state(root_id: StringName = &"") -> BaseState:
	var current_state_linked_tree := _get_current_state_linked_tree(root_id)
	if current_state_linked_tree.is_empty():
		return null
	return current_state_linked_tree[-1]
