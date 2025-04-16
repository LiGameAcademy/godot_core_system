extends Node

## 存档管理器，负责存档的创建、加载、删除等操作

# 引用类型
const GameStateData = CoreSystem.GameStateData
const ResourceSaveStrategy = preload("./save_format_strategy/resource_save_strategy.gd")
const BinarySaveStrategy = preload("./save_format_strategy/binary_save_strategy.gd")
const JSONSaveStrategy = preload("./save_format_strategy/json_save_strategy.gd")
const SaveFormatStrategy = preload("./save_format_strategy/save_format_strategy.gd")

const SaveFormatRegistry = preload("./save_format_strategy/save_format_registry.gd")

# 信号
signal save_created(save_id: String, metadata: Dictionary)
signal save_loaded(save_id: String, metadata: Dictionary)
signal save_deleted(save_id: String)
signal auto_save_created(save_id: String)

# 存档格式注册器单例
var save_format_registry = SaveFormatRegistry.new()

# 配置选项
var save_directory: String = "user://saves"
var encryption_enabled: bool = true
var compression_enabled: bool = true

var auto_save_name: String = "auto_"
var auto_save_enabled: bool = true
var auto_save_interval: float = 300.0					## 自动存档时间间隔，单位：秒
var max_auto_saves: int = 3

# 私有变量
var _current_save_id: String = ""
var _auto_save_timer: float = 0
var _io_manager: CoreSystem.AsyncIOManager = CoreSystem.io_manager
var _encryption_key: String = "123456"
var _save_strategy: SaveFormatStrategy = BinarySaveStrategy.new()

func _process(delta: float) -> void:
	if auto_save_enabled and not _current_save_id.is_empty():
		_auto_save_timer += delta
		if _auto_save_timer >= auto_save_interval:
			_auto_save_timer = 0
			create_auto_save()

#region 公共API

# 设置存档格式
func set_save_format(format: StringName) -> void:
	_set_save_format(format)

# 创建存档
func create_save(save_id: String = "") -> String:
	var actual_id = _generate_save_id() if save_id.is_empty() else save_id
	
	# 收集数据
	var save_data = {
		"metadata": {
			"id": actual_id,
			"timestamp": Time.get_unix_time_from_system(),
			"datetime": Time.get_datetime_string_from_system(),
			"version": ProjectSettings.get_setting("application/config/version", "1.0.0")
		},
		"nodes": _collect_node_states(),
	}
	
	# 存储数据
	var save_path = _get_save_path(actual_id)
	_save_strategy.save(save_path, save_data, func(success: bool):
		if success:
			_current_save_id = actual_id
			save_created.emit(actual_id, save_data.metadata)
	)
	
	return actual_id

# 加载存档
func load_save(save_id: String) -> bool:
	if save_id.is_empty():
		return false
	
	var task = _create_await_task()
	var save_path = _get_save_path(save_id)
	
	_save_strategy.load(save_path, func(success: bool, data: Dictionary):
		if success:
			_current_save_id = save_id

			# 应用实体状态
			if data.has("nodes"):
				_apply_node_states(data.nodes)
		
			save_loaded.emit(save_id, data.metadata)
		else:
			CoreSystem.logger.error("加载存档失败！")
		
		task.complete(success)
	)
	
	return await task.wait()

# 删除存档
func delete_save(save_id: String) -> bool:
	var save_path = _get_save_path(save_id)
	var task = _create_await_task()
	
	_io_manager.delete_file_async(save_path, func(success: bool, _result):
		if success:
			if _current_save_id == save_id:
				_current_save_id = ""
			save_deleted.emit(save_id)
		else:
			CoreSystem.logger.error("删除存档失败：%s" % save_path)
		task.complete(success)
	)
	
	return await task.wait()

# 创建自动存档
func create_auto_save() -> String:
	var auto_save_id = auto_save_name + _get_timestamp()
	var save_id = create_save(auto_save_id)
	
	# 清理旧的自动存档
	_clean_old_auto_saves()
	
	auto_save_created.emit(save_id)
	return save_id

