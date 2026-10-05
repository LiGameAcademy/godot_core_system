class_name CoreSaveStore
extends RefCounted

## Versioned JSON with validation before writes and an explicit replacement backend.
const MAX_FILE_BYTES: int = 1024 * 1024
var _path: String
var _version: int
var _validate: Callable
var _replace: Callable

func _init(path: String, version: int, validate: Callable, replace: Callable = Callable()) -> void:
	_path = path.simplify_path()
	_version = version
	_validate = validate
	_replace = replace

func try_load() -> CoreSaveResult:
	if not _configured():
		return CoreSaveResult.failure(ERR_INVALID_PARAMETER, "Invalid save store configuration.")
	var file: FileAccess = FileAccess.open(_path, FileAccess.READ)
	if file == null:
		var opened: Error = FileAccess.get_open_error()
		if opened == ERR_FILE_NOT_FOUND and not DirAccess.dir_exists_absolute(_path):
			return CoreSaveResult.new()
		return CoreSaveResult.failure(opened, "Failed to open the save file.")
	var expected: int = mini(file.get_length(), MAX_FILE_BYTES + 1)
	var bytes: PackedByteArray = file.get_buffer(expected)
	var read_error: Error = file.get_error()
	file.close()
	if bytes.size() != expected or read_error not in [OK, ERR_FILE_EOF]:
		return CoreSaveResult.failure(ERR_FILE_CANT_READ, "Failed to read the complete save file.")
	if bytes.size() > MAX_FILE_BYTES:
		return CoreSaveResult.failure(ERR_INVALID_DATA, "The save file exceeds the size limit.")
	var text: String = bytes.get_string_from_utf8()
	if text.to_utf8_buffer() != bytes:
		return CoreSaveResult.failure(ERR_INVALID_DATA, "Save files must contain valid UTF-8.")
	var codec: CoreJsonCodec = CoreJsonCodec.new()
	var parsed: Variant = codec.parse(text)
	if codec.error != OK:
		return CoreSaveResult.failure(codec.error, codec.message)
	if not parsed is Dictionary:
		return CoreSaveResult.failure(ERR_INVALID_DATA, "The save envelope must be an object.")
	var envelope: Dictionary = parsed
	if envelope.size() != 2 or not envelope.has("Version") or not envelope.has("Data") or not envelope.Version is int or envelope.Version != _version or not envelope.Data is Dictionary:
		return CoreSaveResult.failure(ERR_INVALID_DATA, "Invalid save envelope or unsupported version.")
	var result: CoreSaveResult = _validated(envelope.Data)
	if result.error == OK:
		result.found = true
		result.data = envelope.Data
	return result

func save(data: Dictionary) -> CoreSaveResult:
	if not _configured():
		return CoreSaveResult.failure(ERR_INVALID_PARAMETER, "Invalid save store configuration.")
	var result: CoreSaveResult = _validated(data)
	if result.error != OK:
		return result
	var envelope: Dictionary = {"Version": _version, "Data": data}
	if not CoreJsonCodec.is_json_value(envelope):
		return CoreSaveResult.failure(ERR_INVALID_DATA, "Save data must contain finite JSON values within the depth limit.")
	var bytes: PackedByteArray = JSON.stringify(envelope, "\t", false, true).to_utf8_buffer()
	if bytes.size() > MAX_FILE_BYTES:
		return CoreSaveResult.failure(ERR_INVALID_DATA, "The save payload exceeds the size limit.")
	var directory: String = _path.get_base_dir()
	var created: Error = DirAccess.make_dir_recursive_absolute(directory)
	if created != OK:
		return CoreSaveResult.failure(created, "Failed to create the save directory.")
	var temporary: String = directory.path_join("." + _path.get_file() + "." + Crypto.new().generate_random_bytes(16).hex_encode() + ".tmp")
	if FileAccess.file_exists(temporary):
		return CoreSaveResult.failure(ERR_ALREADY_EXISTS, "Temporary save file already exists.")
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return CoreSaveResult.failure(FileAccess.get_open_error(), "Failed to create the temporary save file.")
	file.store_buffer(bytes)
	file.flush()
	var written: Error = file.get_error()
	file.close()
	if written != OK:
		return _cleanup(temporary, written, "Failed to write or flush the temporary save file.")
	var replaced: Error = _replace_file(temporary)
	if replaced != OK:
		return _cleanup(temporary, replaced, "Failed to replace the save file.")
	return CoreSaveResult.new()

func _replace_file(temporary: String) -> Error:
	if _replace.is_valid():
		var value: Variant = _replace.call(temporary, _path)
		if typeof(value) != TYPE_INT or value < OK or value > ERR_PRINTER_ON_FIRE:
			return ERR_INVALID_DATA
		return value
	if OS.get_name() == "Windows":
		if not ClassDB.class_exists("CoreAtomicFile"):
			return ERR_UNAVAILABLE
		return ClassDB.class_call_static("CoreAtomicFile", "replace", temporary, _path)
	return DirAccess.rename_absolute(temporary, _path)

func _validated(data: Dictionary) -> CoreSaveResult:
	var value: Variant = _validate.call(data)
	if typeof(value) != TYPE_INT or value < OK or value > ERR_PRINTER_ON_FIRE:
		return CoreSaveResult.failure(ERR_INVALID_DATA, "Save validators must return a valid Error.")
	if value != OK:
		return CoreSaveResult.failure(value, "Save data failed validation.")
	return CoreSaveResult.new()

func _cleanup(temporary: String, error: Error, detail: String) -> CoreSaveResult:
	var result: CoreSaveResult = CoreSaveResult.failure(error, detail)
	if FileAccess.file_exists(temporary):
		result.cleanup_error = DirAccess.remove_absolute(temporary)
	return result

func _configured() -> bool:
	return CoreSaveDirectory.is_os_path(_path) and _version > 0 and _version <= 2147483647 and _validate.is_valid()
