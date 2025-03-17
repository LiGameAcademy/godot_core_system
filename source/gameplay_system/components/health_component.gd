extends Node
class_name HealthComponent

## 生命值组件
## 管理生命值、伤害和治疗

# 信号
signal health_changed(old_health: float, new_health: float)
signal died()

# 属性
@export var max_health: float = 100.0
@export var start_health: float = 100.0

var current_health: float:
	set(value):
		var old_health = current_health
		current_health = clampf(value, 0.0, max_health)
		emit_signal("health_changed", old_health, current_health)
		if current_health <= 0:
			emit_signal("died")

func _ready() -> void:
	current_health = start_health

## 受到伤害
func take_damage(amount: float) -> void:
	current_health -= amount

## 治疗
func heal(amount: float) -> void:
	current_health += amount

## 是否存活
func is_alive() -> bool:
	return current_health > 0
