class_name CoreTimeSettings
extends RefCounted

## A value snapshot; services return copies rather than exposing internal state.
var paused: bool
var speed: float

func _init(is_paused: bool = false, time_speed: float = 1.0) -> void:
	paused = is_paused
	speed = time_speed

func copy() -> CoreTimeSettings:
	return CoreTimeSettings.new(paused, speed)
