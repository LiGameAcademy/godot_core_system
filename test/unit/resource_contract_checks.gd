extends SceneTree

const Loader: GDScript = preload("resource_test_loader.gd")
const Legacy: GDScript = preload("../../source/resource_system/resource_manager.gd")
const FIXTURE: String = "res://addons/godot_core_system/examples/resource_loading/sample_gradient.tres"
const SLOW: String = "user://resource_checks/slow.corecheck"
const FAILURE: String = "user://resource_checks/failure.corecheck"
const EXIT: String = "user://resource_checks/exit.corecheck"
const SHUTDOWN: String = "user://resource_checks/shutdown.corecheck"
const CANCEL: String = "user://resource_checks/cancel.corecheck"

var _checks: int = 0
var _failed: bool = false
var _loader: ResourceFormatLoader
var _notifications: int = 0

func _initialize() -> void:
	create_timer(10.0).timeout.connect(_timeout)
	_run.call_deferred()

func _run() -> void:
	_loader = Loader.new()
	ResourceLoader.add_resource_format_loader(_loader, true)
	DirAccess.make_dir_recursive_absolute("user://resource_checks")
	for path: String in [SLOW, FAILURE, EXIT, SHUTDOWN, CANCEL]:
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file.store_string("Test resource")
		file.close()
	var resources: CoreResources = CoreResources.new()
	_check(resources.request(FIXTURE).result.error == ERR_UNAVAILABLE, "Detached owner rejects requests")
	root.add_child(resources)
	_check(resources.get_cached(FIXTURE) == null and resources.inflight_count == 0, "Cache lookup has no IO")
	_check(resources.load_resource("res://../outside.tres").error == ERR_INVALID_PARAMETER, "Root escape rejected")
	_check(resources.request("sample_gradient.tres").result.error == ERR_INVALID_PARAMETER, "Relative path rejected")
	_check(resources.request("res://missing.tres").result.error == ERR_CANT_OPEN, "Missing resource fails")
	var immediate: CoreResourceResult = resources.load_resource(FIXTURE)
	_check(immediate.error == OK and immediate.resource is Gradient, "Immediate real resource load")
	_check(resources.cache_count == 1, "Only completed resource cached")
	_check(resources.load_resource(FIXTURE).resource == immediate.resource, "Cache hit shares resource")
	_check(resources.request(FIXTURE).is_completed, "Cached request completes immediately")
	var original: Gradient = immediate.resource as Gradient
	var clone: Gradient = original.duplicate() as Gradient
	var unchanged: Color = original.get_color(0)
	clone.set_color(0, Color.RED)
	_check(original.get_color(0) == unchanged, "Mutable clone leaves template unchanged")
	resources.evict(FIXTURE)
	_check(is_instance_valid(original) and resources.cache_count == 0, "Eviction preserves caller reference")
	var first: CoreResourceRequest = resources.request(SLOW)
	_check(not first.is_completed and resources.pending_count == 1, "Request enters pending state")
	_check(resources.request("user://resource_checks/./other/../slow.corecheck") == first, "Canonical duplicates share handle")
	_check(resources.inflight_count == 1 and resources.cache_count == 0, "Pending jobs kept out of cache")
	_check(resources.load_resource(SLOW).error == ERR_BUSY, "Immediate load does not wait for job")
	first.completed.connect(_on_canceled.bind(resources), CONNECT_ONE_SHOT)
	_check(resources.cancel(SLOW), "Cancellation accepted")
	_check(first.result.error == ERR_SKIP and _notifications == 1, "Cancellation notifies once")
	_check(not resources.cancel(SLOW), "Duplicate cancellation rejected")
	_check(resources.pending_count == 0 and resources.inflight_count == 1, "Native job remains after cancel")
	var adopted: CoreResourceRequest = resources.request(SLOW)
	_check(adopted != first and resources.inflight_count == 1, "New request adopts abandoned job")
	resources.clear_cache()
	paused = true
	await _wait(adopted)
	paused = false
	_check(adopted.result != null and adopted.result.error == OK, "Loading continues while paused")
	_check(adopted.progress == 1.0 and resources.pending_count == 0, "Completed progress and counters")
	_check(resources.get_cached(SLOW) == adopted.result.resource, "Clear cache keeps interested request")
	_check(first.result.error == ERR_SKIP and _notifications == 1, "No late canceled result")
	resources.request(CANCEL)
	resources.cancel(CANCEL)
	await _drain(CANCEL)
	_check(resources.get_cached(CANCEL) == null and resources.inflight_count == 0, "Abandoned job collected without filling cache")
	var other: CoreResources = CoreResources.new()
	root.add_child(other)
	other.load_resource(FIXTURE)
	resources.clear_cache()
	_check(other.cache_count == 1 and resources.cache_count == 0, "Owner caches are independent")
	other.close()
	_check(other.cache_count == 0 and is_instance_valid(original), "Close drops local references only")
	root.remove_child(other)
	root.add_child(other)
	root.remove_child(other)
	_check(not root.tree_exiting.is_connected(other._on_shutdown), "Closed reentered owner leaves no subscription")
	other.free()
	var failed_request: CoreResourceRequest = resources.request(FAILURE)
	await _wait(failed_request)
	_check(failed_request.result != null and failed_request.result.error == ERR_CANT_OPEN, "Native loader failure propagates")
	_check(resources.inflight_count == 0 and resources.get_cached(FAILURE) == null, "Failure collects native job without caching")
	resources.evict(FIXTURE)
	var reentrant: CoreResourceRequest = resources.request(FIXTURE)
	reentrant.completed.connect(_on_reentrant.bind(resources), CONNECT_ONE_SHOT)
	await _wait(reentrant)
	_check(resources.is_closed and resources.cache_count == 0, "Completion can close owner after state commit")
	_check(resources.request(FIXTURE).result.error == ERR_UNAVAILABLE, "Closed owner is final")
	resources.close()
	resources.queue_free()
	var leaving: CoreResources = CoreResources.new()
	root.add_child(leaving)
	var late: CoreResourceRequest = leaving.request(EXIT)
	leaving.queue_free()
	await process_frame
	await process_frame
	_check(late.is_completed and late.result.error == ERR_UNAVAILABLE, "Owner exit settles pending request")
	await _drain(EXIT)
	_check(ResourceLoader.load_threaded_get_status(EXIT) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, "Exited native job collected")
	await _legacy_checks()
	for path: String in [SLOW, FAILURE, CANCEL]:
		DirAccess.remove_absolute(path)
	var shutdown_owner: CoreResources = CoreResources.new()
	root.add_child(shutdown_owner)
	shutdown_owner.request(SHUTDOWN)
	shutdown_owner.request(EXIT)
	shutdown_owner.close()
	# Quit immediately: exercise both an active owner and a deferred abandoned-job drainer.
	var active: CoreResources = CoreResources.new()
	root.add_child(active)
	active.request(SHUTDOWN)
	print("Resource contract checks: %d %s" % [_checks, "FAIL" if _failed else "PASS"])
	quit(1 if _failed else 0)

