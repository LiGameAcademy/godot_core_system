extends BaseStateMachine
class_name GameplayGameState

## 游戏状态基类
## 基于状态机实现的游戏状态管理器
# # 职责：
# - 管理特定游戏状态下的逻辑
# - 处理状态进入和退出
# - 更新状态相关的数据
# # 主要接口：
# - on_state_begin()：状态开始时调用
# - on_state_end()：状态结束时调用
# - on_state_update()：状态更新时调用

# 游戏模式引用
var game_mode: GameplayGameMode

func _init(mode: GameplayGameMode = null) -> void:
    super()
    game_mode = mode

## 状态开始
func on_state_begin() -> void:
    pass

## 状态结束
func on_state_end() -> void:
    pass

## 状态更新
func on_state_update(_delta: float) -> void:
    pass

## 添加游戏状态
## [param state_name] 状态名称
## [param state] 状态实例
## [param is_initial] 是否为初始状态
func add_game_state(state_name: StringName, state: BaseState, is_initial: bool = false) -> void:
    # 设置状态的游戏模式引用
    state.game_mode = game_mode
    # 添加状态
    add_state(state_name, state)
    # 如果是初始状态，设置为当前状态
    if is_initial:
        set_initial_state(state_name)

## 添加状态转换规则
## [param from_state] 源状态名称
## [param to_state] 目标状态名称
## [param condition] 转换条件函数
## [param priority] 优先级，数值越大优先级越高
func add_game_transition(from_state: StringName, to_state: StringName, 
                        condition: Callable, priority: int = 0) -> void:
    add_transition(from_state, to_state, condition, priority)

## 强制切换状态
## [param state_name] 目标状态名称
func force_state(state_name: StringName) -> void:
    if has_state(state_name):
        transition_to(state_name)

## 获取当前状态名称
func get_current_state_name() -> StringName:
    return current_state.name if current_state else &""

## 检查是否处于指定状态
func is_in_state(state_name: StringName) -> bool:
    return current_state and current_state.name == state_name
