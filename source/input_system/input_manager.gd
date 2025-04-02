extends Node

## 动作触发信号
signal action_triggered(action_name: String, event: InputEvent)
## 轴值变化信号
signal axis_changed(axis_name: String, value: Vector2)
## 重映射完成信号
signal remap_completed(action: String, event: InputEvent)

## 虚拟轴系统
@onready var virtual_axis: InputVirtualAxis = InputVirtualAxis.new()
## 输入缓冲系统
@onready var input_buffer: InputBuffer = InputBuffer.new()
## 输入记录器
@onready var input_recorder: InputRecorder = InputRecorder.new()
## 输入状态管理器
@onready var input_state: InputState = InputState.new()
## 事件处理器
@onready var event_processor: InputEventProcessor = InputEventProcessor.new()
## 配置管理器
@onready var config_manager: Node = CoreSystem.config_manager

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_handling()
	virtual_axis.axis_changed.connect(_on_axis_changed)

func _process(delta: float) -> void:
	_update_input_state(delta)

func _input(event: InputEvent) -> void:
	if not event_processor.process_event(event):
		return
	_process_action_input(event)

#region 私有方法 - 初始化
func _setup_input_handling() -> void:
	set_process_input(true)
#endregion

#region 私有方法 - 输入处理
## 更新输入状态
## [param delta] 时间增量
func _update_input_state(delta: float) -> void:
	input_buffer.clean_expired_buffers()
	
	# 更新轴状态
	for axis_name in virtual_axis.get_registered_axes():
		virtual_axis.update_axis(axis_name)
	
	# 更新所有动作的状态
	for action in InputMap.get_actions():
		var is_pressed = Input.is_action_pressed(action)
		var strength = Input.get_action_strength(action)
		input_state.update_action(action, is_pressed, strength)

## 处理动作输入
## [param event] 输入事件
func _process_action_input(event: InputEvent) -> void:
	if not event.is_action_type():
		return
		
	for action in InputMap.get_actions():
		if event.is_action(action):
			var just_pressed = event.is_action_pressed(action)
			var just_released = event.is_action_released(action)
			var strength = event.get_action_strength(action)
			
			if just_pressed or just_released:
				# 更新输入状态
				input_state.update_action(action, just_pressed, strength)
				
				# 处理输入缓冲
				if just_pressed:
					input_buffer.add_buffer(action, strength)
				
				# 记录输入
				input_recorder.record_input(action, just_pressed, strength)
				
				# 发送信号
				action_triggered.emit(action, event)
#endregion

#region 私有方法 - 回调函数
## 轴值变化回调
## [param axis_name] 轴名称
## [param value] 轴值
func _on_axis_changed(axis_name: String, value: Vector2) -> void:
	axis_changed.emit(axis_name, value)
#endregion
