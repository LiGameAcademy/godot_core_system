class_name InputConfig
extends Resource

## 配置变更信号
signal config_changed(config: Dictionary)

## 配置数据
var _config: Dictionary = {}

## 默认配置
const DEFAULT_CONFIG = {
	"action_mappings": {},  # 动作映射
	"axis_mappings": {},    # 轴映射
	"device_mappings": {},  # 设备映射
	"input_settings": {     # 输入设置
		"deadzone": 0.2,
		"axis_sensitivity": 1.0,
		"vibration_enabled": true,
		"vibration_strength": 1.0
	}
}

## 初始化配置
func _init() -> void:
	reset_to_default()

## 重置为默认配置
func reset_to_default() -> void:
	_config = DEFAULT_CONFIG.duplicate(true)
	config_changed.emit(_config)

## 更新配置
## [param new_config] 新配置
func update_config(new_config: Dictionary) -> void:
	# 合并配置，保留默认值
	for key in DEFAULT_CONFIG:
		if new_config.has(key):
			if new_config[key] is Dictionary:
				_config[key] = DEFAULT_CONFIG[key].duplicate(true)
				_config[key].merge(new_config[key])
			else:
				_config[key] = new_config[key]
	config_changed.emit(_config)

## 获取完整配置
## [return] 配置数据
func get_config() -> Dictionary:
	return _config.duplicate(true)

## 获取动作映射
## [return] 动作映射
func get_action_mappings() -> Dictionary:
	return _config.action_mappings.duplicate(true)

## 设置动作映射
## [param action] 动作名称
## [param events] 事件列表
func set_action_mapping(action: String, events: Array) -> void:
	_config.action_mappings[action] = events
	config_changed.emit(_config)

## 移除动作映射
## [param action] 动作名称
func remove_action_mapping(action: String) -> void:
	_config.action_mappings.erase(action)
	config_changed.emit(_config)

## 获取轴映射
## [return] 轴映射
func get_axis_mappings() -> Dictionary:
	return _config.axis_mappings.duplicate(true)

## 设置轴映射
## [param axis] 轴名称
## [param mapping] 轴映射数据
func set_axis_mapping(axis: String, mapping: Dictionary) -> void:
	_config.axis_mappings[axis] = mapping
	config_changed.emit(_config)

## 移除轴映射
## [param axis] 轴名称
func remove_axis_mapping(axis: String) -> void:
	_config.axis_mappings.erase(axis)
	config_changed.emit(_config)

## 获取设备映射
## [return] 设备映射
func get_device_mappings() -> Dictionary:
	return _config.device_mappings.duplicate(true)

## 设置设备映射
## [param device_id] 设备ID
## [param mapping] 设备映射数据
func set_device_mapping(device_id: int, mapping: Dictionary) -> void:
	_config.device_mappings[str(device_id)] = mapping
	config_changed.emit(_config)

## 移除设备映射
## [param device_id] 设备ID
func remove_device_mapping(device_id: int) -> void:
	_config.device_mappings.erase(str(device_id))
	config_changed.emit(_config)

## 获取输入设置
## [return] 输入设置
func get_input_settings() -> Dictionary:
	return _config.input_settings.duplicate(true)

## 更新输入设置
## [param settings] 新设置
func update_input_settings(settings: Dictionary) -> void:
	_config.input_settings.merge(settings)
	config_changed.emit(_config)

## 获取死区值
## [return] 死区值
func get_deadzone() -> float:
	return _config.input_settings.deadzone

## 设置死区值
## [param value] 死区值
func set_deadzone(value: float) -> void:
	_config.input_settings.deadzone = value
	config_changed.emit(_config)

## 获取轴灵敏度
## [return] 轴灵敏度
func get_axis_sensitivity() -> float:
	return _config.input_settings.axis_sensitivity

## 设置轴灵敏度
## [param value] 轴灵敏度
func set_axis_sensitivity(value: float) -> void:
	_config.input_settings.axis_sensitivity = value
	config_changed.emit(_config)

## 获取震动是否启用
## [return] 震动是否启用
func is_vibration_enabled() -> bool:
	return _config.input_settings.vibration_enabled

## 设置震动是否启用
## [param enabled] 是否启用
func set_vibration_enabled(enabled: bool) -> void:
	_config.input_settings.vibration_enabled = enabled
	config_changed.emit(_config)

## 获取震动强度
## [return] 震动强度
func get_vibration_strength() -> float:
	return _config.input_settings.vibration_strength

## 设置震动强度
## [param strength] 震动强度
func set_vibration_strength(strength: float) -> void:
	_config.input_settings.vibration_strength = strength
	config_changed.emit(_config)