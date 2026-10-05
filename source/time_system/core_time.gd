class_name CoreTime
extends RefCounted

## One explicit owner controls time and restores its acquired snapshot on release.
var last_error: Error = OK
var _read: Callable
var _write: Callable
var _scope: CoreTimeScope
var _disposed: bool = false

func _init(read_settings: Callable, write_settings: Callable) -> void:
	_read = read_settings
	_write = write_settings

static func for_scene_tree(tree: SceneTree) -> CoreTime:
	return CoreTime.new(
		func() -> CoreTimeSettings:
			if not is_instance_valid(tree):
				return null
			return CoreTimeSettings.new(tree.paused, Engine.time_scale),
		func(settings: CoreTimeSettings) -> Error:
			if not is_instance_valid(tree):
				return ERR_UNAVAILABLE
			Engine.time_scale = settings.speed
			tree.paused = settings.paused
			return OK)

func acquire() -> CoreTimeScope:
	if _disposed or not _read.is_valid() or not _write.is_valid():
		last_error = ERR_UNAVAILABLE
		return null
	if _scope != null:
		last_error = ERR_BUSY
		return null
	var value: Variant = _read.call()
	if value == null:
		last_error = ERR_UNAVAILABLE
		return null
	if not value is CoreTimeSettings:
		last_error = ERR_INVALID_DATA
		return null
	var baseline: CoreTimeSettings = value as CoreTimeSettings
	if not is_finite(baseline.speed) or baseline.speed <= 0.0:
		last_error = ERR_INVALID_PARAMETER
		return null
	_scope = CoreTimeScope.new(self, baseline)
	last_error = OK
	return _scope

func apply(scope: CoreTimeScope, settings: CoreTimeSettings) -> Error:
	if _disposed or scope == null or scope != _scope:
		return ERR_UNAVAILABLE
	if settings == null or not is_finite(settings.speed) or settings.speed <= 0.0:
		return ERR_INVALID_PARAMETER
	if not _write.is_valid():
		return ERR_UNAVAILABLE
	var result: Variant = _write.call(settings.copy())
	if typeof(result) != TYPE_INT:
		return ERR_INVALID_DATA
	if result < OK or result > ERR_PRINTER_ON_FIRE:
		return ERR_INVALID_DATA
	return result

func release(scope: CoreTimeScope, baseline: CoreTimeSettings) -> Error:
	var result: Error = apply(scope, baseline)
	if result == OK:
		_scope = null
	return result

func dispose() -> Error:
	if _disposed:
		return OK
	if _scope != null:
		var result: Error = _scope.dispose()
		if result != OK:
			return result
	_disposed = true
	return OK
