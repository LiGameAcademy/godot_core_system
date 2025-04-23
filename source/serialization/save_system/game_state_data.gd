extends Resource

## 游戏状态数据

const NodeData = preload("./node_data.gd")

# 存档元数据
@export var save_id : StringName = &""
@export var timestamp : int = 0
@export var save_date : String = ""
@export var game_version : String = ""
@export var playtime : float = 0.0

@export var nodes_state : Array[NodeData]

func _init(
		p_save_id: StringName = "",
		p_timestamp: int = 0,
		p_save_date: String = "",
		p_game_version: String = "",
		p_playtime: float = 0.0,
		) -> void:
	save_id = p_save_id
	timestamp = p_timestamp
	save_date = p_save_date
	game_version = p_game_version
	playtime = p_playtime

## 序列化
## [return] 序列化数据
func serialize() -> Dictionary:
	return {
		"metadata": _get_meta_data(),
	}

## 反序列化
## [param data] 序列化数据
func deserialize(data: Dictionary) -> void:
	if data.has("metadata"):
		_set_meta_data(data.metadata)
	# if data.has("game_data"):
	# 	game_data = data.game_data

func _get_meta_data() -> Dictionary:
	return {
		"save_id": save_id,
		"timestamp": timestamp,
		"save_date": save_date,
		"game_version": game_version,
		"playtime": playtime
	}

func _set_meta_data(data: Dictionary) -> void:
	save_id = data.get("save_id", save_id)
	timestamp = data.get("timestamp", timestamp)
	save_date = data.get("save_date", save_date)
	game_version = data.get("game_version", game_version)
	playtime = data.get("playtime", playtime)

# func _get_game_data() -> Dictionary:
# 	var data := {}
# 	for node_state in nodes_state:
# 		data[node_state.node_path] = node_state.serialize()
# 	return data

# func _set_game_data(data: Dictionary) -> void:
# 	for node_path in data:
# 		var node_data : Dictionary = data[node_path]
		
# 		nodes_state.append(node_state.deserialize())
