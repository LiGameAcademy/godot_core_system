extends Control

## The parent owns the bus and coordinates its replaceable subscription owner.
var _bus: CoreEventBus = CoreEventBus.new()
var _receiver: CoreEventExampleOwner
@onready var _status: Label = $Layout/Status

func _ready() -> void:
	$Layout/Publish.pressed.connect(_publish)
	$Layout/Owner.pressed.connect(_toggle_owner)
	_attach_owner()

func _exit_tree() -> void:
	_bus.clear()

func _publish() -> void:
	var result: Error = _bus.publish(&"notice", 1)
	if result != OK:
		push_error("Event publication failed: %s" % error_string(result))
	_refresh()

func _toggle_owner() -> void:
	if is_instance_valid(_receiver):
		remove_child(_receiver)
		_receiver.queue_free()
		_receiver = null
	else:
		_attach_owner()
	_refresh()

func _attach_owner() -> void:
	var packed: PackedScene = load("res://addons/godot_core_system/examples/event_contract/event_owner.tscn")
	_receiver = packed.instantiate() as CoreEventExampleOwner
	_receiver.bus = _bus
	_receiver.notice_received.connect(_on_notice)
	add_child(_receiver)
	_refresh()

func _on_notice(_total: int) -> void:
	_refresh()

func _refresh() -> void:
	var received: int = _receiver.received if is_instance_valid(_receiver) else 0
	_status.text = "Subscriptions: %d | Owner received: %d" % [_bus.subscription_count, received]
	$Layout/Owner.text = "Remove owner and unsubscribe" if is_instance_valid(_receiver) else "Create a fresh owner"
