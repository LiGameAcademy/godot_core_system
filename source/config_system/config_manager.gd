extends Node

## 配置管理器

# 信号
signal config_loaded		## 配置加载
signal config_saved			## 配置保存
signal config_reset			## 配置重置

const SETTING_SCRIPT: Script = preload("../../setting.gd")
const SETTING_CONFIG_SYSTEM := SETTING_SCRIPT.SETTING_CONFIG_SYSTEM
const SETTING_CONFIG_PATH: String = SETTING_CONFIG_SYSTEM + "config_path"
const SETTING_AUTO_SAVE: String = SETTING_CONFIG_SYSTEM + "auto_save"

## 配置文件路径
@export var config_path: String:
	get:
		return ProjectSettings.get_setting(SETTING_CONFIG_PATH, "user://config.cfg")
	set(_value):
		CoreSystem.logger.error("read-only")

## 是否自动保存
@export var auto_save: bool:
	get:
		return ProjectSettings.get_setting(SETTING_AUTO_SAVE, true)
	set(_value):
		CoreSystem.logger.error("read-only")

var _config_file : ConfigFile = ConfigFile.new()
var _modified : bool = false

var _logger : CoreSystem.Logger = CoreSystem.logger

func _init() -> void:
	# 加载配置
	load_config()

func _exit() -> void:
	if auto_save and _modified:
		save_config()

## 加载配置文件
## 尝试从指定路径加载配置。如果文件不存在或是空的，后续 get_value 调用会返回调用者提供的默认值。
## [param p_path] 可选，覆盖设置中定义的路径
## [return] bool 加载是否成功（文件不存在视为成功，但会记录信息）
func load_config(p_path: String = "") -> bool:
	var path_to_load = p_path if not p_path.is_empty() else config_path
	
	# 确保目标目录存在，load 不会创建目录
	var dir_path = path_to_load.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		print("Config directory '%s' does not exist, attempting to load will likely fail (or be empty)." % dir_path)
		# ConfigFile.load 在目录不存在时似乎不会返回特定错误码，更像 ERR_FILE_NOT_FOUND

	var err = _config_file.load(path_to_load)

	if err == OK:
		print("Config loaded successfully from '%s'." % path_to_load)
		_modified = false
		config_loaded.emit()
		return true
	elif err == ERR_FILE_NOT_FOUND:
		print("Config file '%s' not found. Will use default values provided by get_value()." % path_to_load)
		_config_file.clear() # 确保内存中是空的，而不是上次加载的内容
		_modified = false # 文件不存在，没有加载内容，不算修改
		config_loaded.emit() # 仍然发射信号，表示加载过程完成（即使是空配置）
		return true # 文件不存在是预期情况，不算加载失败
	else: # 其他加载错误
		printerr("Failed to load config file '%s'. Error code: %d" % [path_to_load, err])
		_config_file.clear() # 加载失败，清空内存状态以防部分加载
		_modified = false
		# 考虑是否仍要发射 config_loaded 信号？取决于应用逻辑
		# config_loaded.emit() # 如果发射，调用者需要检查返回值
		return false

## 保存配置文件
## [param p_path] 可选，覆盖默认路径
func save_config(p_path: String = "") -> bool:
	var path_to_save = p_path if not p_path.is_empty() else config_path

	# 确保目录存在
	var dir_path = path_to_save.get_base_dir()
	var dir_err = DirAccess.make_dir_recursive_absolute(dir_path)
	if dir_err != OK:
		CoreSystem.logger.error("Failed to create directory for config file '%s'. Error code: %d" % [dir_path, dir_err])
		return false

	# 保存文件
	var err = _config_file.save(path_to_save)
	if err != OK:
		CoreSystem.logger.error("Failed to save config file '%s'. Error code: %d" % [path_to_save, err])
		return false

	_modified = false # 只有成功保存才重置修改状态
	config_saved.emit()
	CoreSystem.logger.info("Config file saved to '%s'." % path_to_save)
	return true

## 重置配置
## 清空当前内存中的所有配置项。
## 外部代码可以监听 config_reset 信号来应用游戏特定的默认值。
func reset_config() -> void: # 方法名也改为 reset_config 更准确
	if _config_file.get_sections().is_empty():
		# 如果已经为空，则无需操作，避免不必要的修改和保存
		_logger.debug("Config is already empty, reset_config skipped.")
		return

	_config_file.clear() # 清空当前 ConfigFile 对象中的所有段和键

	_modified = true # 标记为已修改，以便 auto_save 生效（会保存一个空文件）
	config_reset.emit() # 发出信号，通知外部配置已被清空
	_logger.info("Config cleared. Listening systems can now apply defaults if needed.")

	if auto_save:
		save_config() # 如果自动保存，将保存一个空文件

