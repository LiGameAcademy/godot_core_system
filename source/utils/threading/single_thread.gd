extends RefCounted

## 单线程工作器
## 一个轻量级的线程封装，用于执行一系列异步任务
## 任务按顺序提交并执行，可以在任务间控制执行流程

## 所有任务完成信号
signal thread_finished
## 任务完成信号（结果, 任务ID）
signal task_completed(result, task_id)
## 任务错误信号（错误信息, 任务ID）
signal task_error(error, task_id)

## 线程互斥锁，用于保护共享数据
var _mutex: Mutex

## 线程信号量，用于控制任务执行节奏
var _semaphore: Semaphore

## 线程对象
var _thread: Thread

## 线程运行状态标志
var _thread_running: bool

## 任务索引计数器
var _task_index: int

## 任务可以推进的标志
var _task_can_advance: bool

## 等待执行的任务队列
var _task_pending_list: Array[Task]

## 正在执行的任务列表
var _task_running_list: Array[Task]

## 初始化函数，创建必要的线程控制对象
func _init() -> void:
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()

	_thread = Thread.new()
	_thread_running = true

	_task_index = 0
	_task_can_advance = false
	
	_task_pending_list = []
	_task_running_list = []

	# 启动工作线程
	_thread.start(_thread_function)

## 析构通知处理，确保线程正确清理
func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE: 
		return
	_unload_thread()

## 线程工作函数，处理任务队列中的任务
func _thread_function():
	while _thread_running:
		# 等待新任务信号
		_semaphore.wait()

		# 检查是否应该终止线程
		if not _thread_running: 
			break

		# 从队列中获取下一个任务
		_mutex.lock()
		var next_task: Task
		if not _task_pending_list.is_empty():
			next_task = _task_pending_list.pop_front()
		_mutex.unlock()

		# 如果没有获取到任务，继续等待
		if next_task == null: 
			continue

		# 将任务添加到运行列表，并设置可推进标志
		_mutex.lock()
		_task_can_advance = true
		_task_running_list.append(next_task)
		_mutex.unlock()

		# 连接任务完成信号并执行任务
		next_task.task_finished.connect(_on_task_finished, CONNECT_ONE_SHOT)
		next_task.process_function()

## 任务完成回调处理
## [param task] 已完成的任务
func _on_task_finished(task: Task) -> void:
	# 从运行列表中移除已完成任务
	_task_running_list.erase(task)
	
	# 发出任务完成信号
	if task.has_error:
		task_error.emit(task.error_message, task.id)
	else:
		task_completed.emit(task.result, task.id)
	
	# 如果没有更多任务，发出线程完成信号
	if _task_pending_list.is_empty() && _task_running_list.is_empty():
		thread_finished.emit()

## 卸载线程，确保线程安全终止
func _unload_thread() -> void:
	# 设置线程终止标志
	_mutex.lock()
	_thread_running = false
	_mutex.unlock()
	
	# 发送信号让线程跳出等待状态
	_semaphore.post()
	
	# 等待线程完成
	_thread.wait_to_finish()

## 生成唯一任务ID
## 返回：任务ID字符串
func _generate_task_id() -> String:
	_mutex.lock()
	_task_index += 1
	var counter: int = _task_index
	_mutex.unlock()
	return "%d_%d" % [Time.get_ticks_msec(), counter]

## 添加任务到队列
## [param task_function] 任务执行函数
## [param task_callback] 任务完成回调函数
## [param call_deferred] 是否使用延迟调用执行任务
## 返回：无
func add_task(
	task_function: Callable,
	task_callback: Callable = func(_result: Variant): pass,
	call_deferred: bool = true,
) -> void:
	# 创建新任务
	var new_task: Task = Task.new(
		_generate_task_id(),
		task_function,
		task_callback,
		call_deferred,
	)

	# 添加任务到队列
	_mutex.lock()
	var thread_was_empty: bool = _task_pending_list.is_empty()
	var thread_can_advance: bool = _task_can_advance
	_task_pending_list.append(new_task)
	_mutex.unlock()

	# 如果线程空闲且不能自动推进，则发送信号启动任务
	if thread_was_empty && !thread_can_advance:
		_semaphore.post()

## 推进到下一个任务
## 返回：无
func next_step() -> void:
	# 如果没有更多任务，重置状态
	if _task_pending_list.is_empty():
		_mutex.lock()
		_task_index = 0
		_task_can_advance = false
		_mutex.unlock()
		return

	# 发送信号执行下一个任务
	_semaphore.post()

## 获取当前任务索引
## 返回：当前任务索引
func get_index() -> int:
	_mutex.lock()
	var current_index: int = _task_index
	_mutex.unlock()
	return current_index

## 获取待处理任务数量
## 返回：待处理任务数量
func get_pending_task_count() -> int:
	_mutex.lock()
	var count: int = _task_pending_list.size()
	_mutex.unlock()
	return count

## 获取运行中任务数量
## 返回：运行中任务数量
func get_running_task_count() -> int:
	_mutex.lock()
	var count: int = _task_running_list.size()
	_mutex.unlock()
	return count

## 清空任务队列
## 返回：无
func clear_pending_tasks() -> void:
	_mutex.lock()
	_task_pending_list.clear()
	_mutex.unlock()

## 停止线程工作
func stop() -> void:
	_unload_thread()

## 任务类，表示一个可执行的工作单元
class Task:
	## 任务完成信号
	signal task_finished(task: Task)

	## 任务唯一标识符
	var id: String
	
	## 任务执行函数
	var task_function: Callable
	
	## 任务完成回调函数
	var task_callback: Callable
	
	## 是否使用延迟调用
	var call_deferred: bool
	
	## 任务执行结果
	var result: Variant
	
	## 是否有错误
	var has_error: bool = false
	
	## 错误信息
	var error_message: String = ""

	## 任务初始化
	## [param _id] 任务ID
	## [param _task_function] 任务执行函数
	## [param _task_callback] 任务完成回调函数
	## [param _call_deferred] 是否使用延迟调用
	func _init(
		_id: String,
		_task_function: Callable = Callable(),
		_task_callback: Callable = func(_result: Variant): pass,
		_call_deferred: bool = true,
	) -> void:
		id = _id
		task_function = _task_function
		task_callback = _task_callback
		call_deferred = _call_deferred

	## 处理任务回调
	## [param function] 要执行的函数
	## [param callback] 回调函数
	func process_callback(function: Callable, callback: Callable) -> void:
		print("任务函数开始执行: %s" % id)
		
		# 执行任务函数并捕获可能的错误
		has_error = false
		error_message = ""
		
		# GDScript中没有直接的try-catch，使用push_error代替
		if function.is_valid():
			result = function.call()
			print("任务函数执行完成: %s" % id)
			
			# 如果回调有效，执行回调
			if not has_error and callback.is_valid():
				print("任务回调开始执行: %s" % id)
				callback.call(result)
				print("任务回调执行完成: %s" % id)
		else:
			has_error = true
			error_message = "任务函数无效: %s" % id
			push_error(error_message)

		# 发出任务完成信号
		task_finished.emit(self)

	## 开始执行任务
	func process_function() -> void:
		if call_deferred:
			process_callback.call_deferred(task_function, task_callback)
		else:
			process_callback.call(task_function, task_callback)
