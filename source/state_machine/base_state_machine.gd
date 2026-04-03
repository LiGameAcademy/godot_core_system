extends BaseState
class_name BaseStateMachine

## 基础状态机类；继承 [BaseState]，因此可作为「子状态机」嵌套进另一台状态机。
## 子状态 tick 先委托给 [member current_state]，再执行本机 [_update] / [_physics_update] / [_handle_input]（默认可为空）。
##
## [b]分层语义（避免与 [method BaseState.transition_to] 混淆）：[/b]
## [code]transition_local[/code] / [code]transition_to[/code]（本类）仅在本机 [member states] 内切换。
## 子状态机作为「状态」时，若要切换 [b]外层[/b] 状态机，应对 [member BaseState.state_machine] 调用 [method BaseState.transition_to]（例如 [code]state_machine.transition_to(&"...")[/code]），[b]不要[/b]在无 [member BaseState.state_machine] 前缀时把「本机」与「外层」混读。

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
## 子状态委托后，直接调用本机 _update，避免再经 BaseState.update 多一层转发（语义与 super 等价）
func update(delta: float) -> void:
	if is_active and current_state:
		current_state.update(delta)
	if is_active:
		_update(delta)

## 物理更新
func physics_update(delta: float) -> void:
	if is_active and current_state:
		current_state.physics_update(delta)
	if is_active:
		_physics_update(delta)

func handle_input(event: InputEvent) -> void:
	if is_active and current_state:
		current_state.handle_input(event)
	if is_active:
		_handle_input(event)

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

## 仅在本机 [member states] 内切换到 [param state_id]（[b]不[/b] 经过 [member BaseState.state_machine]）。
## 子状态机脚本里要表达「只切内层」时优先用此名，与 [method BaseState.transition_to]（沿所属关系切换一层）区分开。
func transition_local(state_id: StringName, msg: Dictionary = {}) -> void:
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


## 等同于 [method transition_local]：叶子状态通过 [method BaseState.transition_to] 会调到此处；在 [BaseStateMachine] 上直接调用时也表示「本机 states」。
func transition_to(state_id: StringName, msg: Dictionary = {}) -> void:
	transition_local(state_id, msg)


## 已弃用：请使用 [method transition_local] 或 [method transition_to]。
func switch(state_id: StringName, msg: Dictionary = {}) -> void:
	transition_local(state_id, msg)


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
