extends Node

## Internal cleanup of abandoned native load tokens; it never retains a request or its owner.
var _paths: Array[String] = []
var _root: Window
var _done: bool = false

func start(paths: Array[String], tree: SceneTree, shutting_down: bool) -> void:
	_paths = paths
	_root = tree.root
	process_mode = Node.PROCESS_MODE_ALWAYS
	if shutting_down:
		_flush()
		return
	_root.tree_exiting.connect(_flush)
	_attach.call_deferred()

func _process(_delta: float) -> void:
	for path: String in _paths.duplicate():
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_paths.erase(path)
		if status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_get(path)
	if _paths.is_empty():
		_finish()

func _attach() -> void:
	if not _done:
		_root.add_child(self)

func _flush() -> void:
	# Waiting is restricted to application shutdown, when no future frame can poll the jobs.
	var paths: Array[String] = _paths.duplicate()
	_paths.clear()
	for path: String in paths:
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_get(path)
	_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	if is_instance_valid(_root) and _root.tree_exiting.is_connected(_flush):
		_root.tree_exiting.disconnect(_flush)
	queue_free()
