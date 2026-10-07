class_name CoreEventExampleOwner
extends Node

## The parent supplies the bus; this scene owns only its subscription.
signal notice_received(total: int)
var bus: CoreEventBus
var received: int = 0
var _subscription: CoreEventSubscription

func _ready() -> void:
	if bus == null:
		push_error("The event owner requires an explicit event bus.")
		return
	_subscription = bus.subscribe(&"notice", _receive)

func _exit_tree() -> void:
	if _subscription != null:
		_subscription.dispose()

func _receive(_value: int) -> void:
	received += 1
	notice_received.emit(received)
