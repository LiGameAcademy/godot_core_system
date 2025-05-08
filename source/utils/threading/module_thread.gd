# module_thread.gd
extends RefCounted

## 命名线程管理器
## 管理多个命名的 SingleThread 实例，用于组织和隔离不同类型的后台任务。

const SingleThread = preload("./single_thread.gd")

# --- 信号 ---
## 当某个命名线程上的任务完成时发出
signal task_completed_on_thread(thread_name: StringName, result: Variant, task_id: String) # task_id 现在是 String
## 当某个命名线程完成其所有任务时发出 (如果 SingleThread 支持)
signal all_tasks_finished_on_thread(thread_name: StringName)

# --- 私有变量 ---
var _threads: Dictionary = {}     # 存储: { StringName: SingleThread }
var _mutex := Mutex.new()        # 保护 _threads 字典的访问
var _logger : CoreSystem.Logger = CoreSystem.logger # 假设 Logger 可用

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		clear_threads() # 确保清理

# --- 公共 API ---

## 向指定名称的线程提交任务。如果线程不存在，则自动创建。
## [param thread_name] 目标线程的名称
## [param task_func] 要在后台线程执行的 Callable
## [return] 公开的任务 ID (String)，或空字符串表示失败
func submit_task(thread_name: StringName, task_func: Callable) -> String:
	_mutex.lock()
	var thread = _ensure_thread_exists_internal(thread_name) # 内部方法，已加锁
	_mutex.unlock()

	if not thread:
		_logger.error("ModuleThread: Failed to create or get thread '%s'." % thread_name)
		return ""

	# SingleThread.add_task 现在返回 String ID
	var public_task_id = thread.add_task(task_func)
	# 注意：我们不再需要 ID 映射，因为 SingleThread 已返回 String ID
	return public_task_id

## 显式创建指定名称的线程。如果已存在则返回现有线程。
## 注意：不推荐直接操作返回的线程，应通过 submit_task。
func create_thread(thread_name: StringName) -> SingleThread:
	_mutex.lock()
	var thread = _ensure_thread_exists_internal(thread_name)
	_mutex.unlock()
	return thread # 返回实例，但不鼓励直接使用

## 检查指定名称的线程是否存在
func has_thread(thread_name: StringName) -> bool:
	_mutex.lock()
	var exists = _threads.has(thread_name)
	_mutex.unlock()
	return exists

## 停止并移除指定名称的线程
func unload_thread(thread_name: StringName) -> void:
	_mutex.lock()
	if _threads.has(thread_name):
		var thread: SingleThread = _threads[thread_name]
		_disconnect_thread_signals(thread) # 先断开信号连接
		thread.stop() # 停止线程
		_threads.erase(thread_name) # 从字典移除
		_logger.info("ModuleThread: Unloaded thread '%s'." % thread_name)
	else:
		_logger.warning("ModuleThread: Thread '%s' not found for unloading." % thread_name)
	_mutex.unlock()

## 停止并移除所有管理的线程
func clear_threads() -> void:
	_mutex.lock()
	var thread_names = _threads.keys() # 获取副本以安全迭代
	_logger.info("ModuleThread: Clearing all threads (%d)..." % thread_names.size())
	for thread_name in thread_names:
		var thread: SingleThread = _threads[thread_name]
		_disconnect_thread_signals(thread)
		thread.stop()
	_threads.clear()
	_mutex.unlock()
	_logger.info("ModuleThread: All threads cleared.")

# --- 内部辅助方法 ---

## (内部) 确保线程存在，如果不存在则创建并连接信号。必须在持有锁时调用。
func _ensure_thread_exists_internal(thread_name: StringName) -> SingleThread:
	if _threads.has(thread_name):
		return _threads[thread_name]
	else:
		_logger.info("ModuleThread: Creating new thread '%s'." % thread_name)
		var new_thread := SingleThread.new()
		_threads[thread_name] = new_thread
		_connect_thread_signals(new_thread, thread_name) # 连接信号以实现聚合
		return new_thread

## (内部) 连接单个线程的信号到管理器的处理函数
func _connect_thread_signals(thread: SingleThread, thread_name: StringName) -> void:
	# 使用 bind 将 thread_name 传递给处理函数
	thread.task_completed.connect(_on_single_thread_task_completed.bind(thread_name))
	# 假设 SingleThread 也有 thread_finished 信号
	if thread.has_signal("thread_finished"):
		thread.thread_finished.connect(_on_single_thread_finished.bind(thread_name))

## (内部) 断开单个线程的信号
func _disconnect_thread_signals(thread: SingleThread) -> void:
	# 确保信号确实已连接再断开，防止错误
	if thread.task_completed.is_connected(_on_single_thread_task_completed):
		thread.task_completed.disconnect(_on_single_thread_task_completed)
	if thread.has_signal("thread_finished") and thread.thread_finished.is_connected(_on_single_thread_finished):
		thread.thread_finished.disconnect(_on_single_thread_finished)

# --- 内部信号处理 (聚合) ---

## (内部) 处理来自某个 SingleThread 的 task_completed 信号
func _on_single_thread_task_completed(result: Variant, task_id: String, thread_name: StringName) -> void:
	# 重新发出聚合信号，添加 thread_name
	task_completed_on_thread.emit(thread_name, result, task_id)

## (内部) 处理来自某个 SingleThread 的 thread_finished 信号
func _on_single_thread_finished(thread_name: StringName) -> void:
	# 重新发出聚合信号
	all_tasks_finished_on_thread.emit(thread_name)
