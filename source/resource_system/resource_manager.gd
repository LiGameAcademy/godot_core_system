extends Node

## Legacy loading adapter. New consumers should own a CoreResources instance.
## Pool callers retain responsibility for stopping and resetting their actors.
enum LOAD_MODE { IMMEDIATE, LAZY }

signal resource_loaded(path: String, resource: Resource)
signal resource_unloaded(path: String)

var _loader: CoreResources
var _observed_requests: Dictionary[String, CoreResourceRequest] = {}
var _instance_pools: Dictionary[StringName, CoreInstancePool] = {}

func _exit_tree() -> void:
	for pool: CoreInstancePool in _instance_pools.values():
		pool.close()
	_instance_pools.clear()

func load_resource(path: String, mode: LOAD_MODE = LOAD_MODE.IMMEDIATE) -> Resource:
	var loader: CoreResources = _get_loader()
	if loader == null:
		return null
	var cached: Resource = loader.get_cached(path)
	if cached != null:
		return cached
	if mode == LOAD_MODE.IMMEDIATE:
		var result: CoreResourceResult = loader.load_resource(path)
		if result.error != OK:
			push_error("Resource load failed (%s): %s" % [error_string(result.error), path])
			return null
		resource_loaded.emit(path, result.resource)
		return result.resource
	var handle: CoreResourceRequest = loader.request(path)
	if handle.is_completed:
		_on_load_completed(handle.result, path, handle)
		return handle.result.resource
	if _observed_requests.get(path) != handle:
		_observed_requests[path] = handle
		handle.completed.connect(_on_load_completed.bind(path, handle), CONNECT_ONE_SHOT)
	return null

## This is now a pure query; it never silently performs a blocking reload.
func get_cached_resource(path: String) -> Resource:
	return _loader.get_cached(path) if is_instance_valid(_loader) else null

## Legacy clear also abandons pending results, so they cannot refill the cleared cache.
func clear_resource_cache(path: String = "") -> void:
	if not is_instance_valid(_loader):
		return
	if path.is_empty():
		var paths: Array[String] = _observed_requests.keys()
		_observed_requests.clear()
		for pending_path: String in paths:
			_loader.cancel(pending_path)
		_loader.clear_cache()
		resource_unloaded.emit("")
	else:
		_observed_requests.erase(path)
		var canceled: bool = _loader.cancel(path)
		var evicted: bool = _loader.evict(path)
		if canceled or evicted:
			resource_unloaded.emit(path)

## Deprecated: threaded completion is polled each frame, including while paused.
func set_lazy_load_interval(_interval: float) -> void:
	push_warning("set_lazy_load_interval is deprecated; CoreResources polls every frame.")

func get_instance(id: StringName) -> Node:
	if _instance_pools.has(id):
		return _instance_pools[id].take()
	return null

func recycle_instance(id: StringName, instance: Node) -> void:
	if not is_instance_valid(instance) or instance.is_queued_for_deletion():
		push_error("Cannot recycle an invalid instance.")
		return
	if not _instance_pools.has(id):
		_instance_pools[id] = CoreInstancePool.new()
	if instance.get_parent():
		instance.get_parent().remove_child(instance)
	var error: Error = _instance_pools[id].recycle(instance)
	if error != OK:
		push_error("Instance recycle failed: %s" % error_string(error))

func get_instance_count(id: StringName = "") -> int:
	if id.is_empty():
		var count: int = 0
		for pool: CoreInstancePool in _instance_pools.values():
			count += pool.cached_count
		return count
	return _instance_pools[id].cached_count if _instance_pools.has(id) else 0

func clear_instance_pool(id: StringName = "") -> void:
	if id.is_empty():
		for pool: CoreInstancePool in _instance_pools.values():
			pool.clear()
	elif _instance_pools.has(id):
		_instance_pools[id].clear()
	else:
		push_error("Instance pool for id %s does not exist." % id)

func _get_loader() -> CoreResources:
	if not is_inside_tree():
		push_error("ResourceManager must be inside the scene tree before loading.")
		return null
	if not is_instance_valid(_loader):
		_loader = CoreResources.new()
		_loader.name = "CoreResources"
		add_child(_loader)
	return _loader

func _on_load_completed(result: CoreResourceResult, path: String, handle: CoreResourceRequest) -> void:
	if not handle.is_completed or not is_inside_tree():
		return
	if _observed_requests.has(path) and _observed_requests[path] != handle:
		return
	_observed_requests.erase(path)
	if result.error == ERR_SKIP or result.error == ERR_UNAVAILABLE:
		return
	if result.error == OK:
		resource_loaded.emit(path, result.resource)
	else:
		push_error("Resource load failed (%s): %s" % [error_string(result.error), path])

## Exposes the owned loader for explicit compatibility composition.
func get_resource_service() -> CoreResources:
	return _get_loader()
