extends Node
class_name MovementComponent

## 移动组件接口
## 定义移动相关的基本接口
## 不同类型的移动组件需要实现这些接口

# 移动属性
@export var move_speed: float = 300.0

## 移动到指定位置
func move_to(target_position: Vector2) -> void:
	push_error("move_to() not implemented")

## 旋转到指定角度
func rotate_to(target_rotation: float) -> void:
	push_error("rotate_to() not implemented")

## 应用移动输入
func add_movement_input(direction: Vector2, scale: float = 1.0) -> void:
	push_error("add_movement_input() not implemented")

## 获取当前速度
func get_velocity() -> Vector2:
	push_error("get_velocity() not implemented")
	return Vector2.ZERO

## 设置速度
func set_velocity(new_velocity: Vector2) -> void:
	push_error("set_velocity() not implemented")

## 停止移动
func stop_movement() -> void:
	push_error("stop_movement() not implemented")
