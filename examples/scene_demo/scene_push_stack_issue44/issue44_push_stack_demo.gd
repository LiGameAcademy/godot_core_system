extends Control

## Issue #44 示例：change_scene_async(..., push_to_stack: true) 时，SceneManager 在 remove_child 后 await process_frame。
## 子场景复用 scene_demo/scenes（demo_scene：init_state / save_state / pop）。

const CoreSceneManager = preload("res://addons/godot_core_system/source/scene_system/scene_manager.gd")

const _SCENE_DIR := "res://addons/godot_core_system/examples/scene_demo/scenes/"

@onready var _status: RichTextLabel = %StatusLabel


func _ready() -> void:
	_set_status(
		"[b]Issue #44[/b]：本场景演示 [code]push_to_stack = true[/code] 入栈切换。\n"
		+ "进入 scene1 / scene2 后，子场景内点「返回」即 [code]pop_scene_async[/code] 回到本页。\n"
		+ "修复前可能出现父节点无法移除当前场景等错误；修复后应无此类报错。"
	)


func _set_status(bbcode: String) -> void:
	if _status:
		_status.text = bbcode


func _on_push_scene1_pressed() -> void:
	CoreSystem.scene_manager.change_scene_async(
		_SCENE_DIR + "scene1.tscn",
		{"message": "场景 1（Issue #44 Demo）", "source_scene": "issue44_push_stack_demo"},
		true,
		CoreSceneManager.TransitionEffect.NONE
	)


func _on_push_scene2_pressed() -> void:
	CoreSystem.scene_manager.change_scene_async(
		_SCENE_DIR + "scene2.tscn",
		{"message": "场景 2（Issue #44 Demo）", "source_scene": "issue44_push_stack_demo"},
		true,
		CoreSceneManager.TransitionEffect.FADE,
		0.45
	)


func _on_pop_pressed() -> void:
	CoreSystem.scene_manager.pop_scene_async(CoreSceneManager.TransitionEffect.NONE, 0.35)
