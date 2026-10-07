extends Node

## Instance-owned configuration. Diagnostics are optional; no AutoLoad is required.
signal config_loaded
signal config_saved
signal config_reset

const SETTING_CONFIG_SYSTEM: String = "godot_core_system/config_system/"
const SETTING_CONFIG_PATH: String = SETTING_CONFIG_SYSTEM + "config_path"
const SETTING_AUTO_SAVE: String = SETTING_CONFIG_SYSTEM + "auto_save"

@export var config_path: String = "user://config.cfg"
## Retained metadata; only save_config persists edits, as in the previous implementation.
@export var auto_save: bool = true
var last_error: Error = OK
var diagnostic: Callable
var _config_file: ConfigFile = ConfigFile.new()
var _modified: bool = false
var _load_attempted: bool = false

func _init(path: String = "", report: Callable = Callable()) -> void:
	diagnostic = report
	config_path = path if not path.is_empty() else str(ProjectSettings.get_setting(SETTING_CONFIG_PATH, "user://config.cfg"))
	auto_save = bool(ProjectSettings.get_setting(SETTING_AUTO_SAVE, true))
	if not path.is_empty():
		load_config()

## Serialized exports are assigned after construction and before ready.
func _ready() -> void:
	if not _load_attempted:
		load_config()

## Missing files produce empty state; other failures retain previous state and dirty status.
func load_config(p_path: String = "") -> bool:
	_load_attempted = true
	var path: String = p_path if not p_path.is_empty() else config_path
	var candidate: ConfigFile = ConfigFile.new()
	last_error = candidate.load(path)
	if last_error != OK and last_error != ERR_FILE_NOT_FOUND:
		_report("Configuration load failed (%s): %s" % [error_string(last_error), path])
		return false
	last_error = OK
	_config_file = candidate
	_modified = false
	config_loaded.emit()
	return true

func save_config(p_path: String = "") -> bool:
	var path: String = p_path if not p_path.is_empty() else config_path
	last_error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if last_error == OK:
		last_error = _config_file.save(path)
	if last_error != OK:
		_report("Configuration save failed (%s): %s" % [error_string(last_error), path])
		return false
	_modified = false
	config_saved.emit()
	return true

func reset_config() -> void:
	if _config_file.get_sections().is_empty() and not _modified:
		return
	_config_file.clear()
	_modified = true
	config_reset.emit()

func set_value(section: String, key: String, value: Variant) -> void:
	if _is_value_modified(get_value(section, key, null), value):
		_config_file.set_value(section, key, value)
		_modified = true

func get_value(section: String, key: String, p_default_value: Variant) -> Variant:
	if not _config_file.has_section_key(section, key):
		return p_default_value
	return _config_file.get_value(section, key, p_default_value)

func get_section(section: String) -> Dictionary:
	var result: Dictionary = {}
	if _config_file.has_section(section):
		for key: String in _config_file.get_section_keys(section):
			result[key] = get_value(section, key, null)
	return result.duplicate(true)

## Existing merge semantics: omitted keys are retained.
func set_section(section: String, value: Dictionary) -> void:
	for key: Variant in value:
		set_value(section, str(key), value[key])

func get_sections() -> PackedStringArray:
	return _config_file.get_sections()

func has_section(section: String) -> bool:
	return _config_file.has_section(section)

func has_key(section: String, key: String) -> bool:
	return _config_file.has_section_key(section, key)

func is_modified() -> bool:
	return _modified

func _report(message: String) -> void:
	if diagnostic.is_valid():
		diagnostic.call(message)
	else:
		push_error(message)

func _is_value_modified(current: Variant, value: Variant) -> bool:
	if current is float and value is float:
		return not is_equal_approx(current, value)
	if current is Array and value is Array:
		if current.size() != value.size():
			return true
		for index: int in range(current.size()):
			if _is_value_modified(current[index], value[index]):
				return true
		return false
	if current is Dictionary and value is Dictionary:
		if current.size() != value.size():
			return true
		for key: Variant in current:
			if not value.has(key) or _is_value_modified(current[key], value[key]):
				return true
		return false
	return current != value
