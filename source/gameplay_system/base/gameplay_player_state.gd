extends Node
class_name GameplayPlayerState

## 玩家状态基类
## 管理玩家的基本状态数据

# 基础信号
signal state_changed(state_name: StringName, old_value: Variant, new_value: Variant)

# 状态字典
var _states: Dictionary = {}

## 设置状态值
func set_state(state_name: StringName, value: Variant) -> void:
	var old_value = _states.get(state_name)
	_states[state_name] = value
	state_changed.emit(state_name, old_value, value)

## 获取状态值
func get_state(state_name: StringName, default_value: Variant = null) -> Variant:
	return _states.get(state_name, default_value)

## 是否存在状态
func has_state(state_name: StringName) -> bool:
	return _states.has(state_name)

## 移除状态
func remove_state(state_name: StringName) -> void:
	if _states.has(state_name):
		var old_value = _states[state_name]
		_states.erase(state_name)
		state_changed.emit(state_name, old_value, null)

## 清除所有状态
func clear_states() -> void:
	_states.clear()
