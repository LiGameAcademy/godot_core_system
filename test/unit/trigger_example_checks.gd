extends SceneTree
var _checks: int = 0
var _failed: bool = false
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var scene: PackedScene = load("res://addons/godot_core_system/examples/triggers/triggers_example.tscn")
	var first: Control = scene.instantiate()
	var second: Control = scene.instantiate()
	root.add_child(first)
	root.add_child(second)
	var a: CoreTriggerExampleModel = first.get("model")
	var b: CoreTriggerExampleModel = second.get("model")
	_press(first, "Fire")
	_check(a.trigger.count == 0, "Missing tag blocks attempt")
	_press(first, "Ready")
	_check(a.tags.has("state.ready") and not b.tags.has("state.ready"), "Independent tag ownership")
	_press(first, "Fire")
	_check(a.trigger.count == 1 and b.trigger.count == 0, "Independent trigger count")
	_check(first.get_node("Layout/Status").text.contains("1 / 2"), "UI displays committed count")
	_press(first, "Fire")
	_press(first, "Fire")
	_check(a.trigger.count == 2 and a.last_result == CoreTrigger.Result.LIMIT_REACHED, "Quota blocks third attempt")
	_press(first, "Enabled")
	_press(first, "Reset")
	_check(a.trigger.count == 0 and not a.trigger.enabled and a.tags.has("state.ready"), "Reset preserves condition and enabled state")
	_press(first, "Fire")
	_check(a.last_result == CoreTrigger.Result.DISABLED, "Disabled attempt")
	_press(first, "Enabled")
	_press(first, "Fire")
	_check(a.trigger.count == 1, "Enable restores triggering")
	first.queue_free()
	await process_frame
	await process_frame
	_check(a.tags.tag_added.get_connections().is_empty() and a.tags.tag_removed.get_connections().is_empty(), "Exit disconnects UI")
	a.toggle_ready()
	_check(b.trigger.count == 0, "Retained model remains usable")
	second.queue_free()
	await process_frame
	if not _failed:
		print("PASS: %d trigger example checks" % _checks)
	quit(1 if _failed else 0)
func _press(example: Control, name: String) -> void:
	example.get_node("Layout/" + name).emit_signal("pressed")
func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
