extends MovementComponent
class_name RigidMovementComponent

## 刚体移动组件
## 用于RigidBody2D类型的移动控制

var _rigid_body: RigidBody2D

func _init(body: RigidBody2D) -> void:
	_rigid_body = body

func move_to(target_position: Vector2) -> void:
	if _rigid_body:
		_rigid_body.global_position = target_position

func rotate_to(target_rotation: float) -> void:
	if _rigid_body:
		_rigid_body.global_rotation = target_rotation

func add_movement_input(direction: Vector2, scale: float = 1.0) -> void:
	if _rigid_body:
		_rigid_body.apply_central_impulse(direction * move_speed * scale)

func get_velocity() -> Vector2:
	return _rigid_body.linear_velocity if _rigid_body else Vector2.ZERO

func set_velocity(new_velocity: Vector2) -> void:
	if _rigid_body:
		_rigid_body.linear_velocity = new_velocity

func stop_movement() -> void:
	if _rigid_body:
		_rigid_body.linear_velocity = Vector2.ZERO
