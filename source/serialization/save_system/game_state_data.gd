extends Resource

## 游戏状态数据

## 存档元数据
var metadata: Dictionary = {
	"version": "1.0.0",			## 存档版本号
	"timestamp": 0,				## 存档时间戳
	"save_name": "",			## 存档名称
	"play_time": 0,				## 游戏时间
	"screenshot": "",			## 截图
}

## 游戏数据
var game_data: Dictionary = {}

## 初始化，同时设置存档名称和时间戳
## [param save_name] 存档名称
func _init(save_name: String = "") -> void:
	metadata.save_name = save_name
	metadata.timestamp = Time.get_unix_time_from_system()

## 设置游戏数据
## [param key] 键
## [param value] 值
func set_data(key: String, value: Variant) -> void:
	game_data[key] = value

## 获取游戏数据
## [param key] 键
## [param default_value] 默认值
## [return] 值
func get_data(key: String, default_value: Variant = null) -> Variant:
	return game_data.get(key, default_value)

## 删除游戏数据
## [param key] 键
func remove_data(key: String) -> void:
	game_data.erase(key)

## 清空游戏数据
func clear_data() -> void:
	game_data.clear()

## 序列化
## [return] 序列化数据
func serialize() -> Dictionary:
	return {
		"metadata": metadata,
		"game_data": game_data
	}

## 反序列化
## [param data] 序列化数据
func deserialize(data: Dictionary) -> void:
	if data.has("metadata"):
		metadata.merge(data.metadata, true)
	if data.has("game_data"):
		game_data = data.game_data
