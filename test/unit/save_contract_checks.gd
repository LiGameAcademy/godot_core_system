extends SceneTree

var _checks: int = 0
var _failed: bool = false
var _directory: String

func _initialize() -> void:
	_run.call_deferred()

func _validate(data: Dictionary) -> Error:
	if not data.has("Count") or not data.Count is int or data.Count < 0 or data.Count > 2147483647:
		return ERR_INVALID_DATA
	for key: Variant in data:
		if key not in ["Count", "Text"]:
			return ERR_INVALID_DATA
	if data.has("Text") and not data.Text is String:
		return ERR_INVALID_DATA
	return OK

func _run() -> void:
	_directory = ProjectSettings.globalize_path("user://save-contract-" + Crypto.new().generate_random_bytes(12).hex_encode())
	var directory: CoreSaveDirectory = CoreSaveDirectory.new(_directory)
	var store: CoreSaveStore = directory.create_store("settings", 1, _validate)
	var path: String = _directory.path_join("settings.json")
	var result: CoreSaveResult = store.try_load()
	_check(result.error == OK and not result.found and not FileAccess.file_exists(path), "Missing files do not create default data")
	_check(store.save({"Count": 7}).error == OK, "Initial write succeeds")
	result = store.try_load()
	_check(result.error == OK and result.found and result.data.Count == 7, "Data round trips with an integer field")
	var valid: String = FileAccess.get_file_as_string(path)
	_check(store.save({"Count": -1}).error == ERR_INVALID_DATA and FileAccess.get_file_as_string(path) == valid, "Validation failure preserves the original file")
	for name: String in ["../escape", "a/b", "a\\b", "a.json", ".", "a:b", "CON", "nul", "COM1", "LPT9", "x".repeat(65), ""]:
		_check(directory.create_store(name, 1, _validate) == null, "Reject invalid save identifier")
	_check(CoreSaveDirectory.new("relative").create_store("test", 1, _validate) == null, "Reject relative directories")
	_check(directory.create_store("test", 0, _validate) == null, "Reject invalid versions")
	_check(directory.create_store("test", 1, Callable()) == null, "Reject invalid validators")
	var malformed: Array[String] = [
		"{", "null", "{}", '{"Version":1,"Data":null}',
		'{"Version":2,"Data":{"Count":1}}', '{"Version":0,"Data":{"Count":1}}',
		'{"Version":1,"Data":{}}', '{"Version":1,"Data":{"Count":-1}}',
		'{"Version":1,"Data":{"Count":1,"Unknown":2}}',
		'{"Version":1,"Data":{"Count":1,"Count":2}}',
		'{"Version":1,"Version":2,"Data":{"Count":1}}',
		'{"Version":1,"Data":{"Count":1},"Unknown":2}',
		'{"Version":1.0,"Data":{"Count":1}}',
		'{"Version":1,"Data":{"Count":1.0}}',
		'{"Version":1,"Data":{"Count":1,}}',
		'{"Version":1,"Data":{"Count":01}}',
		'{"Version":1,"Data":{"Count":1},}',
		'{"Version":1,"Data":{"Count":1}} extra',
		'{"Version":1,"Data":{"Count":1,"Text":NaN}}',
		'{"Version":1,"Data":{"Count":1,"Text":"bad\\q"}}',
		'{"Version":1,"Data":{"Count":1,"\\u0043ount":2}}',
	]
	for text: String in malformed:
		_write(path, text.to_utf8_buffer())
		_check(store.try_load().error == ERR_INVALID_DATA, "Malformed saves are rejected")
		_check(FileAccess.get_file_as_string(path) == text, "Rejected reads preserve original bytes")
	_write(path, valid.to_utf8_buffer())
	_check(store.save({"Count": 1, "Text": "x".repeat(CoreSaveStore.MAX_FILE_BYTES)}).error == ERR_INVALID_DATA, "Oversized writes rejected")
	_check(FileAccess.get_file_as_string(path) == valid, "Oversized writes preserve previous data")
	var huge: PackedByteArray = PackedByteArray()
	huge.resize(CoreSaveStore.MAX_FILE_BYTES + 1)
	_write(path, huge)
	_check(store.try_load().error == ERR_INVALID_DATA, "Oversized reads rejected")
	_write(path, valid.to_utf8_buffer())
	var blocked: CoreSaveStore = directory.create_store("settings", 1, _validate, func(_from: String, _to: String) -> Error: return ERR_FILE_NO_PERMISSION)
	result = blocked.save({"Count": 8})
	_check(result.error == ERR_FILE_NO_PERMISSION and result.cleanup_error == OK, "Replacement failure propagates and cleans the temporary file")
	_check(FileAccess.get_file_as_string(path) == valid, "Replacement failure preserves original bytes")
	_check(DirAccess.get_files_at(_directory).size() == 1, "No temporary files remain after replacement failure")
	if OS.get_name() == "Windows":
		_check(ClassDB.class_exists("CoreAtomicFile"), "Native replacement backend is loaded")
		_check(store.save({"Count": 8}).error == OK and store.try_load().data.Count == 8, "Windows native overwrite succeeds")
		_check(ClassDB.class_call_static("CoreAtomicFile", "replace", path, path) == ERR_INVALID_PARAMETER, "Native replacement rejects identical paths")
		_check(ClassDB.class_call_static("CoreAtomicFile", "replace", path + ".missing", path) == ERR_FILE_NOT_FOUND, "Missing source cannot destroy the destination")
		_check(store.try_load().data.Count == 8, "Native failure retains previous save")
	DirAccess.remove_absolute(path)
	DirAccess.make_dir_absolute(path)
	result = store.save({"Count": 8})
	_check(result.error != OK and result.cleanup_error == OK and DirAccess.dir_exists_absolute(path), "A directory target is retained after replacement failure")
	DirAccess.remove_absolute(path)
	var codec: CoreJsonCodec = CoreJsonCodec.new()
	var parsed: Variant = codec.parse('{"a":[true,false,null,1,-2,1.25,1e2],"s":"hello\\nworld"}')
	_check(codec.error == OK and parsed.a.size() == 7 and parsed.s == "hello\nworld", "Strict codec supports normal nested JSON values")
	codec.parse('['.repeat(66) + '0' + ']'.repeat(66))
	_check(codec.error == ERR_INVALID_DATA, "Depth is bounded")
	_check(not CoreJsonCodec.is_json_value({"bad": INF}) and not CoreJsonCodec.is_json_value({"bad": NodePath("x")}), "Nonfinite and engine-only values cannot be serialized")
	DirAccess.remove_absolute(_directory)
	if not _failed:
		print("PASS: %d save foundation checks" % _checks)
	quit(1 if _failed else 0)

func _write(path: String, bytes: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
