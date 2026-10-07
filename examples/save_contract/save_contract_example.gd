extends Control

@onready var _status: Label = $Layout/Status
var _count: int = 0
var _store: CoreSaveStore

func _ready() -> void:
	var directory: CoreSaveDirectory = CoreSaveDirectory.new(ProjectSettings.globalize_path("user://core_save_example"))
	_store = directory.create_store("counter", 1, _validate)
	_refresh("Change the draft, then save or load explicitly.")

func _on_increment_pressed() -> void:
	_count += 1
	_refresh("Draft changed; disk data is unchanged.")

func _on_save_pressed() -> void:
	var result: CoreSaveResult = _store.save({"Count": _count})
	_refresh("Saved." if result.error == OK else result.message + " Error: " + str(result.error))

func _on_load_pressed() -> void:
	var result: CoreSaveResult = _store.try_load()
	if result.error != OK:
		_refresh(result.message + " The current draft was retained.")
	elif not result.found:
		_refresh("No save exists. The current draft was retained.")
	else:
		_count = result.data.Count
		_refresh("Loaded a validated snapshot.")

func _validate(data: Dictionary) -> Error:
	return OK if data.size() == 1 and data.has("Count") and data.Count is int and data.Count >= 0 and data.Count <= 2147483647 else ERR_INVALID_DATA

func _refresh(message: String) -> void:
	_status.text = "Draft count: %d\n%s" % [_count, message]
