extends Node

## 场景管理器
## 这是一个场景管理系统，提供了与Godot原生场景切换相似的功能，但增加了以下特性：
## 1. 场景切换时的过渡效果
## 2. 场景状态的保存和恢复（场景栈）
## 3. 异步加载场景
## 4. 预加载场景功能

# 信号
## 开始加载场景
signal scene_loading_started(scene_path: String)
## 场景切换
signal scene_changed(old_scene: Node, new_scene: Node)
## 结束加载场景
signal scene_loading_finished()
## 场景预加载完成
signal scene_preloaded(scene_path: String)

## 场景转换效果
enum TransitionEffect {
	NONE,       ## 无转场效果
	FADE,       ## 淡入淡出
	SLIDE,      ## 滑动
	DISSOLVE,   ## 溶解
	CUSTOM,      ## 自定义
}

# 属性
## 当前场景
var _current_scene: Node = null
## 转场层
var _transition_layer: CanvasLayer
## 转场矩形
var _transition_rect: ColorRect
## 场景栈
## 每个元素的结构为:
## {
##   "scene": Node,           # 场景节点
##   "scene_path": String,    # 场景路径
##   "data": Dictionary       # 场景数据
## }
var _scene_stack: Array[Dictionary] = []
## 是否正在切换场景
var _is_switching: bool = false
## 转场效果实例
var _transitions: Dictionary = {}
## 自定义转场效果
var _custom_transitions: Dictionary = {}

## 资源管理器
var _resource_manager : CoreSystem.ResourceManager:
	get:
		return CoreSystem.resource_manager
## 日志管理器
var _logger : CoreSystem.Logger:
	get:
		return CoreSystem.logger

var _preloaded_scenes: Array[String] = []

func _ready() -> void:
	var root : Window = get_tree().root
	if not root:
		return
	# 连接资源加载完成信号
	if not _resource_manager.resource_loaded.is_connected(_on_resource_loaded):
		_resource_manager.resource_loaded.connect(_on_resource_loaded)
	_setup_transition_layer()
	# 初始化当前场景
	_current_scene = get_tree().current_scene
	# 初始化默认转场效果
	_setup_default_transitions()

## 预加载场景
## @param scene_path 场景路径
func preload_scene(scene_path: String) -> void:
	_preloaded_scenes.append(scene_path)
	_resource_manager.load_resource(scene_path, _resource_manager.LOAD_MODE.LAZY)

## 异步切换场景
## [param scene_path] 场景路径
## [param scene_data] 场景数据
## [param push_to_stack] 是否保存当前场景到栈
## [param effect] 转场效果
## [param duration] 转场持续时间
## [param callback] 切换完成回调
func change_scene_async(
		scene_path: String, 
		scene_data: Dictionary = {},
		push_to_stack: bool = false,
		effect: TransitionEffect = TransitionEffect.NONE, 
		duration: float = 0.5, 
		callback: Callable = Callable(),
		custom_transition_name: StringName = ""
		) -> void:
	# 防止同时切换多个场景
	if _is_switching:
		_logger.warning("Scene switch already in progress, ignoring request to switch to: %s" % scene_path)
		return
		
	_is_switching = true
	scene_loading_started.emit(scene_path)
	
	# 检查场景栈中是否已存在该场景
	var stack_index := -1
	for i in _scene_stack.size():
		if _scene_stack[i].scene_path == scene_path:
			stack_index = i
			break
	
	var new_scene : Node
	if stack_index >= 0:
		# 如果场景在栈中存在，重用该场景
		var stack_data = _scene_stack[stack_index]
		new_scene = stack_data.scene
		# 更新场景数据
		if new_scene.has_method("init_state"):
			new_scene.init_state(scene_data)
		# 从栈中移除该场景（因为它将成为当前场景）
		_scene_stack.remove_at(stack_index)
		new_scene.show()
		new_scene.move_to_front()
	else:
		# 加载新场景
		new_scene = _resource_manager.get_instance(scene_path)
		if not new_scene:
			var scene_resource : PackedScene = _resource_manager.get_cached_resource(scene_path)
			new_scene = scene_resource.instantiate()
		
		if not new_scene:
			_logger.error("Failed to load scene: %s" % scene_path)
			_is_switching = false
			return
		
		if new_scene.has_method("init_state"):
			new_scene.init_state(scene_data)
	
	await _do_scene_switch(new_scene, effect, duration, callback, custom_transition_name, push_to_stack)
	await get_tree().process_frame
	_is_switching = false

## 返回上一个场景
## [param effect] 转场效果
## [param duration] 持续时间
## [param callback] 回调
func pop_scene_async(effect: TransitionEffect = TransitionEffect.NONE, 
					duration: float = 0.5, 
					callback: Callable = Callable(),
					custom_transition_name: StringName = ""
					) -> void:
	if _scene_stack.is_empty():
		return
		
	var prev_scene_data = _scene_stack.pop_back()
	var prev_scene = prev_scene_data.scene
	
	if prev_scene.has_method("restore_state"):
		prev_scene.restore_state(prev_scene_data.data)
	prev_scene.show()
	await _do_scene_switch(prev_scene, effect, duration, callback, custom_transition_name)
	
