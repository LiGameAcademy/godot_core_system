@tool
extends Node
class_name SerializableComponent

## 可序列化组件
## 提供节点级别的序列化支持，可用于存档系统

#region 信号定义
## 属性变化
signal property_changed(property: String, value: Variant)
## 序列化
signal serialized(data: Dictionary)
## 反序列化
signal deserialized(data: Dictionary)
#endregion

#region 私有变量
## 属性数据
var _properties: Dictionary = {}
## 默认值
var _default_values: Dictionary = {}
## 回调函数
var _callbacks: Dictionary = {
	"serialize": {},
	"deserialize": {}
}
## 保存系统引用
var _save_system: SaveSystem
#endregion

## 初始化
func _ready() -> void:
	# 获取保存系统引用
	_save_system = CoreSystem.save_system
	if _save_system:
		_save_system.register_serializable_component(self)

## 清理
func _exit_tree() -> void:
	if _save_system:
		_save_system.unregister_serializable_component(self)

#region 公共API
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
		_callbacks.serialize[property] = serialize_callback
		
	if deserialize_callback.is_valid():
		_callbacks.deserialize[property] = deserialize_callback

## 注销属性
## [param property] 属性名
func unregister_property(property: String) -> void:
	_properties.erase(property)
	_default_values.erase(property)
	_callbacks.serialize.erase(property)
	_callbacks.deserialize.erase(property)

## 设置属性值
## [param property] 属性名
## [param value] 值
func set_property(property: String, value: Variant) -> void:
	if _properties.has(property):
		var old_value = _properties[property]
		_properties[property] = value
		
		if old_value != value:
			property_changed.emit(property, value)

## 获取属性值
## [param property] 属性名
## [param default] 默认值（可选）
## [return] 属性值
func get_property(property: String, default: Variant = null) -> Variant:
	if _properties.has(property):
		return _properties[property]
	elif _default_values.has(property):
		return _default_values[property]
	return default

## 检查属性是否存在
## [param property] 属性名
## [return] 是否存在
func has_property(property: String) -> bool:
	return _properties.has(property)

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
		if _callbacks.serialize.has(property):
			data[property] = _callbacks.serialize[property].call()
		else:
			data[property] = _properties[property]
	
	# 添加元数据
	data["__meta"] = {
		"node_name": name,
		"node_path": get_path()
	}
	
	serialized.emit(data)
	return data

## 反序列化
## [param data] 序列化数据
func deserialize(data: Dictionary) -> void:
	# 移除元数据
	var clean_data = data.duplicate()
	clean_data.erase("__meta")
	
	for property in clean_data.keys():
		if _callbacks.deserialize.has(property):
			_callbacks.deserialize[property].call(clean_data[property])
		else:
			set_property(property, clean_data[property])
	
	deserialized.emit(clean_data)
#endregion