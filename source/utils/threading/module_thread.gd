extends RefCounted

## 线程模块
## 提供命名线程管理功能，允许创建和管理多个命名线程
## 每个命名线程可以接收多个任务，并按顺序执行

const SingleThread := CoreSystem.SingleThread

## 任务完成信号（结果, 任务ID）
signal task_completed(result, task_id)
## 任务错误信号（错误信息, 任务ID）
signal task_error(error, task_id)

## 线程字典，存储所有已创建的命名线程
var _thread_dictionary: Dictionary[StringName, SingleThread] = {}

## 初始化函数
func _init() -> void:
	# 确保线程字典被初始化
	_thread_dictionary = {}

## 向指定名称的线程添加任务
## [param name] 线程名称，如果线程不存在会自动创建
## [param function] 要执行的函数
## [param callback] 任务完成后的回调函数
## [param call_deferred] 是否使用延迟调用执行任务
## 返回：无
func add_task(
	name: StringName,
	function: Callable,
	callback: Callable = func(_result: Variant): pass,
	call_deferred: bool = true,
) -> void:
	# 如果指定名称的线程不存在，则创建一个
	if not _thread_dictionary.has(name):
		create_thread(name)

	# 获取目标线程并添加任务
	var target_thread: SingleThread = _thread_dictionary.get(name) as SingleThread
	target_thread.add_task(function, callback, call_deferred)

## 提交任务到指定线程
## [param name] 线程名称
## [param function] 要执行的函数
## [param callback] 任务完成后的回调函数（可选）
## 返回：无
func submit_task(
	name: StringName,
	function: Callable,
	callback: Callable = func(_result: Variant): pass
) -> void:
	add_task(name, function, callback)

## 推进指定线程执行下一个任务
## [param name] 线程名称
## 返回：无
func next_step(name: StringName) -> void:
	if not _thread_dictionary.has(name):
		push_warning("线程未找到: %s" % name)
		return

	var target_thread: SingleThread = _thread_dictionary.get(name) as SingleThread
	target_thread.next_step()

## 创建一个新的命名线程
## [param name] 线程名称
## 返回：创建的SingleThread实例
func create_thread(name: StringName) -> SingleThread:
	var new_thread: SingleThread = SingleThread.new()
	_thread_dictionary[name] = new_thread
	print("线程已创建: %s" % name)
	
	# 连接信号
	new_thread.thread_finished.connect(unload_thread.bind(name))
	new_thread.task_completed.connect(_on_task_completed)
	new_thread.task_error.connect(_on_task_error)
	
	return new_thread

## 当任务完成时的回调
## [param result] 任务执行结果
## [param task_id] 任务ID
func _on_task_completed(result: Variant, task_id: String) -> void:
	# 转发信号
	task_completed.emit(result, task_id)

## 当任务出错时的回调
## [param error] 错误信息
## [param task_id] 任务ID
func _on_task_error(error: String, task_id: String) -> void:
	# 转发信号
	task_error.emit(error, task_id)

## 检查线程是否存在
## [param name] 线程名称
## 返回：线程是否存在
func has_thread(name: StringName) -> bool:
	return _thread_dictionary.has(name)

## 获取指定名称的线程
## [param name] 线程名称
## 返回：线程实例，如果不存在则返回null
func get_thread(name: StringName) -> SingleThread:
	if not _thread_dictionary.has(name):
		return null
	return _thread_dictionary[name]

## 获取所有线程名称
## 返回：线程名称数组
func get_thread_names() -> Array[StringName]:
	return _thread_dictionary.keys()

## 获取线程总数
## 返回：当前管理的线程数量
func get_thread_count() -> int:
	return _thread_dictionary.size()

## 清空所有线程
## 返回：无
func clear_threads() -> void:
	# 遍历并停止所有线程
	for thread_name in _thread_dictionary.keys():
		var thread = _thread_dictionary[thread_name]
		if thread:
			thread.stop()
	
	# 清空线程字典
	var thread_names: Array[StringName] = _thread_dictionary.keys()
	_thread_dictionary.clear()
	for thread_name in thread_names:
		print("线程已卸载: %s" % thread_name)

## 卸载指定线程
## [param name] 线程名称
## 返回：无
func unload_thread(name: StringName) -> void:
	if _thread_dictionary.has(name):
		var thread = _thread_dictionary[name]
		if thread:
			thread.stop()
		_thread_dictionary.erase(name)
		print("线程已卸载: %s" % name)
	else:
		print("线程已被卸载: %s" % name)
