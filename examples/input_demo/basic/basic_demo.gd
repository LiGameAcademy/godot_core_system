extends Node

## 输入系统基础演示
## 展示输入系统的基本功能，包括：
## 1. 输入系统初始化
## 2. 基本输入检测
## 3. 配置管理

@onready var input_manager = CoreSystem.input_manager
@onready var status_label = $UI/StatusLabel
@onready var input_log = $UI/InputLog

# 定义输入动作
const INPUT_ACTIONS = {
	"move_right": "ui_right",
	"move_left": "ui_left",
	"move_up": "ui_up",
	"move_down": "ui_down",
	"jump": "ui_accept",
	"attack": "ui_select"
}

func _ready() -> void:
	# 初始化UI
	status_label.text = "输入系统就绪"
	input_log.text = ""
	
	# 连接信号
	input_manager.action_triggered.connect(_on_action_triggered)
	
	# 初始化输入配置
	_setup_input()

func _setup_input() -> void:
	# 注册虚拟轴
	input_manager.virtual_axis.register_axis(
		"movement",
		INPUT_ACTIONS.move_right,
		INPUT_ACTIONS.move_left,
		INPUT_ACTIONS.move_down,
		INPUT_ACTIONS.move_up
	)
	
	# 设置轴参数
	input_manager.virtual_axis.set_sensitivity(1.0)
	input_manager.virtual_axis.set_deadzone(0.2)

func _process(_delta: float) -> void:
	# 更新状态显示
	var status_text = "输入状态:\n"
	
	# 检查移动轴
	var movement = input_manager.virtual_axis.get_axis_value("movement")
	status_text += "移动轴: " + str(movement) + "\n"
	
	# 检查跳跃状态
	if input_manager.input_state.is_pressed(INPUT_ACTIONS.jump):
		status_text += "跳跃按下中\n"
	if input_manager.input_state.is_just_pressed(INPUT_ACTIONS.jump):
		status_text += "刚刚跳跃\n"
	
	# 检查攻击状态
	if input_manager.input_state.is_pressed(INPUT_ACTIONS.attack):
		status_text += "攻击按下中\n"
	if input_manager.input_state.is_just_pressed(INPUT_ACTIONS.attack):
		status_text += "刚刚攻击\n"
	
	status_label.text = status_text

func _on_action_triggered(action_name: String, event: InputEvent) -> void:
	# 记录输入事件
	var log_text = "动作触发: %s (%s)\n" % [action_name, event.as_text()]
	input_log.text = log_text + input_log.text
	
	# 限制日志长度
	if input_log.text.length() > 500:
		input_log.text = input_log.text.substr(0, 500)

func _on_clear_log_pressed() -> void:
	input_log.text = ""

func _on_reset_config_pressed() -> void:
	# 重置输入配置
	input_manager.virtual_axis.set_sensitivity(1.0)
	input_manager.virtual_axis.set_deadzone(0.2)
	status_label.text = "配置已重置"

func _on_sensitivity_value_changed(value: float) -> void:
	input_manager.virtual_axis.set_sensitivity(value)
	status_label.text = "灵敏度已更新: " + str(value)

func _on_deadzone_value_changed(value: float) -> void:
	input_manager.virtual_axis.set_deadzone(value)
	status_label.text = "死区已更新: " + str(value)
