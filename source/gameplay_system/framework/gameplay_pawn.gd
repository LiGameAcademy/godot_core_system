extends GameplayObject
class_name GameplayPawn

## 可被Controller控制的游戏对象
## 通过组件模式实现不同功能

# 基础组件引用
@export var camera: Camera2D                          ## 相机组件
@export var sprite: Sprite2D                          ## 精灵组件
@export var animation_player: AnimationComponent      ## 动画组件
@export var movement_component: MovementComponent     ## 移动组件
@export var health_component: HealthComponent         ## 生命值组件

# 基本属性
@export var move_speed: float = 300.0
@export var jump_force: float = -400.0

func _ready() -> void:
	# 连接生命值组件信号
	if health_component:
		health_component.died.connect(_on_died)
	
	# 设置移动组件参数
	if movement_component:
		movement_component.move_speed = move_speed
		movement_component.jump_force = jump_force

func _on_died() -> void:
	destroy()

## 移动相关方法（通过移动组件实现）
func move_to(target_position: Vector2) -> void:
	if movement_component:
		movement_component.move_to(target_position)

func rotate_to(target_rotation: float) -> void:
	if movement_component:
		movement_component.rotate_to(target_rotation)

func add_movement_input(direction: Vector2, scale: float = 1.0) -> void:
	if movement_component:
		movement_component.add_movement_input(direction, scale)

func get_velocity() -> Vector2:
	return movement_component.get_velocity() if movement_component else Vector2.ZERO

func set_velocity(new_velocity: Vector2) -> void:
	if movement_component:
		movement_component.set_velocity(new_velocity)

func stop_movement() -> void:
	if movement_component:
		movement_component.stop_movement()

## 基本移动功能
func move_left() -> void:
	if movement_component:
		movement_component.move_left()
		if sprite:
			sprite.flip_h = true

func move_right() -> void:
	if movement_component:
		movement_component.move_right()
		if sprite:
			sprite.flip_h = false

func jump() -> void:
	if movement_component:
		movement_component.jump()
