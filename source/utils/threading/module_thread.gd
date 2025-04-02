extends RefCounted

## 线程模块
## 提供命名线程管理功能，允许创建和管理多个命名线程
## 每个命名线程可以接收多个任务，并按顺序执行

## 预加载单线程类
const SingleThread: = preload("res://addons/godot_core_system/source/utils/thread_pool/single_thread.gd")

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
	# 当线程完成所有任务时自动卸载
	new_thread.thread_finished.connect(unload_thread.bind(name))
	return new_thread

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
	var thread_names: Array[StringName] = _thread_dictionary.keys()
	_thread_dictionary.clear()
	for thread_name in thread_names:
		print("线程已卸载: %s" % thread_name)

## 卸载指定线程
## [param name] 线程名称
## 返回：无
func unload_thread(name: StringName) -> void:
	if _thread_dictionary.has(name):
		_thread_dictionary.erase(name)
		print("线程已卸载: %s" % name)
	else:
		print("线程已被卸载: %s" % name)
