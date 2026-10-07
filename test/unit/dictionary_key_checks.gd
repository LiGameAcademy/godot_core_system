extends Node

const AsyncIOStrategy = preload("../../source/save_system/save_format_strategy/async_io_strategy.gd")
const JSONSaveStrategy = preload("../../source/save_system/save_format_strategy/json_save_strategy.gd")
const BinarySaveStrategy = preload("../../source/save_system/save_format_strategy/binary_save_strategy.gd")

var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	var integers: Dictionary[int, String] = {7: "seven", -2: "negative"}
	var names: Dictionary[StringName, int] = {&"coins": 3}
	var vectors: Dictionary[Vector2i, String] = {Vector2i(2, -3): "cell"}
	var mixed: Dictionary = {7: "integer", "7": "string", &"name": "name", Vector2i(1, 2): "vector"}
	var samples: Array[Dictionary] = [
		{"values": integers}, {"values": names}, {"values": vectors},
		{"values": mixed}, {"nested": [{"deep": mixed}]}, integers, {}
	]
	var path: String = "res://dictionary_keys_%d.save" % Time.get_ticks_usec()
	for strategy: AsyncIOStrategy in [JSONSaveStrategy.new(), BinarySaveStrategy.new()]:
		strategy.set_encryption_key("test-key")
		for sample: Dictionary in samples:
			var encoded: Dictionary = strategy._process_data_for_save(sample)
			var parsed: Dictionary = JSON.parse_string(JSON.stringify(encoded))
			var restored: Dictionary = strategy._process_data_for_load(parsed)
			_check(restored == sample, "Keys and nested values survive JSON intermediate layer")
			_check(await strategy.save(path, sample), "Disk save succeeds")
			_check(await strategy.load_save(path) == sample, "Disk round trip preserves typed and untyped keys")
		var typed_restored: Dictionary = strategy._process_data_for_load(
			JSON.parse_string(JSON.stringify(strategy._process_data_for_save({"values": integers}))))
		_check(typed_restored.values.is_typed() and typed_restored.values.get_typed_key_builtin() == TYPE_INT, "Typed integer dictionary metadata survives")
		var legacy: Dictionary = {"plain": {"a": "b"}, "typed": {
			"_type_": TYPE_DICTIONARY, "key_type": TYPE_STRING, "key_class": "", "key_script": "",
			"value_type": TYPE_STRING, "value_class": "", "value_script": "", "dictionary": {"old": "value"}
		}}
		var loaded_legacy: Dictionary = strategy._process_data_for_load(legacy)
		_check(loaded_legacy.plain == {"a": "b"} and loaded_legacy.typed.get("old") == "value", "Legacy string-key and typed dictionary files remain readable")
		strategy._io_manager._shutdown()
	DirAccess.remove_absolute(path)
	print("%s: %d dictionary key checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
