class_name CoreSceneTransitionOperation
extends RefCounted

## Own the asynchronous operation outside the potentially freed presentation node.
var request: CoreSceneRequest = CoreSceneRequest.new()

func run(transition: CoreSceneTransition, scenes: CoreScenes, path: String) -> void:
	var fade: CoreSceneRequest = transition.fade_to(1.0)
	var result: Error = await fade.wait()
	if result != OK:
		_finish(transition, result)
		return
	var switching: CoreSceneRequest = scenes.switch_to_path(path)
	result = await switching.wait()
	if not is_instance_valid(transition) or not transition.is_inside_tree():
		_finish(transition, ERR_UNAVAILABLE)
		return
	fade = transition.fade_to(0.0)
	var faded: Error = await fade.wait()
	_finish(transition, result if faded == OK else ERR_UNAVAILABLE)

func _finish(transition: CoreSceneTransition, result: Error) -> void:
	if is_instance_valid(transition):
		transition.finish_transition()
	request.complete(result)
