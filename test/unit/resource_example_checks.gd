extends SceneTree

const Loader: GDScript = preload("resource_test_loader.gd")
const EXAMPLE: String = "res://addons/godot_core_system/examples/resource_loading/resource_loading_example.tscn"
const SLOW: String = "user://resource_example.corecheck"

var _checks: int = 0
var _failed: bool = false

func _initialize() -> void:
	create_timer(10.0).timeout.connect(_timeout)
	_run.call_deferred()

func _run() -> void:
	var loader: ResourceFormatLoader = Loader.new()
	ResourceLoader.add_resource_format_loader(loader, true)
	var file: FileAccess = FileAccess.open(SLOW, FileAccess.WRITE)
	file.store_string("Test resource")
	file.close()
	var scene: PackedScene = load(EXAMPLE) as PackedScene
	var first: Control = scene.instantiate() as Control
	var second: Control = scene.instantiate() as Control
	root.add_child(first)
	root.add_child(second)
	var a: CoreResources = first.get("resources") as CoreResources
	var b: CoreResources = second.get("resources") as CoreResources
	_press(first, "LoadNow")
	_check(a.cache_count == 1 and b.cache_count == 0, "Load button and A/B cache isolation")
	_press(second, "LoadNow")
	var path: String = first.get("resource_path")
	var template: Gradient = a.get_cached(path) as Gradient
	var color: Color = template.get_color(0)
	_press(first, "Clone")
	_check(first.get_node("Layout/Preview/Clone").color == Color.RED, "Clone button edits copy")
	_check(template.get_color(0) == color and second.get_node("Layout/Preview/Template").color == color, "Copy does not mutate template or B")
	_press(first, "Missing")
	_check(first.get_node("Layout/Status").text.contains("Load result:"), "Failure button presents result")
	_press(first, "ClearCache")
	_check(a.cache_count == 0 and b.cache_count == 1, "Clear button affects only owner A")
	first.set("resource_path", SLOW)
	_press(first, "Request")
	var handle: CoreResourceRequest = first.get("active_request") as CoreResourceRequest
	_check(a.pending_count == 1 and a.inflight_count == 1, "Request button deduplicates native work")
	_press(first, "Cancel")
	_check(handle.result.error == ERR_SKIP and a.pending_count == 0, "Cancel button abandons interest")
	_press(first, "Request")
	var replacement: CoreResourceRequest = first.get("active_request") as CoreResourceRequest
	_press(first, "NewOwner")
	var fresh: CoreResources = first.get("resources") as CoreResources
	_check(a.is_closed and replacement.result.error == ERR_UNAVAILABLE and fresh.cache_count == 0, "Replacement button closes old owner")
	await _drain()
	_check(first.get_node("Layout/Status").text.begins_with("New owner"), "Old completion cannot overwrite replacement UI")
	_press(first, "Request")
	var leaving: CoreResourceRequest = first.get("active_request") as CoreResourceRequest
	_press(first, "Leave")
	await process_frame
	await process_frame
	_check(leaving.result.error == ERR_UNAVAILABLE, "Leave button settles outstanding request")
	await _drain()
	_check(is_instance_valid(second) and b.cache_count == 1, "Leaving A preserves B")
	second.queue_free()
	await process_frame
	await process_frame
	ResourceLoader.remove_resource_format_loader(loader)
	DirAccess.remove_absolute(SLOW)
	print("Resource example checks: %d %s" % [_checks, "FAIL" if _failed else "PASS"])
	quit(1 if _failed else 0)

func _drain() -> void:
	for _frame: int in range(600):
		if ResourceLoader.load_threaded_get_status(SLOW) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			return
		await process_frame
	_check(false, "Example native cleanup timeout")

func _press(scene: Control, name: String) -> void:
	var button: Button = scene.get_node("Layout/" + name) as Button
	button.pressed.emit()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)

func _timeout() -> void:
	push_error("Resource example checks timed out.")
	quit(1)
