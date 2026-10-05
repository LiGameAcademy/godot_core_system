extends Control

## This main scene owns its controls; the explicit host owns persistent navigation.
@export var title: String = "Scene"
@export_file("*.tscn") var next_scene: String = ""
@onready var _next: Button = $Layout/Next
@onready var _status: Label = $Layout/Status
var _host: CoreSceneExampleHost

func _ready() -> void:
	_host = SceneExampleHost
	$Layout/Title.text = title
	_next.pressed.connect(_switch)

func _switch() -> void:
	if _host.transition.is_transitioning:
		return
	_next.disabled = true
	var request: CoreSceneRequest = _host.transition.switch_to(_host.scenes, next_scene)
	if request.is_completed:
		_on_switch_completed(request.result)
	else:
		request.completed.connect(_on_switch_completed, CONNECT_ONE_SHOT)

func _on_switch_completed(result: Error) -> void:
	if result == OK or not is_instance_valid(self) or not is_inside_tree():
		return
	_status.text = "Scene switch failed: %s" % error_string(result)
	_next.disabled = false