## 子场景管理
## [param parent_node] 父节点
## [param scene_path] 场景路径
## [param scene_data] 场景数据
## [return] 子场景
func add_sub_scene(
		parent_node: Node, 
		scene_path: String, 
		scene_data: Dictionary = {}) -> Node:
	var scene_resource = _resource_manager.load_resource(scene_path)
	var sub_scene = scene_resource.instantiate()
	if sub_scene.has_method("init_state"):
		sub_scene.init_state(scene_data)
	parent_node.add_child(sub_scene)
	return sub_scene

## 获取当前场景
func get_current_scene() -> Node:
	return _current_scene

## 清除预加载的场景
func clear_preloaded_scenes() -> void:
	for scene_path in _preloaded_scenes:
		_resource_manager.clear_resource_cache(scene_path)
	_preloaded_scenes.clear()

## 注册自定义转场效果
## @param effect 转场效果类型
## @param transition 转场效果实例
func register_transition(effect: TransitionEffect, transition: BaseTransition, custom_name: StringName = "") -> void:
	if not transition:
		return
	if effect == TransitionEffect.CUSTOM:
		if custom_name.is_empty():
			_logger.error("Custom transition name cannot be empty")
		_custom_transitions[custom_name] = transition
	else:
		_transitions[effect] = transition
	transition.init(_transition_rect)

## 开始转场效果
## @param effect 转场效果
## @param duration 转场持续时间
func _start_transition(effect: TransitionEffect, duration: float, custom_transition_name: StringName = "") -> void:
	_transition_rect.visible = true
	if effect == TransitionEffect.CUSTOM and custom_transition_name:
		await _custom_transitions[custom_transition_name].start(duration)
	else:
		if effect in _transitions:
			await _transitions[effect].start(duration)
		else:
			_logger.warning("Transition effect not found: %d" % effect)

## 结束转场效果
## @param effect 转场效果
## @param duration 转场持续时间
func _end_transition(effect: TransitionEffect, duration: float, custom_transition_name: StringName = "") -> void:
	if effect == TransitionEffect.CUSTOM and custom_transition_name:
		await _custom_transitions[custom_transition_name].end(duration)
	else:
		if effect in _transitions:
			await _transitions[effect].end(duration)
		else:
			_logger.warning("Transition effect not found: %d" % effect)
	_transition_rect.visible = false

## 清理转场效果
func _cleanup_transition(effect: TransitionEffect, custom_transition_name: StringName = "") -> void:
	_transition_rect.visible = false

## 设置转场层
func _setup_transition_layer() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 128  # 确保在最上层
	add_child(_transition_layer)
	
	_transition_rect = ColorRect.new()
	_transition_rect.color = Color.BLACK
	_transition_rect.visible = false
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 忽略鼠标输入
	_transition_layer.add_child(_transition_rect)
	
	var root : Window = get_tree().root
	if not root.size_changed.is_connected(_on_viewport_size_changed):
		root.size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

## 设置转场矩形大小
func _on_viewport_size_changed():
	if _transition_rect:
		var size = get_viewport().get_visible_rect().size
		_transition_rect.size = size
		_transition_rect.position = Vector2.ZERO  # 让转场效果自己处理位置

## 设置默认转场效果
func _setup_default_transitions() -> void:
	register_transition(TransitionEffect.FADE, FadeTransition.new())
	register_transition(TransitionEffect.SLIDE, SlideTransition.new())
	register_transition(TransitionEffect.DISSOLVE, DissolveTransition.new())

## 私有方法：执行场景切换
## [param new_scene] 新场景
## [param effect] 转场效果
## [param duration] 持续时间
## [param callback] 回调
## [param save_current] 是否保存当前场景
func _do_scene_switch(
		new_scene: Node, 
		effect: TransitionEffect, 
		duration: float, 
		callback: Callable, 
		custom_transition_name: StringName = "",
		save_current: bool = false
		) -> void:
	var old_scene : Node = _current_scene

	# 开始转场效果
	if effect != TransitionEffect.NONE:
		await _start_transition(effect, duration, custom_transition_name)
		
	# 添加新场景
	if not new_scene.get_parent():
		get_tree().root.call_deferred("add_child", new_scene)
	_current_scene = new_scene
	
	if save_current and old_scene:
		# 保存当前场景到栈
		_scene_stack.push_back({
			"scene": old_scene,
			"scene_path": old_scene.scene_file_path,
			"data": old_scene.save_state() if old_scene.has_method("save_state") else {},
		})
		old_scene.hide()
	else:
		# 如果不需要保存状态，则直接销毁当前场景
		if old_scene:
			old_scene.get_parent().call_deferred("remove_child", old_scene)
			old_scene.queue_free()
	
	# 结束转场效果
	if effect != TransitionEffect.NONE:
		await _end_transition(effect, duration, custom_transition_name)
		_cleanup_transition(effect, custom_transition_name)
		
	scene_changed.emit(old_scene, new_scene)

	# 回调
	if callback.is_valid():
		callback.call()        
	
	scene_loading_finished.emit()

## 资源加载完成回调
func _on_resource_loaded(path: String, resource: Resource) -> void:
	if path in _preloaded_scenes and resource is PackedScene:
		_preloaded_scenes.erase(path)
		scene_preloaded.emit(path)
