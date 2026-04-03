extends Node

## 分层状态机示例
## 这个示例展示了一个简单的游戏状态机系统，包含主状态机和子状态机
##
## [StateMachineManager.transition_state_machine]：任意脚本可通过管理器按 ID 跳转已注册状态机。
## - 若该机尚未 [method BaseStateMachine.start]（[code]current_state == null[/code]），则等价于 [method StateMachineManager.start_state_machine]。
## - 否则在内部调用 [method BaseStateMachine.transition_local]，与状态内 [code]transition_to[/code] 一致，但无需持有状态机引用。
var state_machine_manager : CoreSystem.StateMachineManager = CoreSystem.state_machine_manager
var state_label : Label

func _ready() -> void:
	# 创建并注册主状态机
	var game_state_machine = ExampleGameStateMachine.new()
	state_machine_manager.register_state_machine(&"game", game_state_machine, self, &"menu")
	
	# 获取状态显示标签
	state_label = $StateLabel


## 演示：根节点从外部调用 [method StateMachineManager.transition_state_machine]，
## 将已注册的 [code]&"game"[/code] 切到 [code]&"pause"[/code]（无需 [code]get_state_machine[/code] 再调 [code]transition_to[/code]）。
## 默认输入映射中 [code]ui_focus_prev[/code] 一般为 Shift+Tab。
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_focus_prev"):
		return
	if state_machine_manager.transition_state_machine(&"game", &"pause", {}):
		print("transition_state_machine: game -> pause (via manager)")


func _process(_delta: float) -> void:
	# 更新状态显示
	update_state_display()
	
func update_state_display() -> void:
	var current_state_text = "当前状态: "
	var game_state_machine = state_machine_manager.get_state_machine(&"game")
	
	if game_state_machine and game_state_machine.is_active:
		var main_state_name = game_state_machine.get_current_state_name()
		current_state_text += main_state_name
		
		# 如果是游戏状态，还要显示子状态
		if main_state_name == &"gameplay" and game_state_machine.current_state is BaseStateMachine:
			var gameplay_state = game_state_machine.current_state as BaseStateMachine
			if gameplay_state.current_state:
				current_state_text += " > " + gameplay_state.get_current_state_name()
	else:
		current_state_text += "无"
	
	state_label.text = current_state_text
