extends "./save_format_strategy.gd"

const encryption_key : String = "123456"
#var io_manager : CoreSystem.AsyncIOManager = CoreSystem.io_manager

## 是否为有效存档
func is_valid_save_file(file_name: String) -> bool:
	return file_name.ends_with(".save")

## 获取存档ID
func get_save_id_from_file(file_name: String) -> String:
	return file_name.trim_suffix(".save")

## 获取存档路径
func get_save_path(directory: String, save_id: String) -> String:
	return directory.path_join("%s.save" % save_id)

## 保存存档
func save(path: String, data: Dictionary, callback: Callable) -> void:
	#io_manager.write_file_async(
		#path, 
		#data, 
		#true,
		#encryption_key,
		#func(success: bool, _result): callback.call(success)
	#)
	pass

## 加载存档
func load(path: String, callback: Callable) -> void:
	#io_manager.read_file_async(
		#path,
		#true,
		#encryption_key,
		#func(success: bool, result):
			#if success:
				#callback.call(true, result)
			#else:
				#callback.call(false, {})
	#)
	pass

## 加载元数据
func load_metadata(path: String, callback: Callable) -> void:
	#io_manager.read_file_async(
		#path,
		#true,
		#encryption_key,
		#func(success: bool, result):
			#if success and result is Dictionary and result.has("metadata"):
				#callback.call(true, result.metadata)
			#else:
				#callback.call(false, {})
	#)
	pass
