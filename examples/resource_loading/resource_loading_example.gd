extends Control

@export_file("*.tres", "*.tscn") var resource_path: String = "res://addons/godot_core_system/examples/resource_loading/sample_gradient.tres"
@onready var resources: CoreResources = $Resources
@onready var _status: Label = $Layout/Status
@onready var _counts: Label = $Layout/Counts
@onready var _progress: ProgressBar = $Layout/Progress
@onready var _template: ColorRect = $Layout/Preview/Template
@onready var _clone: ColorRect = $Layout/Preview/Clone

var active_request: CoreResourceRequest:
	get:
		return _active
var _active: CoreResourceRequest
var _copy: Gradient

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Layout/LoadNow.pressed.connect(_load_now)
	$Layout/Request.pressed.connect(_request)
	$Layout/Cancel.pressed.connect(_cancel)
	$Layout/ClearCache.pressed.connect(_clear_cache)
	$Layout/Missing.pressed.connect(_missing)
	$Layout/Clone.pressed.connect(_clone_resource)
	$Layout/NewOwner.pressed.connect(_new_owner)
	$Layout/Leave.pressed.connect(_leave)
	_status.text = "Load the template, request it twice, or leave while a request is pending."

func _process(_delta: float) -> void:
	_counts.text = "Cached: %d   Interested: %d   Native jobs: %d" % [resources.cache_count, resources.pending_count, resources.inflight_count]
	_progress.value = _active.progress * 100.0 if _active != null else 0.0

func _load_now() -> void:
	_show_result(resources.load_resource(resource_path))

func _request() -> void:
	resources.evict(resource_path)
	var handle: CoreResourceRequest = resources.request(resource_path)
	var duplicate: CoreResourceRequest = resources.request(resource_path)
	_status.text = "Duplicate requests share one pending handle: %s" % (handle == duplicate)
	if _active == handle:
		return
	_active = handle
	if handle.is_completed:
		_show_result(handle.result)
	else:
		handle.completed.connect(_on_completed.bind(handle), CONNECT_ONE_SHOT)

func _cancel() -> void:
	_status.text = "Cancellation accepted: %s. Native work is collected separately." % resources.cancel(resource_path)

func _clear_cache() -> void:
	resources.clear_cache()
	_status.text = "Local cache cleared. Interested requests continue and caller references remain valid."

func _missing() -> void:
	_show_result(resources.request("res://missing_resource_example.tres").result)

func _clone_resource() -> void:
	var template: Gradient = resources.get_cached(resource_path) as Gradient
	if template == null:
		_status.text = "Load the gradient template before cloning."
		return
	_copy = template.duplicate() as Gradient
	_copy.set_color(0, Color.RED)
	_clone.color = _copy.get_color(0)
	_template.color = template.get_color(0)
	_status.text = "Clone changed to red. The shared template keeps its original color."

func _new_owner() -> void:
	_active = null
	resources.close()
	resources.queue_free()
	resources = CoreResources.new()
	add_child(resources)
	_copy = null
	_status.text = "New owner with an empty cache. Old requests cannot update this example."

func _on_completed(result: CoreResourceResult, handle: CoreResourceRequest) -> void:
	if is_inside_tree() and not is_queued_for_deletion() and _active == handle and not resources.is_closed:
		_show_result(result)

func _leave() -> void:
	resources.close()
	queue_free()

func _show_result(result: CoreResourceResult) -> void:
	_status.text = "Load result: %s" % error_string(result.error)
	var gradient: Gradient = result.resource as Gradient
	if gradient != null:
		_template.color = gradient.get_color(0)
