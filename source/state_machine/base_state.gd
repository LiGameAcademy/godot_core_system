extends RefCounted
class_name BaseState

## 基础状态类（运行时逻辑对象，由 [BaseStateMachine] 持有；不进场景树）
## 生命周期：子类实现 [_enter] / [_exit]；可选 [method ready] / [method dispose] 做一次性资源准备与释放。

# 信号
## 状态进入
signal state_entered(msg: Dictionary)
## 状态退出
signal state_exited

var state_id : StringName = &""
## 状态机引用（请通过 [method bind_to_state_machine] 或 [method BaseStateMachine.add_state] 设置，勿依赖直接赋值到内层子类时的引擎行为）
var state_machine : BaseStateMachine = null
## 代理者
var agent: Object = null : set = _agent_setter

## 是否活跃
var is_active: bool = false
var _is_ready

var is_debug: bool = false
var _logger : CoreSystem.CoreLogger = CoreSystem.logger

func ready() -> void:
	if _is_ready: 
		_logger.warning("State is already ready!")
		return
	_ready()
	_is_ready = true

func dispose() -> void:
	_dispose()
	_is_ready = false

## 进入状态
func enter(msg: Dictionary = {}) -> bool:
	if is_active:
		_logger.warning("State is already active!")
		return false
	is_active = true
	_enter(msg)
	_debug("Entering state: %s" % state_id)
	state_entered.emit(msg)
	return true

## 退出状态
func exit() -> bool:
	if not is_active:
		_logger.warning("State is not active!")
		return false
	is_active = false
	_exit()
	_debug("Exiting state: %s" % state_id)
	state_exited.emit()
	return true

## 更新
func update(delta: float) -> void:
	if not is_active:
		return
	_update(delta)

## 物理更新
func physics_update(delta: float) -> void:
	if not is_active:
		return
	_physics_update(delta)

## 处理事件
func handle_input(event: InputEvent) -> void:
	if not is_active:
		return
	_handle_input(event)

## 在 [b]所属[/b] 状态机（[member state_machine]）所管理的那一层子状态里切换到 [param state_id]。
## 实现为调用 [method BaseStateMachine.transition_local]：沿「谁 add_state 了我」这一层切换，[b]不[/b]区分叶子还是子状态机脚本；要改的是 [b]外层[/b] 状态机时，应对 [member state_machine] 调用本方法（见 [method BaseStateMachine] 类说明）。
func transition_to(state_id: StringName, msg: Dictionary = {}) -> void:
	if not state_machine:
		_logger.error(
			"State machine is not set (state_id=%s). Ensure this state was added via BaseStateMachine.add_state()."
			% state_id
		)
		return

	if not state_machine.has_state(state_id):
		_logger.error("State %s does not exist!" % state_id)
		return

	state_machine.transition_local(state_id, msg)


## 已弃用：请使用 [method transition_to]。
func switch_to(state_id: StringName, msg: Dictionary = {}) -> void:
	transition_to(state_id, msg)

## 获取变量
func get_variable(key: StringName) -> Variant:
	if state_machine:
		return state_machine.get_variable(key)
	return null

## 设置变量
func set_variable(key: StringName, value: Variant) -> void:
	if state_machine:
		state_machine.set_variable(key, value)

## 检查变量是否存在
func has_variable(key: StringName) -> bool:
	if state_machine:
		return state_machine.has_variable(key)
	return false

## 虚函数 - 准备
func _ready() -> void:
	pass

## 虚函数 - 清理
func _dispose() -> void:
	pass

## 虚函数 - 进入状态
func _enter(_msg: Dictionary = {}) -> void:
	pass

## 虚函数 - 退出状态
func _exit() -> void:
	pass

## 虚函数 - 更新
func _update(_delta: float) -> void:
	pass

## 虚函数 - 物理更新
func _physics_update(_delta: float) -> void:
	pass

## 虚函数 - 处理输入
func _handle_input(_event: InputEvent) -> void:
	pass


func _debug(debug: String) -> void:
	if not is_debug:
		return
	_logger.debug("[State] " + state_id + ": " + debug)


func _agent_setter(value: Object) -> void:
	agent = value
