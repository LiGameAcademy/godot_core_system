extends Node

## 异步IO管理器
## 提供三个层次的API：
## 1. 基础API - 简单的异步读写操作
## 2. 进阶API - 支持压缩功能
## 3. 完整API - 支持压缩和加密功能

# 信号
## IO完成
signal io_completed(task_id: String, success: bool, result: Variant)
## IO错误
signal io_error(task_id: String, error: String)

## IO任务类型
enum TaskType {
	READ,   # 读取
	WRITE,  # 写入
	DELETE  # 删除
}

## IO任务状态
enum TaskStatus {
	PENDING,   # 未开始
	RUNNING,   # 运行中
	COMPLETED, # 完成
	ERROR      # 错误
}

# 私有变量
var _tasks: Array[IOTask] = []
var _io_thread: CoreSystem.SingleThread
var _task_counter: int = 0  # 任务计数器

## 加密提供者
var encryption_provider: EncryptionProvider:
	get:
		if not _encryption_provider:
			_encryption_provider = XOREncryptionProvider.new()
		return _encryption_provider
	set(value):
		_encryption_provider = value

## 内部加密提供者实例
var _encryption_provider: EncryptionProvider = null

func _init(_data:Dictionary = {}):
	_io_thread = CoreSystem.SingleThread.new()
	_io_thread.task_completed.connect(_on_task_completed)
	_io_thread.task_error.connect(_on_task_error)

func _exit() -> void:
	if _io_thread:
		_io_thread.stop()

## 处理任务完成
func _on_task_completed(result: Variant, task_id: String) -> void:
	io_completed.emit(task_id, true, result)

## 处理任务错误
func _on_task_error(error: String, task_id: String) -> void:
	io_error.emit(task_id, error)

## 异步读取文件（基础版本）
## [param path] 文件路径
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func read_file(path: String, callback: Callable = func(_s, _r): pass) -> String:
	return read_file_async(path, false, "", callback)

## 异步写入文件（基础版本）
## [param path] 文件路径
## [param data] 要写入的数据
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func write_file(path: String, data: Variant, callback: Callable = func(_s, _r): pass) -> String:
	return write_file_async(path, data, false, "", callback)

## 异步删除文件（基础版本）
## [param path] 文件路径
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func delete_file(path: String, callback: Callable = func(_s, _r): pass) -> String:
	return delete_file_async(path, callback)

## 异步读取文件（进阶版本）
## [param path] 文件路径
## [param use_compression] 是否使用压缩
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func read_file_advanced(path: String, use_compression: bool = false, callback: Callable = func(_s, _r): pass) -> String:
	return read_file_async(path, use_compression, "", callback)

## 异步写入文件（进阶版本）
## [param path] 文件路径
## [param data] 要写入的数据
## [param use_compression] 是否使用压缩
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func write_file_advanced(path: String, data: Variant, use_compression: bool = false, callback: Callable = func(_s, _r): pass) -> String:
	return write_file_async(path, data, use_compression, "", callback)

## 异步读取文件
## [param path] 文件路径
## [param use_compression] 是否使用压缩
## [param encryption_key] 加密密钥
## [param callback] 回调函数
## [return] 任务ID
func read_file_async(path: String, use_compression: bool = false, encryption_key: String = "", callback: Callable = func(_s, _r): pass) -> String:
	var task_id = str(_task_counter)
	_task_counter += 1
	var work_func : Callable = func():
		var file = FileAccess.open(path, FileAccess.READ)
		if not file:
			push_error("Failed to open file: " + path)
			return null
		
		var content = file.get_buffer(file.get_length())
		file.close()
		
		return _process_data_for_read(content, use_compression, encryption_key)
	var callback_func : Callable = func(result):
		if result != null:
			callback.call(true, result)
		else:
			callback.call(false, null)

	_io_thread.add_task(work_func, callback_func)
	
	return task_id

## 异步写入文件
## [param path] 文件路径
## [param data] 要写入的数据
## [param use_compression] 是否使用压缩
## [param encryption_key] 加密密钥
## [param callback] 回调函数
## [return] 任务ID
func write_file_async(
		path: String, 
		data: Variant, 
		use_compression: bool = false, 
		encryption_key: String = "", 
		callback: Callable = Callable()) -> String:
	var task_id = str(_task_counter)
	_task_counter += 1

	var work_func : Callable = func():
		var processed_data = _process_data_for_write(data, use_compression, encryption_key)
		var file = FileAccess.open(path, FileAccess.WRITE)
		if not file:
			push_error("Failed to open file for writing: " + path)
			return false
		
		file.store_buffer(processed_data)
		file.close()
		return true

	var callback_func : Callable = func(success):
		if callback.is_valid():
			callback.call(success, null)
		
	_io_thread.add_task(work_func,callback_func)
	
	return task_id

## 异步删除文件
## [param path] 文件路径
## [param callback] 回调函数
## [return] 任务ID
func delete_file_async(path: String, callback: Callable = Callable()) -> String:
	var task_id = str(_task_counter)
	_task_counter += 1
	
	var work_func : Callable = func():
		var dir = DirAccess.open(path.get_base_dir())
		if not dir:
			push_error("Failed to access directory: " + path.get_base_dir())
			return false
		
		var err = dir.remove(path)
		return err == OK

	var callback_func : Callable = func(success):
		if callback.is_valid():
			callback.call(success, null)

	_io_thread.add_task(work_func, callback_func)
	
	return task_id

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

## IO任务
class IOTask:
	## 任务ID
	var id: String
	## 任务类型
	var type: TaskType
	## 路径
	var path: String
	## 数据
	var data: Variant
	## 状态
	var status: TaskStatus
	## 错误
	var error: String
	## 回调
	var callback: Callable
	## 压缩
	var compression: bool
	## 加密密钥, 为空表示不加密
	var encryption_key: String
	
	func _init(
		_id: String, 
		_type: TaskType, 
		_path: String, 
		_data: Variant = null,
		_compression: bool = false,
		_encryption_key: String = "",
		_callback: Callable = func(_s, _r): pass
	) -> void:
		id = _id
		type = _type
		path = _path
		data = _data
		status = TaskStatus.PENDING
		compression = _compression
		encryption_key = _encryption_key
		callback = _callback