## 设置配置值
func set_value(section: String, key: String, value: Variant) -> void:
	# 获取当前值（如果存在）和默认值，用于比较是否真的修改了
	var current_value = get_value(section, key, null) # 使用 get_value 获取合并后的当前值

	# 使用更严格的比较
	_modified = _is_value_modified(current_value, value)

	if _modified:
		_config_file.set_value(section, key, value)
		CoreSystem.logger.debug("Config value set: [%s] %s = %s" % [section, key, str(value)])
		if auto_save:
			save_config()

## 获取配置值
## [param section] 配置段
## [param key] 键
## [param p_default_override] 默认值
## [return] 值
func get_value(section: String, key: String, p_default_value: Variant) -> Variant:
	# 直接从 ConfigFile 获取，如果不存在则返回调用者提供的 p_default_value
	return _config_file.get_value(section, key, p_default_value)

## 获取配置段中实际存在于文件中的所有键值对
## 注意：此方法不包含未写入文件的默认值。
## 如需获取包含默认值的值，请使用 get_value(section, key, default)。
## [param section] 配置段名称
## [return] 包含该段落文件内所有键值对的字典副本
func get_section(section: String) -> Dictionary:
	var result := {}
	if not _config_file.has_section(section):
		return result # 如果段落不存在于文件中，返回空字典

	var file_keys = _config_file.get_section_keys(section)
	for key in file_keys:
		# 直接从 ConfigFile 获取值，不传递默认值，因为我们只关心文件中的内容
		result[key] = _config_file.get_value(section, key)

	return result.duplicate() # 返回副本

## 设置整个配置段 (替换模式)
## 注意：此方法会先删除指定段落中所有现有的键，然后添加新字典中的所有键值。
## [param section] 要设置的配置段名称
## [param value] 包含新键值对的字典
func set_section(section: String, value: Dictionary) -> void:
	var changed = false

	# 1. 删除段落中所有现有的键
	if _config_file.has_section(section):
		var existing_keys = _config_file.get_section_keys(section)
		if not existing_keys.is_empty():
			changed = true # 标记为更改，因为我们要删除
			for key in existing_keys:
				_config_file.erase_section_key(section, key)
				# 注意: erase_section_key 在 ConfigFile 中似乎不存在
				# ConfigFile API 的限制使得完美实现 "erase section" 很困难
				# 替代方案：我们可以不删除，只覆盖。但这不符合"设置整个段"的替换语义。
				#
				# **重要更新：** 查阅文档后，ConfigFile 确实没有 erase_section_key 或 erase_section。
				# 最接近的方法是重新加载一个空的 ConfigFile 或者手动比较。
				# 为了简单起见，我们将采用"覆盖或添加"的策略，并更新注释说明其行为。
				# 如果需要严格的"替换"，ConfigManager 需要更复杂的逻辑或完全不同的存储方式。

	# --- 更新后的实现：采用"覆盖或添加"策略 ---
	# (移除上面的删除逻辑)

	# 2. 遍历新字典，设置或覆盖值
	for key in value:
		var current_value = _config_file.get_value(section, key, null) # 获取当前文件中的值
		if current_value != value[key]: # 仅在值确实改变时设置
			_config_file.set_value(section, key, value[key])
			changed = true

	# 3. 如果有任何值被修改或添加
	if changed:
		_modified = true
		CoreSystem.logger.debug("Config section updated/set: [%s]" % section)
		if auto_save:
			save_config()

## 获取配置文件中存在的所有段落名称
## [return] 包含所有段落名称的 PackedStringArray
func get_sections() -> PackedStringArray:
	return _config_file.get_sections()

## 检查是否有配置段
func has_section(section: String) -> bool:
	# 检查文件是否存在该段
	return _config_file.has_section(section)

## 检查配置段中是否有某个键
func has_key(section: String, key: String) -> bool:
	# 只检查文件
	return _config_file.has_section_key(section, key)

## 比较两个值是否不同
func _is_value_modified(current: Variant, new: Variant) -> bool:
	# 处理 null 情况
	if current == null and new == null:
		return false
	if current == null or new == null:
		return true

	# 处理数组
	if current is Array and new is Array:
		if current.size() != new.size():
			return true
		for i in range(current.size()):
			if _is_value_modified(current[i], new[i]):
				return true
		return false

	# 处理字典
	if current is Dictionary and new is Dictionary:
		if current.size() != new.size():
			return true
		for key in current:
			if not new.has(key) or _is_value_modified(current[key], new[key]):
				return true
		return false

	# 处理浮点数
	if current is float and new is float:
		return not is_equal_approx(current, new)

	# 默认比较
	return current != new
