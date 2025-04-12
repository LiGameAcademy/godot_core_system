extends RefCounted

## 存档格式策略接口

var manager: Node # 引用存档管理器

func _init(p_manager: Node):
    manager = p_manager

## 是否为有效的存档文件
func is_valid_save_file(file_name: String) -> bool:
    return false

## 从文件名获取存档ID
func get_save_id_from_file(file_name: String) -> String:
    return ""

## 获取存档路径
func get_save_path(directory: String, save_id: String) -> String:
    return ""

## 保存数据
func save(path: String, data: Dictionary, callback: Callable) -> void:
    callback.call(false)

## 加载数据
func load(path: String, callback: Callable) -> void:
    callback.call(false, {})

## 加载元数据
func load_metadata(path: String, callback: Callable) -> void:
    callback.call(false, {})
