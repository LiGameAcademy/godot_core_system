extends Node

## 存档管理器，负责存档的创建、加载、删除等操作

## 存档数据
const GameStateData = preload("./game_state_data.gd")
const SETTING_SCRIPT: Script = preload("../../../setting.gd")
const SETTING_SAVE_SYSTEM := SETTING_SCRIPT.SETTING_SAVE_SYSTEM

## 项目设置路径常量
const SETTING_SAVE_DIR =  SETTING_SAVE_SYSTEM + "save_directory"
const SETTING_SAVE_EXT = SETTING_SAVE_SYSTEM + "save_extension"
const SETTING_AUTO_SAVE_INTERVAL = SETTING_SAVE_SYSTEM + "auto_save_interval"
const SETTING_MAX_AUTO_SAVES = SETTING_SAVE_SYSTEM + "max_auto_saves"
const SETTING_AUTO_SAVE_ENABLED = SETTING_SAVE_SYSTEM + "auto_save_enabled"

## 存档目录
var save_directory: String:
	get:
		return ProjectSettings.get_setting(SETTING_SAVE_DIR, "user://saves")

## 存档扩展名
var save_extension: String:
	get:
		return ProjectSettings.get_setting(SETTING_SAVE_EXT, "save")

## 自动存档间隔（秒）
var auto_save_interval: float:
	get:
		return ProjectSettings.get_setting(SETTING_AUTO_SAVE_INTERVAL, 300)

## 自动存档最大数量
var max_auto_saves: int:
	get:
		return ProjectSettings.get_setting(SETTING_MAX_AUTO_SAVES, 3)

## 是否启用自动存档
var auto_save_enabled: bool:
	get:
		return ProjectSettings.get_setting(SETTING_AUTO_SAVE_ENABLED, true)

## 当前存档
var _current_save: GameStateData = null

## 异步IO管理器
var _io_manager: CoreSystem.AsyncIOManager:
	get:
		return CoreSystem.io_manager

## 自动存档计时器
var _auto_save_timer: float = 0

var _serializable_components : Array[SerializableComponent]

# 信号
## 存档创建
signal save_created(save_name: String)
## 存档加载
signal save_loaded(save_name: String)
## 存档删除
signal save_deleted(save_name: String)
## 自动存档
signal auto_save_created
## 自动存档清理完成
signal auto_save_cleaned

# 每帧判断是否需要自动存档
func _process(delta: float) -> void:
	_update_auto_save(delta)


## 注册可序列化组件
func register_serializable_component(component: SerializableComponent) -> void:
	if _serializable_components.has(component):
		CoreSystem.logger.warning("Serializable component already registered: " + component.name)
		return
	_serializable_components.append(component)


## 注销可序列化组件
func unregister_serializable_component(component: SerializableComponent) -> void:
	if not _serializable_components.has(component):
		CoreSystem.logger.warning("Serializable component not registered: " + component.name)
		return
	_serializable_components.erase(component)


## 创建存档
## [param save_name] 存档名称
## [param callback] 回调函数，用于通知创建结果
func create_save(save_name: String, callback: Callable = func(_success: bool): pass) -> void:
	_current_save = GameStateData.new(save_name)

	# 收集所有可序列化组件的数据
	var serialized_data = {}
	for node in _serializable_components:
		if node is SerializableComponent:
			var node_path = str(node.get_path())
			serialized_data[node_path] = node.serialize()

	_current_save.set_data("nodes", serialized_data)

	# 保存到文件
	var save_path = _get_save_path(save_name)
	_io_manager.write_file_async(
		save_path,
		_current_save.serialize(),
		true,
		"12345",
		func(success: bool, _result: Variant):
			if success:
				save_created.emit(save_name)
			callback.call(success)
	)

## 加载存档
## [param save_name] 存档名称
## [param callback] 回调函数,用于通知加载结果
func load_save(save_name: String, callback: Callable = func(_success: bool): pass) -> void:
	var save_path = _get_save_path(save_name)

	_io_manager.read_file_async(
		save_path,
		true,
		"12345",
		func(success: bool, result: Variant):
			if success:
				_current_save = GameStateData.new()
				_current_save.deserialize(result)

				# 恢复所有可序列化组件的数据
				var serialized_data = _current_save.get_data("nodes", {})
				for node_path in serialized_data.keys():
					var node = get_node_or_null(node_path)
					if node is SerializableComponent:
						node.deserialize(serialized_data[node_path])

				save_loaded.emit(save_name)
			callback.call(success)
	)

## 删除存档
## [param save_name] 存档名称
## [param callback] 回调函数
func delete_save(save_name: String, callback: Callable = func(_success: bool): pass) -> void:
	var save_path = _get_save_path(save_name)

	_io_manager.delete_file_async(
		save_path,
		func(success: bool, _result: Variant):
			if success:
				if _current_save and _current_save.metadata.save_name == save_name:
					_current_save = null
				save_deleted.emit(save_name)
			callback.call(success)
	)

## 创建自动存档
func create_auto_save() -> void:
	if not _current_save:
		return

	var timestamp = Time.get_unix_time_from_system()
	var auto_save_name = "auto_save_%d" % timestamp

	create_save(auto_save_name, func(success: bool):
		if success:
			auto_save_created.emit()
			# 清理旧的自动存档
			_clean_old_auto_saves(func():
				auto_save_cleaned.emit()
			)
	)

## 获取存档列表
## [param callback] 回调函数
func get_save_list(callback: Callable = Callable()) -> void:
	if not callback.is_valid(): 
		return
	var saves = []
	var dir = DirAccess.open(save_directory)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with("." + save_extension):
				var save_name = file_name.get_basename()
				saves.append(save_name)
			file_name = dir.get_next()
	callback.call(saves)

## 获取当前存档
## [return] 当前存档
func get_current_save() -> GameStateData:
	return _current_save

## 清理旧的自动存档
## [param callback] 回调函数，在清理完成后调用
func _clean_old_auto_saves(callback: Callable = Callable()) -> void:
	get_save_list(func(saves: Array):
		var auto_saves = saves.filter(func(save_name: String):
			return save_name.begins_with("auto_save_")
		)
		auto_saves.sort()
		
		var remaining_deletes = auto_saves.size() - max_auto_saves
		if remaining_deletes <= 0:
			if callback.is_valid():
				callback.call()
			return
		
		var deletes_completed = 0
		while auto_saves.size() > max_auto_saves:
			var old_save = auto_saves.pop_front()
			delete_save(old_save, func(success: bool):
				deletes_completed += 1
				if deletes_completed >= remaining_deletes and callback.is_valid():
					callback.call()
			)
	)

## 获取存档路径
## [param save_name] 存档名称
## [return] 存档路径
func _get_save_path(save_name: String) -> String:
	return save_directory.path_join(save_name + "." + save_extension)

## 更新自动存档计时器并在需要时创建自动存档
## [param delta] 时间增量
func _update_auto_save(delta: float) -> void:
	if not auto_save_enabled or _current_save == null:
		return

	_auto_save_timer += delta
	if _auto_save_timer >= auto_save_interval:
		_auto_save_timer = 0
		create_auto_save()
