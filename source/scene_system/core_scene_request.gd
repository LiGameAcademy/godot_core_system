class_name CoreSceneRequest
extends RefCounted

## A reusable completion handle; wait also supports an already-completed request.
signal completed(result: Error)
var is_completed: bool = false
var result: Error = ERR_BUSY

func wait() -> Error:
	if not is_completed:
		await completed
	return result

func complete(value: Error) -> void:
	if is_completed:
		return
	result = value
	is_completed = true
	completed.emit(value)
