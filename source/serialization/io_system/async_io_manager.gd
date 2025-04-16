extends Node

## 异步IO管理器
## 提供文件系统操作的异步执行功能，支持压缩和加密
#region 信号定义
## IO操作完成信号
signal io_completed(task_id: String, success: bool, result: Variant)
## IO操作错误信号
signal io_error(task_id: String, error: String)
#endregion

#region 私有变量
# 任务管理
var _task_counter: int = 0                 ## 任务计数器

# 线程管理
var _io_thread: CoreSystem.SingleThread    ## IO专用线程

# 加密管理
var _encryption_provider: EncryptionProvider = null
#endregion

## 初始化IO管理器
func _init() -> void:
	_initialize_thread()
	_connect_signals()

## 清理资源
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_shutdown()

#region 公共属性
## 加密提供者
var encryption_provider: EncryptionProvider:
	get:
		if not _encryption_provider:
			_encryption_provider = XOREncryptionProvider.new()
		return _encryption_provider
	set(value):
		_encryption_provider = value
#endregion

#region 初始化和清理
## 初始化IO线程
func _initialize_thread() -> void:
	_io_thread = CoreSystem.SingleThread.new()

## 连接信号
func _connect_signals() -> void:
	_io_thread.task_completed.connect(_on_task_completed)
	_io_thread.task_error.connect(_on_task_error)

## 关闭管理器
func _shutdown() -> void:
	if _io_thread:
		_io_thread.stop()
		_io_thread = null
#endregion

#region 基础API - 简单操作
## 异步读取文件（基础版本）
## [param path] 文件路径
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func read_file(path: String, callback: Callable = Callable()) -> String:
	return read_file_async(path, false, "", callback)

## 异步写入文件（基础版本）
## [param path] 文件路径
## [param data] 要写入的数据
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func write_file(path: String, data: Variant, callback: Callable = Callable()) -> String:
	return write_file_async(path, data, false, "", callback)

## 异步删除文件
## [param path] 文件路径
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func delete_file(path: String, callback: Callable = func(_s, _r): pass) -> String:
	return delete_file_async(path, callback)
#endregion

#region 进阶API - 支持压缩
## 异步读取文件（支持压缩）
## [param path] 文件路径
## [param use_compression] 是否使用压缩
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func read_file_advanced(path: String, use_compression: bool = false, callback: Callable = func(_s, _r): pass) -> String:
	return read_file_async(path, use_compression, "", callback)

## 异步写入文件（支持压缩）
## [param path] 文件路径
## [param data] 要写入的数据
## [param use_compression] 是否使用压缩
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func write_file_advanced(path: String, data: Variant, use_compression: bool = false, callback: Callable = func(_s, _r): pass) -> String:
	return write_file_async(path, data, use_compression, "", callback)
#endregion

#region 完整API - 支持压缩和加密
## 异步读取文件（完整版）
## [param path] 文件路径
## [param use_compression] 是否使用压缩
## [param encryption_key] 加密密钥，空字符串表示不加密
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func read_file_async(path: String, use_compression: bool = false, encryption_key: String = "", callback: Callable = func(_s, _r): pass) -> String:
	var task_id = _generate_task_id()
	
	# 创建读取任务
	var read_task = func() -> Variant:
		return _execute_read_operation(path, use_compression, encryption_key)
	
	# 创建回调处理
	var callback_handler = func(result: Variant) -> void:
		if result != null:
			callback.call(true, result)
		else:
			callback.call(false, null)

	# 提交到IO线程
	_io_thread.add_task(read_task, callback_handler)
	return task_id

## 异步写入文件（完整版）
## [param path] 文件路径
## [param data] 要写入的数据
## [param use_compression] 是否使用压缩
## [param encryption_key] 加密密钥，空字符串表示不加密
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func write_file_async(
		path: String, 
		data: Variant, 
		use_compression: bool = false, 
		encryption_key: String = "", 
		callback: Callable = func(_s, _r): pass
		) -> String:
	var task_id = _generate_task_id()
	
	# 创建写入任务
	var write_task = func() -> bool:
		return _execute_write_operation(path, data, use_compression, encryption_key)
	
	# 创建回调处理
	var callback_handler = func(success: bool) -> void:
		if callback.is_valid():
			callback.call(success, null)

	# 提交到IO线程
	_io_thread.add_task(write_task, callback_handler)
	return task_id

## 异步删除文件
## [param path] 文件路径
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func delete_file_async(path: String, callback: Callable = func(_s, _r): pass) -> String:
	var task_id = _generate_task_id()
	
	# 创建删除任务
	var delete_task = func() -> bool:
		return _execute_delete_operation(path)
	
	# 创建回调处理
	var callback_handler = func(success: bool) -> void:
		if callback.is_valid():
			callback.call(success, null)

	# 提交到IO线程
	_io_thread.add_task(delete_task, callback_handler)
	return task_id