# 获取所有存档列表
func get_save_list() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	var task = _create_await_task()
	
	_io_manager.list_files_async(save_directory, func(success: bool, files: Array):
		if not success:
			CoreSystem.logger.error("获取文件列表失败：%s" % save_directory)
			return
		var pending_loads = files.size()
		
		if pending_loads == 0:
			task.complete(saves)
			return
			
		for file in files:
			if _is_valid_save_file(file):
				var save_id = _get_save_id_from_file(file)
				var save_path = _get_save_path(save_id)
				
				_save_strategy.load_metadata(save_path, func(meta_success: bool, metadata: Dictionary):
					pending_loads -= 1
					
					if meta_success:
						saves.append({
							"id": save_id,
							"metadata": metadata
						})
						
					if pending_loads == 0:
						# 按时间戳排序
						saves.sort_custom(func(a, b): 
							return a.metadata.timestamp > b.metadata.timestamp
						)
						task.complete(saves)
				)
			else:
				pending_loads -= 1
				if pending_loads == 0:
					task.complete(saves)
	)
	
	return await task.wait()

# 注册自定义存档格式策略
func register_save_format_strategy(format: StringName, strategy: SaveFormatStrategy) -> void:
	save_format_registry.register_strategy(format, strategy)

#endregion

#region 辅助方法
# 设置当前存档格式
func _set_save_format(format: StringName) -> void:
	_save_strategy = save_format_registry.get_strategy(format)
	if _save_strategy == null:
		push_error("无法创建存档格式策略: %d" % format)
		_save_strategy = save_format_registry.get_strategy("binary")

# 检查文件是否为有效的存档文件
func _is_valid_save_file(file_name: String) -> bool:
	return _save_strategy.is_valid_save_file(file_name)

# 从文件名获取存档ID
func _get_save_id_from_file(file_name: String) -> String:
	return _save_strategy.get_save_id_from_file(file_name)

# 创建等待任务
func _create_await_task():
	var task = AwaitTask.new()
	return task

# 确保存档目录存在
func _ensure_save_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(save_directory):
		DirAccess.make_dir_recursive_absolute(save_directory)

# 获取存档路径
func _get_save_path(save_id: String) -> String:
	return _save_strategy.get_save_path(save_directory, save_id)

# 清理旧的自动存档
func _clean_old_auto_saves() -> void:
	var saves = await get_save_list()
	var auto_saves = saves.filter(func(save): return save.id.begins_with(auto_save_name))
	
	if auto_saves.size() > max_auto_saves:
		for i in range(max_auto_saves, auto_saves.size()):
			delete_save(auto_saves[i].id)

# 生成时间戳
func _get_timestamp() -> String:
	return str(Time.get_unix_time_from_system())

# 生成存档ID
func _generate_save_id() -> String:
	return "save_" + _get_timestamp()

# 收集Node状态
func _collect_node_states() -> Array:
	var nodes = []
	var saveables = get_tree().get_nodes_in_group("saveable")
	for saveable in saveables:
		if saveable.has_method("save"):
			var node_data = saveable.save()
			node_data["node_path"] = saveable.get_path()
			node_data["position"] = saveable.global_position
			nodes.append(node_data)
		else:
			CoreSystem.logger.warning("缺少save方法！%s" % str(saveable))
	return nodes

# 应用Node状态
func _apply_node_states(nodes: Array) -> void:
	for node_data in nodes:
		var node_path : String = node_data.node_path
		var node = get_node_or_null(node_path)
		if not node:
			CoreSystem.logger.error("不是有效的Node: %s" % node_path)
			return

		if node.has_method("load_data"):
			node.global_position = node_data.position
			node.load_data(node_data)
		else:
			CoreSystem.logger.warning("缺少 load_data 方法！%s" % str(node))

#endregion

# 等待任务类，用于异步到同步转换
class AwaitTask:
	signal completed(result)
	
	func complete(result) -> void:
		completed.emit(result)
		
	func wait():
		return await completed