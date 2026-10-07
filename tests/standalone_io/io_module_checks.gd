extends Node

const IO = preload("../../source/utils/async_io_manager.gd")
const Threads = preload("../../source/utils/threading/module_thread.gd")
const JSONSave = preload("../../source/save_system/save_format_strategy/json_save_strategy.gd")
const BinarySave = preload("../../source/save_system/save_format_strategy/binary_save_strategy.gd")
const ResourceSave = preload("../../source/save_system/save_format_strategy/resource_save_strategy.gd")

var _checks: int = 0
var _failed: bool = false
var _results: Dictionary[String, Dictionary] = {}
var _counts: Dictionary[String, int] = {}
var _diagnostics: int = 0
var _thread_results: Dictionary[String, int] = {}

func _ready() -> void:
	await _check_io()
	await _check_formats()
	await _check_threads()
	await get_tree().process_frame
	await get_tree().process_frame
	print("%s: %d standalone IO checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check_io() -> void:
	var io: IO = IO.new(null, null, null, _diagnose)
	_check(io._io_thread == null, "Construction does not start a worker")
	io.io_completed.connect(_completed)
	var ids: Array[String] = []
	for index: int in range(3):
		ids.append(io.write_file_async("res://data_%d.json" % index, {"index": index}))
	_check(ids[0] != ids[1] and ids[1] != ids[2] and ids[0] != ids[2], "Concurrent writes have distinct IDs")
	for id: String in ids:
		await _wait_result(id)
		_check(_results.get(id, {}).get("success", false), "Concurrent write completes with its own ID")
	ids.clear()
	for index: int in range(3):
		ids.append(io.read_file_async("res://data_%d.json" % index))
	for index: int in range(3):
		await _wait_result(ids[index])
		_check(_results.get(ids[index], {}).get("result", {}).get("index", -1) == index, "Concurrent reads retain matching data")
	var file: FileAccess = FileAccess.open("res://sentinel.json", FileAccess.WRITE)
	file.store_string("preserved")
	file.close()
	io.set_serialization_strategy(null)
	var failed_write: String = io.write_file_async("res://sentinel.json", {})
	await _wait_result(failed_write)
	_check(not _results.get(failed_write, {}).get("success", true), "Missing serializer reports failure")
	_check(FileAccess.get_file_as_string("res://sentinel.json") == "preserved", "Encoding failure preserves the existing file")
	var missing_directory: String = io.list_files_async("res://absent_directory")
	await _wait_result(missing_directory)
	_check(not _results.get(missing_directory, {}).get("success", true), "Missing directory reports failure")
	await get_tree().process_frame
	_check(_diagnostics >= 2, "Diagnostics work without a logger module")
	io.set_serialization_strategy(IO.JSONSerializationStrategy.new())
	var worker_ref: WeakRef = weakref(io._io_thread)
	var canceled: Array[String] = []
	for index: int in range(3):
		canceled.append(io.write_file_async("res://cancel_%d.json" % index, {"index": index}))
	io.close()
	io.close()
	for id: String in canceled:
		_check(_counts.get(id, 0) == 1 and not _results.get(id, {}).get("success", true), "Close reports each undelivered task once")
	_check(io.read_file_async("res://sentinel.json").is_empty(), "Closed IO rejects submissions")
	io = null
	await get_tree().process_frame
	await get_tree().process_frame
	_check(worker_ref.get_ref() == null, "Close releases the worker")
	for index: int in range(3):
		DirAccess.remove_absolute("res://data_%d.json" % index)
		if FileAccess.file_exists("res://cancel_%d.json" % index):
			DirAccess.remove_absolute("res://cancel_%d.json" % index)
	DirAccess.remove_absolute("res://sentinel.json")

func _check_formats() -> void:
	var data: Dictionary = {"metadata": {"save_id": "sample", "timestamp": 1, "save_date": "today", "game_version": "test", "playtime": 0.0}, "nodes": [{"value": 42}]}
	var resource: ResourceSave = ResourceSave.new()
	_check(resource.save("res://sample.tres", data), "Resource save works synchronously without CoreSystem")
	_check(resource.load_save("res://sample.tres").get("nodes", []) == data.nodes, "Resource data roundtrips")
	resource.close()
	resource = null
	DirAccess.remove_absolute("res://sample.tres")
	var json: JSONSave = JSONSave.new(_diagnose)
	var binary: BinarySave = BinarySave.new(_diagnose)
	_check(json._io_manager._io_thread == null and binary._io_manager._io_thread == null, "Format construction leaves workers dormant")
	_check(await json.save("res://format.json", data), "Standalone JSON save succeeds")
	_check(await json.load_save("res://format.json") == data, "Standalone JSON data roundtrips")
	var text: String = "compressible payload ".repeat(110000)
	var bytes: PackedByteArray = text.to_utf8_buffer()
	var gzip: IO.GzipCompressionStrategy = IO.GzipCompressionStrategy.new()
	var compressed: PackedByteArray = gzip.compress(bytes)
	_check(bytes.size() > 2000000 and compressed.size() * 100 < bytes.size(), "Fixture exercises a high compression ratio")
	_check(gzip.decompress(compressed) == bytes, "High ratio Gzip expands to its original size")
	binary.set_encryption_key("obfuscation-only")
	_check(await binary.save("res://format.save", {"text": text}), "Binary format writes large data")
	_check((await binary.load_save("res://format.save")).get("text", "") == text, "Gzip and XOR format data roundtrips")
	json.close()
	binary.close()
	_check(not await json.save("res://closed.json", {}), "Closed format returns failure without waiting")
	_check((await binary.load_save("res://format.save")).is_empty(), "Closed format load returns without waiting")
	json = null
	binary = null
	DirAccess.remove_absolute("res://format.json")
	DirAccess.remove_absolute("res://format.save")

func _check_threads() -> void:
	var threads: Threads = Threads.new()
	_check(not threads.has_thread(&"alpha"), "Named workers are created on demand")
	threads.task_completed_on_thread.connect(_thread_completed)
	var first: String = threads.submit_task(&"alpha", func() -> int: return 11)
	var second: String = threads.submit_task(&"beta", func() -> int: return 22)
	_check(first != second and not first.is_empty() and not second.is_empty(), "IDs are unique across named workers")
	var deadline: int = Time.get_ticks_msec() + 5000
	while _thread_results.size() < 2 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(_thread_results.get(first, -1) == 11 and _thread_results.get(second, -1) == 22, "Named results match their public IDs")
	threads.clear_threads()
	_check(not threads.has_thread(&"alpha") and not threads.has_thread(&"beta"), "Reusable reset joins and removes workers")
	var worker_ref: WeakRef = weakref(threads.create_thread(&"again"))
	threads.close()
	threads.close()
	_check(threads.submit_task(&"again", func() -> int: return 0).is_empty(), "Terminal close rejects new tasks")
	_check(threads.create_thread(&"again") == null, "Terminal close rejects explicit workers")
	threads = null
	await get_tree().process_frame
	await get_tree().process_frame
	_check(worker_ref.get_ref() == null, "Named worker is released after close")

func _completed(id: String, success: bool, result: Variant) -> void:
	_counts[id] = _counts.get(id, 0) + 1
	_results[id] = {"success": success, "result": result}

func _thread_completed(_name: StringName, result: Variant, id: String) -> void:
	_thread_results[id] = int(result)

func _diagnose(level: StringName, _message: String) -> void:
	_check(OS.get_thread_caller_id() == OS.get_main_thread_id(), "Diagnostic callback runs on the main thread")
	if level == &"error":
		_diagnostics += 1

func _wait_result(id: String) -> void:
	var deadline: int = Time.get_ticks_msec() + 5000
	while not _results.has(id) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(_results.has(id), "Accepted task completes before the deadline")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