func _legacy_checks() -> void:
	var legacy: Node = Legacy.new()
	root.add_child(legacy)
	var events: Array[String] = []
	legacy.resource_loaded.connect(func(path: String, _resource: Resource) -> void: events.append(path))
	_check(legacy.get_cached_resource(FIXTURE) == null, "Legacy cache query no longer loads")
	legacy.load_resource(FIXTURE, Legacy.LOAD_MODE.LAZY)
	legacy.load_resource(FIXTURE, Legacy.LOAD_MODE.LAZY)
	for _frame: int in range(60):
		if not events.is_empty():
			break
		await process_frame
	_check(events.size() == 1 and legacy.get_cached_resource(FIXTURE) != null, "Legacy duplicate requests emit once")
	legacy.clear_resource_cache()
	_check(legacy.get_cached_resource(FIXTURE) == null, "Legacy clear drops cache")
	legacy.load_resource(SLOW, Legacy.LOAD_MODE.LAZY)
	legacy.clear_resource_cache()
	await _drain(SLOW)
	_check(legacy.get_cached_resource(SLOW) == null and events.size() == 1, "Legacy clear abandons pending result")
	legacy.queue_free()

func _on_canceled(result: CoreResourceResult, resources: CoreResources) -> void:
	_notifications += 1
	_check(result.error == ERR_SKIP and resources.pending_count == 0, "Cancel commits before notification")

func _on_reentrant(_result: CoreResourceResult, resources: CoreResources) -> void:
	_check(resources.pending_count == 0 and resources.cache_count == 1, "Load commits before notification")
	resources.close()

func _wait(handle: CoreResourceRequest) -> void:
	for _frame: int in range(600):
		if handle.is_completed:
			return
		await process_frame
	_check(false, "Request timeout")

func _drain(path: String) -> void:
	for _frame: int in range(600):
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			return
		await process_frame
	_check(false, "Native drain timeout")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)

func _timeout() -> void:
	push_error("Resource contract checks timed out.")
	quit(1)
