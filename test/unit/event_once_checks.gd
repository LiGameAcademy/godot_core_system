extends Node

const EventBus = preload("../../source/event_system/event_bus.gd")
var _bus: EventBus
var _hits: int = 0
var _reentered: bool = false
var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	_bus = EventBus.new()
	add_child(_bus)
	_bus.subscribe_once("self", _self_once)
	_bus.push_event("self")
	_check(_hits == 1 and _bus.get_subscriber_count("self") == 0, "Self-reentrant once callback is consumed before invocation")
	_hits = 0
	_bus.subscribe("other", _high, _bus.Priority.HIGH)
	_bus.subscribe_once("other", _count, _bus.Priority.LOW)
	_bus.push_event("other")
	_check(_hits == 1, "Another callback cannot reenter a pending once subscription")
	_hits = 0
	_bus.subscribe_once("filtered", _count, _bus.Priority.NORMAL,
		func(payload: Array) -> bool: return payload[0] == 1)
	_bus.push_event("filtered", [0])
	_check(_hits == 0 and _bus.get_subscriber_count("filtered") == 1, "Rejected filter does not consume once")
	_bus.push_event("filtered", [1])
	_check(_hits == 1 and _bus.get_subscriber_count("filtered") == 0, "Accepted filter consumes once")
	_hits = 0
	_reentered = false
	_bus.subscribe_once("filter_reentry", _count, _bus.Priority.NORMAL,
		func(payload: Array) -> bool:
			if not _reentered:
				_reentered = true
				_bus.push_event("filter_reentry", payload)
			return true)
	_bus.push_event("filter_reentry")
	_check(_hits == 1, "Filter reentry cannot consume the same once subscription twice")
	_hits = 0
	_bus.subscribe_once("filter_replace", _count, _bus.Priority.NORMAL,
		func(_payload: Array) -> bool:
			_bus.unsubscribe("filter_replace", _count)
			_bus.subscribe_once("filter_replace", _count)
			return true)
	_bus.push_event("filter_replace")
	_check(_hits == 0 and _bus.get_subscriber_count("filter_replace") == 1, "Filter replacement does not dispatch or consume the new registration")
	_bus.push_event("filter_replace")
	_check(_hits == 1 and _bus.get_subscriber_count("filter_replace") == 0, "Replacement registration handles the next event once")
	_hits = 0
	_bus.subscribe_once("deferred", _deferred_once)
	_bus.push_event("deferred", [], false)
	_bus.push_event("deferred", [], false)
	for frame: int in range(3):
		await get_tree().process_frame
	_check(_hits == 1 and _bus.get_subscriber_count("deferred") == 0, "Deferred delivery is reserved when queued")
	_hits = 0
	_bus.subscribe_once("renew", _renew)
	_bus.push_event("renew")
	_bus.push_event("renew")
	_check(_hits == 2 and _bus.get_subscriber_count("renew") == 0, "A new once subscription created by its callback survives old consumption")
	_bus.clear_subscriptions()
	print("%s: %d event once checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _self_once() -> void:
	_hits += 1
	if _hits == 1:
		_bus.push_event("self")

func _high() -> void:
	if not _reentered:
		_reentered = true
		_bus.push_event("other")

func _count(_value: Variant = null) -> void:
	_hits += 1

func _deferred_once() -> void:
	_hits += 1
	_bus.push_event("deferred")

func _renew() -> void:
	_hits += 1
	if _hits == 1:
		_bus.subscribe_once("renew", _renew)
		_bus.push_event("renew")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
