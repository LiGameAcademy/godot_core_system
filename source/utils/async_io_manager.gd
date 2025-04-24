extends RefCounted

const SerializationStrategy = preload("./io_strategies/serialization/serialization_strategy.gd")
const JSONSerializationStrategy = preload("./io_strategies/serialization/json_serialization_strategy.gd")

const CompressionStrategy = preload("./io_strategies/compression/compression_strategy.gd")
const NoCompressionStrategy = preload("./io_strategies/compression/no_compression_strategy.gd")
const GzipCompressionStrategy = preload("./io_strategies/compression/gzip_compression_strategy.gd")

const EncryptionStrategy = preload("./io_strategies/encryption/encryption_strategy.gd")
const NoEncryptionStrategy = preload("./io_strategies/encryption/no_encryption_strategy.gd")
const XOREncryptionStrategy = preload("./io_strategies/encryption/xor_encryption_strategy.gd")

const SingleThread = CoreSystem.SingleThread

## IO操作完成信号
signal io_completed(task_id: String, success: bool, result: Variant)
## IO操作错误信号
# signal io_error(task_id: String, error: String)

# Task Management
var _task_counter: int = 0
var _task_id_map: Dictionary = {} # 映射: { int_id_from_thread: string_id_for_public }

# Thread Management
var _io_thread: SingleThread # 假设 SingleThread 已被正确 Preload

# Strategy Instances
var _serializer: SerializationStrategy
var _compressor: CompressionStrategy
var _encryptor: EncryptionStrategy

var _logger : CoreSystem.Logger = CoreSystem.logger

func _init(p_serializer = null, p_compressor = null, p_encryptor = null) -> void:
	set_serialization_strategy(p_serializer if p_serializer else JSONSerializationStrategy.new())
	set_compression_strategy(p_compressor if p_compressor else NoCompressionStrategy.new())
	set_encryption_strategy(p_encryptor if p_encryptor else NoEncryptionStrategy.new())

	_initialize_thread()
	_connect_signals()

## Clean up resources when the object is about to be deleted.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(self):
		_shutdown()

#region Strategy Setters
func set_serialization_strategy(strategy: SerializationStrategy) -> void:
	_serializer = strategy

func set_compression_strategy(strategy: CompressionStrategy) -> void:
	_compressor = strategy

func set_encryption_strategy(strategy: EncryptionStrategy) -> void:
	_encryptor = strategy
#endregion

#region Initialization and Cleanup
## Initialize the IO thread.
func _initialize_thread() -> void:
	# Ensure previous thread is cleaned up if called multiple times (though unlikely for init)
	if _io_thread and is_instance_valid(_io_thread):
		_io_thread.stop()
	_io_thread = SingleThread.new()

## Connect signals from the IO thread.
func _connect_signals() -> void:
	# Check if thread exists before connecting
	if not _io_thread or not is_instance_valid(_io_thread):
		_logger.error("AsyncIO: Cannot connect signals, IO thread is not initialized.")
		return
	# Connect directly to the internal handler
	# Ensure not already connected if _connect_signals could be called multiple times
	if not _io_thread.task_completed.is_connected(_on_task_completed):
		_io_thread.task_completed.connect(_on_task_completed)
	# If SingleThread emits task_error, connect it too
	# if not _io_thread.task_error.is_connected(_on_task_error):
	# 	_io_thread.task_error.connect(_on_task_error)

## Shut down the IO thread manager.
func _shutdown() -> void:
	# Disconnect signals first to prevent issues during shutdown
	if _io_thread and is_instance_valid(_io_thread):
		if _io_thread.task_completed.is_connected(_on_task_completed):
			_io_thread.task_completed.disconnect(_on_task_completed)
		# Disconnect error signal if connected
		_io_thread.stop()
	_io_thread = null
#endregion

