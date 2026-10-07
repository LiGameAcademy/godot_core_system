extends RefCounted

## 管理多个命名线程，公开 String ID 与 SingleThread 的局部 int ID 分离。
const SingleThread = preload("./single_thread.gd")

signal task_completed_on_thread(thread_name: StringName, result: Variant, task_id: String)
signal all_tasks_finished_on_thread(thread_name: StringName)

var _threads: Dictionary[StringName, SingleThread] = {}
var _task_ids: Dictionary[StringName, Dictionary] = {}
var _next_task_id: int = 0
var _mutex: Mutex = Mutex.new()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(self):
		clear_threads()

## 返回此管理器生命周期内唯一的 String ID；失败返回空字符串。
func submit_task(thread_name: StringName, task_func: Callable) -> String:
	if not task_func.is_valid():
		return ""
	_mutex.lock()
	var thread: SingleThread = _ensure_thread_exists_internal(thread_name)
	var internal_id: int = thread.add_task(task_func)
	var public_id: String = str(_next_task_id)
	_next_task_id += 1
	_task_ids[thread_name][internal_id] = public_id
	_mutex.unlock()
	return public_id

## 返回线程仅供诊断；直接 add_task 的任务不产生管理器的聚合完成通知。
func create_thread(thread_name: StringName) -> SingleThread:
	_mutex.lock()
	var thread: SingleThread = _ensure_thread_exists_internal(thread_name)
	_mutex.unlock()
	return thread

func has_thread(thread_name: StringName) -> bool:
	_mutex.lock()
	var exists: bool = _threads.has(thread_name)
	_mutex.unlock()
	return exists

## 取消尚未报告的完成通知。stop 等待运行中的任务，但不能终止其函数。
func unload_thread(thread_name: StringName) -> void:
	_mutex.lock()
	var thread: SingleThread = _threads.get(thread_name)
	if thread != null:
		_disconnect_thread_signals(thread, thread_name)
		_threads.erase(thread_name)
		_task_ids.erase(thread_name)
	_mutex.unlock()
	# 不持有管理器锁等待工作线程，避免任务调用 submit_task 时死锁。
	if thread != null:
		thread.stop()

func clear_threads() -> void:
	var detached: Array[SingleThread] = []
	_mutex.lock()
	for thread_name: StringName in _threads:
		var thread: SingleThread = _threads[thread_name]
		_disconnect_thread_signals(thread, thread_name)
		detached.append(thread)
	_threads.clear()
	_task_ids.clear()
	_mutex.unlock()
	for thread: SingleThread in detached:
		thread.stop()

## 必须持有 _mutex。
func _ensure_thread_exists_internal(thread_name: StringName) -> SingleThread:
	if not _threads.has(thread_name):
		var thread: SingleThread = SingleThread.new()
		_threads[thread_name] = thread
		_task_ids[thread_name] = {}
		thread.task_completed.connect(_on_single_thread_task_completed.bind(thread_name))
		thread.thread_finished.connect(_on_single_thread_finished.bind(thread_name))
	return _threads[thread_name]

func _disconnect_thread_signals(thread: SingleThread, thread_name: StringName) -> void:
	var completed: Callable = _on_single_thread_task_completed.bind(thread_name)
	var finished: Callable = _on_single_thread_finished.bind(thread_name)
	if thread.task_completed.is_connected(completed):
		thread.task_completed.disconnect(completed)
	if thread.thread_finished.is_connected(finished):
		thread.thread_finished.disconnect(finished)

func _on_single_thread_task_completed(result: Variant, task_id: int, thread_name: StringName) -> void:
	_mutex.lock()
	var public_id: String = ""
	if _task_ids.has(thread_name):
		public_id = _task_ids[thread_name].get(task_id, "")
		_task_ids[thread_name].erase(task_id)
	_mutex.unlock()
	if not public_id.is_empty():
		task_completed_on_thread.emit(thread_name, result, public_id)

func _on_single_thread_finished(thread_name: StringName) -> void:
	all_tasks_finished_on_thread.emit(thread_name)
