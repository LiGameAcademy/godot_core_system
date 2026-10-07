class_name CoreResources
extends Node

## Caller-owned resource cache and threaded requests. Use from the Godot main thread.
const Drain: GDScript = preload("core_resource_drain.gd")

var cache_count: int:
	get:
		return _cache.size()
var pending_count: int:
	get:
		var count: int = 0
		for request_handle: CoreResourceRequest in _jobs.values():
			if request_handle != null:
				count += 1
		return count
var inflight_count: int:
	get:
		return _jobs.size()
var is_closed: bool:
	get:
		return _closed

var _cache: Dictionary[String, Resource] = {}
var _jobs: Dictionary[String, CoreResourceRequest] = {}
var _closed: bool = false
var _shutting_down: bool = false

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _enter_tree() -> void:
	if not _closed:
		get_tree().root.tree_exiting.connect(_on_shutdown)

func _process(_delta: float) -> void:
	for path: String in _jobs.keys():
		if _closed or not _jobs.has(path):
			continue
		var handle: CoreResourceRequest = _jobs[path]
		var progress_values: Array = []
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path, progress_values)
		if handle != null and not progress_values.is_empty():
			handle._advance(float(progress_values[0]))
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_jobs.erase(path)
		var resource: Resource = null
		if status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			# Failed tokens must also be collected to release the native request.
			resource = ResourceLoader.load_threaded_get(path)
		if handle == null:
			continue
		var error: Error = OK if resource != null else ERR_CANT_OPEN
		if resource != null:
			_cache[path] = resource
		handle._finish(CoreResourceResult.new(error, resource))

func _exit_tree() -> void:
	close()

## Immediate loading may block. An outstanding native job returns ERR_BUSY instead.
func load_resource(path: String) -> CoreResourceResult:
	if not _check_main_thread():
		return CoreResourceResult.new(ERR_INVALID_PARAMETER)
	if not _available():
		return CoreResourceResult.new(ERR_UNAVAILABLE)
	var key: String = _key(path)
	if key.is_empty():
		return CoreResourceResult.new(ERR_INVALID_PARAMETER)
	var cached: Resource = get_cached(key)
	if cached != null:
		return CoreResourceResult.new(OK, cached)
	if _jobs.has(key):
		return CoreResourceResult.new(ERR_BUSY)
	if not ResourceLoader.exists(key):
		return CoreResourceResult.new(ERR_CANT_OPEN)
	var resource: Resource = ResourceLoader.load(key, "", ResourceLoader.CACHE_MODE_REUSE)
	if resource == null:
		return CoreResourceResult.new(ERR_CANT_OPEN)
	_cache[key] = resource
	return CoreResourceResult.new(OK, resource)

## Duplicate pending paths share one handle. Canceled jobs can be adopted by a new request.
func request(path: String) -> CoreResourceRequest:
	var handle: CoreResourceRequest = CoreResourceRequest.new()
	if not _check_main_thread():
		handle._finish(CoreResourceResult.new(ERR_INVALID_PARAMETER))
		return handle
	if not _available():
		handle._finish(CoreResourceResult.new(ERR_UNAVAILABLE))
		return handle
	var key: String = _key(path)
	if key.is_empty():
		handle._finish(CoreResourceResult.new(ERR_INVALID_PARAMETER))
		return handle
	var cached: Resource = get_cached(key)
	if cached != null:
		handle._finish(CoreResourceResult.new(OK, cached))
		return handle
	if _jobs.has(key):
		if _jobs[key] != null:
			return _jobs[key]
		_jobs[key] = handle
		return handle
	if not ResourceLoader.exists(key):
		handle._finish(CoreResourceResult.new(ERR_CANT_OPEN))
		return handle
	var error: Error = ResourceLoader.load_threaded_request(key, "", false, ResourceLoader.CACHE_MODE_REUSE)
	if error != OK:
		handle._finish(CoreResourceResult.new(error))
		return handle
	_jobs[key] = handle
	return handle

## Cache queries never start or wait for a load.
func get_cached(path: String) -> Resource:
	if not _check_main_thread():
		return null
	var key: String = _key(path)
	var resource: Resource = _cache.get(key)
	if resource != null and not is_instance_valid(resource):
		_cache.erase(key)
		return null
	return resource

func evict(path: String) -> bool:
	if not _check_main_thread():
		return false
	return _cache.erase(_key(path))

## Clearing completed resources does not cancel interested requests or destroy shared resources.
func clear_cache() -> void:
	if not _check_main_thread():
		return
	_cache.clear()

## Cancellation abandons the result, not the native Godot load. Duplicate callers share cancellation.
func cancel(path: String) -> bool:
	if not _check_main_thread():
		return false
	var key: String = _key(path)
	var handle: CoreResourceRequest = _jobs.get(key)
	if handle == null:
		return false
	_jobs[key] = null
	handle._finish(CoreResourceResult.new(ERR_SKIP))
	return true

func close() -> void:
	if not _check_main_thread():
		return
	if _closed:
		return
	_closed = true
	set_process(false)
	if is_inside_tree() and get_tree().root.tree_exiting.is_connected(_on_shutdown):
		get_tree().root.tree_exiting.disconnect(_on_shutdown)
	var paths: Array[String] = _jobs.keys()
	var handles: Array[CoreResourceRequest] = _jobs.values()
	_jobs.clear()
	_cache.clear()
	if not paths.is_empty():
		var drain: Node = Drain.new()
		drain.start(paths, get_tree(), _shutting_down)
	for handle: CoreResourceRequest in handles:
		if handle != null:
			handle._finish(CoreResourceResult.new(ERR_UNAVAILABLE))

func _on_shutdown() -> void:
	_shutting_down = true
	close()

func _available() -> bool:
	return not _closed and is_inside_tree() and not is_queued_for_deletion()

func _check_main_thread() -> bool:
	if OS.get_thread_caller_id() == OS.get_main_thread_id():
		return true
	push_error("CoreResources requires the main thread.")
	return false

func _key(path: String) -> String:
	var normalized: String = path.replace("\\", "/")
	var prefix: String = ""
	if normalized.begins_with("res://"):
		prefix = "res://"
	elif normalized.begins_with("user://"):
		prefix = "user://"
	else:
		return ""
	var parts: PackedStringArray = []
	for part: String in normalized.substr(prefix.length()).split("/", false):
		if part == ".":
			continue
		if part == "..":
			if parts.is_empty():
				return ""
			parts.remove_at(parts.size() - 1)
		else:
			parts.append(part)
	return "" if parts.is_empty() else prefix + "/".join(parts)