## 异步获取文件列表
func list_files_async(path: String, callback:Callable = Callable()) -> String:
	var task_id = _generate_task_id()

	## 创建获取文件列表任务
	var list_task := func() -> Variant:
		return _get_file_list(path)
	
	## 创建回调处理
	var callback_handler := func(result: Variant) -> void:
		if result != null:
			callback.call(true, result)
		else:
			callback.call(false, null)
	
	## 提交到IO线程
	_io_thread.add_task(list_task, callback_handler)
	return task_id

#endregion

#region 文件操作实现
## 执行读取操作
## [param path] 文件路径
## [param use_compression] 是否使用压缩
## [param encryption_key] 加密密钥
## [return] 读取的数据或null（失败时）
func _execute_read_operation(path: String, use_compression: bool, encryption_key: String) -> Variant:
	# 打开文件
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("无法打开文件: %s, 错误: %s" % [path, FileAccess.get_open_error()])
		return null
	
	# 读取内容
	var content = file.get_buffer(file.get_length())
	file.close()
	
	# 处理数据
	return _process_data_for_read(content, use_compression, encryption_key)

## 执行写入操作
## [param path] 文件路径
## [param data] 数据
## [param use_compression] 是否使用压缩
## [param encryption_key] 加密密钥
## [return] 是否成功
func _execute_write_operation(path: String, data: Variant, use_compression: bool, encryption_key: String) -> bool:
	# 处理数据
	var processed_data = _process_data_for_write(data, use_compression, encryption_key)
	
	# 打开文件
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("无法打开文件写入: %s, 错误: %s" % [path, FileAccess.get_open_error()])
		return false
	
	# 写入内容
	file.store_buffer(processed_data)
	file.close()
	return true

## 执行删除操作
## [param path] 文件路径
## [return] 是否成功
func _execute_delete_operation(path: String) -> bool:
	var dir = DirAccess.open(path.get_base_dir())
	if not dir:
		push_error("无法访问目录: %s, 错误: %s" % [path.get_base_dir(), DirAccess.get_open_error()])
		return false
	
	var err = dir.remove(path)
	return err == OK

## 获取文件列表
func _get_file_list(file_directory: String) -> Array:
	var files : Array = []
	var dir := DirAccess.open(file_directory)

	if not dir:
		CoreSystem.logger.error("无法访问目录：%s" %file_directory)
	
	dir.list_dir_begin()
	var file_name := dir.get_next()

	while not file_name.is_empty():
		if not dir.current_is_dir():
			files.append(file_name)
		file_name = dir.get_next()

	return files

#endregion

#region 数据处理
## 处理数据（写入）
## [param data] 数据
## [param compression] 是否压缩
## [param encryption_key] 加密密钥
## [return] 处理后的数据
func _process_data_for_write(data: Variant, compression: bool, encryption_key: String = "") -> PackedByteArray:
	# 将数据转换为JSON字符串
	var json_str := JSON.stringify(data)
	var byte_array := json_str.to_utf8_buffer()
	
	# 压缩
	if compression:
		byte_array = byte_array.compress(FileAccess.COMPRESSION_GZIP)
	
	# 加密
	if not encryption_key.is_empty():
		var key := encryption_key.sha256_buffer()
		byte_array = _encrypt_data(byte_array, key)
	
	return byte_array

## 处理数据（读取）
## [param byte_array] 数据
## [param compression] 是否压缩
## [param encryption_key] 加密密钥
## [return] 处理后的数据
func _process_data_for_read(byte_array: PackedByteArray, compression: bool, encryption_key: String = "") -> Variant:
	# 解密
	if not encryption_key.is_empty():
		var key := encryption_key.sha256_buffer()
		byte_array = _decrypt_data(byte_array, key)
	
	# 解压
	if compression:
		byte_array = byte_array.decompress(byte_array.size() * 10, FileAccess.COMPRESSION_GZIP)
	
	# 解析JSON
	var json_str := byte_array.get_string_from_utf8()
	var json := JSON.new()
	var error := json.parse(json_str)
	if error == OK:
		return json.get_data()
	
	push_error("JSON解析错误: %s" % json.get_error_message())
	return null

## 加密数据
## [param data] 要加密的数据
## [param key] 密钥
## [return] 加密后的数据
func _encrypt_data(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	return encryption_provider.encrypt(data, key)

## 解密数据
## [param data] 要解密的数据
## [param key] 密钥
## [return] 解密后的数据
func _decrypt_data(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	return encryption_provider.decrypt(data, key)
#endregion

#region 工具方法
## 生成唯一任务ID
## [return] 任务ID
func _generate_task_id() -> String:
	_task_counter += 1
	return "%d_%d" % [Time.get_ticks_msec(), _task_counter]
#endregion

#region 信号处理
## 处理任务完成信号
func _on_task_completed(result: Variant, task_id: String) -> void:
	io_completed.emit(task_id, true, result)

## 处理任务错误信号
func _on_task_error(error: String, task_id: String) -> void:
	io_error.emit(task_id, error)
#endregion