#region Public API
## 异步读取文件
## [param path] 文件路径
## [param encryption_key] 加密密钥
## [return] 唯一任务ID字符串
func read_file_async(path: String, encryption_key: String = "") -> String:
	var public_task_id := _generate_task_id() # 生成 String ID
	var key_bytes := encryption_key.to_utf8_buffer()

	# Create the read task callable
	var read_task := func() -> Dictionary:
		var result_data = _execute_read_operation(path, key_bytes)
		return { "success": result_data != null, "result": result_data }

	# Submit the task to the IO thread
	var internal_task_id = _io_thread.add_task(read_task)
	# 存储映射
	_task_id_map[internal_task_id] = public_task_id

	return public_task_id # 返回 String ID

## 异步写入数据到文件
## [param path] 文件路径
## [param data] 数据
## [param encryption_key] 加密密钥
## [return] 唯一任务ID字符串
func write_file_async(path: String, data: Variant, encryption_key: String = "") -> String:
	var public_task_id := _generate_task_id()
	var key_bytes := encryption_key.to_utf8_buffer()

	# Create the write task callable
	var write_task := func() -> Dictionary:
		var success = _execute_write_operation(path, data, key_bytes)
		return { "success": success, "result": null } # Write result is just success/fail

	# Submit the task to the IO thread
	var internal_task_id = _io_thread.add_task(write_task)
	# 存储映射
	_task_id_map[internal_task_id] = public_task_id
	return public_task_id

## Asynchronously deletes a file.
## [param path] The path to the file to delete.
## [return] A unique task ID string.
func delete_file_async(path: String) -> String:
	var public_task_id := _generate_task_id()

	# Create the delete task callable
	var delete_task := func() -> Dictionary:
		var success = _execute_delete_operation(path)
		return { "success": success, "result": null } # Delete result is just success/fail

	# Submit the task to the IO thread
	var internal_task_id = _io_thread.add_task(delete_task)
	# 存储映射
	_task_id_map[internal_task_id] = public_task_id
	return public_task_id

## Asynchronously lists files in a directory (no strategies involved).
## [param path] The directory path.
## [return] A unique task ID string.
func list_files_async(path: String) -> String:
	var public_task_id := _generate_task_id()

	# Create the list task callable
	var list_task := func() -> Dictionary:
		var files = _get_file_list(path)
		# Check if _get_file_list indicates error (e.g., returns null)
		var success = files != null
		return { "success": success, "result": files if success else [] }

	# Submit the task to the IO thread
	var internal_task_id = _io_thread.add_task(list_task)
	# 存储映射
	_task_id_map[internal_task_id] = public_task_id
	return public_task_id
#endregion

#region Internal File Operations (Executed in IO Thread)
## 执行读取操作
## [param path] 路径
## [param key_bytes] 密钥
## [return] 读取的数据
func _execute_read_operation(path: String, key_bytes: PackedByteArray) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		_logger.error("AsyncIO: Failed to open file for reading: %s, Error: %s" % [path, FileAccess.get_open_error()])
		return null

	var content_bytes := file.get_buffer(file.get_length())
	file.close()

	# Process data using strategies
	var result_data: Variant = _process_data_for_read(content_bytes, key_bytes)
	return result_data

## 执行写入操作
## [param path] 路径
## [param data] 数据
## [param key_bytes] 密钥
## [return] 是否写入成功
func _execute_write_operation(path: String, data: Variant, key_bytes: PackedByteArray) -> bool:
	var processed_bytes: PackedByteArray = _process_data_for_write(data, key_bytes)

	var dir_path = path.get_base_dir()
	var dir = DirAccess.open(dir_path.get_base_dir())
	if not dir.dir_exists(dir_path):
		var err = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			_logger.error("AsyncIO: Failed to create directory: %s, Error code: %d" % [dir_path, err])
			return false
	
	# Open and write file
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		_logger.error("AsyncIO: Failed to open file for writing: %s, Error: %s" % [path, FileAccess.get_open_error()])
		return false

	var ok := file.store_buffer(processed_bytes)
	if not ok:
		_logger.error("AsyncIO: Failed to write file: %s" % path)
	file.close()
	return true

