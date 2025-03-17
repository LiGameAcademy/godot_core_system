extends BaseState
class_name GameplayState

## 游戏状态基类
## 所有具体的游戏状态都应该继承此类

# 游戏模式引用
var game_mode: GameplayGameMode

func _init(mode: GameplayGameMode = null) -> void:
    game_mode = mode

## 状态开始时调用
func enter() -> void:
    pass

## 状态结束时调用
func exit() -> void:
    pass

## 状态更新时调用
func update(delta: float) -> void:
    pass

## 状态物理更新时调用
func physics_update(delta: float) -> void:
    pass

## 状态输入处理
func handle_input(event: InputEvent) -> void:
    pass

## 获取状态数据
func get_state_data() -> Dictionary:
    return {}

## 设置状态数据
func set_state_data(data: Dictionary) -> void:
    pass
