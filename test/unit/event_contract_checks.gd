extends SceneTree

var _checks: int = 0
var _failed: bool = false
var _values: Array[int] = []
var _once_calls: int = 0
var _later: CoreEventSubscription
var _added: CoreEventSubscription
var _new_calls: int = 0
var _after_error: int = 0
var _after_clear: int = 0
var _independent: int = 0
var _nested_added: bool = false
var _order: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var bus: CoreEventBus = CoreEventBus.new()
	var token: CoreEventSubscription = bus.subscribe(&"value", func(value: int) -> void: _values.append(value))
	bus.publish(&"value", 4)
	bus.publish(&"different", 4)
	_check(_values == [4], "Exact name routing")
	token.dispose()
	token.dispose()
	bus.publish(&"value", 5)
	_check(_values == [4] and bus.subscription_count == 0, "Idempotent release")
	bus.subscribe(&"value", func(value: int) -> void:
		_once_calls += 1
		bus.publish(&"value", value + 1), true)
	bus.publish(&"value", 1)
	_check(_once_calls == 1 and bus.subscription_count == 0, "Once removed before recursive publish")
	bus.subscribe(&"value", func(_value: int) -> void: _later.dispose())
	_later = bus.subscribe(&"value", func(_value: int) -> Error: return FAILED)
	_check(bus.publish(&"value", 1) == OK and bus.subscription_count == 1, "Cancellation skips pending snapshot entry")
	bus.clear()
	bus.subscribe(&"value", func(_value: int) -> void:
		if _added == null:
			_added = bus.subscribe(&"value", func(_next: int) -> void: _new_calls += 1))
	bus.publish(&"value", 1)
	_check(_new_calls == 0, "New subscriber excluded from current publication")
	bus.publish(&"value", 2)
	_check(_new_calls == 1, "New subscriber receives next publication")
	bus.clear()
	bus.subscribe(&"value", func(_value: int) -> Error: return ERR_UNAVAILABLE, true)
	bus.subscribe(&"value", func(_value: int) -> void: _after_error += 1)
	_check(bus.publish(&"value", 1) == ERR_UNAVAILABLE, "Callback failure propagates")
	_check(_after_error == 0 and bus.subscription_count == 1, "Failure stops dispatch and once remains removed")
	bus.publish(&"value", 2)
	_check(_after_error == 1, "Bus usable after failure")
	bus.clear()
	bus.subscribe(&"value", func(_value: int) -> void: bus.clear())
	bus.subscribe(&"value", func(_value: int) -> void: _after_clear += 1)
	bus.publish(&"value", 1)
	_check(_after_clear == 0 and bus.subscription_count == 0, "Clear invalidates pending entries")
	var second: CoreEventBus = CoreEventBus.new()
	second.subscribe(&"value", func(_value: int) -> void: _independent += 1)
	bus.publish(&"value", 1)
	_check(_independent == 0, "Bus instance isolation")
	second.clear()
	_check(bus.subscribe(&"value", Callable()) == null and bus.last_error == ERR_INVALID_PARAMETER, "Invalid callback rejected")
	_check(bus.publish(&"value", null) == ERR_INVALID_PARAMETER, "Null payload rejected")
	var stale: CoreEventSubscription = bus.subscribe(&"value", func(_value: int) -> void: pass)
	bus.clear()
	var fresh: CoreEventSubscription = bus.subscribe(&"value", func(_value: int) -> void: _after_clear += 1)
	stale.dispose()
	bus.publish(&"value", 3)
	_check(_after_clear == 1 and bus.subscription_count == 1, "Stale token cannot cancel a fresh registration")
	fresh.dispose()
	bus.subscribe(&"value", func(_value: int) -> void: _order.append("first"))
	bus.subscribe(&"value", func(_value: int) -> void: _order.append("second"))
	bus.publish(&"value", 1)
	_check(_order == ["first", "second"], "Registration order is stable")
	bus.clear()
	_order.clear()
	bus.subscribe(&"value", func(value: int) -> void:
		_order.append("outer" if value == 1 else "nested")
		if not _nested_added:
			_nested_added = true
			bus.subscribe(&"value", func(nested: int) -> void: _order.append("added:%d" % nested))
			bus.publish(&"value", 2))
	bus.publish(&"value", 1)
	_check(_order == ["outer", "nested", "added:2"], "Nested publication sees newly added listeners")
	bus.clear()
	var duplicate: Callable = func(_value: int) -> void: _independent += 1
	var first: CoreEventSubscription = bus.subscribe(&"value", duplicate)
	bus.subscribe(&"value", duplicate)
	first.dispose()
	bus.publish(&"value", 1)
	_check(_independent == 1 and bus.subscription_count == 1, "Duplicate callbacks have independent tokens")
	bus.clear()
	bus.subscribe(&"value", func(_value: int) -> bool: return false, true)
	_check(bus.publish(&"value", 1) == ERR_INVALID_DATA and bus.subscription_count == 0, "Malformed return is rejected after removing once")
	bus.clear()
	_check(bus.subscribe(&"", duplicate) == null and bus.publish(&"", 1) == ERR_INVALID_PARAMETER, "Empty event names rejected")
	bus.subscribe(&"value", func(_value: int) -> void:
		bus.clear()
		bus.subscribe(&"value", func(_next: int) -> void: _order.append("fresh")))
	bus.publish(&"value", 1)
	_order.clear()
	bus.publish(&"value", 2)
	_check(_order == ["fresh"] and bus.subscription_count == 1, "Clear and resubscribe creates a usable registration")
	bus.clear()
	var target: Listener = Listener.new()
	bus.subscribe(&"value", target.receive)
	target.free()
	_check(bus.publish(&"value", 1) == OK and bus.subscription_count == 0, "Freed callback targets are pruned")
	var receiver: CoreEventExampleOwner = load("res://addons/godot_core_system/examples/event_contract/event_owner.tscn").instantiate() as CoreEventExampleOwner
	receiver.bus = bus
	root.add_child(receiver)
	bus.publish(&"notice", 1)
	_check(receiver.received == 1 and bus.subscription_count == 1, "Scene owner receives an event")
	root.remove_child(receiver)
	receiver.free()
	_check(bus.subscription_count == 0 and bus.publish(&"notice", 2) == OK, "Scene exit releases its token")
	var example: Control = load("res://addons/godot_core_system/examples/event_contract/event_contract_example.tscn").instantiate() as Control
	root.add_child(example)
	example.get_node("Layout/Publish").emit_signal("pressed")
	_check(example.get_node("Layout/Status").text == "Subscriptions: 1 | Owner received: 1", "Actual publish button updates the owner UI")
	example.get_node("Layout/Owner").emit_signal("pressed")
	_check(example.get_node("Layout/Status").text == "Subscriptions: 0 | Owner received: 0", "Actual remove button releases the token")
	example.get_node("Layout/Owner").emit_signal("pressed")
	example.get_node("Layout/Publish").emit_signal("pressed")
	_check(example.get_node("Layout/Status").text == "Subscriptions: 1 | Owner received: 1", "Actual create button starts a fresh owner")
	root.remove_child(example)
	example.free()
	if not _failed:
		print("PASS: %d event contract checks" % _checks)
	quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)

class Listener extends Node:
	func receive(_value: int) -> void:
		pass
