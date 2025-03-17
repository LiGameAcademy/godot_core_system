extends MovementComponent
class_name CharacterMovementComponent

## 角色移动组件
## 处理角色的移动、跳跃等物理行为

# 移动参数
@export var jump_force: float = -400.0
@export var gravity_scale: float = 1.0

# 物理状态
var velocity: Vector2

var _character_body: CharacterBody2D

func _init(body: CharacterBody2D) -> void:
	_character_body = body

## 物理更新
func _physics_process(_delta: float) -> void:
	# 应用重力
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_scale
	
	# 移动
	if _character_body:
		_character_body.velocity = velocity
		_character_body.move_and_slide()
	
	# 重置水平速度
	velocity.x = 0

## 移动到指定位置
func move_to(target_position: Vector2) -> void:
	if _character_body:
		_character_body.global_position = target_position

## 旋转到指定角度
func rotate_to(target_rotation: float) -> void:
	if _character_body:
		_character_body.global_rotation = target_rotation

## 添加移动输入
func add_movement_input(direction: Vector2, scale: float = 1.0) -> void:
	velocity += direction * scale * move_speed

## 获取当前速度
func get_velocity() -> Vector2:
	return velocity

## 设置速度
func set_velocity(new_velocity: Vector2) -> void:
	velocity = new_velocity

## 停止移动
func stop_movement() -> void:
	velocity = Vector2.ZERO

## 向左移动
func move_left() -> void:
	velocity.x = -move_speed

## 向右移动
func move_right() -> void:
	velocity.x = move_speed

## 跳跃
func jump() -> void:
	if is_on_floor():
		velocity.y = jump_force

## 检查是否在地面上
func is_on_floor() -> bool:
	return _character_body and _character_body.is_on_floor()
