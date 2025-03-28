class_name InputConfigAdapter
extends RefCounted

## 配置更新信号
signal config_updated(config: Dictionary)

## 配置管理器
var _config_manager: CoreSystem.ConfigManager
## 输入配置
var _input_config: InputConfig

## 配置节名称
const INPUT_CONFIG_SECTION = "input"

## 初始化适配器
## [param config_manager] 配置管理器实例
func _init() -> void:
	_config_manager = CoreSystem.config_manager
	_input_config = InputConfig.new()
	
	# 连接信号
	_config_manager.config_loaded.connect(_on_config_loaded)
	_config_manager.config_saved.connect(_on_config_saved)
	_input_config.config_changed.connect(_on_input_config_changed)
	
	# 如果配置管理器已经加载了配置，立即更新输入配置
	if _config_manager.is_loaded():
		_on_config_loaded()

## 获取输入配置实例
## [return] 输入配置实例
func get_input_config() -> InputConfig:
	return _input_config

## 配置加载回调
func _on_config_loaded() -> void:
	var input_section = _config_manager.get_section(INPUT_CONFIG_SECTION)
	if input_section.is_empty():
		_input_config.reset_to_default()
	else:
		_input_config.update_config(input_section)

## 配置保存回调
func _on_config_saved() -> void:
	_config_manager.set_section(INPUT_CONFIG_SECTION, _input_config.get_config())

## 输入配置变更回调
## [param config] 新配置
func _on_input_config_changed(config: Dictionary) -> void:
	_config_manager.set_section(INPUT_CONFIG_SECTION, config)
	config_updated.emit(config)

## 保存当前配置
func save_config() -> void:
	_config_manager.save_config()

## 重置为默认配置
func reset_to_default() -> void:
	_input_config.reset_to_default()
	save_config()

## 获取动作映射
## [return] 动作映射
func get_action_mappings() -> Dictionary:
	return _input_config.get_action_mappings()

## 设置动作映射
## [param action] 动作名称
## [param events] 事件列表
func set_action_mapping(action: String, events: Array) -> void:
	_input_config.set_action_mapping(action, events)

## 移除动作映射
## [param action] 动作名称
func remove_action_mapping(action: String) -> void:
	_input_config.remove_action_mapping(action)

## 获取轴映射
## [return] 轴映射
func get_axis_mappings() -> Dictionary:
	return _input_config.get_axis_mappings()

## 设置轴映射
## [param axis] 轴名称
## [param mapping] 轴映射数据
func set_axis_mapping(axis: String, mapping: Dictionary) -> void:
	_input_config.set_axis_mapping(axis, mapping)

## 移除轴映射
## [param axis] 轴名称
func remove_axis_mapping(axis: String) -> void:
	_input_config.remove_axis_mapping(axis)

## 获取设备映射
## [return] 设备映射
func get_device_mappings() -> Dictionary:
	return _input_config.get_device_mappings()

## 设置设备映射
## [param device_id] 设备ID
## [param mapping] 设备映射数据
func set_device_mapping(device_id: int, mapping: Dictionary) -> void:
	_input_config.set_device_mapping(device_id, mapping)

## 移除设备映射
## [param device_id] 设备ID
func remove_device_mapping(device_id: int) -> void:
	_input_config.remove_device_mapping(device_id)

## 获取输入设置
## [return] 输入设置
func get_input_settings() -> Dictionary:
	return _input_config.get_input_settings()

## 更新输入设置
## [param settings] 新设置
func update_input_settings(settings: Dictionary) -> void:
	_input_config.update_input_settings(settings)

## 获取死区值
## [return] 死区值
func get_deadzone() -> float:
	return _input_config.get_deadzone()

## 设置死区值
## [param value] 死区值
func set_deadzone(value: float) -> void:
	_input_config.set_deadzone(value)

## 获取轴灵敏度
## [return] 轴灵敏度
func get_axis_sensitivity() -> float:
	return _input_config.get_axis_sensitivity()

## 设置轴灵敏度
## [param value] 轴灵敏度
func set_axis_sensitivity(value: float) -> void:
	_input_config.set_axis_sensitivity(value)

## 获取震动是否启用
## [return] 震动是否启用
func is_vibration_enabled() -> bool:
	return _input_config.is_vibration_enabled()

## 设置震动是否启用
## [param enabled] 是否启用
func set_vibration_enabled(enabled: bool) -> void:
	_input_config.set_vibration_enabled(enabled)

## 获取震动强度
## [return] 震动强度
func get_vibration_strength() -> float:
	return _input_config.get_vibration_strength()

## 设置震动强度
## [param strength] 震动强度
func set_vibration_strength(strength: float) -> void:
	_input_config.set_vibration_strength(strength)