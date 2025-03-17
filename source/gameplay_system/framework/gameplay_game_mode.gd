extends Node
class_name GameplayGameMode

## 游戏模式基类
## 管理游戏规则和流程
## 控制玩家生成和游戏状态

# 信号
signal state_changed(old_state: StringName, new_state: StringName)
signal player_spawned(player: Character)

# 当前状态
var _current_state: GameplayGameState
var _states: Dictionary = {}

# 游戏配置
var game_config: Dictionary = {}

func _init() -> void:
	# 注册默认状态
	register_game_states()

func _ready() -> void:
	# 设置初始状态
	transition_to_initial_state()

## 注册游戏状态
## 子类应该重写此方法来注册自己的状态
func register_game_states() -> void:
	pass

## 设置初始状态
## 子类应该重写此方法来设置初始状态
func transition_to_initial_state() -> void:
	pass

## 注册状态
## [param state] 要注册的状态实例
func register_state(state: GameplayGameState) -> void:
	_states[state.get_state_name()] = state

## 转换到指定状态
## [param state_name] 目标状态名称
## [return] 是否成功转换
func transition_to_state(state_name: StringName) -> bool:
	if not _states.has(state_name):
		push_error("Attempting to transition to non-existent state: %s" % state_name)
		return false
	
	var new_state = _states[state_name]
	if _current_state == new_state:
		return true
	
	# 检查是否可以转换
	if _current_state and not _current_state.can_transition_to(new_state):
		return false
	
	# 退出当前状态
	var old_state = _current_state
	if _current_state:
		if not _current_state.exit(new_state):
			return false
	
	# 进入新状态
	_current_state = new_state
	if not _current_state.enter(old_state):
		# 进入失败，恢复到原状态
		_current_state = old_state
		if old_state:
			old_state.enter(new_state)
		return false
	
	# 发出状态改变信号
	emit_signal("state_changed", old_state.get_state_name() if old_state else &"", state_name)
	return true

## 获取当前状态
## [return] 当前状态实例
func get_current_state() -> GameplayGameState:
	return _current_state

## 获取当前状态名称
## [return] 当前状态名称
func get_current_state_name() -> StringName:
	return _current_state.get_state_name() if _current_state else &""

## 检查是否处于指定状态
## [param state_name] 状态名称
## [return] 是否处于指定状态
func is_in_state(state_name: StringName) -> bool:
	return _current_state and _current_state.get_state_name() == state_name

## 更新状态
func _process(delta: float) -> void:
	if _current_state:
		_current_state.update(delta)

## 物理更新状态
func _physics_process(delta: float) -> void:
	if _current_state:
		_current_state.physics_update(delta)

## 处理输入
func _unhandled_input(event: InputEvent) -> void:
	if _current_state:
		_current_state.handle_input(event)

## 生成玩家
func spawn_player(character_class: PackedScene, spawn_point: Node2D) -> Character:
	var instance = character_class.instantiate() as Character
	if instance:
		get_tree().current_scene.add_child(instance)
		instance.global_position = spawn_point.global_position
		emit_signal("player_spawned", instance)
	return instance
