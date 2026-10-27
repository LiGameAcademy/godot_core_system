class_name InputConfigAdapter
extends RefCounted

## 配置更新信号
signal config_updated(config: Dictionary)

const Config = preload("./input_config.gd")
var _input_config: Config
var _read_section: Callable
var _write_section: Callable
var _save_file: Callable
var _closed: bool = false

## Optional callbacks operate on the input section; persistence is never discovered.
func _init(config: Config = null, read_section: Callable = Callable(), write_section: Callable = Callable(), save_file: Callable = Callable()) -> void:
	_input_config = config if config != null else Config.new()
	_read_section = read_section
	_write_section = write_section
	_save_file = save_file
	_input_config.config_changed.connect(_on_input_config_changed)

func get_input_config() -> Config:
	return _input_config

## Read callback returns a section Dictionary. Load the external file before calling.
func reload_config() -> Error:
	if _closed or not _read_section.is_valid():
		return ERR_UNCONFIGURED
	var section: Variant = _read_section.call()
	if not section is Dictionary:
		return ERR_INVALID_DATA
	if section.is_empty():
		_input_config.reset_to_default()
		return OK
	return _input_config.update_config(section)

func _on_input_config_changed(config: Dictionary) -> void:
	if not _closed:
		config_updated.emit(config)

## Stage the latest section before saving. Save callback returns an Error.
func save_config() -> Error:
	if _closed or not _write_section.is_valid() or not _save_file.is_valid():
		return ERR_UNCONFIGURED
	_write_section.call(_input_config.get_config())
	var result: Variant = _save_file.call()
	return result as Error if result is int else ERR_INVALID_DATA

func close() -> void:
	if _closed:
		return
	_closed = true
	if _input_config.config_changed.is_connected(_on_input_config_changed):
		_input_config.config_changed.disconnect(_on_input_config_changed)
	_read_section = Callable()
	_write_section = Callable()
	_save_file = Callable()

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
