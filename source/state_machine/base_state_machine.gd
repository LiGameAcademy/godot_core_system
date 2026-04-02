extends BaseState
class_name BaseStateMachine

## 基础状态机类, 状态机本身也是一个状态。

# 信号
## 状态改变
signal state_changed(from_state: BaseState, to_state: BaseState)

## 当前状态
var current_state: BaseState = null
## 状态字典
var states: Dictionary[StringName, BaseState] = {}
## 变量字典
var values: Dictionary = {}
## 上一个状态
var previous_state: StringName = &""

func enter(msg: Dictionary = {}) -> bool:
	if not super(msg):
		return false
	if current_state == null:
		_logger.error("Entering null state!")
		return false
	return current_state.enter(msg)

## 更新
func update(delta: float) -> void:
	if is_active and current_state:
		current_state.update(delta)
	super(delta)

## 物理更新
func physics_update(delta: float) -> void:
	if is_active and current_state:
		current_state.physics_update(delta)
	super(delta)

func handle_input(event: InputEvent) -> void:
	if is_active and current_state:
		current_state.handle_input(event)
	super(event)

func exit() -> bool:
	if not super():
		return false
	if current_state:
		current_state.exit()
		current_state = null
	return true

func ready() -> void:
	super()
	for state in states.values():
		state.ready()

func dispose() -> void:
	for state in states.values():
		state.dispose()
	super()

## 启动状态机
## [param initial_state] 初始状态ID
## [param msg] 传递给状态的消息
## [param resume] 是否恢复到上一个状态
func start(initial_state: StringName = &"", msg: Dictionary = {}, resume: bool = false) -> void:
	if current_state != null:
		_logger.warning("State machine is already running!")
		return
	
	var target_state = initial_state
	if resume and not previous_state.is_empty():
		target_state = previous_state
	
	if target_state.is_empty():
		target_state = states.keys()[0] if not states.is_empty() else &""
	
	if target_state.is_empty():
		push_error("No state to start with!")
		return
	
	current_state = states.get(target_state)
	if current_state == null:
		push_error("Attempting to start with non-existent state: %s" % target_state)
		return
	
	current_state.enter(msg)
	is_active = true
	_debug("Starting state: %s" % target_state)

## 停止状态机
func stop() -> void:
	if current_state:
		previous_state = get_current_state_name()
		current_state.exit()
		current_state = null
	is_active = false
	_debug("Stopping state machine: %s" % state_id)


## 暂停状态机
func pause() -> void:
	is_active = false

## 恢复状态机
func resume() -> void:
	is_active = true

## 添加状态
func add_state(state_id: StringName, new_state: BaseState) -> BaseState:
	states[state_id] = new_state
	new_state.state_machine = self
	new_state.agent = agent
	new_state.is_debug = is_debug
	new_state.state_id = state_id
	_debug("Adding state: %s" % state_id)
	return new_state

## 移除状态
func remove_state(state_id: StringName) -> void:
	if current_state == states.get(state_id):
		current_state.exit()
		current_state = null
	_debug("Removing state: %s" % state_id)
	states.erase(state_id)

## 检查状态是否存在
func has_state(state_id: StringName) -> bool:
	return states.has(state_id)

## 切换状态
func switch(state_id: StringName, msg: Dictionary = {}) -> void:
	if not states.has(state_id):
		push_error("Attempting to transition to non-existent state: %s" % state_id)
		return
	
	var from_state = current_state
	if current_state:
		previous_state = get_current_state_name()
		current_state.exit()
	
	current_state = states[state_id]
	if not current_state:
		push_error("Attempting to transition to non-existent state: %s" % state_id)
		return
	
	current_state.enter(msg)
	state_changed.emit(from_state, current_state)


## 获取变量
func get_variable(key: StringName) -> Variant:
	return values.get(key)


## 设置变量
func set_variable(key: StringName, value: Variant) -> void:
	values[key] = value


## 检查变量是否存在
func has_variable(key: StringName) -> bool:
	return values.has(key)


## 移除变量
func erase_variable(key: StringName) -> void:
	values.erase(key)


## 获取当前状态名称
func get_current_state_name() -> StringName:
	return current_state.state_id if current_state else &""


func _agent_setter(value: Object) -> void:
	agent = value
	for state in states.values():
		state.agent = agent
