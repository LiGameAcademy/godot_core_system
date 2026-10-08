extends RefCounted

## Single worker owned by its caller. Call stop() on the main thread before release.
signal task_completed(result: Variant, task_id: int)
signal thread_finished()

var _thread: Thread = Thread.new()
var _mutex: Mutex = Mutex.new()
var _semaphore: Semaphore = Semaphore.new()
var _is_running: bool = true
var _task_queue: Array[Dictionary] = []
var _task_id_counter: int = 0

func _init() -> void:
	_thread.start(_thread_function)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(self):
		stop()

## Returns -1 when this worker has stopped.
func add_task(task_func: Callable) -> int:
	_mutex.lock()
	if not _is_running or not task_func.is_valid():
		_mutex.unlock()
		return -1
	var task_id: int = _task_id_counter
	_task_id_counter += 1
	_task_queue.append({"id": task_id, "func": task_func})
	_mutex.unlock()
	_semaphore.post()
	return task_id

func get_pending_task_count() -> int:
	_mutex.lock()
	var count: int = _task_queue.size()
	_mutex.unlock()
	return count

## Cancel queued work and completion notifications, and join a running task.
## Running functions cannot be interrupted; they must finish for stop() to return.
func stop() -> void:
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		push_error("SingleThread.stop must be called by its owner, outside its worker.")
		return
	_mutex.lock()
	_is_running = false
	var canceled: Array[Dictionary] = _task_queue
	_task_queue = []
	_mutex.unlock()
	# Captured objects may run destructors; release them outside the worker lock.
	canceled.clear()
	if _thread.is_started():
		_semaphore.post()
		_thread.wait_to_finish()

func _thread_function() -> void:
	while true:
		_semaphore.wait()
		_mutex.lock()
		if not _is_running:
			_mutex.unlock()
			break
		var task: Dictionary = {} if _task_queue.is_empty() else _task_queue.pop_front()
		_mutex.unlock()
		if not task.is_empty():
			var callback: Callable = task["func"]
			var result: Variant = callback.call()
			call_deferred("_emit_task_completed", result, task["id"])

func _emit_task_completed(result: Variant, task_id: int) -> void:
	_mutex.lock()
	var running: bool = _is_running
	_mutex.unlock()
	if not running:
		return
	task_completed.emit(result, task_id)
	# A completion callback may stop the worker or submit another task.
	_mutex.lock()
	var queue_empty: bool = _is_running and _task_queue.is_empty()
	_mutex.unlock()
	if queue_empty:
		thread_finished.emit()
