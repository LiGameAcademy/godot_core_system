class_name CoreTrigger
extends RefCounted

## Local synchronous gate; external owners provide event or timer driving.
enum Result { FIRED, DISABLED, LIMIT_REACHED, CONDITION_FAILED, BUSY, INVALID_CONFIGURATION, INVALID_CONDITION }
signal triggered(context: Dictionary)
var enabled: bool = true
var count: int:
	get:
		return _count
var max_triggers: int:
	get:
		return _max_triggers
var _condition: Callable
var _count: int = 0
var _max_triggers: int = -1
var _busy: bool = false
var _valid: bool = false

func _init(condition: Callable, limit: int = -1) -> void:
	if not condition.is_valid() or limit < -1 or limit > 2147483647:
		push_error("Trigger requires a valid condition and a limit from -1 to 2147483647.")
		return
	_condition = condition
	_max_triggers = limit
	_valid = true

func try_fire(context: Dictionary) -> Result:
	if _busy:
		return Result.BUSY
	if not _valid:
		return Result.INVALID_CONFIGURATION
	if not enabled:
		return Result.DISABLED
	if _count == 2147483647 or (_max_triggers >= 0 and _count >= _max_triggers):
		return Result.LIMIT_REACHED
	if not _condition.is_valid():
		return Result.INVALID_CONDITION
	_busy = true
	var accepted: Variant = _condition.call(context)
	if not accepted is bool:
		_busy = false
		push_error("Trigger condition must return bool.")
		return Result.INVALID_CONDITION
	if not accepted:
		_busy = false
		return Result.CONDITION_FAILED
	if not enabled:
		_busy = false
		return Result.DISABLED
	# Commit before notifying. Nested execution and reset stay blocked during notification.
	_count += 1
	triggered.emit(context)
	_busy = false
	return Result.FIRED

## Reset count only; condition, limit and enabled state remain unchanged.
func reset() -> bool:
	if _busy:
		return false
	_count = 0
	return true
