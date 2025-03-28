extends CanvasLayer

## 输入缓冲系统演示
## 展示输入缓冲系统的功能，包括：
## 1. 技能释放
## 2. 缓冲窗口配置
## 3. 缓冲可视化

@onready var input_manager = CoreSystem.input_manager
@onready var status_label = $UI/StatusLabel
@onready var buffer_display = $UI/BufferDisplay
@onready var input_log = $UI/InputLog
@onready var buffer_window_label = $UI/Controls/BufferWindow/Value

# 输入配置
const INPUT_ACTIONS = {
	"skill1": "ui_accept",  # 空格键
	"skill2": "ui_select",  # 回车键
	"skill3": "ui_focus_next"  # Tab键
}

# 缓冲配置
var buffer_window := 0.15  # 默认缓冲窗口（秒）
var active_buffers := {}  # 当前活动的缓冲

func _ready() -> void:
	# 初始化显示
	status_label.text = "输入缓冲系统就绪"
	buffer_display.text = ""
	input_log.text = ""
	
	# 初始化缓冲系统
	input_manager.input_buffer.set_buffer_duration(buffer_window)
	buffer_window_label.text = str(buffer_window)

func _process(_delta: float) -> void:
	# 检查输入并添加缓冲
	_check_inputs()
	
	# 更新缓冲显示
	_update_buffer_display()
	
	# 更新状态显示
	_update_status_display()

func _check_inputs() -> void:
	# 检查技能输入
	for skill_name in INPUT_ACTIONS:
		var action = INPUT_ACTIONS[skill_name]
		if input_manager.input_state.is_just_pressed(action):
			_add_skill_buffer(skill_name)

func _add_skill_buffer(skill_name: String) -> void:
	# 添加技能缓冲
	input_manager.input_buffer.add_buffer(skill_name, 1.0)
	_log_input("添加缓冲: " + skill_name)
	
	# 模拟技能冷却
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(_on_skill_ready.bind(skill_name))

func _on_skill_ready(skill_name: String) -> void:
	# 检查是否有对应的缓冲
	if input_manager.input_buffer.has_buffer(skill_name):
		_execute_skill(skill_name)
		input_manager.input_buffer.clear_buffer(skill_name)

func _execute_skill(skill_name: String) -> void:
	_log_input("释放技能: " + skill_name)
	
	# 创建技能特效
	var effect = _create_skill_effect(skill_name)
	add_child(effect)
	
	# 2秒后移除特效
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(effect.queue_free)

func _create_skill_effect(skill_name: String) -> Node2D:
	# 创建一个简单的视觉效果
	var effect = Node2D.new()
	var color_rect = ColorRect.new()
	
	# 根据技能设置不同颜色
	var color = Color.WHITE
	match skill_name:
		"skill1": color = Color.RED
		"skill2": color = Color.BLUE
		"skill3": color = Color.GREEN
	
	color_rect.color = color
	color_rect.size = Vector2(50, 50)
	color_rect.position = Vector2(-25, -25)
	
	effect.position = get_viewport().get_mouse_position()
	effect.add_child(color_rect)
	
	return effect

func _update_buffer_display() -> void:
	var display_text = "当前缓冲:\n"
	
	for skill_name in INPUT_ACTIONS:
		if input_manager.input_buffer.has_buffer(skill_name):
			display_text += "%s: 已缓冲\n" % skill_name
		else:
			display_text += "%s: 无缓冲\n" % skill_name
	
	buffer_display.text = display_text

func _update_status_display() -> void:
	var status_text = "系统状态:\n"
	status_text += "缓冲窗口: %.2f秒\n" % buffer_window
	status_text += "活动缓冲数: %d" % len(active_buffers)
	
	status_label.text = status_text

func _log_input(message: String) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	var log_text = "[%.2f] %s\n" % [time, message]
	input_log.text = log_text + input_log.text
	
	# 限制日志长度
	if input_log.text.length() > 500:
		input_log.text = input_log.text.substr(0, 500)

func _on_clear_log_pressed() -> void:
	input_log.text = ""

func _on_buffer_window_value_changed(value: float) -> void:
	buffer_window = value
	input_manager.input_buffer.set_buffer_duration(value)
	buffer_window_label.text = "%.2f" % value

func _on_reset_pressed() -> void:
	buffer_window = 0.15
	input_manager.input_buffer.set_buffer_duration(buffer_window)
	$UI/Controls/BufferWindow/Slider.value = buffer_window
	buffer_window_label.text = "%.2f" % buffer_window
