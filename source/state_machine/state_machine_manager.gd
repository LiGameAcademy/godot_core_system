extends Node

## 状态机管理器

# 信号

## 状态机注册
signal state_machine_registered(id: StringName)
## 状态机注销
signal state_machine_unregistered(id: StringName)
## 状态机启动
signal state_machine_started(id: StringName)
## 状态机停止
signal state_machine_stopped(id: StringName)

## 状态机字典
## key: 状态机ID
## value: 状态机
var _state_machines: Dictionary[StringName, BaseStateMachine] = {}

func _process(delta: float) -> void:
	for state_machine in _state_machines.values():
		if state_machine.is_active:
			state_machine.update(delta)

func _physics_process(delta: float) -> void:
	for state_machine in _state_machines.values():
		if state_machine.is_active:
			state_machine.physics_update(delta)

func _input(event: InputEvent) -> void:
	for state_machine in _state_machines.values():
		if state_machine.is_active:
			state_machine.handle_input(event)

## 注册状态机
## [param id] 状态机ID
## [param agent] 状态机所属节点
## [param initial_state] 初始状态, 非空字符串表示自动启动
## [param msg] 传递给状态机的消息
func register_state_machine(
		id: StringName, 
		state_machine: BaseStateMachine,
		agent: Object = null,
		initial_state: StringName = &"", 
		msg: Dictionary = {}) -> void:
	if _state_machines.has(id):
		push_warning("State machine %s already registered" % id)
		return
	
	_state_machines[id] = state_machine
	state_machine.agent = agent
	# 避免与 Node.ready（信号）同名解析冲突，显式按方法名调用 BaseState.ready()
	state_machine.call("ready")
	if not initial_state.is_empty():
		start_state_machine(id, initial_state, msg)
	state_machine_registered.emit(id)

## 注销状态机
## [param id] 状态机ID
func unregister_state_machine(id: StringName) -> void:
	if not _state_machines.has(id):
		return
	
	var state_machine = _state_machines[id]
	stop_state_machine(id)
	_state_machines.erase(id)
	state_machine.dispose()
	state_machine_unregistered.emit(id)

## 获取状态机
## [param id] 状态机ID
func get_state_machine(id: StringName) -> BaseStateMachine:
	return _state_machines.get(id) as BaseStateMachine

## 启动状态机
## [param id] 状态机ID
## [param initial_state] 初始状态
## [param msg] 传递给状态机的消息
func start_state_machine(
		id: StringName, 
		initial_state: StringName, 
		msg: Dictionary = {}) -> void:
	var state_machine = get_state_machine(id)
	if not state_machine:
		push_error("State machine %s does not exist" % id)
		return
	if initial_state.is_empty():
		push_error("Initial state cannot be empty")
		return
	
	state_machine.start(initial_state, msg)
	state_machine_started.emit(id)

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
	return _state_machines.values()

## 获取所有状态机ID
## [return] 所有状态机ID的数组
func get_all_state_machine_ids() -> Array[StringName]:
	return _state_machines.keys()

## 清除所有状态机
func clear_state_machines() -> void:
	var ids: Array[StringName] = []
	ids.assign(_state_machines.keys())
	for id in ids:
		unregister_state_machine(id)

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

func is_active(state_id: StringName) -> bool:
	# 判断正处于指定状态机/状态
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
