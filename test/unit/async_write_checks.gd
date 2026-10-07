extends Node

const AsyncIOManager = preload("../../source/utils/async_io_manager.gd")

class EmptySerializer extends AsyncIOManager.SerializationStrategy:
	func serialize(_data: Variant) -> PackedByteArray:
		return PackedByteArray()

class FailureSerializer extends AsyncIOManager.SerializationStrategy:
	func serialize(_data: Variant) -> Variant:
		return null

class InvalidSerializer extends AsyncIOManager.SerializationStrategy:
	func serialize(_data: Variant) -> Variant:
		return {"invalid": "not bytes"}

class ProbeCompressor extends AsyncIOManager.CompressionStrategy:
	var calls: int = 0
	var result: Variant = null

	func compress(_bytes: PackedByteArray) -> Variant:
		calls += 1
		return result

class ProbeEncryptor extends AsyncIOManager.EncryptionStrategy:
	var calls: int = 0
	var result: Variant = null

	func encrypt(_bytes: PackedByteArray, _key: PackedByteArray) -> Variant:
		calls += 1
		return result

var _checks: int = 0
var _failed: bool = false
var _test_directory: String = ""
var _pending_id: String = ""
var _completed: bool = false
var _success: bool = false
var _completion_count: int = 0
var _result: Variant = null

