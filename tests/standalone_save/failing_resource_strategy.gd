extends "../../source/save_system/save_format_strategy/resource_save_strategy.gd"

var fail_write: bool = false
var close_calls: int = 0

func close() -> void:
	close_calls += 1

func save(path: String, data: Dictionary) -> bool:
	var success: bool = super.save(path, data)
	return success and not fail_write
