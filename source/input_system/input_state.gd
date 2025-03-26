extends RefCounted
class_name InputState

## 动作状态数据结构
class ActionState:
	## 是否按下
	var pressed: bool = false
	## 是否刚按下
	var just_pressed: bool = false
	## 是否刚释放
	var just_released: bool = false
	## 输入强度
	var strength: float = 0.0
	## 按下时间
	var press_time: float = 0.0
	## 上次按下时间
	var last_press_time: float = 0.0
	## 上次释放时间
	var last_release_time: float = 0.0
	
	func _init() -> void:
		reset()
	
	## 重置状态
	func reset() -> void:
		pressed = false
		just_pressed = false
		just_released = false
		strength = 0.0
		press_time = 0.0
		last_press_time = 0.0
		last_release_time = 0.0
	
	## 更新状态
	## [param is_pressed] 是否按下
	## [param input_strength] 输入强度
	func update(is_pressed: bool, input_strength: float) -> void:
		var current_time = Time.get_ticks_msec() / 1000.0
		
		# 更新按下/释放状态
		just_pressed = is_pressed and not pressed
		just_released = not is_pressed and pressed
		pressed = is_pressed
		
		# 更新强度
		strength = input_strength if pressed else 0.0
		
		# 更新时间
		if just_pressed:
			last_press_time = current_time
		elif just_released:
			last_release_time = current_time
			press_time = 0.0
		
		if pressed:
			press_time = current_time - last_press_time

## 动作状态字典
var _action_states: Dictionary = {}

## 初始化动作
## [param action_name] 动作名称
func init_action(action_name: String) -> void:
	if not _action_states.has(action_name):
		_action_states[action_name] = ActionState.new()

## 移除动作
## [param action_name] 动作名称
func remove_action(action_name: String) -> void:
	_action_states.erase(action_name)

## 更新动作状态
## [param action_name] 动作名称
## [param pressed] 是否按下
## [param strength] 输入强度
func update_action(action_name: String, pressed: bool, strength: float) -> void:
	if not _action_states.has(action_name):
		init_action(action_name)
	
	_action_states[action_name].update(pressed, strength)

## 检查动作是否按下
## [param action_name] 动作名称
## [return] 是否按下
func is_pressed(action_name: String) -> bool:
	if not _action_states.has(action_name):
		return false
	return _action_states[action_name].pressed

## 检查动作是否刚按下
## [param action_name] 动作名称
## [return] 是否刚按下
func is_just_pressed(action_name: String) -> bool:
	if not _action_states.has(action_name):
		return false
	return _action_states[action_name].just_pressed

## 检查动作是否刚释放
## [param action_name] 动作名称
## [return] 是否刚释放
func is_just_released(action_name: String) -> bool:
	if not _action_states.has(action_name):
		return false
	return _action_states[action_name].just_released

## 获取动作强度
## [param action_name] 动作名称
## [return] 动作强度
func get_strength(action_name: String) -> float:
	if not _action_states.has(action_name):
		return 0.0
	return _action_states[action_name].strength

## 获取动作按下时间
## [param action_name] 动作名称
## [return] 按下时间（秒）
func get_press_time(action_name: String) -> float:
	if not _action_states.has(action_name):
		return 0.0
	return _action_states[action_name].press_time

## 重置指定动作的状态
## [param action_name] 动作名称
func reset_action(action_name: String) -> void:
	if _action_states.has(action_name):
		_action_states[action_name].reset()

## 重置所有动作状态
func reset_all() -> void:
	for action in _action_states.values():
		action.reset()

## 获取动作状态
## [param action_name] 动作名称
## [return] 动作状态字典
func get_action_state(action_name: String) -> Dictionary:
	if not _action_states.has(action_name):
		return {}
	
	var state = _action_states[action_name]
	return {
		"pressed": state.pressed,
		"just_pressed": state.just_pressed,
		"just_released": state.just_released,
		"strength": state.strength,
		"press_time": state.press_time,
		"last_press_time": state.last_press_time,
		"last_release_time": state.last_release_time
	}

## 获取所有动作状态
## [return] 所有动作状态字典
func get_all_states() -> Dictionary:
	var states = {}
	for action_name in _action_states:
		states[action_name] = get_action_state(action_name)
	return states