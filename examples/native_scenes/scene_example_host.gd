class_name CoreSceneExampleHost
extends Node

## A standalone example host with no dependency on legacy plugin managers.
var scenes: CoreScenes
var transition: CoreSceneTransition

func _ready() -> void:
	scenes = CoreScenes.new(get_tree())
	transition = CoreSceneTransition.attach_to(self)

func _exit_tree() -> void:
	if scenes != null:
		scenes.dispose()
