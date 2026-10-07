extends SceneTree

var _checks: int = 0
var _failed: bool = false
var _exit_count: int = 0
var _reentrant: Error = OK
const SCENE_A: String = "res://addons/godot_core_system/examples/native_scenes/scene_a.tscn"
const SCENE_B: String = "res://addons/godot_core_system/examples/native_scenes/scene_b.tscn"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var host: CoreSceneExampleHost = root.get_node("SceneExampleHost") as CoreSceneExampleHost
	var scenes: CoreScenes = host.scenes
	var transition: CoreSceneTransition = host.transition
	var missing: CoreSceneRequest = scenes.switch_to_path("res://missing_parity_scene.tscn")
	_check(await missing.wait() == ERR_CANT_OPEN and not scenes.is_switching, "Missing path releases the guard")
	_check(await scenes.switch_to_path(" ").wait() == ERR_INVALID_PARAMETER, "Empty path rejected")
	_check(await scenes.switch_to_packed(PackedScene.new()).wait() == ERR_INVALID_PARAMETER, "Empty packed scene rejected")
	var request: CoreSceneRequest = scenes.switch_to_path(SCENE_A)
	_check(not request.is_completed and scenes.is_switching, "Native switch is deferred")
	_check(await scenes.switch_to_path(SCENE_B).wait() == ERR_BUSY, "Duplicate native request rejected")
	_check(await request.wait() == OK and current_scene.get_node("Layout/Title").text == "Scene A", "Native completion follows scene initialization")
	var first: Node = current_scene
	first.tree_exiting.connect(func() -> void:
		_exit_count += 1
		_reentrant = scenes.switch_to_path(SCENE_A).result)
	paused = true
	Engine.time_scale = 8.0
	await process_frame
	await process_frame
	transition.duration = 0.1
	var began: int = Time.get_ticks_msec()
	request = transition.switch_to(scenes, SCENE_B)
	_check(transition.is_transitioning and transition.get_node("Cover").visible, "Fade begins with input cover")
	_check(await transition.switch_to(scenes, SCENE_A).wait() == ERR_BUSY, "Duplicate transition rejected")
	_check(await request.wait() == OK, "Paused transition succeeds")
	_check(Time.get_ticks_msec() - began >= 180, "Animation ignores gameplay speed")
	_check(not is_instance_valid(first) and _exit_count == 1 and _reentrant == ERR_BUSY, "Old scene exits and is freed; exit reentry is rejected")
	_check(paused and Engine.time_scale == 8.0, "Animation does not alter engine time")
	_check(not transition.is_transitioning and not transition.get_node("Cover").visible, "New scene revealed before completion")
	var retained: Node = current_scene
	request = transition.switch_to(scenes, "res://missing_parity_scene.tscn")
	_check(await request.wait() == ERR_CANT_OPEN and current_scene == retained, "Failure reveals the original scene")
	_check(not transition.is_transitioning and not transition.get_node("Cover").visible, "Failure releases input cover")
	paused = false
	Engine.time_scale = 1.0
	var cancelled: CoreScenes = CoreScenes.new(self)
	request = cancelled.switch_to_path(SCENE_A)
	cancelled.dispose()
	cancelled.dispose()
	_check(await request.wait() == ERR_UNAVAILABLE, "Dispose settles queued native request")
	await process_frame
	_check(current_scene == retained, "Disposed queued request does not switch")
	_check(await cancelled.switch_to_path(SCENE_A).wait() == ERR_UNAVAILABLE, "Disposed service rejects future requests")
	var departing: CoreSceneTransition = load("res://addons/godot_core_system/source/scene_system/core_scene_transition.tscn").instantiate() as CoreSceneTransition
	host.add_child(departing)
	request = departing.switch_to(scenes, SCENE_A)
	host.remove_child(departing)
	departing.free()
	_check(await request.wait() == ERR_UNAVAILABLE and not scenes.is_switching, "Freed transition settles fade without submitting a switch")
	transition.duration = 0.0
	for index: int in range(3):
		request = transition.switch_to(scenes, SCENE_A if index % 2 == 0 else SCENE_B)
		_check(await request.wait() == OK and not transition.is_transitioning, "Zero-duration repeated switches complete")
	transition.duration = 0.03
	var outgoing: Node = current_scene
	outgoing.get_node("Layout/Next").emit_signal("pressed")
	_check(transition.is_transitioning, "Actual example button starts the transition")
	while transition.is_transitioning:
		await process_frame
	_check(not is_instance_valid(outgoing), "Example callback is disconnected when its scene is freed")
	unload_current_scene()
	scenes.dispose()
	if not _failed:
		print("PASS: %d GDScript scene parity checks" % _checks)
	quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
