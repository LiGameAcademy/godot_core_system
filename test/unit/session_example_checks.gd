extends SceneTree

var _checks: int = 0
var _failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://addons/godot_core_system/examples/game_session/game_session_example.tscn")
	var first: Control = scene.instantiate()
	var second: Control = scene.instantiate()
	root.add_child(first)
	root.add_child(second)
	var a: CoreSessionExampleModel = first.get("model")
	var b: CoreSessionExampleModel = second.get("model")
	_press(first, "Progress")
	_check(a.points == 0, "Preparing button rejects progress")
	_press(first, "Start")
	_check(a.session.phase == CoreGameSession.Phase.RUNNING and b.session.phase == CoreGameSession.Phase.PREPARING, "A/B session isolation")
	_press(first, "Progress")
	_press(first, "Pause")
	_press(first, "Progress")
	_check(a.points == 1 and a.session.phase == CoreGameSession.Phase.PAUSED, "Paused button leaves count unchanged")
	_press(first, "Resume")
	_press(first, "Progress")
	_press(first, "Progress")
	_check(a.points == 3 and a.session.phase == CoreGameSession.Phase.ENDED, "Count rule ends")
	var old: CoreGameSession = a.session
	_press(first, "TimedRun")
	_check(old.phase == CoreGameSession.Phase.CLOSED and old.changed.get_connections().is_empty()
		and a.session.id != old.id and a.points == 0, "New run closes and unbinds old session")
	_press(first, "Start")
	_press(first, "Step")
	_press(first, "Pause")
	_press(first, "Step")
	_check(a.elapsed == 1.0, "Paused local clock does not advance")
	_press(first, "Resume")
	_press(first, "Step")
	_press(first, "Step")
	_check(a.elapsed == 3.0 and a.session.phase == CoreGameSession.Phase.ENDED, "Timer rule ends")
	_check(first.get_node("Layout/Status").text.contains("ENDED") and not paused, "Presentation shows phase without global pause")
	_press(first, "CountRun")
	_press(first, "Start")
	_press(first, "End")
	_check(a.session.phase == CoreGameSession.Phase.ENDED, "Manual end button")
	_press(first, "Close")
	_press(first, "Start")
	_check(a.session.phase == CoreGameSession.Phase.CLOSED, "Closed instance cannot restart")
	_press(first, "CountRun")
	_press(first, "Start")
	first.queue_free()
	await process_frame
	await process_frame
	_check(a.session.phase == CoreGameSession.Phase.CLOSED and a.session.changed.get_connections().is_empty(), "Owner exit closes and unbinds session")
	_check(b.session.phase == CoreGameSession.Phase.PREPARING, "Exit does not affect B")
	second.queue_free()
	await process_frame
	_check(b.session.phase == CoreGameSession.Phase.CLOSED, "Both owners clean up")
	if not _failed:
		print("PASS: %d session example checks" % _checks)
	quit(1 if _failed else 0)

func _press(example: Control, name: String) -> void:
	example.get_node("Layout/" + name).emit_signal("pressed")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
