extends RefCounted

## 单线程工作器
## 实现生产者消费者模式的轻量级线程封装，用于执行一系列异步任务

#region 信号定义
signal thread_finished						## 所有任务完成信号
signal task_completed(result, task_id)		## 任务完成信号（结果, 任务ID）
signal task_error(error, task_id)			## 任务错误信号（错误信息, 任务ID）
#endregion

#region 私有变量
# 线程同步
var _mutex: Mutex
var _semaphore: Semaphore
var _thread: Thread

# 线程状态
var _is_running: bool = true						## 是否正在运行
var _can_process_next_task: bool = false			## 是否可以处理下一个任务

# 任务管理
var _task_counter: int = 0							## 任务计数器
var _task_queue: Array[Task] = []					## 任务队列
var _active_tasks: Array[Task] = []					## 正在执行的任务列表
#endregion

## 初始化线程和同步原语
func _init() -> void:
	_initialize_sync_primitives()
	_start_worker_thread()

## 析构通知处理
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_shutdown_thread()

#region 线程管理方法
## 初始化同步原语
func _initialize_sync_primitives() -> void:
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()

## 启动工作线程
func _start_worker_thread() -> void:
	_thread.start(_worker_thread_main)

## 工作线程主函数 - 消费者
func _worker_thread_main() -> void:
	while _is_thread_active():
		# 等待任务信号
		_wait_for_task()
		
		# 检查线程状态
		if not _is_thread_active():
			break
			
		# 获取并执行下一个任务
		var next_task = _get_next_task()
		if next_task != null:
			_execute_task(next_task)

## 等待新任务
func _wait_for_task() -> void:
	_semaphore.wait()

## 检查线程是否应该继续运行
func _is_thread_active() -> bool:
	_mutex.lock()
	var active = _is_running
	_mutex.unlock()
	return active

## 从队列获取下一个任务
func _get_next_task() -> Task:
	_mutex.lock()
	
	var next_task: Task = null
	if not _task_queue.is_empty():
		next_task = _task_queue.pop_front()
		_can_process_next_task = true
		_active_tasks.append(next_task)
	
	_mutex.unlock()
	return next_task

## 执行任务
func _execute_task(task: Task) -> void:
	task.task_finished.connect(_on_task_finished, CONNECT_ONE_SHOT)
	task.process_function()

## 安全终止线程
func _shutdown_thread() -> void:
	_mutex.lock()
	_is_running = false
	_mutex.unlock()
	
	# 唤醒线程以处理终止信号
	_semaphore.post()
	_thread.wait_to_finish()
#endregion

#region 任务处理方法
## 处理任务完成事件
## [param task] 完成的任务
func _on_task_finished(task: Task) -> void:
	_remove_active_task(task)
	_emit_task_result(task)
	_check_queue_status()

## 从活动任务列表中移除任务
func _remove_active_task(task: Task) -> void:
	_active_tasks.erase(task)

## 发出任务结果信号
func _emit_task_result(task: Task) -> void:
	if task.has_error:
		task_error.emit(task.error_message, task.id)
	else:
		task_completed.emit(task.result, task.id)

## 检查队列状态并在空闲时发出信号
func _check_queue_status() -> void:
	if _is_queue_empty() and _active_tasks.is_empty():
		thread_finished.emit()

## 检查队列是否为空
func _is_queue_empty() -> bool:
	_mutex.lock()
	var is_empty = _task_queue.is_empty()
	_mutex.unlock()
	return is_empty

## 生成唯一任务ID
func _generate_task_id() -> String:
	_mutex.lock()
	_task_counter += 1
	var counter = _task_counter
	_mutex.unlock()
	return "%d_%d" % [Time.get_ticks_msec(), counter]
#endregion

#region 公共API

## 添加任务到队列 - 生产者
## [param task_function] 任务执行函数
## [param task_callback] 任务完成回调函数
## [param call_deferred] 是否使用延迟调用执行任务
func add_task(
		task_function: Callable, 
		task_callback: Callable = func(_result: Variant): pass, 
		call_deferred: bool = true) -> void:
	var new_task = Task.new(_generate_task_id(), task_function, task_callback, call_deferred)
	
	_mutex.lock()
	var was_queue_empty = _task_queue.is_empty()
	var can_auto_advance = _can_process_next_task
	_task_queue.append(new_task)
	_mutex.unlock()
	
	# 如果队列之前为空且没有自动推进，则发送信号
	if was_queue_empty and not can_auto_advance:
		_semaphore.post()

## 手动推进到下一个任务
func next_step() -> void:
	if _is_queue_empty():
		_reset_task_state()
		return
		
	_semaphore.post()
	
## 重置任务状态
func _reset_task_state() -> void:
	_mutex.lock()
	_task_counter = 0
	_can_process_next_task = false
	_mutex.unlock()

## 获取当前任务计数
## [return] 当前任务计数
func get_index() -> int:
	_mutex.lock()
	var counter = _task_counter
	_mutex.unlock()
	return counter

## 获取待处理任务数量
## [return] 待处理任务数量
func get_pending_task_count() -> int:
	_mutex.lock()
	var count = _task_queue.size()
	_mutex.unlock()
	return count

## 获取运行中任务数量
## [return] 运行中任务数量
func get_running_task_count() -> int:
	_mutex.lock()
	var count = _active_tasks.size()
	_mutex.unlock()
	return count

## 清空任务队列
func clear_pending_tasks() -> void:
	_mutex.lock()
	_task_queue.clear()
	_mutex.unlock()

## 停止线程工作
func stop() -> void:
	_shutdown_thread()
#endregion

## 任务类，表示一个可执行的工作单元
class Task:
	## 任务完成信号
	signal task_finished(task: Task)

	## 任务属性
	var id: String
	var task_function: Callable
	var task_callback: Callable
	var call_deferred: bool
	
	## 任务结果
	var result: Variant
	var has_error: bool = false
	var error_message: String = ""

	## 任务初始化
	func _init(
		p_id: String,
		p_task_function: Callable = Callable(),
		p_task_callback: Callable = func(_result: Variant): pass,
		p_call_deferred: bool = true,
	) -> void:
		id = p_id
		task_function = p_task_function
		task_callback = p_task_callback
		call_deferred = p_call_deferred

	## 开始执行任务
	func process_function() -> void:
		if call_deferred:
			process_callback.call_deferred(task_function, task_callback)
		else:
			process_callback.call(task_function, task_callback)

	## 处理任务回调
	func process_callback(function: Callable, callback: Callable) -> void:
		print("任务函数开始执行: %s" % id)
		
		# 执行任务并捕获可能的错误
		_execute_function(function)
		
		# 如果没有错误且回调有效，执行回调
		if not has_error and callback.is_valid():
			_execute_callback(callback)

		# 发出任务完成信号
		task_finished.emit(self)
	
	## 执行任务函数
	func _execute_function(function: Callable) -> void:
		has_error = false
		error_message = ""
		
		if function.is_valid():
			result = function.call()
			CoreSystem.logger.debug("任务函数执行完成: %s" % id)
		else:
			has_error = true
			error_message = "任务函数无效: %s" % id
			CoreSystem.logger.error(error_message)
	
	## 执行回调函数
	func _execute_callback(callback: Callable) -> void:
		CoreSystem.logger.debug("任务回调开始执行: %s" % id)
		callback.call(result)
		CoreSystem.logger.debug("任务回调执行完成: %s" % id)
