extends "./save_format_strategy.gd"

var _io_manager: CoreSystem.AsyncIOManager
var _encryption_key: String = ""

func _init() -> void:
	_io_manager = CoreSystem.AsyncIOManager.new()

## 设置加密密钥
func set_encryption_key(key: String) -> void:
	_encryption_key = key

## 保存数据
func save(path: String, data: Dictionary) -> bool:
	var processed_data = _process_data_for_save(data)
	var task_id = _io_manager.write_file_async(path, processed_data, _encryption_key)
	var result = await _io_manager.io_completed
	return result[1] if result[0] == task_id else false

## 加载数据
func load_save(path: String) -> Dictionary:
	var task_id = _io_manager.read_file_async(path, _encryption_key)
	var result = await _io_manager.io_completed
	if result[0] == task_id and result[1]:
		return _process_data_for_load(result[2])
	
	return {}

## 加载元数据
func load_metadata(path: String) -> Dictionary:
	var data : Dictionary = await load_save(path)
	return data.get("metadata", {}) if data.has("metadata") else {}

## 处理数据保存
func _process_data_for_save(data: Dictionary) -> Dictionary:
	var result = {}
	for key in data:
		var value = data[key]
		if value is Vector2:
			result[key] = {
				"__type": "Vector2",
				"x": value.x,
				"y": value.y
			}
		elif value is Vector3:
			result[key] = {
				"__type": "Vector3",
				"x": value.x,
				"y": value.y,
				"z": value.z
			}
		elif value is Color:
			result[key] = {
				"__type": "Color",
				"r": value.r,
				"g": value.g,
				"b": value.b,
				"a": value.a
			}
		elif value is Dictionary:
			result[key] = _process_data_for_save(value)
		elif value is Array:
			result[key] = _process_array_for_save(value)
		else:
			result[key] = value
	return result

## 处理数组保存
func _process_array_for_save(array: Array) -> Array:
	var result = []
	for item in array:
		if item is Dictionary:
			result.append(_process_data_for_save(item))
		elif item is Array:
			result.append(_process_array_for_save(item))
		elif item is Vector2 or item is Vector3 or item is Color:
			result.append(_process_data_for_save({ "_": item })["_"])
		else:
			result.append(item)
	return result

## 处理数据加载
func _process_data_for_load(data: Dictionary) -> Dictionary:
	var result = {}
	for key in data:
		var value = data[key]
		if value is Dictionary and value.has("__type"):
			match value.__type:
				"Vector2":
					result[key] = Vector2(value.x, value.y)
				"Vector3":
					result[key] = Vector3(value.x, value.y, value.z)
				"Color":
					result[key] = Color(value.r, value.g, value.b, value.a)
		elif value is Dictionary:
			result[key] = _process_data_for_load(value)
		elif value is Array:
			result[key] = _process_array_for_load(value)
		else:
			result[key] = value
	return result

## 处理数组加载
func _process_array_for_load(array: Array) -> Array:
	var result = []
	for item in array:
		if item is Dictionary:
			result.append(_process_data_for_load(item))
		elif item is Array:
			result.append(_process_array_for_load(item))
		else:
			result.append(item)
	return result
