extends Node

## Compatibility adapter. New code should keep CoreEntityLease values directly.
signal entity_loaded(entity_id: StringName, entity: PackedScene)
signal entity_unloaded(entity_id: StringName)
signal entity_created(entity_id: StringName, entity: Node)
signal entity_destroyed(entity_id: StringName, entity: Node)
enum LOAD_MODE { IMMEDIATE, LAZY }

var last_error: Error = OK
var _closed: bool = false
var _clearing: bool = false
var _closing: Dictionary[StringName, bool] = {}
var _resources: CoreResources
var _groups: Dictionary[StringName, CoreEntities] = {}
var _scenes: Dictionary[StringName, PackedScene] = {}
var _paths: Dictionary[StringName, String] = {}
var _watchers: Dictionary[StringName, Callable] = {}
var _requests: Dictionary[StringName, CoreResourceRequest] = {}

func configure(resources: CoreResources) -> Error:
	if not _groups.is_empty() or not _requests.is_empty():
		return ERR_ALREADY_IN_USE
	_resources = resources
	return OK

func _exit_tree() -> void:
	_closed = true
	for id: StringName in _requests.keys():
		_unwatch(id)
	for group: CoreEntities in _groups.values():
		group.close()
	_groups.clear()
	_scenes.clear()
	_paths.clear()

func get_entity_scene(id: StringName) -> PackedScene:
	return _scenes.get(id)

func load_entity(id: StringName, path: String, mode: int = LOAD_MODE.IMMEDIATE) -> PackedScene:
	last_error = OK
	if _closed or _clearing or _closing.has(id) or not is_instance_valid(_resources) or _resources.is_closed:
		last_error = ERR_UNAVAILABLE
		return null
	if id.is_empty() or (mode != LOAD_MODE.IMMEDIATE and mode != LOAD_MODE.LAZY):
		last_error = ERR_INVALID_PARAMETER
		return null
	if _paths.has(id):
		if _paths[id] != path:
			last_error = ERR_ALREADY_IN_USE
		return _scenes.get(id)
	_paths[id] = path
	if mode == LOAD_MODE.IMMEDIATE:
		_accept(_resources.load_resource(path), id)
	else:
		var handle: CoreResourceRequest = _resources.request(path)
		if handle.is_completed:
			_accept(handle.result, id)
		else:
			_requests[id] = handle
			# A distinct closure is required: bound method equality can collide for shared handles.
			var watcher: Callable = func(value: CoreResourceResult) -> void: _on_completed(value, id, handle)
			_watchers[id] = watcher
			handle.completed.connect(watcher)
	return _scenes.get(id)

func unload_entity(id: StringName) -> void:
	last_error = ERR_DOES_NOT_EXIST
	if not _paths.has(id):
		return
	if _closed or _clearing or _closing.has(id):
		last_error = ERR_UNAVAILABLE
		return
	_closing[id] = true
	_unwatch(id)
	var group: CoreEntities = _groups.get(id)
	_groups.erase(id)
	_scenes.erase(id)
	_paths.erase(id)
	if group != null:
		group.close()
	last_error = OK
	entity_unloaded.emit(id)
	_closing.erase(id)

## The explicit parent must already be inside the tree. Failed initialization is released.
func create_entity(id: StringName, config: Resource, parent: Node = null) -> Node:
	if _closed or _clearing or _closing.has(id):
		last_error = ERR_UNAVAILABLE
		return null
	last_error = ERR_DOES_NOT_EXIST
	if not _groups.has(id):
		return null
	var result: CoreEntityResult = _groups[id].create(parent, _initialize.bind(config))
	last_error = result.error
	if result.error != OK:
		return null
	var instance: Node = result.lease.node
	entity_created.emit(id, instance)
	return instance if is_instance_valid(instance) and not instance.is_queued_for_deletion() else null

func update_entity(instance: Node, config: Resource) -> void:
	if _closed or _clearing:
		last_error = ERR_UNAVAILABLE
		return
	last_error = ERR_DOES_NOT_EXIST
	for group: CoreEntities in _groups.values():
		for lease: CoreEntityLease in group.get_leases():
			if lease.node == instance:
				last_error = group.update(lease, _update.bind(config))
				return

func destroy_entity(id: StringName, instance: Node) -> void:
	if _closed or _clearing or _closing.has(id):
		last_error = ERR_UNAVAILABLE
		return
	last_error = ERR_DOES_NOT_EXIST
	if not _groups.has(id):
		return
	for lease: CoreEntityLease in _groups[id].get_leases():
		if lease.node == instance:
			last_error = _groups[id].recycle(lease, _deactivate)
			if last_error == OK:
				entity_destroyed.emit(id, instance if is_instance_valid(instance) else null)
			return

func clear_entities() -> void:
	if _closed or _clearing:
		return
	_clearing = true
	for id: StringName in _requests.keys():
		_unwatch(id)
		_paths.erase(id)
	for group: CoreEntities in _groups.values():
		group.clear()
	_clearing = false

func _on_completed(result: CoreResourceResult, id: StringName, handle: CoreResourceRequest) -> void:
	if _requests.get(id) != handle:
		return
	_unwatch(id)
	_accept(result, id)

func _accept(result: CoreResourceResult, id: StringName) -> void:
	last_error = result.error
	if result.error != OK or not result.resource is PackedScene:
		if result.error == OK:
			last_error = ERR_INVALID_DATA
		_paths.erase(id)
		return
	var scene: PackedScene = result.resource as PackedScene
	if not scene.can_instantiate():
		last_error = ERR_CANT_CREATE
		_paths.erase(id)
		return
	_scenes[id] = scene
	_groups[id] = CoreEntities.new(scene, CoreInstancePool.new())
	entity_loaded.emit(id, scene)

func _unwatch(id: StringName) -> void:
	if _requests.has(id):
		var handle: CoreResourceRequest = _requests[id]
		var watcher: Callable = _watchers[id]
		if handle.completed.is_connected(watcher):
			handle.completed.disconnect(watcher)
	_requests.erase(id)
	_watchers.erase(id)

static func _initialize(instance: Node, config: Resource) -> Error:
	if not instance.has_method("initialize"):
		return ERR_METHOD_NOT_FOUND
	return _legacy_result(instance.call("initialize", config))

static func _update(instance: Node, config: Resource) -> Error:
	if not instance.has_method("update"):
		return ERR_METHOD_NOT_FOUND
	return _legacy_result(instance.call("update", config))

static func _deactivate(instance: Node) -> Error:
	if instance.has_method("destroy"):
		return _legacy_result(instance.call("destroy"))
	return OK


static func _legacy_result(value: Variant) -> Error:
	if value == null:
		return OK
	if value is int and int(value) >= OK and int(value) <= ERR_PRINTER_ON_FIRE:
		return int(value) as Error
	return ERR_INVALID_DATA
