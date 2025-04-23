extends RefCounted

## 线程模块管理器
## 实现命名线程的管理系统，提供方便的接口创建和使用多个命名线程
## 每个命名线程独立工作并处理各自的任务队列

# 引用依赖
const SingleThread := CoreSystem.SingleThread

#region 信号定义
signal task_completed(result, task_id)  ## 任务完成信号（结果, 任务ID）
signal task_error(error, task_id)       ## 任务错误信号（错误信息, 任务ID）
#endregion

#region 私有变量
# 线程管理
var _threads: Dictionary = {}           ## 存储所有命名线程的映射表
#endregion

## 初始化模块线程管理器
func _init() -> void:
	_threads = {}

#region 公共API
## 向指定名称的线程提交任务
## [param thread_name] 线程名称，不存在则自动创建
## [param task_function] 要执行的任务函数
## [param callback] 任务完成后的回调函数
## [param call_deferred] 是否使用延迟调用执行任务
func submit_task(
	thread_name: StringName,
	task_function: Callable,
	callback: Callable = func(_result: Variant): pass,
	call_deferred: bool = true
) -> void:
	_ensure_thread_exists(thread_name)
	var thread = _threads[thread_name]
	thread.add_task(task_function, callback, call_deferred)

## 创建新的命名线程
## [param thread_name] 线程名称
## [return] 创建的SingleThread实例
func create_thread(thread_name: StringName) -> SingleThread:
	if has_thread(thread_name):
		push_warning("线程已存在: %s" % thread_name)
		return _threads[thread_name]
		
	var new_thread = SingleThread.new()
	_threads[thread_name] = new_thread
	
	# 连接信号
	_connect_thread_signals(new_thread, thread_name)
	print("线程已创建: %s" % thread_name)
	
	return new_thread

## 手动推进指定线程到下一个任务
## [param thread_name] 线程名称
func next_step(thread_name: StringName) -> void:
	if not has_thread(thread_name):
		push_warning("线程未找到: %s" % thread_name)
		return

	_threads[thread_name].next_step()

## 检查线程是否存在
## [param thread_name] 线程名称
## [return] 线程是否存在
func has_thread(thread_name: StringName) -> bool:
	return _threads.has(thread_name)

## 获取指定名称的线程
## [param thread_name] 线程名称
## [return] 线程实例，不存在则返回null
func get_thread(thread_name: StringName) -> SingleThread:
	return _threads.get(thread_name)

## 获取所有线程名称
## [return] 线程名称数组
func get_thread_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for key in _threads.keys():
		names.append(key)
	return names

## 获取线程总数
## [return] 当前管理的线程数量
func get_thread_count() -> int:
	return _threads.size()

## 卸载指定线程
## [param thread_name] 线程名称
func unload_thread(thread_name: StringName) -> void:
	if not has_thread(thread_name):
		print("线程不存在: %s" % thread_name)
		return
		
	var thread = _threads[thread_name]
	thread.stop()
	_threads.erase(thread_name)
	print("线程已卸载: %s" % thread_name)

## 清空所有线程
func clear_threads() -> void:
	var thread_names = get_thread_names()
	
	for thread_name in thread_names:
		var thread = _threads[thread_name]
		if thread:
			thread.stop()
	
	_threads.clear()
	print("已清空所有线程，共计: %d" % thread_names.size())
#endregion

#region 内部辅助方法
## 确保指定名称的线程存在
## [param thread_name] 线程名称
func _ensure_thread_exists(thread_name: StringName) -> void:
	if not has_thread(thread_name):
		create_thread(thread_name)

## 连接线程的信号
## [param thread] 线程实例
## [param thread_name] 线程名称
func _connect_thread_signals(thread: SingleThread, thread_name: StringName) -> void:
	thread.thread_finished.connect(_on_thread_finished.bind(thread_name))
	thread.task_completed.connect(_on_task_completed)
	thread.task_error.connect(_on_task_error)

## 当线程完成所有任务时的回调
## [param thread_name] 线程名称
func _on_thread_finished(thread_name: StringName) -> void:
	print("线程完成所有任务: %s" % thread_name)

## 当任务完成时的回调
## [param result] 任务执行结果
## [param task_id] 任务ID
func _on_task_completed(result: Variant, task_id: String) -> void:
	task_completed.emit(result, task_id)

## 当任务出错时的回调
## [param error] 错误信息
## [param task_id] 任务ID
func _on_task_error(error: String, task_id: String) -> void:
	task_error.emit(error, task_id)
#endregion
