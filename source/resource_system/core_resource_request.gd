class_name CoreResourceRequest
extends RefCounted

signal completed(result: CoreResourceResult)

var is_completed: bool:
	get:
		return _result != null
var result: CoreResourceResult:
	get:
		return _result
var progress: float:
	get:
		return _progress

var _result: CoreResourceResult = null
var _progress: float = 0.0

func wait() -> CoreResourceResult:
	if _result == null:
		await completed
	return _result

func _advance(value: float) -> void:
	_progress = maxf(_progress, clampf(value, 0.0, 1.0))

func _finish(value: CoreResourceResult) -> void:
	if _result != null:
		return
	_result = value
	if value.error == OK:
		_progress = 1.0
	completed.emit(value)
