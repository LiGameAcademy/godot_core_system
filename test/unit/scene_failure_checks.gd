extends Node

var _failed: bool = false
var _checks: int = 0
var _failures: int = 0
var _started: int = 0
var _finished: int = 0
var _changed: int = 0

func _ready() -> void:
	var tree: SceneTree = get_tree()
	await tree.process_frame
	var original: Node = Node.new()
	original.name = "OriginalScene"
	tree.root.add_child(original)
	tree.current_scene = original
	var manager: CoreSystem.CoreSceneManager = CoreSystem.scene_manager
	manager.scene_loading_started.connect(func(_path: String) -> void: _started += 1)
	manager.scene_loading_finished.connect(func() -> void: _finished += 1)
	manager.scene_changed.connect(func(_old: Node, _new: Node) -> void: _changed += 1)
	if manager.has_signal("scene_loading_failed"):
		manager.connect("scene_loading_failed", func(_path: String, _reason: String) -> void: _failures += 1)
	var directory: String = "res://scene_failure_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	var valid_path: String = directory.path_join("valid.tscn")
	var template: Node = Node.new()
	template.name = "ReplacementScene"
	var scene: PackedScene = PackedScene.new()
	scene.pack(template)
	ResourceSaver.save(scene, valid_path)
	template.free()
	var resource_path: String = directory.path_join("not_scene.tres")
	ResourceSaver.save(Resource.new(), resource_path)
	var empty_path: String = directory.path_join("empty.tscn")
	CoreSystem.resource_manager._resource_cache[empty_path] = PackedScene.new()
	for path: String in [directory.path_join("missing.tscn"), resource_path, empty_path]:
		await manager.change_scene_async(path)
		_check(not manager._is_switching, "Failed load releases the scene switch lock")
		_check(tree.current_scene == original, "Failed load preserves the current scene")
	await manager.change_scene_async(valid_path, {}, false, manager.TransitionEffect.CUSTOM, 0.0, Callable(), &"missing")
	_check(not manager._is_switching and tree.current_scene == original, "Unregistered custom transition fails before changing scenes")
	_check(_failures == 4 and _changed == 0, "Each rejected switch reports failure without scene_changed")
	await manager.change_scene_async(valid_path)
	_check(not manager._is_switching and tree.current_scene.name == "ReplacementScene", "Valid retry succeeds after rejected switches")
	_check(_changed == 1 and _started == 5 and _finished == 5, "Started and finished notifications are balanced")
	CoreSystem.resource_manager._resource_cache.erase(empty_path)
	manager.clear_scene_stack()
	for path: String in [valid_path, resource_path]:
		DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("%s: %d scene failure checks" % ["FAIL" if _failed else "PASS", _checks])
	tree.quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
