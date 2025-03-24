@tool
extends Node
class_name SerializableComponent

## 可序列化组件
## 提供节点级别的序列化支持，可用于存档系统和配置系统


# 信号
## 属性变化
signal property_changed(property: String, value: Variant)
## 序列化
signal serialized(data: Dictionary)
## 反序列化
signal deserialized(data: Dictionary)

## 序列化属性
var _properties: Dictionary = {}
## 默认值
var _default_values: Dictionary = {}
## 序列化回调
var _serialize_callbacks: Dictionary = {}
## 反序列化回调
var _deserialize_callbacks: Dictionary = {}

var _save_manager : CoreSystem.SaveManager = CoreSystem.save_manager

func _ready() -> void:
	_save_manager.register_serializable_component(self)


func _exit_tree() -> void:
	_save_manager.unregister_serializable_component(self)
	

## 注册属性
## [param property] 属性名
## [param default_value] 默认值
## [param serialize_callback] 序列化回调
## [param deserialize_callback] 反序列化回调
func register_property(
	property: String, 
	default_value: Variant,
	serialize_callback: Callable = Callable(),
	deserialize_callback: Callable = Callable()
) -> void:
	_properties[property] = default_value
	_default_values[property] = default_value
	if serialize_callback.is_valid():
		_serialize_callbacks[property] = serialize_callback
	if deserialize_callback.is_valid():
		_deserialize_callbacks[property] = deserialize_callback

## 注销属性
## [param property] 属性名
func unregister_property(property: String) -> void:
	_properties.erase(property)
	_default_values.erase(property)
	_serialize_callbacks.erase(property)
	_deserialize_callbacks.erase(property)


## 设置属性值
## [param property] 属性名
## [param value] 值
func set_property(property: String, value: Variant) -> void:
	if _properties.has(property):
		_properties[property] = value
		property_changed.emit(property, value)


## 获取属性值
## [param property] 属性名
## [return] 值
func get_property(property: String) -> Variant:
	return _properties.get(property, _default_values.get(property))


## 重置属性
## [param property] 属性名
func reset_property(property: String) -> void:
	if _default_values.has(property):
		set_property(property, _default_values[property])


## 重置所有属性
func reset_all_properties() -> void:
	for property in _properties.keys():
		reset_property(property)


## 序列化
## [return] 序列化数据
func serialize() -> Dictionary:
	var data = {}
	for property in _properties.keys():
		if _serialize_callbacks.has(property):
			data[property] = _serialize_callbacks[property].call()
		else:
			data[property] = _properties[property]
	serialized.emit(data)
	return data


## 反序列化
## [param data] 序列化数据
func deserialize(data: Dictionary) -> void:
	for property in data.keys():
		if _properties.has(property):
			if _deserialize_callbacks.has(property):
				_deserialize_callbacks[property].call(data[property])
			else:
				set_property(property, data[property])
	deserialized.emit(data)
