extends Node2D

@onready var input_manager = CoreSystem.input_manager
@onready var player_sprite = $PlayerSprite
@onready var status_label = $StatusLabel
@onready var settings_ui = $SettingsUI

# 虚拟动作和轴的名称
const ACTIONS = {
	"attack": "player_attack",
	"jump": "player_jump",
	"movement": "player_movement"
}

# 默认输入映射
const DEFAULT_MAPPINGS = {
	"player_jump": KEY_SPACE,
	"player_attack": KEY_J,
	"ui_right": KEY_D,
	"ui_left": KEY_A,
	"ui_down": KEY_S,
	"ui_up": KEY_W
}

func _ready():
	# 设置状态标签
	status_label.text = "按WASD移动，空格跳跃，J攻击"
	
	# 设置输入配置
	setup_input_config()
	
	# 连接信号
	input_manager.action_triggered.connect(_on_action_triggered)
	input_manager.axis_changed.connect(_on_axis_changed)
	
	# 设置UI事件
	settings_ui.remap_requested.connect(_on_remap_requested)
	settings_ui.sensitivity_changed.connect(_on_sensitivity_changed)
	settings_ui.deadzone_changed.connect(_on_deadzone_changed)
	settings_ui.reset_requested.connect(_on_reset_requested)

func setup_input_config() -> void:
	# 注册默认动作映射
	for action in DEFAULT_MAPPINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event = InputEventKey.new()
			event.keycode = DEFAULT_MAPPINGS[action]
			InputMap.action_add_event(action, event)
	
	# 注册虚拟动作
	var jump_event = InputEventKey.new()
	jump_event.keycode = DEFAULT_MAPPINGS[ACTIONS.jump]
	input_manager.register_virtual_action(ACTIONS.jump, [jump_event])
	
	var attack_event = InputEventKey.new()
	attack_event.keycode = DEFAULT_MAPPINGS[ACTIONS.attack]
	input_manager.register_virtual_action(ACTIONS.attack, [attack_event])
	
	# 注册移动轴
	input_manager.register_axis(
		ACTIONS.movement,  # 轴名称
		"ui_right",       # 正X轴动作 - D
		"ui_left",        # 负X轴动作 - A
		"ui_down",        # 正Y轴动作 - S
		"ui_up"          # 负Y轴动作 - W
	)

func _process(_delta):
	# 更新玩家精灵的位置
	var movement = input_manager.get_axis_value(ACTIONS.movement)
	if movement != Vector2.ZERO:
		var sensitivity = input_manager.get_axis_sensitivity()
		player_sprite.position += movement * 5 * sensitivity

## 动作触发回调
func _on_action_triggered(action_name: String, _event: InputEvent):
	match action_name:
		ACTIONS.jump:
			if input_manager.is_action_just_pressed(action_name):
				_show_action_status("跳跃！")
				var tween = create_tween()
				tween.tween_property(player_sprite, "position:y", 
					player_sprite.position.y - 50, 0.3)
				tween.tween_property(player_sprite, "position:y", 
					player_sprite.position.y, 0.3)
		
		ACTIONS.attack:
			if input_manager.is_action_just_pressed(action_name):
				_show_action_status("攻击！")
				var tween = create_tween()
				tween.tween_property(player_sprite, "rotation", 
					player_sprite.rotation + PI, 0.3)
				tween.tween_property(player_sprite, "rotation", 
					player_sprite.rotation, 0.3)

## 轴变化回调
func _on_axis_changed(axis_name: String, value: Vector2):
	if axis_name == ACTIONS.movement and value != Vector2.ZERO:
		_show_action_status("移动：" + str(value))

## 显示动作状态
func _show_action_status(text: String):
	status_label.text = text
	await get_tree().create_timer(1.0).timeout
	status_label.text = "按WASD移动，空格跳跃，J攻击"

## 重映射请求回调
func _on_remap_requested(action: String) -> void:
	_show_action_status("请按下新的按键...")
	var event = await get_next_input_event()
	if event is InputEventKey:
		# 更新输入映射
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		
		# 如果是虚拟动作，也更新虚拟动作
		if action == ACTIONS.jump or action == ACTIONS.attack:
			input_manager.register_virtual_action(action, [event])
		
		_show_action_status("按键已重映射！")

## 灵敏度变化回调
func _on_sensitivity_changed(value: float) -> void:
	input_manager.set_axis_sensitivity(value)
	_show_action_status("灵敏度已更新：" + str(value))

## 死区变化回调
func _on_deadzone_changed(value: float) -> void:
	input_manager.set_axis_deadzone(value)
	_show_action_status("死区已更新：" + str(value))

## 重置请求回调
func _on_reset_requested() -> void:
	setup_input_config()
	settings_ui.update_sensitivity(1.0)
	settings_ui.update_deadzone(0.2)
	_show_action_status("已重置为默认设置！")

## 获取下一个输入事件
func get_next_input_event() -> InputEvent:
	var event = await get_viewport().gui_get_focus_owner().get_next_input_event()
	return event if event else null
