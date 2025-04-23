extends "./save_format_strategy.gd"

## 是否为有效的存档文件
func is_valid_save_file(file_name: String) -> bool:
	return file_name.ends_with(".json")

## 获取存档名
func get_save_id_from_file(file_name: String) -> String:
	return file_name.trim_suffix(".json")

## 获取存档路径
func get_save_path(directory: String, save_id: String) -> String:
	return directory.path_join("%s.json" % save_id)

## 保存存档
func save(path: String, data: Dictionary, callback: Callable) -> void:
	var json_str = JSON.stringify(data, "  ")
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file:
		file.store_string(json_str)
		file.close()
		callback.call(true)
	else:
		callback.call(false)

## 加载存档
func load(path: String, callback: Callable) -> void:
	var json_str = _get_json_str(path)
	if json_str.is_empty():
		callback.call(false, {})

	var json = JSON.new()
	var error = json.parse(json_str)
	
	if error == OK:
		callback.call(true, json.data)
	else:
		callback.call(false, {})

## 加载元数据
func load_metadata(path: String, callback: Callable) -> void:
	var json_str : String = _get_json_str(path)
	if json_str.is_empty():
		callback.call(false, {})

	var json = JSON.new()
	var error = json.parse(json_str)
	
	if error == OK and json.data is Dictionary and json.data.has("metadata"):
		callback.call(true, json.data.metadata)
	else:
		callback.call(false, {})

## 获取JSON字符串
func _get_json_str(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""
		
	var json_str = file.get_as_text()
	file.close()
	return json_str
