class_name CoreScenes
extends RefCounted

## Native main-scene switching. All calls must run on the Godot main thread.
var is_switching: bool:
	get: return _pending != null
var _tree: SceneTree
var _pending: CoreSceneRequest
var _awaiting_scene: bool = false
var _disposed: bool = false

func _init(tree: SceneTree) -> void:
	_tree = tree
	if is_instance_valid(_tree):
		_tree.scene_changed.connect(_on_scene_changed)

func switch_to_path(path: String) -> CoreSceneRequest:
	if _disposed or not is_instance_valid(_tree):
		return _completed(ERR_UNAVAILABLE)
	if is_switching:
		return _completed(ERR_BUSY)
	if path.strip_edges().is_empty():
		return _completed(ERR_INVALID_PARAMETER)
	if not ResourceLoader.exists(path, "PackedScene"):
		return _completed(ERR_CANT_OPEN)
	var resource: Resource = ResourceLoader.load(path, "PackedScene")
	if resource == null:
		return _completed(ERR_CANT_OPEN)
	if not resource is PackedScene:
		return _completed(ERR_INVALID_PARAMETER)
	return switch_to_packed(resource as PackedScene)

func switch_to_packed(scene: PackedScene) -> CoreSceneRequest:
	if _disposed or not is_instance_valid(_tree):
		return _completed(ERR_UNAVAILABLE)
	if is_switching:
		return _completed(ERR_BUSY)
	if not is_instance_valid(scene) or not scene.can_instantiate():
		return _completed(ERR_INVALID_PARAMETER)
	var request: CoreSceneRequest = CoreSceneRequest.new()
	_pending = request
	_begin.call_deferred(scene, request)
	return request

func dispose() -> void:
	if _disposed:
		return
	_disposed = true
	if is_instance_valid(_tree) and _tree.scene_changed.is_connected(_on_scene_changed):
		_tree.scene_changed.disconnect(_on_scene_changed)
	_complete(ERR_UNAVAILABLE)

func _begin(scene: PackedScene, request: CoreSceneRequest) -> void:
	if _disposed or _pending != request:
		return
	if not is_instance_valid(_tree):
		_complete(ERR_UNAVAILABLE)
		return
	if not is_instance_valid(scene) or not scene.can_instantiate():
		_complete(ERR_INVALID_PARAMETER)
		return
	_awaiting_scene = true
	var result: Error = _tree.change_scene_to_packed(scene)
	if result != OK:
		_complete(result)

func _on_scene_changed() -> void:
	if _awaiting_scene:
		_complete(OK)

func _complete(result: Error) -> void:
	var request: CoreSceneRequest = _pending
	_pending = null
	_awaiting_scene = false
	if request != null:
		request.complete(result)

func _completed(result: Error) -> CoreSceneRequest:
	var request: CoreSceneRequest = CoreSceneRequest.new()
	request.complete(result)
	return request
