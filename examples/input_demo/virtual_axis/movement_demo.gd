extends CanvasLayer

## 虚拟轴系统演示
## 展示虚拟轴系统的功能，包括：
## 1. 角色移动控制
## 2. 死区和灵敏度调节
## 3. 轴值可视化

@onready var input_manager = CoreSystem.input_manager
@onready var character = $Character
@onready var axis_visualizer = $UI/AxisVisualizer
@onready var status_label = $UI/StatusLabel

# 移动参数
const MOVE_SPEED = 300.0
const ACCELERATION = 1500.0
const FRICTION = 2000.0

# 虚拟轴配置
const MOVEMENT_AXIS = "movement"
const INPUT_ACTIONS = {
	"right": "ui_right",
	"left": "ui_left",
	"up": "ui_up",
	"down": "ui_down"
}

func _ready() -> void:
	# 初始化虚拟轴
	_setup_virtual_axis()
	
	# 设置初始状态显示
	status_label.text = "虚拟轴系统就绪"

func _setup_virtual_axis() -> void:
	# 注册移动轴
	input_manager.virtual_axis.register_axis(
		MOVEMENT_AXIS,
		INPUT_ACTIONS.right,
		INPUT_ACTIONS.left,
		INPUT_ACTIONS.down,
		INPUT_ACTIONS.up
	)
	
	# 设置默认参数
	input_manager.virtual_axis.set_sensitivity(1.0)
	input_manager.virtual_axis.set_deadzone(0.2)

func _physics_process(delta: float) -> void:
	# 获取移动输入
	var movement = input_manager.virtual_axis.get_axis_value(MOVEMENT_AXIS)
	
	# 更新角色移动
	_update_character_movement(movement, delta)
	
	# 更新轴值可视化
	_update_axis_visualizer(movement)
	
	# 更新状态显示
	_update_status_display(movement)

func _update_character_movement(movement: Vector2, delta: float) -> void:
	var velocity = character.velocity
	
	# 应用加速度
	if movement.length() > 0:
		velocity = velocity.move_toward(movement * MOVE_SPEED, ACCELERATION * delta)
	else:
		# 应用摩擦力
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	character.velocity = velocity
	character.move_and_slide()

func _update_axis_visualizer(movement: Vector2) -> void:
	# 更新可视化显示
	axis_visualizer.update_axis(movement)

func _update_status_display(movement: Vector2) -> void:
	var status_text = "轴值: " + str(movement) + "\n"
	status_text += "速度: " + str(character.velocity.length()) + "\n"
	status_text += "灵敏度: " + str(input_manager.virtual_axis.get_sensitivity()) + "\n"
	status_text += "死区: " + str(input_manager.virtual_axis.get_deadzone())
	status_label.text = status_text

func _on_sensitivity_value_changed(value: float) -> void:
	input_manager.virtual_axis.set_sensitivity(value)

func _on_deadzone_value_changed(value: float) -> void:
	input_manager.virtual_axis.set_deadzone(value)

func _on_reset_pressed() -> void:
	input_manager.virtual_axis.set_sensitivity(1.0)
	input_manager.virtual_axis.set_deadzone(0.2)
