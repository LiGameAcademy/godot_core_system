extends Node

const AsyncIOStrategy = preload("../../source/save_system/save_format_strategy/async_io_strategy.gd")
const JSONSaveStrategy = preload("../../source/save_system/save_format_strategy/json_save_strategy.gd")
const BinarySaveStrategy = preload("../../source/save_system/save_format_strategy/binary_save_strategy.gd")

var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	var path: String = "res://rect_save_checks_%d.save" % Time.get_ticks_usec()
	var rectangles: Array[Variant] = [
		Rect2(1.0, 2.0, 3.0, 7.0), Rect2(-1.5, 2.5, -3.5, 7.5),
		Rect2(0.0, 0.0, 0.0, -2.0), Rect2i(1, 2, 3, 7),
		Rect2i(-1, -2, -3, -7), Rect2i(0, 0, 0, 2)
	]
	for strategy: AsyncIOStrategy in [JSONSaveStrategy.new(), BinarySaveStrategy.new()]:
		strategy.set_encryption_key("test-key")
		for rectangle: Variant in rectangles:
			var original: Dictionary = {"rect": rectangle, "nested": [{"rect": rectangle}]}
			var encoded: Dictionary = strategy._process_data_for_save(original)
			var parsed: Dictionary = JSON.parse_string(JSON.stringify(encoded))
			_check(strategy._process_data_for_load(parsed) == original, "JSON intermediate layer preserves rectangle and nested values")
			_check(await strategy.save(path, original), "Disk save succeeds")
			_check(await strategy.load_save(path) == original, "Disk round trip preserves rectangle type, position and size")
		strategy._io_manager._shutdown()
	DirAccess.remove_absolute(path)
	print("%s: %d rectangle checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
