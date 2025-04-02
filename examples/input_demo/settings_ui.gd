extends Control

# 信号
signal remap_requested(action: String)
signal sensitivity_changed(value: float)
signal deadzone_changed(value: float)
signal reset_requested

# 节点引用
@onready var jump_button = $VBoxContainer/InputSettings/JumpButton
@onready var attack_button = $VBoxContainer/InputSettings/AttackButton
@onready var sensitivity_slider = $VBoxContainer/InputSettings/SensitivitySlider
@onready var deadzone_slider = $VBoxContainer/InputSettings/DeadzoneSlider
@onready var reset_button = $VBoxContainer/ResetButton

func _ready():
	# 连接按钮信号
	jump_button.pressed.connect(func(): remap_requested.emit("player_jump"))
	attack_button.pressed.connect(func(): remap_requested.emit("player_attack"))
	
	# 连接滑块信号
	sensitivity_slider.value_changed.connect(func(value: float): sensitivity_changed.emit(value))
	deadzone_slider.value_changed.connect(func(value: float): deadzone_changed.emit(value))
	
	# 连接重置按钮信号
	reset_button.pressed.connect(func(): reset_requested.emit())
	
	# 设置初始值
	sensitivity_slider.value = 1.0
	deadzone_slider.value = 0.2

## 更新按钮文本
func update_button_text(action: String, event: InputEvent) -> void:
	var button_text = ""
	match event.get_class():
		"InputEventKey":
			button_text = OS.get_keycode_string(event.keycode)
		"InputEventJoypadButton":
			button_text = "手柄按钮 " + str(event.button_index)
		"InputEventMouseButton":
			button_text = "鼠标按钮 " + str(event.button_index)
	
	match action:
		"player_jump":
			jump_button.text = "跳跃: " + button_text
		"player_attack":
			attack_button.text = "攻击: " + button_text

## 更新滑块值
func update_sensitivity(value: float) -> void:
	sensitivity_slider.value = value

func update_deadzone(value: float) -> void:
	deadzone_slider.value = value
