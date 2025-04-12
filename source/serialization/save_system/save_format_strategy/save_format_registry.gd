extends RefCounted

const SaveFormatStrategy = preload("./save_format_strategy.gd")
const SaveManager = CoreSystem.SaveManager
const ResourceSaveStrategy = preload("./resource_save_strategy.gd")
const BinarySaveStrategy = preload("./binary_save_strategy.gd")
const JSONSaveStrategy = preload("./json_save_strategy.gd")

var _strategies = {}

## 注册策略
func register_strategy(format: SaveManager.SaveFormat, strategy: SaveFormatStrategy) -> void:
    _strategies[format] = strategy

## 获取策略
func get_strategy(format: SaveManager.SaveFormat, manager: Node) -> SaveFormatStrategy:
    if _strategies.has(format):
        return _strategies[format]
    
    # 创建新策略实例
    var strategy: SaveFormatStrategy
    match format:
        SaveManager.SaveFormat.RESOURCE:
            strategy = ResourceSaveStrategy.new(manager)
        SaveManager.SaveFormat.BINARY:
            strategy = BinarySaveStrategy.new(manager)
        SaveManager.SaveFormat.JSON:
            strategy = JSONSaveStrategy.new(manager)
        _:
            strategy = BinarySaveStrategy.new(manager)
    
    _strategies[format] = strategy
    return strategy