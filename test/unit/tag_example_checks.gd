extends SceneTree

var _checks: int = 0
var _failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://addons/godot_core_system/examples/tags/tags_example.tscn")
	var first: Control = scene.instantiate()
	var second: Control = scene.instantiate()
	root.add_child(first)
	root.add_child(second)
	var a: CoreTagExampleModel = first.get("model")
	var b: CoreTagExampleModel = second.get("model")
	_check(a.can_act and b.can_act, "Both models start independently")
	_press(first, "Act")
	_check(a.actions_completed == 1 and b.actions_completed == 0, "Action button changes only A")
	_press(first, "Stun")
	_check(not a.can_act and b.can_act, "Stun affects only A")
	_press(first, "Act")
	_check(a.actions_completed == 1, "Blocked action has no side effect")
	_press(first, "Shield")
	_check(a.tags.has_all(["state.stunned", "effect.shield"]), "Independent tags coexist")
	_check(first.get_node("Layout/Status").text.contains("state.stunned"), "Notification refreshes UI")
	_press(first, "Stun")
	_press(first, "Act")
	_check(a.actions_completed == 2 and a.can_act, "Removing stun restores action")
	a.tags.add("state.stunned")
	_check(first.get_node("Layout/Status").text.contains("state.stunned"), "External rule mutation refreshes UI")
	_press(first, "Reset")
	_check(a.actions_completed == 0 and a.tags.snapshot() == ["unit.scout"], "Reset clears example state")
	first.queue_free()
	await process_frame
	await process_frame
	_check(a.tags.tag_added.get_connections().is_empty() and a.tags.tag_removed.get_connections().is_empty(), "Exit disconnects local notifications")
	a.tags.add("state.stunned")
	_check(b.can_act, "Retained model remains independent after UI exit")
	second.queue_free()
	await process_frame
	if not _failed:
		print("PASS: %d tag example checks" % _checks)
	quit(1 if _failed else 0)

func _press(example: Control, name: String) -> void:
	example.get_node("Layout/" + name).emit_signal("pressed")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
