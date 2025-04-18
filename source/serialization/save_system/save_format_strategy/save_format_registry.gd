extends RefCounted

const SaveFormatStrategy = preload("./save_format_strategy.gd")
const SaveManager = CoreSystem.SaveManager
const ResourceSaveStrategy = preload("./resource_save_strategy.gd")
const BinarySaveStrategy = preload("./binary_save_strategy.gd")
const JSONSaveStrategy = preload("./json_save_strategy.gd")

var _strategies = {}

## 注册策略
func register_strategy(format: StringName, strategy: SaveFormatStrategy) -> void:
	_strategies[format] = strategy

## 获取策略
func get_strategy(format: StringName) -> SaveFormatStrategy:
	if _strategies.has(format):
		return _strategies[format]
	
	# 创建新策略实例
	var strategy: SaveFormatStrategy
	match format:
		&"resource":
			strategy = ResourceSaveStrategy.new()
		&"binary":
			strategy = BinarySaveStrategy.new()
		&"json":
			strategy = JSONSaveStrategy.new()
		_:
			strategy = BinarySaveStrategy.new()
	
	_strategies[format] = strategy
	return strategy
