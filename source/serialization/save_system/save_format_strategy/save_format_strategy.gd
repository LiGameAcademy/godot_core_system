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
func save(path: String, data: Dictionary, callback: Callable) -> void:
    callback.call(false)

## 加载数据
## [param path] 存档路径
## [param callback] 完成回调，参数：bool是否完成，Dictionary存档数据
func load(path: String, callback: Callable) -> void:
    callback.call(false, {})

## 加载元数据
## [param path] 存档路径
## [param callback] 完成回调，参数：bool是否完成，Dictionary存档元数据
func load_metadata(path: String, callback: Callable) -> void:
    callback.call(false, {})