## 执行删除操作
## [param path] 路径
## [return] 是否删除成功
func _execute_delete_operation(path: String) -> bool:
	if not FileAccess.file_exists(path):
		_logger.warning("AsyncIO: File to delete does not exist: %s" % path)
		return true
	
	var dir = DirAccess.open(path.get_base_dir())
	if not dir:
		_logger.error("AsyncIO: Could not access directory for deletion: %s" % path.get_base_dir())
		return false

	var err := dir.remove(path.get_file())
	if err != OK:
		_logger.error("AsyncIO: Failed to delete file: %s, Error code: %d" % [path, err])
		return false
	
	return true

## Gets the file list in the background thread.
func _get_file_list(directory_path: String) -> Array:
	var files := []
	var dir := DirAccess.open(directory_path)

	if not dir:
		_logger.error("AsyncIO: Cannot access directory: %s" % directory_path)
		return []

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name != "." and file_name != "..": # Skip . and ..
			# Consider adding option to include directories or get full paths
			if not dir.current_is_dir():
				files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return files
#endregion

#region Internal Data Processing (Uses Strategies)
## 处理数据写入
## [param data] 数据
## [param key_bytes] 密钥
## [return] 处理后的数据
func _process_data_for_write(data: Variant, key_bytes: PackedByteArray) -> PackedByteArray:
	var current_bytes: PackedByteArray
	
	if not _serializer:
		_logger.error("AsyncIO: No serialization strategy set.")
		return PackedByteArray() # Or raise exception
		
	current_bytes = _serializer.serialize(data)
	
	if _compressor:
		current_bytes = _compressor.compress(current_bytes)
	
	if _encryptor:
		current_bytes = _encryptor.encrypt(current_bytes, key_bytes)
		
	return current_bytes

## 处理数据读取
## [param bytes] 数据
## [param key_bytes] 密钥
## [return] 处理后的数据
func _process_data_for_read(bytes: PackedByteArray, key_bytes: PackedByteArray) -> Variant:
	var current_bytes := bytes
	var result_data: Variant = null
	
	if _encryptor:
		current_bytes = _encryptor.decrypt(current_bytes, key_bytes)
	
	if _compressor:
		current_bytes = _compressor.decompress(current_bytes)

	if not _serializer:
		_logger.error("AsyncIO: No serialization strategy set.")
		return null # Or raise exception

	result_data = _serializer.deserialize(current_bytes)
	return result_data
#endregion

#region Utility Methods
## Generates a unique task ID.
func _generate_task_id() -> String:
	_task_counter += 1
	return "%d_%d" % [Time.get_ticks_usec(), _task_counter]
#endregion

#region Signal handling
## 处理来自 SingleThread 的 task_completed 信号
func _on_task_completed(result_dict: Dictionary, internal_task_id: int) -> void: # 注意：这里接收 int ID
	# 查找对应的 Public String ID
	var public_task_id = _task_id_map.get(internal_task_id, "") # 获取 String ID

	if public_task_id.is_empty():
		_logger.error("AsyncIO: Received completed signal for unknown internal task ID: %d" % internal_task_id)
		return # 无法处理，直接返回

	# 任务完成，从映射中移除
	_task_id_map.erase(internal_task_id)

	# 检查任务函数返回的结果字典格式
	if not result_dict is Dictionary or not result_dict.has("success"):
		_logger.error("AsyncIO: Internal task result format error for task %s (Internal ID: %d): %s" % [public_task_id, internal_task_id, str(result_dict)])
		io_completed.emit(public_task_id, false, {"error": "Internal task result format error"})
		return

	var success: bool = result_dict["success"]
	var result_data: Variant = result_dict.get("result")

	_logger.info("AsyncIO: Task %s completed (Internal ID: %d). Success: %s" % [public_task_id, internal_task_id, str(success)])
	# 发出公共信号，使用 String ID
	io_completed.emit(public_task_id, success, result_data)

#endregion 
