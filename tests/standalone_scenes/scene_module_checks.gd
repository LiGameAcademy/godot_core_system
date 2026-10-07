extends Node

const SCENE_A: String = "res://fixtures/scene_a.tscn"
const SCENE_B: String = "res://fixtures/scene_b.tscn"
var _checks: int = 0
var _failed: bool = false
var _completions: int = 0
var _scenes: CoreScenes

func _ready() -> void:
	await get_tree().process_frame
	_check(not get_tree().root.has_node("CoreSystem"), "No legacy CoreSystem AutoLoad is installed")
	_check(not FileAccess.file_exists("res://addons/godot_core_system/source/core_system.gd"), "The whole plugin entry is absent")
	_check(not DirAccess.dir_exists_absolute("res://addons/godot_core_system/source/logger"), "The logger module is absent")
	_check(not DirAccess.dir_exists_absolute("res://addons/godot_core_system/source/resource_system"), "The resource module is absent")
	_check(get_tree().current_scene.name == "SceneA", "The real initial main scene is A")
	_scenes = CoreScenes.new(get_tree())
	var missing: CoreSceneRequest = _scenes.switch_to_path("res://fixtures/missing.tscn")
	_check(await missing.wait() == ERR_CANT_OPEN, "Missing path completes with failure")
	_check(not _scenes.is_switching, "Missing path does not hold the switch lock")
	var old_scene: WeakRef = weakref(get_tree().current_scene)
	var first: CoreSceneRequest = _scenes.switch_to_path(SCENE_B)
	first.completed.connect(_on_completed)
	var duplicate: CoreSceneRequest = _scenes.switch_to_path(SCENE_A)
	_check(await duplicate.wait() == ERR_BUSY, "Concurrent request receives a completed busy result")
	_check(await first.wait() == OK, "A to B completes successfully")
	_check(get_tree().current_scene.name == "SceneB", "The actual SceneTree current scene is B")
	_check(old_scene.get_ref() == null, "The old main scene has been released")
	_check(_completions == 1 and not _scenes.is_switching, "The successful request completes exactly once")
	var transition: CoreSceneTransition = CoreSceneTransition.attach_to(self)
	transition.duration = 0.0
	var back: CoreSceneRequest = transition.switch_to(_scenes, SCENE_A)
	_check(await back.wait() == OK and get_tree().current_scene.name == "SceneA", "Optional presentation completes B to A")
	_check(not transition.is_transitioning, "Presentation restores its idle state")
	var rejected: CoreSceneRequest = transition.switch_to(_scenes, "res://fixtures/missing.tscn")
	_check(await rejected.wait() == ERR_CANT_OPEN, "Presentation forwards a failed scene result")
	_check(not transition.is_transitioning, "Failed presentation releases its transition lock")
	var presentation_owner: Node = Node.new()
	add_child(presentation_owner)
	var transient: CoreSceneTransition = CoreSceneTransition.attach_to(presentation_owner)
	transient.duration = 0.1
	var interrupted: CoreSceneRequest = transient.switch_to(_scenes, SCENE_B)
	presentation_owner.free()
	_check(await interrupted.wait() == ERR_UNAVAILABLE, "Presentation owner exit completes its fade operation")
	_check(not _scenes.is_switching, "Interrupted presentation leaves the service available")
	var temporary: Node = Node.new()
	add_child(temporary)
	var owned: CoreScenes = CoreScenes.new(get_tree())
	temporary.tree_exiting.connect(owned.dispose)
	var canceled: CoreSceneRequest = owned.switch_to_path(SCENE_B)
	temporary.free()
	_check(await canceled.wait() == ERR_UNAVAILABLE, "Owner exit completes its pending request")
	_check(await owned.switch_to_path(SCENE_B).wait() == ERR_UNAVAILABLE, "Disposed service rejects new requests")
	await get_tree().process_frame
	await get_tree().process_frame
	_check(get_tree().current_scene.name == "SceneA", "Canceled deferred switch cannot change the scene later")
	owned.dispose()
	_scenes.dispose()
	transition.queue_free()
	await get_tree().process_frame
	print("%s: %d standalone scene module checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _exit_tree() -> void:
	if _scenes != null:
		_scenes.dispose()

func _on_completed(_result: Error) -> void:
	_completions += 1

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
