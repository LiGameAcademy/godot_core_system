extends Node

const ResourceManager = preload("../../source/resource_system/resource_manager.gd")
var _manager: ResourceManager
var _loaded: Dictionary[String, int] = {}
var _consume_other: String = ""
var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	_manager = ResourceManager.new()
	add_child(_manager)
	_manager.resource_loaded.connect(_on_loaded)
	var directory: String = "res://lazy_checks_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	var path: String = directory.path_join("one.tres")
	var other: String = directory.path_join("two.tres")
	ResourceSaver.save(Resource.new(), path)
	ResourceSaver.save(Resource.new(), other)
	_manager.load_resource(path, _manager.LOAD_MODE.LAZY)
	_manager.load_resource(path, _manager.LOAD_MODE.LAZY)
	_check(_manager._loading_count == 1, "Duplicate path has one pending request")
	await _wait()
	_check(_manager._loading_count == 0 and _loaded.get(path, 0) == 1, "One request produces one completion and no residual count")
	_manager.clear_resource_cache()
	_loaded.clear()
	_manager.load_resource(path, _manager.LOAD_MODE.LAZY)
	_manager.clear_resource_cache(path)
	await _wait()
	_check(not _manager._resource_cache.has(path) and _loaded.get(path, 0) == 0, "Cleared in-flight request is drained without republishing")
	_manager.load_resource(path, _manager.LOAD_MODE.LAZY)
	_manager.clear_resource_cache(path)
	_manager.load_resource(path, _manager.LOAD_MODE.LAZY)
	await _wait()
	_check(_manager._resource_cache.get(path) != null and _loaded.get(path, 0) == 1, "New request after clear can reuse the actual pending operation")
	_manager.clear_resource_cache()
	_manager.load_resource(path, _manager.LOAD_MODE.LAZY)
	_manager.load_resource(other, _manager.LOAD_MODE.LAZY)
	_manager.clear_resource_cache()
	await _wait()
	_check(_manager._loading_count == 0 and _manager._resource_cache.is_empty(), "Clear-all drains all in-flight paths")
	_manager.load_resource(path, _manager.LOAD_MODE.LAZY)
	_check(_manager.get_cached_resource(path) != null and _manager._loading_count == 0, "Immediate cache lookup consumes its pending request once")
	_manager.load_resource(directory.path_join("missing.tres"), _manager.LOAD_MODE.LAZY)
	_check(_manager._loading_count == 0, "Missing request does not add pending state")
	var broken: String = directory.path_join("broken.tres")
	var file: FileAccess = FileAccess.open(broken, FileAccess.WRITE)
	file.store_string("invalid resource text")
	file.close()
	_manager.load_resource(broken, _manager.LOAD_MODE.LAZY)
	await _wait()
	_check(_manager._loading_count == 0 and not _manager._resource_cache.has(broken), "Failed resource request is removed")
	_manager.clear_resource_cache()
	_loaded.clear()
	_manager.load_resource(path, _manager.LOAD_MODE.LAZY)
	_manager.load_resource(other, _manager.LOAD_MODE.LAZY)
	_consume_other = other
	await _wait()
	_check(_loaded.get(path, 0) == 1 and _loaded.get(other, 0) == 1, "A completion callback can consume another pending path without duplicate publication")
	_manager.clear_resource_cache()
	for item: String in [path, other, broken]:
		DirAccess.remove_absolute(item)
	DirAccess.remove_absolute(directory)
	print("%s: %d lazy resource checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _wait() -> void:
	var deadline: int = Time.get_ticks_msec() + 5000
	while _manager._loading_count > 0 and Time.get_ticks_msec() < deadline:
		_manager._lazy_load(1.1)
		await get_tree().process_frame
	_check(_manager._loading_count == 0, "Pending operations finish before timeout")

func _on_loaded(path: String, _resource: Resource) -> void:
	_loaded[path] = _loaded.get(path, 0) + 1
	if not _consume_other.is_empty():
		var other: String = _consume_other
		_consume_other = ""
		_check(_manager.get_cached_resource(other) != null, "Reentrant synchronous lookup consumes its pending request")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
