extends RefCounted
class_name InputVirtualAxis

## 轴值变化信号
signal axis_changed(axis_name: String, value: Vector2)

## 轴映射数据结构
class AxisMapping:
	## 轴名称
	var name: String
	## 正向动作
	var positive: String
	## 负向动作
	var negative: String
	## 当前值
	var value: float
	
	func _init(p_name: String = "", p_positive: String = "", p_negative: String = "") -> void:
		name = p_name
		positive = p_positive
		negative = p_negative
		value = 0.0

## 轴映射字典
var _axis_mappings: Dictionary = {}
## 灵敏度
var _sensitivity: float = 1.0
## 死区
var _deadzone: float = 0.1

## 注册轴
## [param axis_name] 轴名称
## [param positive_x] X轴正向动作
## [param negative_x] X轴负向动作
## [param positive_y] Y轴正向动作
## [param negative_y] Y轴负向动作
func register_axis(axis_name: String, positive_x: String = "", negative_x: String = "", 
	positive_y: String = "", negative_y: String = "") -> void:
	
	if not _axis_mappings.has(axis_name):
		_axis_mappings[axis_name] = {
			"x": AxisMapping.new(axis_name + "_x", positive_x, negative_x),
			"y": AxisMapping.new(axis_name + "_y", positive_y, negative_y)
		}

## 注销轴
## [param axis_name] 轴名称
func unregister_axis(axis_name: String) -> void:
	_axis_mappings.erase(axis_name)

## 清除轴映射
## [param axis_name] 轴名称，如果为空则清除所有
func clear_axis(axis_name: String = "") -> void:
	if axis_name.is_empty():
		_axis_mappings.clear()
	else:
		_axis_mappings.erase(axis_name)

## 更新轴值
## [param axis_name] 轴名称
func update_axis(axis_name: String) -> void:
	if not _axis_mappings.has(axis_name):
		return
	
	var mapping = _axis_mappings[axis_name]
	var x_value = _calculate_axis_value(mapping.x)
	var y_value = _calculate_axis_value(mapping.y)
	
	var axis_value = Vector2(x_value, y_value)
	if not axis_value.is_equal_approx(_get_axis_value(axis_name)):
		_set_axis_value(axis_name, axis_value)
		axis_changed.emit(axis_name, axis_value)

## 获取轴值
## [param axis_name] 轴名称
## [return] 轴值
func get_axis_value(axis_name: String) -> Vector2:
	return _get_axis_value(axis_name)

## 获取轴映射
## [param axis_name] 轴名称
## [return] 轴映射字典
func get_axis_mapping(axis_name: String) -> Dictionary:
	if _axis_mappings.has(axis_name):
		var mapping = _axis_mappings[axis_name]
		return {
			"positive_x": mapping.x.positive,
			"negative_x": mapping.x.negative,
			"positive_y": mapping.y.positive,
			"negative_y": mapping.y.negative
		}
	return {}

## 获取所有轴映射
## [return] 所有轴映射字典
func get_axis_mappings() -> Dictionary:
	var result = {}
	for axis_name in _axis_mappings:
		result[axis_name] = get_axis_mapping(axis_name)
	return result

## 设置轴映射
## [param axis_name] 轴名称
## [param mapping] 轴映射字典
func set_axis_mapping(axis_name: String, mapping: Dictionary) -> void:
	if _axis_mappings.has(axis_name):
		var axis_mapping = _axis_mappings[axis_name]
		axis_mapping.x.positive = mapping.get("positive_x", "")
		axis_mapping.x.negative = mapping.get("negative_x", "")
		axis_mapping.y.positive = mapping.get("positive_y", "")
		axis_mapping.y.negative = mapping.get("negative_y", "")

## 获取已注册的轴列表
## [return] 轴名称列表
func get_registered_axes() -> Array:
	return _axis_mappings.keys()

## 设置灵敏度
## [param value] 灵敏度值
func set_sensitivity(value: float) -> void:
	_sensitivity = value

## 获取灵敏度
## [return] 灵敏度值
func get_sensitivity() -> float:
	return _sensitivity

## 设置死区
## [param value] 死区值
func set_deadzone(value: float) -> void:
	_deadzone = value

## 获取死区
## [return] 死区值
func get_deadzone() -> float:
	return _deadzone

## 计算轴值
## [param mapping] 轴映射
## [return] 轴值
func _calculate_axis_value(mapping: AxisMapping) -> float:
	if mapping.positive.is_empty() and mapping.negative.is_empty():
		return 0.0
	
	var value = 0.0
	if not mapping.positive.is_empty():
		value += 1.0 if Input.is_action_pressed(mapping.positive) else 0.0
	if not mapping.negative.is_empty():
		value -= 1.0 if Input.is_action_pressed(mapping.negative) else 0.0
	
	# 应用死区
	if abs(value) < _deadzone:
		value = 0.0
	elif value > 0:
		value = (value - _deadzone) / (1.0 - _deadzone)
	else:
		value = (value + _deadzone) / (1.0 - _deadzone)
	
	# 应用灵敏度
	value *= _sensitivity
	
	return value

## 获取轴值
## [param axis_name] 轴名称
## [return] 轴值
func _get_axis_value(axis_name: String) -> Vector2:
	if _axis_mappings.has(axis_name):
		return Vector2(
			_axis_mappings[axis_name].x.value,
			_axis_mappings[axis_name].y.value
		)
	return Vector2.ZERO

## 设置轴值
## [param axis_name] 轴名称
## [param value] 轴值
func _set_axis_value(axis_name: String, value: Vector2) -> void:
	if _axis_mappings.has(axis_name):
		_axis_mappings[axis_name].x.value = value.x
		_axis_mappings[axis_name].y.value = value.y
