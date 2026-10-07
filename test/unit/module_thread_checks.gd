extends Node

const ModuleThread = preload("../../source/utils/threading/module_thread.gd")
var _manager: ModuleThread
var _expected: Dictionary[String, Dictionary] = {}
var _received: Dictionary[String, Variant] = {}
var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	_manager = ModuleThread.new()
	_manager.task_completed_on_thread.connect(_on_completed)
	for name: StringName in [&"alpha", &"beta"]:
		for value: int in range(3):
			_submit(name, value)
	await _wait(6)
	var old: ModuleThread.SingleThread = _manager.create_thread(&"alpha")
	var canceled: String = _manager.submit_task(&"alpha", func() -> int: return 99)
	_manager.unload_thread(&"alpha")
	_check(not old.task_completed.is_connected(_manager._on_single_thread_task_completed.bind(&"alpha")), "Unload disconnects the actual bound completion callback")
	_check(not old.thread_finished.is_connected(_manager._on_single_thread_finished.bind(&"alpha")), "Unload disconnects the actual bound finish callback")
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not _received.has(canceled), "Unloaded worker emits no leftover aggregate completion")
	var replacement: String = _submit(&"alpha", 42)
	_check(replacement != canceled, "Recreated thread does not reuse a public ID")
	await _wait(7)
	_manager.clear_threads()
	_check(not _manager.has_thread(&"alpha") and not _manager.has_thread(&"beta"), "Clear removes all named threads")
	_manager.task_completed_on_thread.disconnect(_on_completed)
	print("%s: %d module thread checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _submit(name: StringName, value: int) -> String:
	var id: String = _manager.submit_task(name, func() -> int: return value)
	_check(not id.is_empty() and not _expected.has(id), "Public task IDs are nonempty and unique across workers")
	_expected[id] = {"name": name, "value": value}
	return id

func _on_completed(name: StringName, result: Variant, id: String) -> void:
	_check(_expected.has(id), "Aggregate signal carries a submitted public ID")
	_check(not _received.has(id), "Each task completes once")
	if _expected.has(id):
		_check(_expected[id].name == name and _expected[id].value == result, "Worker, task ID and result match")
	_received[id] = result

func _wait(count: int) -> void:
	var deadline: int = Time.get_ticks_msec() + 5000
	while _received.size() < count and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(_received.size() == count, "All tasks complete before timeout")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
