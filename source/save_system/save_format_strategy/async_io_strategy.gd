extends "./save_format_strategy.gd"

var _io_manager: CoreSystem.AsyncIOManager

func _init() -> void:
	_io_manager = CoreSystem.AsyncIOManager.new()

## 保存数据
func save(path: String, data: Dictionary) -> bool:
	var task_id = _io_manager.write_file_async(path, data)
	var result = await _io_manager.io_completed
	return result[1] if result[0] == task_id else false

## 加载数据
func load_save(path: String) -> Dictionary:
	var task_id = _io_manager.read_file_async(path)
	var result = await _io_manager.io_completed
	if result[0] == task_id and result[1]:
		return result[2]
	return {}

## 加载元数据
func load_metadata(path: String) -> Dictionary:
	var data : Dictionary = await load_save(path)
	return data.get("metadata", {}) if data.has("metadata") else {}
