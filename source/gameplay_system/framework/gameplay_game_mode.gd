extends Node
class_name GameplayGameMode

## 游戏模式基类
## 管理游戏规则和流程
## 控制玩家生成和游戏状态
# # 职责：
# - 定义游戏规则和流程
# - 管理游戏状态的切换
# - 控制玩家的生成和重生
# - 处理游戏开始、结束等核心事件
# # 主要接口：
# - begin_play()：开始游戏
# - end_game()：结束游戏
# - spawn_player()：生成玩家
# - get_game_state()：获取当前游戏状态

# 信号
signal state_changed(old_state: StringName, new_state: StringName)
signal player_spawned(player: Character)

# 当前状态
var current_state: StringName:
	set(value):
		var old = current_state
		current_state = value
		emit_signal("state_changed", old, value)

# 游戏配置
var game_config: Dictionary = {}

func _init() -> void:
	current_state = &"none"

## 开始游戏
func begin_play() -> void:
	pass

## 结束游戏
func end_game() -> void:
	pass

## 生成玩家
func spawn_player(character_class: PackedScene, spawn_point: Node2D) -> Character:
	var instance = character_class.instantiate() as Character
	if instance:
		get_tree().current_scene.add_child(instance)
		instance.global_position = spawn_point.global_position
		emit_signal("player_spawned", instance)
	return instance
