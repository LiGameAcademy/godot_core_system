extends Node

## 分层状态机示例
## 这个示例展示了一个简单的游戏状态机系统，包含主状态机和子状态机

## StateMachineManager常规由CoreSystem维护单例，这里进行单元测试
const StateMachineManager = preload("../../source/state_machine/state_machine_manager.gd")

@onready var state_machine_manager = StateMachineManager.new()

## 游戏主状态机
class ExampleGameStateMachine extends BaseStateMachine:
	enum STATE {
		MENU,
		GAMEPLAY,
		PAUSE
	}
	
	func _ready() -> void:
		# 添加主要状态
		add_state(&"menu", MenuState.new())
		add_state(&"gameplay", GameplayState.new())
		add_state(&"pause", PauseState.new())
	
	## 菜单状态
	class MenuState extends BaseState:
		func _enter(_msg := {}) -> void:
			print("进入菜单状态")
	
		func _handle_input(event: InputEvent) -> void:
			if event.is_action_pressed("ui_accept"):
				switch_to(&"gameplay")
	
	## 游戏状态（包含子状态机）
	class GameplayState extends BaseStateMachine:
		func _ready() -> void:
			# 添加子状态
			add_state(&"explore", ExploreState.new())		# 添加探索状态
			add_state(&"battle", BattleState.new())		# 添加战斗状态
			add_state(&"dialog", DialogState.new())		# 添加对话状态
			print("gameplay state ready")
		
		func _enter(msg := {}) -> void:
			print("进入游戏状态")
			# 如果msg中指定了resume，则恢复到上一个状态
			if current_state == null:  # 只在没有当前状态时才启动
				start(&"explore", {}, msg.get("resume", false))
		
		func _handle_input(event: InputEvent) -> void:
			if event.is_action_pressed("ui_cancel"):
				print("退出游戏状态 ui_cancel")
				switch_to(&"pause", {"resume": true}) # 传递resume标记
		
		func _exit() -> void:
			print("退出游戏状态")
			stop()
		
		## 探索状态
		class ExploreState extends BaseState:
			func _enter(_msg := {}) -> void:
				print("进入探索状态")
			
			func _handle_input(event: InputEvent) -> void:
				if event.is_action_pressed("ui_accept"):
					switch_to(&"battle")
				elif event.is_action_pressed("ui_focus_next"):
					switch_to(&"dialog")
		
		## 战斗状态
		class BattleState extends BaseState:
			func _enter(_msg := {}) -> void:
				print("进入战斗状态")
			
			func _exit() -> void:
				print("退出战斗状态")

			func _handle_input(event: InputEvent) -> void:
				if event.is_action_pressed("ui_cancel"):
					print("退出战斗状态 ui_cancel")
					switch_to(&"explore")
		
		## 对话状态
		class DialogState extends BaseState:
			func _enter(_msg := {}) -> void:
				print("进入对话状态")
			
			func _handle_input(event: InputEvent) -> void:
				if event.is_action_pressed("ui_cancel"):
					switch_to(&"explore")
	
	## 暂停状态
	class PauseState extends BaseState:
		func _enter(_msg := {}) -> void:
			print("进入暂停状态")
		
		func _handle_input(event: InputEvent) -> void:
			if event.is_action_pressed("ui_cancel"):
				switch_to(&"gameplay", {"resume": true}) # 传递resume标记
			elif event.is_action_pressed("ui_home"):
				switch_to(&"menu")

func _ready() -> void:
	# 创建并注册主状态机
	var game_state_machine = ExampleGameStateMachine.new()
	state_machine_manager.register_state_machine(&"game", game_state_machine, null, &"menu")
	state_machine_manager._ready()

func _process(delta: float) -> void:
	state_machine_manager._process(delta)

func _physics_process(delta: float) -> void:
	state_machine_manager._physics_process(delta)

func _input(event: InputEvent) -> void:
	state_machine_manager._input(event)

## 使用说明：
## 1. 将此脚本附加到场景中的节点
## 2. 添加StateMachineManager子节点
## 3. 按键操作：
##    - Enter (ui_accept): 
##      - 在菜单中：开始游戏
##      - 在探索中：进入战斗
##    - Tab (ui_focus_next):
##      - 在探索中：开始对话
##    - Esc (ui_cancel):
##      - 在游戏中：暂停（将保存当前游戏状态）
##      - 在暂停中：继续（将恢复到之前的游戏状态）
##      - 在战斗/对话中：返回探索
##    - Home (ui_home):
##      - 在暂停中：返回主菜单
