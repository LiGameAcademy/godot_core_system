extends "./save_format_strategy.gd"

const GameStateData = CoreSystem.SaveManager.GameStateData

## 文件名是否有效
func is_valid_save_file(file_name: String) -> bool:
	return file_name.ends_with(".tres")

## 获取存档ID
func get_save_id_from_file(file_name: String) -> String:
	return file_name.trim_suffix(".tres")

## 获取存档路径
func get_save_path(directory: String, save_id: String) -> String:
	return directory.path_join("%s.tres" % save_id)

## 保存存档
func save(path: String, data: Dictionary) -> bool:
	var save_data = GameStateData.new(
		data.metadata.save_id,
		data.metadata.timestamp,
		data.metadata.save_date,
		data.metadata.game_version,
		data.metadata.playtime
	)
	# 设置节点状态
	save_data.nodes_state = data.nodes
	
	# 保存资源
	var error = ResourceSaver.save(save_data, path)
	return error == OK

## 加载存档数据
func load_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
		
	var resource = ResourceLoader.load(path)
	if not resource:
		return {}
		
	var result = {
		"metadata": resource.metadata,
		"nodes": resource.nodes_state
	}
	
	return result

## 加载元数据
func load_metadata(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
		
	var resource = ResourceLoader.load(path)
	return resource.metadata if resource else {}
