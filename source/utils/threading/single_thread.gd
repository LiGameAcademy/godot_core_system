extends RefCounted

## 简化的单线程工作器
## 实现基本的异步任务执行功能，用于验证线程测试

signal task_completed(result, task_id)
signal thread_finished()

var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore
var _is_running: bool = true
var _task_queue = []
var _task_id_counter = 0

func _init():
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	_thread.start(_thread_function)

func _notification(what):
	if what == NOTIFICATION_PREDELETE and is_instance_valid(self):
		stop()

## 添加任务到队列
func add_task(task_func: Callable) -> int:
	_mutex.lock()
	var task_id = _task_id_counter
	_task_id_counter += 1
	_task_queue.append({"id": task_id, "func": task_func})
	_mutex.unlock()
	
	_semaphore.post()
	return task_id

## 获取待处理任务数
func get_pending_task_count() -> int:
	_mutex.lock()
	var count = _task_queue.size()
	_mutex.unlock()
	return count

## 停止线程
func stop():
	if not _thread or not _thread.is_alive():
		return
		
	_mutex.lock()
	_is_running = false
	_mutex.unlock()
	
	_semaphore.post()  # 唤醒线程以处理终止信号
	_thread.wait_to_finish() 

## 工作线程主函数
func _thread_function():
	while _is_running:
		_semaphore.wait()
		
		if not _is_running:
			break
			
		var task = null
		_mutex.lock()
		if not _task_queue.is_empty():
			task = _task_queue.pop_front()
		_mutex.unlock()
		
		if task:
			var result = null
			# 执行任务并获取结果
			result = task.func.call()
			
			# 使用 CallDeferred 安全地从主线程发出信号
			call_deferred("_emit_task_completed", result, task.id)
			
	CoreSystem.logger.info("线程已停止")

## 从主线程发出任务完成信号
func _emit_task_completed(result, task_id):
	task_completed.emit(result, task_id)
	
	# 检查是否所有任务已完成
	_mutex.lock()
	var queue_empty : bool = _task_queue.is_empty()
	_mutex.unlock()
	
	if queue_empty:
		thread_finished.emit()
