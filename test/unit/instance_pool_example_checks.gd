extends SceneTree

var _checks: int = 0
var _failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var demo: Control = load("res://addons/godot_core_system/examples/instance_pool/instance_pool.tscn").instantiate()
	root.add_child(demo)
	var actors: Node = demo.get_node("Actors")
	(demo.get_node("Panel/Spawn") as Button).pressed.emit()
	_check(actors.get_child_count() == 2, "Button spawns A/B")
	var a: PoolActor = actors.get_child(0) as PoolActor
	var b: PoolActor = actors.get_child(1) as PoolActor
	var original: Color = a.palette.get_color(0)
	_check(a.current_color() == original and b.current_color() == original, "Fresh actors use template color")
	(demo.get_node("Panel/Tint") as Button).pressed.emit()
	_check(a.current_color() == Color.RED and b.current_color() == original and a.palette.get_color(0) == original, "Tint isolates A/B/template")
	(demo.get_node("Panel/Recycle") as Button).pressed.emit()
	_check(actors.get_child_count() == 0 and a.get_parent() == null and b.get_parent() == null, "Button detaches actors before admission")
	demo.spawn_pair()
	_check(actors.get_child_count() == 2 and actors.get_child(0) == b and actors.get_child(1) == a, "Second wave preserves node identities")
	_check(a.current_color() == original and b.current_color() == original, "Activation resets mutable color")
	demo.clear_pool()
	_check(is_instance_valid(a) and is_instance_valid(b), "Clear retains active leases")
	demo.recycle_all()
	demo.clear_pool()
	_check(not is_instance_valid(a) and not is_instance_valid(b), "Clear frees returned instances")
	demo.spawn_pair()
	demo.recycle_all()
	demo.spawn_pair()
	var lease: Node = actors.get_child(0)
	demo.queue_free()
	await process_frame
	await process_frame
	_check(not is_instance_valid(lease), "Scene exit releases active leases")
	print("Instance pool example checks: %d %s" % [_checks, "FAIL" if _failed else "PASS"])
	quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
