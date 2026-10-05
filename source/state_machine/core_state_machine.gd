extends RefCounted
class_name CoreStateMachine

## Value-only transitions. The explicit enum values define the valid domain.
var current: int:
	get:
		return _current
var _current: int
var _values: Array[int] = []
var _rule: Callable
var _checking: bool = false
var _valid: bool = false

func _init(initial: int, valid_values: Array[int], rule: Callable) -> void:
	if not valid_values.has(initial) or not rule.is_valid():
		push_error("A defined initial state and transition predicate are required.")
		return
	_current = initial
	_values.assign(valid_values)
	_rule = rule
	_valid = true

func try_transition(target: int) -> bool:
	if not _valid or _checking or not _values.has(target) or target == _current:
		return false
	_checking = true
	var allowed: bool = _rule.call(_current, target)
	if allowed:
		_current = target
	_checking = false
	return allowed