func _ready() -> void:
	_test_directory = "res://async_write_checks_%d" % Time.get_ticks_usec()
	_check(DirAccess.make_dir_recursive_absolute(_test_directory) == OK, "Create test directory")
	await _run()
	print("%s: %d AsyncIO write checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _run() -> void:
	var io: AsyncIOManager = AsyncIOManager.new()
	io.io_completed.connect(_on_completed)
	var path: String = _test_directory.path_join("existing.json")
	_seed(path)
	io.set_serialization_strategy(null)
	await _write(io, path, {"value": 123}, false)
	_check(FileAccess.get_file_as_bytes(path) == "original save".to_utf8_buffer(), "Missing serializer preserves existing bytes")
	var missing: String = _test_directory.path_join("never_created/data.json")
	await _write(io, missing, {}, false)
	_check(not DirAccess.dir_exists_absolute(missing.get_base_dir()), "Failed encoding creates no directory")
	_check(not FileAccess.file_exists(missing), "Failed encoding creates no file")

	var compressor: ProbeCompressor = ProbeCompressor.new()
	var encryptor: ProbeEncryptor = ProbeEncryptor.new()
	io.set_compression_strategy(compressor)
	io.set_encryption_strategy(encryptor)
	for serializer: AsyncIOManager.SerializationStrategy in [
		FailureSerializer.new(), InvalidSerializer.new(), AsyncIOManager.SerializationStrategy.new()
	]:
		io.set_serialization_strategy(serializer)
		await _write(io, path, {}, false)
		_check(FileAccess.get_file_as_bytes(path) == "original save".to_utf8_buffer(), "Failed serializer preserves bytes")
	_check(compressor.calls == 0 and encryptor.calls == 0, "Serialization failure stops later stages")

	io.set_serialization_strategy(AsyncIOManager.JSONSerializationStrategy.new())
	for invalid: Variant in [null, "not bytes"]:
		compressor.result = invalid
		await _write(io, path, {}, false)
		_check(FileAccess.get_file_as_bytes(path) == "original save".to_utf8_buffer(), "Failed compressor preserves bytes")
	_check(encryptor.calls == 0, "Compression failure stops encryption")
	io.set_compression_strategy(AsyncIOManager.CompressionStrategy.new())
	await _write(io, path, {}, false)
	_check(FileAccess.get_file_as_bytes(path) == "original save".to_utf8_buffer(), "Abstract compressor fails safely")

	io.set_compression_strategy(null)
	for invalid: Variant in [null, "not bytes"]:
		encryptor.result = invalid
		await _write(io, path, {}, false)
		_check(FileAccess.get_file_as_bytes(path) == "original save".to_utf8_buffer(), "Failed encryptor preserves bytes")
	io.set_encryption_strategy(AsyncIOManager.EncryptionStrategy.new())
	await _write(io, path, {}, false)
	_check(FileAccess.get_file_as_bytes(path) == "original save".to_utf8_buffer(), "Abstract encryptor fails safely")

	io.set_encryption_strategy(null)
	io.set_serialization_strategy(EmptySerializer.new())
	await _write(io, path, {}, true)
	_check(FileAccess.get_file_as_bytes(path).is_empty(), "Valid empty payload writes an empty file")
	io.set_compression_strategy(AsyncIOManager.NoCompressionStrategy.new())
	io.set_encryption_strategy(AsyncIOManager.NoEncryptionStrategy.new())
	await _write(io, path, {}, true)
	_check(FileAccess.get_file_as_bytes(path).is_empty(), "Existing typed no-op strategies accept empty bytes")

	io.set_serialization_strategy(AsyncIOManager.JSONSerializationStrategy.new())
	await _write(io, path, null, true)
	_check(FileAccess.get_file_as_bytes(path).get_string_from_utf8() == "null", "JSON null is successful content, not processing failure")
	# JSON decodes numbers as floats; compare against that existing format.
	var data: Dictionary = {"level": 3.0, "name": "测试", "items": [1.0, 2.0]}
	await _write(io, path, data, true)
	await _read(io, path)
	_check(_result == data, "Default JSON async read/write round trip")
	io.set_compression_strategy(AsyncIOManager.GzipCompressionStrategy.new())
	io.set_encryption_strategy(AsyncIOManager.XOREncryptionStrategy.new())
	await _write(io, path, data, true, "test-key")
	await _read(io, path, "test-key")
	_check(_result == data, "Gzip and XOR async round trip retains existing format")
	io.set_compression_strategy(null)
	io.set_encryption_strategy(null)

	var nested: String = _test_directory.path_join("new/parent/data.json")
	await _write(io, nested, data, true)
	_check(JSON.parse_string(FileAccess.get_file_as_bytes(nested).get_string_from_utf8()) == data, "Create multiple missing parent directories")
	await _write(io, path.path_join("blocked/data.json"), data, false)
	_check(FileAccess.file_exists(path), "Parent file prevents directory creation without crash")
	await _write(io, _test_directory, data, false)
	_check(DirAccess.dir_exists_absolute(_test_directory), "Opening directory as file fails")

	var read_only: FileAccess = FileAccess.open(path, FileAccess.READ)
	_check(read_only != null, "Open read-only handle for real storage failure")
	if read_only:
		var before: PackedByteArray = FileAccess.get_file_as_bytes(path)
		_check(not io._write_buffer(read_only, "cannot write".to_utf8_buffer()), "store_buffer failure returns false")
		read_only.close()
		_check(FileAccess.get_file_as_bytes(path) == before, "Read-only storage failure preserves bytes")
	var relative: String = "async_write_relative_%d.json" % Time.get_ticks_usec()
	await _write(io, relative, data, true)
	_check(FileAccess.file_exists(relative), "Relative filename without parent directory succeeds")
	DirAccess.remove_absolute(relative)
	DirAccess.remove_absolute(nested)
	DirAccess.remove_absolute(nested.get_base_dir())
	DirAccess.remove_absolute(nested.get_base_dir().get_base_dir())
	io._shutdown()
	io.io_completed.disconnect(_on_completed)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(_test_directory)

func _write(io: AsyncIOManager, path: String, data: Variant, expected: bool, key: String = "") -> void:
	_reset_completion()
	_pending_id = io.write_file_async(path, data, key)
	await _wait_completion(expected)
	_check(_result == null, "Write completion keeps existing null result contract")

func _read(io: AsyncIOManager, path: String, key: String = "") -> void:
	_reset_completion()
	_pending_id = io.read_file_async(path, key)
	await _wait_completion(true)

func _reset_completion() -> void:
	_completed = false
	_success = false
	_completion_count = 0
	_result = null

func _wait_completion(expected: bool) -> void:
	var deadline: int = Time.get_ticks_msec() + 5000
	while not _completed and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(_completed, "Completion arrives before timeout")
	_check(_completed and _success == expected, "Completion success matches expected %s" % expected)
	_check(_completion_count == 1, "Exactly one completion for returned task ID")

func _on_completed(task_id: String, success: bool, result: Variant) -> void:
	_check(task_id == _pending_id, "Completion uses returned task ID")
	_completion_count += 1
	_success = success
	_result = result
	_completed = true

func _seed(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "Open seed file")
	if file:
		_check(file.store_buffer("original save".to_utf8_buffer()), "Seed original bytes")
		file.close()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		push_error(message)
		_failed = true
