extends RefCounted

## 线程池
## 用于管理和复用多个线程来处理并发任务
## 主要功能：
## 1. 线程管理：自动创建和管理线程池
## 2. 任务分发：将任务分配给空闲线程
## 3. 任务队列：当所有线程都忙时，将任务加入队列
## 4. 结果回调：支持任务完成后的回调处理
##
## 使用示例：
## ```gdscript
## # 创建一个有4个线程的线程池
## var pool = ThreadPool.new(4)
##
## # 提交任务
## pool.submit_task(func(): 
##     # 执行耗时操作
##     return result
## , func(result):
##     # 处理结果
##     print("任务完成，结果：", result)
## )
## ```

## 任务完成信号
signal task_completed(task_id: String, result: Variant)
## 任务错误信号
signal task_error(task_id: String, error: String)

## 线程池大小
var pool_size: int = 4

## 任务队列
var _task_queue: Array = []
## 线程列表
var _threads: Array[Thread] = []
## 信号量：用于任务调度
var _semaphore: Semaphore
## 互斥锁：用于保护共享资源
var _mutex: Mutex
## 运行标志
var _running: bool = true
## 任务计数器
var _task_counter: int = 0

## 线程状态
class ThreadState:
	var thread: Thread  # 线程对象
	var is_busy: bool = false  # 是否正在执行任务
	var current_task  # 当前任务

## 任务对象
class Task:
	var id: String  # 任务ID
	var work_func: Callable  # 工作函数
	var callback: Callable  # 回调函数
	
	func _init(p_id: String, p_work: Callable, p_callback: Callable = func(_r): pass):
		id = p_id
		work_func = p_work
		callback = p_callback

## 构造函数
## [param p_pool_size] 线程池大小，默认为4
func _init(p_pool_size: int = 4) -> void:
	pool_size = p_pool_size
	_semaphore = Semaphore.new()
	_mutex = Mutex.new()
	_init_threads()

## 初始化线程池
func _init_threads() -> void:
	for i in range(pool_size):
		var thread := Thread.new()
		thread.start(_thread_function.bind(i))
		_threads.append(thread)

## 提交任务
## [param work_func] 工作函数，将在线程中执行
## [param callback] 可选的回调函数，在主线程中执行
## [return] 任务ID
func submit_task(work_func: Callable, callback: Callable = func(_r): pass) -> String:
	_mutex.lock()
	var task_id = str(_task_counter)
	_task_counter += 1
	var task = Task.new(task_id, work_func, callback)
	_task_queue.append(task)
	_mutex.unlock()
	_semaphore.post()  # 通知线程有新任务
	return task_id

## 线程函数
## [param thread_id] 线程ID
func _thread_function(thread_id: int) -> void:
	while _running:
		_semaphore.wait()  # 等待任务
		
		if not _running:
			break
			
		var task: Task
		_mutex.lock()
		if not _task_queue.is_empty():
			task = _task_queue.pop_front()
		_mutex.unlock()
		
		if task:
			var result = null
			var error = null
			
			if task.work_func.is_valid():
				result = task.work_func.call()
				if result != null:
					# 在主线程中调用回调
					call_deferred("_handle_task_completion", task.id, result, task.callback)
				else:
					error = "任务执行失败：返回值为null"
					call_deferred("_handle_task_error", task.id, error)
			else:
				error = "任务执行失败：无效的工作函数"
				call_deferred("_handle_task_error", task.id, error)

## 处理任务完成
## [param task_id] 任务ID
## [param result] 任务结果
## [param callback] 回调函数
func _handle_task_completion(task_id: String, result: Variant, callback: Callable) -> void:
	if callback.is_valid():
		callback.call(result)
	task_completed.emit(task_id, result)

## 处理任务错误
## [param task_id] 任务ID
## [param error] 错误信息
func _handle_task_error(task_id: String, error: String) -> void:
	task_error.emit(task_id, error)

## 停止所有线程
func stop() -> void:
	_running = false
	# 发送足够的信号以唤醒所有线程
	for i in range(pool_size):
		_semaphore.post()
	# 等待所有线程完成
	for thread in _threads:
		if thread.is_started():
			thread.wait_to_finish()

## 获取当前队列中的任务数量
func get_pending_tasks() -> int:
	_mutex.lock()
	var count = _task_queue.size()
	_mutex.unlock()
	return count

## 清空任务队列
func clear_queue() -> void:
	_mutex.lock()
	_task_queue.clear()
	_mutex.unlock()
