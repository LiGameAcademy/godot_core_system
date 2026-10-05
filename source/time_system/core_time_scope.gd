class_name CoreTimeScope
extends RefCounted

## Dispose when the scene owner exits. Weak ownership avoids a reference cycle.
var current: CoreTimeSettings:
	get: return _current.copy()
var _owner: WeakRef
var _baseline: CoreTimeSettings
var _current: CoreTimeSettings

func _init(owner: CoreTime, baseline: CoreTimeSettings) -> void:
	_owner = weakref(owner)
	_baseline = baseline.copy()
	_current = baseline.copy()

func set_paused(paused: bool) -> Error:
	return _apply(CoreTimeSettings.new(paused, _current.speed))

func set_speed(speed: float) -> Error:
	return _apply(CoreTimeSettings.new(_current.paused, speed))

func dispose() -> Error:
	if _owner == null:
		return OK
	var owner: CoreTime = _owner.get_ref() as CoreTime
	if owner == null:
		_owner = null
		return ERR_UNAVAILABLE
	var result: Error = owner.release(self, _baseline)
	if result == OK:
		_owner = null
	return result

func _apply(settings: CoreTimeSettings) -> Error:
	if _owner == null:
		return ERR_UNAVAILABLE
	var owner: CoreTime = _owner.get_ref() as CoreTime
	if owner == null:
		return ERR_UNAVAILABLE
	var result: Error = owner.apply(self, settings)
	if result == OK:
		_current = settings.copy()
	return result
