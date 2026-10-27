class_name CoreEventSubscription
extends RefCounted

## An independently disposable subscription; the bus owns its registration.
var event_name: StringName:
	get: return _event_name
var _event_name: StringName
var _callback: Callable
var _once: bool
var _owner: WeakRef

func _init(owner: CoreEventBus, name: StringName, callback: Callable, once: bool) -> void:
	_owner = weakref(owner)
	_event_name = name
	_callback = callback
	_once = once

func is_active() -> bool:
	return _callback.is_valid()

func dispose() -> void:
	_callback = Callable()
	if _owner == null:
		return
	var owner: CoreEventBus = _owner.get_ref() as CoreEventBus
	_owner = null
	if owner != null:
		owner._remove(self)

func _invoke(payload: Variant) -> Error:
	var callback: Callable = _callback
	if not callback.is_valid():
		dispose()
		return OK
	# Remove before calling so recursion or failure cannot repeat a one-shot.
	if _once:
		dispose()
	var result: Variant = callback.call(payload)
	# Ordinary void callbacks succeed; explicit Error results expose recoverable failures.
	if result == null:
		return OK
	if typeof(result) != TYPE_INT or result < OK or result > ERR_PRINTER_ON_FIRE:
		return ERR_INVALID_DATA
	return result
