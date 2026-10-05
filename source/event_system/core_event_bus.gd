class_name CoreEventBus
extends RefCounted

## Single-threaded synchronous events with registration order and snapshot dispatch.
var last_error: Error = OK
var subscription_count: int:
	get:
		_prune()
		return _subscriptions.size()
var _subscriptions: Array[CoreEventSubscription] = []

func subscribe(event_name: StringName, callback: Callable, once: bool = false) -> CoreEventSubscription:
	if event_name.is_empty() or not callback.is_valid():
		last_error = ERR_INVALID_PARAMETER
		return null
	var subscription: CoreEventSubscription = CoreEventSubscription.new(self, event_name, callback, once)
	_subscriptions.append(subscription)
	last_error = OK
	return subscription

func publish(event_name: StringName, payload: Variant) -> Error:
	if event_name.is_empty() or payload == null:
		return ERR_INVALID_PARAMETER
	_prune()
	# New registrations affect later publications, including nested ones, not this snapshot.
	var snapshot: Array[CoreEventSubscription] = _subscriptions.duplicate()
	for subscription: CoreEventSubscription in snapshot:
		if subscription.event_name != event_name:
			continue
		var result: Error = subscription._invoke(payload)
		if result != OK:
			return result
	return OK

func clear() -> void:
	var snapshot: Array[CoreEventSubscription] = _subscriptions.duplicate()
	for subscription: CoreEventSubscription in snapshot:
		subscription.dispose()

func _remove(subscription: CoreEventSubscription) -> void:
	_subscriptions.erase(subscription)

func _prune() -> void:
	var snapshot: Array[CoreEventSubscription] = _subscriptions.duplicate()
	for subscription: CoreEventSubscription in snapshot:
		if not subscription.is_active():
			subscription.dispose()
