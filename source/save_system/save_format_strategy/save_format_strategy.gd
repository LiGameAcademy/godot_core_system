extends RefCounted

## 存档格式策略接口

## 是否为有效的存档文件
## [param file_name] 文件名称
## [return] 是否存在有效的存档文件
func is_valid_save_file(file_name: String) -> bool:
	return false

## 从文件名获取存档ID
## [param file_name] 文件名称
## [return] 存档ID
func get_save_id_from_file(file_name: String) -> String:
	return ""

## 获取存档路径
## [param directory] 
## [param save_id] 存档ID
## [return] 存档路径
func get_save_path(directory: String, save_id: String) -> String:
	return ""

## 保存数据
## [param path] 存档路径
## [param data] 存储数据
## [param callback] 完成回调，参数bool是否完成
func save(path: String, data: Dictionary) -> bool:
	return false

## 加载数据
## [param path] 存档路径
## [param callback] 完成回调，参数：bool是否完成，Dictionary存档数据
func load_save(path: String) -> Dictionary:
	return {}

## 加载元数据
## [param path] 存档路径
## [param callback] 完成回调，参数：bool是否完成，Dictionary存档元数据
func load_metadata(path: String) -> Dictionary:
	return {}

## 删除文件
## [param path] 存档路径
## [return] 是否删除成功
func delete_file(path: String) -> bool:
	var dir = DirAccess.open(path.get_base_dir())
	if not dir:
		return false
	return dir.remove(path.get_file()) == OK

## 列出文件
## [param directory] 存档目录
## [return] 文件列表
func list_files(directory: String) -> Array:
	var files := []
	var dir := DirAccess.open(directory)
	if not dir:
		return files
		
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name != "." and file_name != ".." and not dir.current_is_dir():
			if is_valid_save_file(file_name):
				files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return files
