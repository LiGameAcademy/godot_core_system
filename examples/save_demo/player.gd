extends Node

## 玩家基本属性
@export var player_name: String = "Player"
@export var player_level: int = 1
@export var player_exp: int = 0
@export var player_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 注册需要序列化的属性
	CoreSystem.save_manager.register_saveable_node(self)

func save() -> Dictionary:
	return {
		"player_name": player_name,
		"player_level": player_level,
		"player_exp": player_exp,
		"player_position": player_position,
	}

func load_data(data: Dictionary) -> void:
	player_name = data.get("player_name", player_name)
	player_level = data.get("player_level", player_level)
	player_exp = data.get("player_exp", player_exp)
	player_position = data.get("player_position", player_position)
