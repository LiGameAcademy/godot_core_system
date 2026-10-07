extends Node

const AsyncIO = preload("../../source/utils/async_io_manager.gd")
const AsyncStrategy = preload("../../source/save_system/save_format_strategy/async_io_strategy.gd")
const JSONStrategy = preload("../../source/save_system/save_format_strategy/json_save_strategy.gd")
const BinaryStrategy = preload("../../source/save_system/save_format_strategy/binary_save_strategy.gd")
const Worker = preload("../../source/utils/threading/single_thread.gd")

var _checks: int = 0
var _failed: bool = false
var _completed: int = 0
var _canceled: Dictionary[String, int] = {}

func _ready() -> void:
	var probe: AsyncIO = AsyncIO.new()
	if not probe.has_method("close"):
		_check(false, "IO owners need a public close protocol")
		probe._shutdown()
	else:
		probe.call("close")
	probe = null
	for script: Script in [AsyncStrategy, JSONStrategy, BinaryStrategy]:
		var strategy: RefCounted = script.new()
		var io: RefCounted = strategy.get("_io_manager")
		_check(io.get("_io_thread") == null, "Construction leaves the IO worker dormant")
		io.call("list_files_async", "res://")
		var worker: RefCounted = io.get("_io_thread")
		var io_ref: WeakRef = weakref(io)
		var worker_ref: WeakRef = weakref(worker)
		_close_strategy(strategy)
		_close_strategy(strategy)
		_check(io.get("_io_thread") == null, "Repeated close stops the owned worker")
		worker = null
		io = null
		strategy = null
		await get_tree().process_frame
		_check(worker_ref.get_ref() == null and io_ref.get_ref() == null, "Closed strategy releases IO and worker")
	var baseline: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	for index: int in range(6):
		var strategy: RefCounted = JSONStrategy.new() if index % 2 == 0 else BinaryStrategy.new()
		_close_strategy(strategy)
		strategy = null
	await get_tree().process_frame
	_check(int(Performance.get_monitor(Performance.OBJECT_COUNT)) <= baseline, "Derived construction does not orphan a base worker")
	var io: AsyncIO = AsyncIO.new()
	io.connect("io_completed", _on_completed)
	var path: String = "res://worker_cleanup_probe.json"
	var task: String = io.call("write_file_async", path, {"value": 7})
	var result: Array = await io.io_completed
	_check(result[0] == task and result[1], "Normal IO completes before owner close")
	if io.has_method("close"):
		io.call("close")
		_check(io.call("read_file_async", path) == "", "Closed IO rejects new work")
		_check(io.call("write_file_async", path, {}) == "", "Closed IO rejects writes")
		_check(io.call("delete_file_async", path) == "", "Closed IO rejects deletes")
		_check(io.call("list_files_async", "res://") == "", "Closed IO rejects listing")
	else:
		io._shutdown()
	io = null
	DirAccess.remove_absolute(path)
	await _check_io_cancel()
	await _check_worker_stop()
	var manager: Node = CoreSystem.SaveManager.new()
	add_child(manager)
	var refs: Array[WeakRef] = []
	for strategy: RefCounted in manager.get("_strategies").values():
		if strategy is AsyncStrategy:
			strategy.get("_io_manager").call("list_files_async", "res://")
			refs.append(weakref(strategy.get("_io_manager").get("_io_thread")))
	remove_child(manager)
	manager.free()
	await get_tree().process_frame
	for reference: WeakRef in refs:
		_check(reference.get_ref() == null, "SaveManager exit closes every owned strategy")
	manager = CoreSystem.SaveManager.new()
	refs.clear()
	for strategy: RefCounted in manager.get("_strategies").values():
		if strategy is AsyncStrategy:
			strategy.get("_io_manager").call("list_files_async", "res://")
			refs.append(weakref(strategy.get("_io_manager").get("_io_thread")))
	manager.free()
	await get_tree().process_frame
	for reference: WeakRef in refs:
		_check(reference.get_ref() == null, "Deleting an unattached manager closes its strategies")
	_finish()

func _check_io_cancel() -> void:
	var io: AsyncIO = AsyncIO.new()
	if not io.has_method("close"):
		io._shutdown()
		return
	io.io_completed.connect(func(id: String, success: bool, result: Variant) -> void:
		_canceled[id] = _canceled.get(id, 0) + 1
		_check(not success and result == null, "Close delivers failure for an undelivered task")
		io.call("close"))
	var ids: Array[String] = []
	for index: int in range(3):
		ids.append(io.write_file_async("res://cancel_%d.json" % index, {"value": index}))
	io.call("close")
	io.call("close")
	await get_tree().process_frame
	await get_tree().process_frame
	for index: int in range(3):
		_check(_canceled.get(ids[index], 0) == 1, "Canceled task completes once with its matching ID")
		DirAccess.remove_absolute("res://cancel_%d.json" % index)
	io.io_completed.disconnect(io.io_completed.get_connections()[0]["callable"])
	var strategy: AsyncStrategy = JSONStrategy.new()
	strategy.call("close")
	_check(not await strategy.save("res://closed.json", {}), "Closed strategy save returns failure without waiting")
	_check((await strategy.load_save("res://closed.json")).is_empty(), "Closed strategy load returns empty without waiting")

func _check_worker_stop() -> void:
	var worker: Worker = Worker.new()
	var entered: Semaphore = Semaphore.new()
	var marker: RefCounted = RefCounted.new()
	var marker_ref: WeakRef = weakref(marker)
	worker.task_completed.connect(func(_result: Variant, _id: int) -> void: _completed += 1)
	worker.add_task(func() -> int:
		entered.post()
		OS.delay_msec(30)
		return 1)
	entered.wait()
	worker.add_task(_queued_task.bind(marker))
	marker = null
	var before: int = _completed
	worker.stop()
	worker.stop()
	_check(worker.get_pending_task_count() == 0, "Stop releases queued task captures")
	_check(worker.add_task(func() -> int: return 3) == -1, "Stopped worker rejects new tasks")
	await get_tree().process_frame
	await get_tree().process_frame
	_check(_completed == before, "Stopped worker suppresses deferred completion")
	_check(marker_ref.get_ref() == null, "Canceled queue does not retain captured objects")
	worker = null

func _queued_task(_marker: RefCounted) -> int:
	return 2

func _close_strategy(strategy: RefCounted) -> void:
	if strategy.has_method("close"):
		strategy.call("close")
	else:
		strategy.get("_io_manager")._shutdown()

func _on_completed(_id: String, _success: bool, _result: Variant) -> void:
	_completed += 1

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)

func _finish() -> void:
	print("%s: %d worker cleanup checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)
