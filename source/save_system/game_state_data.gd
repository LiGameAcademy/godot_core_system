extends Resource

## 游戏状态数据

## 存档元数据
@export var metadata : Dictionary = {
	"save_id": "",
	"timestamp": 0,
	"save_date": "",
	"game_version": "",
	"playtime": 0.0,
}
## 节点状态
@export var nodes_state : Array[Dictionary] = []

func _init(
		p_save_id: StringName = "",
		p_timestamp: int = 0,
		p_save_date: String = "",
		p_game_version: String = "",
		p_playtime: float = 0.0,
		) -> void:
	metadata.save_id = p_save_id
	metadata.timestamp = p_timestamp
	metadata.save_date = p_save_date
	metadata.game_version = p_game_version
	metadata.playtime = p_playtime
