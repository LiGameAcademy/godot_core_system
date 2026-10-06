extends SceneTree

## Run with the legacy CoreSystem AutoLoad enabled to catch global-class type collisions.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var entry: Node = root.get_node_or_null("CoreSystem")
	if entry == null:
		_fail("Legacy CoreSystem AutoLoad is required")
		return
	var expected: Script = load("res://addons/godot_core_system/source/event_system/event_bus.gd")
	var actual: Node = entry.get("event_bus") as Node
	var constants: Dictionary = entry.get_script().get_script_constant_map()
	if actual == null or actual.get_script() != expected:
		_fail("Legacy event service must retain its Node implementation")
		return
	if constants.get("CoreEventBus") != expected or constants.get("LegacyEventBus") != expected:
		_fail("Legacy type aliases must retain the compatibility constant")
		return
	var demo: Script = load("res://addons/godot_core_system/examples/event_bus_demo/event_bus_demo.gd")
	if demo == null or not demo.can_instantiate():
		_fail("Legacy event example type references must compile")
		return
	print("PASS: legacy event entry and demo type references")
	quit()

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
