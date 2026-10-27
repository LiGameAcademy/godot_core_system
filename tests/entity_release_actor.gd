extends Node

var on_release: Callable

func initialize(_config: Resource) -> void:
	pass
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and on_release.is_valid():
		on_release.call()
