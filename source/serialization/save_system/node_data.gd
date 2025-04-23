extends Resource

@export var scene: PackedScene
@export var node_path: String = ""

## 序列化
## [return] 序列化数据
func serialize() -> Dictionary:
	return {
		"scene": scene,
		"node_path" : node_path
	}

## 反序列化
## [param data] 序列化数据
func deserialize(data: Dictionary) -> void:
	scene = data.get("scene", scene)
	node_path = data.get("node_path", node_path)
