extends Node

var key: String = ""
var fail_save: bool = false
var writes: int = 0
var path: String = "res://legacy-key.cfg"

func get_value(_section: String, _name: String, _fallback: Variant) -> Variant:
	return key

func set_value(_section: String, _name: String, value: Variant) -> void:
	key = value

func save_config() -> bool:
	writes += 1
	if fail_save:
		return false
	var file: ConfigFile = ConfigFile.new()
	file.set_value("save_system", "encryption_key", key)
	return file.save(path) == OK
