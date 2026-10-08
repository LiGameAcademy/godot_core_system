extends Node

const AsyncIOStrategy = preload("../../source/save_system/save_format_strategy/async_io_strategy.gd")
const JSONSaveStrategy = preload("../../source/save_system/save_format_strategy/json_save_strategy.gd")
const BinarySaveStrategy = preload("../../source/save_system/save_format_strategy/binary_save_strategy.gd")

var _failed: bool = false
var _checks: int = 0
var _results: Dictionary = {}
var _directory: String = ""

func _ready() -> void:
	_directory = "res://async_tasks_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_directory)
	for strategy: AsyncIOStrategy in [JSONSaveStrategy.new(), BinarySaveStrategy.new()]:
		strategy.set_encryption_key("test-key")
		await _run(strategy)
		strategy._io_manager._shutdown()
	DirAccess.remove_absolute(_directory)
	print("%s: %d async task checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _run(strategy: AsyncIOStrategy) -> void:
	var path: String = _directory.path_join("one.save")
	var second: String = _directory.path_join("two.save")
	_results.clear()
	_save(strategy, "a", path, {"id": "a"})
	_save(strategy, "b", second, {"id": "b"})
	await _wait(2)
	_check(_results.get("a") == true and _results.get("b") == true, "Concurrent writes both succeed")
	_results.clear()
	_load(strategy, "a", path)
	_load(strategy, "b", second)
	_load(strategy, "missing", _directory.path_join("missing.save"))
	await _wait(3)
	_check(_results.get("a") == {"id": "a"} and _results.get("b") == {"id": "b"}, "Concurrent reads match their task")
	_check(_results.get("missing") == {}, "Missing read has its own failure result")
	_results.clear()
	_save(strategy, "fail", _directory, {})
	_save(strategy, "write", path, {"id": "updated"})
	_load(strategy, "read", second)
	await _wait(3)
	_check(_results.get("fail") == false and _results.get("write") == true, "Mixed write results remain independent")
	_check(_results.get("read") == {"id": "b"}, "Concurrent read/write remains independent")
	_results.clear()
	_save(strategy, "first", path, {"id": "first"})
	_save(strategy, "last", path, {"id": "last"})
	_load(strategy, "after", path)
	await _wait(3)
	_check(_results.get("first") == true and _results.get("last") == true, "Same-path writes both complete")
	_check(_results.get("after") == {"id": "last"}, "Same manager processes same-path requests in submission order")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(second)

func _save(strategy: AsyncIOStrategy, id: String, path: String, data: Dictionary) -> void:
	var success: bool = await strategy.save(path, data)
	_check(not _results.has(id), "Write coroutine completes once")
	_results[id] = success

func _load(strategy: AsyncIOStrategy, id: String, path: String) -> void:
	var data: Dictionary = await strategy.load_save(path)
	_check(not _results.has(id), "Read coroutine completes once")
	_results[id] = data

func _wait(count: int) -> void:
	var deadline: int = Time.get_ticks_msec() + 5000
	while _results.size() < count and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(_results.size() == count, "All requests complete within timeout")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
