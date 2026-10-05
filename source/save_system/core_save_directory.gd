class_name CoreSaveDirectory
extends RefCounted

## Names are identifiers, never externally supplied filesystem paths.
var last_error: Error = OK
var _directory: String

func _init(directory: String) -> void:
	_directory = directory.simplify_path()

func create_store(name: String, version: int, validate: Callable, replace: Callable = Callable()) -> CoreSaveStore:
	if not is_os_path(_directory) or not is_valid_name(name) or version <= 0 or version > 2147483647 or not validate.is_valid():
		last_error = ERR_INVALID_PARAMETER
		return null
	last_error = OK
	return CoreSaveStore.new(_directory.path_join(name + ".json"), version, validate, replace)

static func is_os_path(path: String) -> bool:
	return not path.strip_edges().is_empty() and path.is_absolute_path() and not path.contains("://")

static func is_valid_name(name: String) -> bool:
	if name.is_empty() or name.length() > 64:
		return false
	for character: String in name:
		if not character in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-":
			return false
	var upper: String = name.to_upper()
	if upper in ["CON", "PRN", "AUX", "NUL"]:
		return false
	return not (upper.length() == 4 and (upper.begins_with("COM") or upper.begins_with("LPT")) and upper[3] in "123456789")
