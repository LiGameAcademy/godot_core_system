extends CanvasLayer

## 输入状态系统演示
## 展示输入状态系统的功能，包括：
## 1. 连击检测
## 2. 长按判定
## 3. 状态可视化

@onready var input_manager = CoreSystem.input_manager
@onready var status_label = $UI/StatusLabel
@onready var combo_display = $UI/ComboDisplay
@onready var hold_indicator = $UI/HoldIndicator
@onready var input_log = $UI/InputLog

# 输入配置
const INPUT_ACTIONS = {
	"punch": "ui_accept",  # 空格键
	"kick": "ui_select",   # 回车键
	"special": "ui_focus_next"  # Tab键
}

# 连击配置
const COMBO_WINDOW = 0.5  # 连击窗口（秒）
const HOLD_THRESHOLD = 0.5  # 长按阈值（秒）

var combo_count := 0
var last_hit_time := 0.0
var current_hold_time := 0.0

func _ready() -> void:
	# 初始化显示
	status_label.text = "输入状态系统就绪"
	combo_display.text = "连击数：0"
	input_log.text = ""
	
	# 初始化长按指示器
	hold_indicator.max_value = HOLD_THRESHOLD
	hold_indicator.value = 0

func _process(delta: float) -> void:
	_update_combo_system()
	_update_hold_system(delta)
	_update_status_display()

func _update_combo_system() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# 检查连击超时
	if current_time - last_hit_time > COMBO_WINDOW and combo_count > 0:
		_reset_combo()
	
	# 检测新的攻击输入
	if input_manager.input_state.is_just_pressed(INPUT_ACTIONS.punch):
		_handle_punch()
	elif input_manager.input_state.is_just_pressed(INPUT_ACTIONS.kick):
		_handle_kick()

func _update_hold_system(delta: float) -> void:
	# 更新长按状态
	if input_manager.input_state.is_pressed(INPUT_ACTIONS.special):
		current_hold_time += delta
		hold_indicator.value = current_hold_time
		
		# 检查是否达到长按阈值
		if current_hold_time >= HOLD_THRESHOLD:
			_handle_special_move()
	else:
		current_hold_time = 0
		hold_indicator.value = 0

func _handle_punch() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_hit_time <= COMBO_WINDOW:
		combo_count += 1
	else:
		combo_count = 1
	
	last_hit_time = current_time
	_log_input("拳击")
	_update_combo_display()

func _handle_kick() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_hit_time <= COMBO_WINDOW:
		combo_count += 1
	else:
		combo_count = 1
	
	last_hit_time = current_time
	_log_input("踢腿")
	_update_combo_display()

func _handle_special_move() -> void:
	_log_input("特殊技能！")
	# 重置长按状态
	current_hold_time = 0
	hold_indicator.value = 0

func _reset_combo() -> void:
	combo_count = 0
	_update_combo_display()
	_log_input("连击重置")

func _update_combo_display() -> void:
	combo_display.text = "连击数：%d" % combo_count

func _update_status_display() -> void:
	var status_text = "输入状态：\n"
	
	# 显示按键状态
	for action_name in INPUT_ACTIONS.values():
		if input_manager.input_state.is_pressed(action_name):
			status_text += "%s: 按下\n" % action_name
		elif input_manager.input_state.is_just_released(action_name):
			status_text += "%s: 刚释放\n" % action_name
	
	status_label.text = status_text

func _log_input(action: String) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	var log_text = "[%.2f] %s\n" % [time, action]
	input_log.text = log_text + input_log.text
	
	# 限制日志长度
	if input_log.text.length() > 500:
		input_log.text = input_log.text.substr(0, 500)

func _on_clear_log_pressed() -> void:
	input_log.text = ""

func _on_reset_combo_pressed() -> void:
	_reset_combo()
