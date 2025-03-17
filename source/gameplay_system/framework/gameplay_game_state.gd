extends RefCounted
class_name GameplayGameState

## 游戏状态基类
## 定义游戏状态的基本接口和行为
## 每个具体的游戏状态都应该继承此类并实现相应的方法

# 游戏模式引用
var game_mode: GameplayGameMode

# 状态名称
var _state_name: StringName

func _init(mode: GameplayGameMode, name: StringName) -> void:
	game_mode = mode
	_state_name = name
	mode.register_state(self)

## 状态激活时调用
## [param prev_state] 前一个状态
## [return] 是否成功进入状态
func enter(prev_state: GameplayGameState) -> bool:
	return true

## 状态退出时调用
## [param next_state] 下一个状态
## [return] 是否成功退出状态
func exit(next_state: GameplayGameState) -> bool:
	return true

## 状态更新
## [param delta] 更新时间间隔
func update(delta: float) -> void:
	pass

## 状态物理更新
## [param delta] 物理更新时间间隔
func physics_update(delta: float) -> void:
	pass

## 输入处理
## [param event] 输入事件
func handle_input(event: InputEvent) -> void:
	pass

## 暂停处理
## [param paused] 是否暂停
func handle_pause(paused: bool) -> void:
	pass

## 获取状态名称
## [return] 状态名称
func get_state_name() -> StringName:
	return _state_name

## 检查是否可以转换到指定状态
## [param next_state] 目标状态
## [return] 是否可以转换
func can_transition_to(next_state: GameplayGameState) -> bool:
	return true

## 获取状态数据
## [return] 状态数据字典
func get_state_data() -> Dictionary:
	return {}

## 设置状态数据
## [param data] 状态数据字典
func set_state_data(data: Dictionary) -> void:
	pass
