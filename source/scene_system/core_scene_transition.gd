class_name CoreSceneTransition
extends CanvasLayer

## Optional persistent presentation. The owner must outlive main-scene switches.
@export_range(0.0, 2.0, 0.05) var duration: float = 0.25
@onready var _cover: ColorRect = $Cover
var is_transitioning: bool = false
var _tween: Tween
var _fade: CoreSceneRequest
var _operation: CoreSceneTransitionOperation

static func attach_to(owner: Node) -> CoreSceneTransition:
	if not is_instance_valid(owner) or not owner.is_inside_tree():
		push_error("The transition owner must be in the tree.")
		return null
	var existing: Node = owner.get_node_or_null("CoreSceneTransition")
	if existing != null:
		if not existing is CoreSceneTransition:
			push_error("The transition node name is already in use.")
		return existing as CoreSceneTransition
	var packed: PackedScene = load("res://addons/godot_core_system/source/scene_system/core_scene_transition.tscn")
	var transition: CoreSceneTransition = packed.instantiate() as CoreSceneTransition
	owner.add_child(transition)
	return transition

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cover.hide()

func _input(_event: InputEvent) -> void:
	if is_transitioning:
		get_viewport().set_input_as_handled()

func switch_to(scenes: CoreScenes, path: String) -> CoreSceneRequest:
	var rejected: CoreSceneRequest = CoreSceneRequest.new()
	if not is_inside_tree() or scenes == null:
		rejected.complete(ERR_UNAVAILABLE)
		return rejected
	if is_transitioning or scenes.is_switching:
		rejected.complete(ERR_BUSY)
		return rejected
	if path.strip_edges().is_empty() or not is_finite(duration) or duration < 0.0:
		rejected.complete(ERR_INVALID_PARAMETER)
		return rejected
	is_transitioning = true
	_cover.color = Color(0.0, 0.0, 0.0, 0.0)
	_cover.show()
	var operation: CoreSceneTransitionOperation = CoreSceneTransitionOperation.new()
	_operation = operation
	operation.run(self, scenes, path)
	return operation.request

func _exit_tree() -> void:
	if is_instance_valid(_tween):
		_tween.kill()
	var pending: CoreSceneRequest = _fade
	_fade = null
	if pending != null:
		pending.complete(ERR_UNAVAILABLE)

func fade_to(alpha: float) -> CoreSceneRequest:
	var completion: CoreSceneRequest = CoreSceneRequest.new()
	if duration == 0.0:
		_cover.color.a = alpha
		completion.complete(OK)
		return completion
	_fade = completion
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	_tween.tween_property(_cover, "color:a", alpha, duration)
	_tween.finished.connect(func() -> void:
		_fade = null
		completion.complete(OK), CONNECT_ONE_SHOT)
	return completion

func finish_transition() -> void:
	if is_instance_valid(_cover):
		_cover.hide()
	is_transitioning = false
	_operation = null
