extends Node

## TODO 待补充的功能
## 输入的录制和回放
## 复杂的输入组合
## 多设备输入支持
## 网络同步的输入系统

## 动作触发
signal action_triggered(action_name: String, event: InputEvent)
## 轴变化
signal axis_changed(axis_name: String, value: Vector2)
## 输入重映射
signal input_remapped(action_name: String, events: Array[InputEvent])

## 默认缓冲时间
const DEFAULT_BUFFER_TIME = 0.15  # 150ms的输入缓冲时间
## 输入配置-section
const INPUT_CONFIG_SECTION = "input_bindings"

## 虚拟动作
var _virtual_actions: Dictionary = {}
## 轴映射
var _axis_mappings: Dictionary = {}
## 动作状态
var _action_states: Dictionary = {}
## 输入缓冲
var _input_buffers: Dictionary = {}  # 存储输入缓冲
## 配置管理器
var _config_manager: Node = CoreSystem.config_manager

func _ready() -> void:
	# 初始化所有已注册的输入动作状态
	for action in InputMap.get_actions():
		_action_states[action] = false
		_input_buffers[action] = []
	
	# 订阅配置加载事件
	_config_manager.config_loaded.connect(_on_config_loaded)
	
	# 加载输入配置
	_load_input_config()

func _physics_process(_delta: float) -> void:
	# 清理过期的输入缓冲
	var current_time = Time.get_ticks_msec() / 1000.0
	for action in _input_buffers.keys():
		var buffers = _input_buffers[action] as Array
		buffers = buffers.filter(func(buffer): 
			return current_time - buffer.timestamp <= DEFAULT_BUFFER_TIME and not buffer.consumed
		)
		_input_buffers[action] = buffers

func _input(event: InputEvent) -> void:
	# 处理所有已注册的输入动作
	for action in InputMap.get_actions():
		if event.is_action(action):
			var just_pressed = event.is_action_pressed(action)
			var just_released = event.is_action_released(action)
			
			if just_pressed:
				_action_states[action] = true
				_input_buffers[action].append(InputBuffer.new(action))
				action_triggered.emit(action, event)
			elif just_released:
				_action_states[action] = false
				action_triggered.emit(action, event)

	# 处理虚拟轴输入
	_process_axis_input()

## 检查动作是否在缓冲时间内被按下
## [param action_name] 动作名称
## [param consume] 是否消耗这个输入
## [return] 是否在缓冲时间内按下
func is_action_buffered(action_name: String, consume: bool = true) -> bool:
	if not _input_buffers.has(action_name):
		return false
	
	var buffers = _input_buffers[action_name] as Array
	if buffers.is_empty():
		return false
	
	if consume:
		buffers[0].consumed = true
	return true

## 加载输入配置
func _load_input_config() -> void:
	var bindings = _config_manager.get_section(INPUT_CONFIG_SECTION)
	for action in bindings:
		if InputMap.has_action(action):
			var events = bindings[action]
			if events != null:
				# 清除现有的映射
				InputMap.action_erase_events(action)
				# 添加保存的映射
				for event in events:
					InputMap.action_add_event(action, event)

## 重映射输入动作
## [param action_name] 动作名称
## [param event] 新的输入事件
func remap_action(action_name: String, event: InputEvent) -> void:
	if not InputMap.has_action(action_name):
		return
	
	# 清除现有的映射
	InputMap.action_erase_events(action_name)
	# 添加新的映射
	InputMap.action_add_event(action_name, event)
	
	# 保存到配置
	var bindings = _config_manager.get_section(INPUT_CONFIG_SECTION)
	bindings[action_name] = [event]  # 目前只支持单个事件，可以扩展为支持多个
	_config_manager.set_value(INPUT_CONFIG_SECTION, action_name, [event])
	
	# 发送重映射事件
	input_remapped.emit(action_name, [event])

## 注册虚拟轴
## [param axis_name] 轴名称
## [param positive_x] 正向 X 轴动作
## [param negative_x] 负向 X 轴动作
## [param positive_y] 正向 Y 轴动作
## [param negative_y] 负向 Y 轴动作
func register_axis(axis_name: String, positive_x: String = "", negative_x: String = "", 
				  positive_y: String = "", negative_y: String = "") -> void:
	_axis_mappings[axis_name] = {
		"positive_x": positive_x,
		"negative_x": negative_x,
		"positive_y": positive_y,
		"negative_y": negative_y
	}

## 注册虚拟动作
## [param action_name] 动作名称
## [param key_combination] 按键组合
func register_virtual_action(action_name: String, key_combination: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	for event in key_combination:
		InputMap.action_add_event(action_name, event)
	_virtual_actions[action_name] = key_combination
	_action_states[action_name] = false

## 检查动作是否被按下
## [param action_name] 动作名称
## [return] 是否按下
func is_action_pressed(action_name: String) -> bool:
	return _action_states.get(action_name, false)

## 检查动作是否刚刚被按下
## [param action_name] 动作名称
## [return] 是否刚刚按下
func is_action_just_pressed(action_name: String) -> bool:
	return Input.is_action_just_pressed(action_name)

## 检查动作是否刚刚被释放
## [param action_name] 动作名称
## [return] 是否刚刚释放
func is_action_just_released(action_name: String) -> bool:
	return Input.is_action_just_released(action_name)

## 获取轴的值
## [param axis_name] 轴名称
## [return] 值 value
func get_axis_value(axis_name: String) -> Vector2:
	if not _axis_mappings.has(axis_name):
		return Vector2.ZERO
	
	var mapping = _axis_mappings[axis_name]
	var result = Vector2.ZERO
	
	if mapping.has("positive_x") and Input.is_action_pressed(mapping.positive_x):
		result.x += 1
	if mapping.has("negative_x") and Input.is_action_pressed(mapping.negative_x):
		result.x -= 1
	if mapping.has("positive_y") and Input.is_action_pressed(mapping.positive_y):
		result.y += 1
	if mapping.has("negative_y") and Input.is_action_pressed(mapping.negative_y):
		result.y -= 1
	
	return result

## 处理虚拟轴输入
func _process_axis_input() -> void:
	for axis_name in _axis_mappings:
		var axis_value = get_axis_value(axis_name)
		axis_changed.emit(axis_name, axis_value)

## 清除所有虚拟输入
func clear_virtual_inputs() -> void:
	for action in _virtual_actions.keys():
		InputMap.erase_action(action)
	_virtual_actions.clear()
	_axis_mappings.clear()
	_action_states.clear()

## 配置加载回调
func _on_config_loaded() -> void:
	_load_input_config()

class InputBuffer:
	var action_name: String
	var timestamp: float
	var consumed: bool
	
	func _init(action: String) -> void:
		action_name = action
		timestamp = Time.get_ticks_msec() / 1000.0
		consumed = false
