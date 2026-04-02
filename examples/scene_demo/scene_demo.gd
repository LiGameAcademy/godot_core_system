extends Node2D

const SceneManager = CoreSystem.SceneManager

@onready var scene_manager : SceneManager = CoreSystem.scene_manager
@onready var status_label = $UI/StatusLabel
@onready var buttons = $UI/Buttons
@onready var preload_status = $UI/PreloadStatus

# 场景路径
var SCENE_PATHS = [
	FileDirHandler.get_object_script_dir(self) + "/scenes/scene1.tscn",
	FileDirHandler.get_object_script_dir(self) + "/scenes/scene2.tscn",
	FileDirHandler.get_object_script_dir(self) + "/scenes/scene3.tscn",
]

# 预加载状态
var _preloaded_scenes : Dictionary = {}

func _ready() -> void:
	# 连接信号
	scene_manager.scene_loading_started.connect(_on_scene_loading_started)
	scene_manager.scene_changed.connect(_on_scene_changed)
	scene_manager.scene_loading_finished.connect(_on_scene_loading_finished)
	scene_manager.scene_preloaded.connect(_on_scene_preloaded)
	
	# 预加载所有场景
	for scene_path in SCENE_PATHS:
		_preloaded_scenes[scene_path] = false
		scene_manager.preload_scene(scene_path)
	
	# 设置状态标签
	status_label.text = "正在预加载场景..."
	buttons.visible = false

## 切换到场景1（无转场效果）
func _on_scene1_pressed() -> void:
	scene_manager.change_scene_async(
		SCENE_PATHS[0],
		{
			"message": "这是场景1",
			"source_scene": name
		},
		true,
		SceneManager.TransitionEffect.NONE
	)

## 切换到场景2（淡入淡出）
func _on_scene2_pressed() -> void:
	scene_manager.change_scene_async(
		SCENE_PATHS[1],
		{
			"message": "这是场景2",
			"source_scene": name
		},
		true,
		SceneManager.TransitionEffect.FADE
	)

## 切换到场景3（滑动）
func _on_scene3_pressed() -> void:
	scene_manager.change_scene_async(
		SCENE_PATHS[2],
		{
			"message": "这是场景3",
			"source_scene": name
		},
		true,
		SceneManager.TransitionEffect.SLIDE
	)

## 场景加载开始回调
func _on_scene_loading_started(scene_path: String):
	status_label.text = "开始加载场景：" + scene_path
	buttons.visible = false

## 场景切换回调
func _on_scene_changed(_old_scene: Node, _new_scene: Node):
	status_label.text = "场景切换完成"

## 场景加载完成回调
func _on_scene_loading_finished():
	if scene_manager.get_current_scene() == self:
		status_label.text = "加载完成"
		buttons.visible = true

## 场景预加载完成回调
func _on_scene_preloaded(scene_path: String):
	_preloaded_scenes[scene_path] = true
	var loaded_count = _preloaded_scenes.values().count(true)
	
	# 所有场景预加载完成
	if loaded_count == SCENE_PATHS.size():
		status_label.text = "选择一个转场效果和目标场景"
		buttons.visible = true
