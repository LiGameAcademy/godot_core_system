extends Node
class_name GameplayManager

## 游戏管理器
## 管理游戏模式、玩家控制器等核心游戏系统

# 信号
signal game_mode_changed(old_mode: GameplayGameMode, new_mode: GameplayGameMode)
signal player_controller_changed(old_controller: GameplayPlayerController, new_controller: GameplayPlayerController)
signal ai_controller_added(controller: GameplayAIController)
signal ai_controller_removed(controller: GameplayAIController)

# 当前游戏模式
var current_game_mode: GameplayGameMode:
	set(value):
		if current_game_mode != value:
			var old_mode = current_game_mode
			if current_game_mode:
				current_game_mode.queue_free()
			current_game_mode = value
			if current_game_mode:
				add_child(current_game_mode)
			game_mode_changed.emit(old_mode, current_game_mode)

# 当前玩家控制器
var current_player_controller: GameplayPlayerController:
	set(value):
		if current_player_controller != value:
			var old_controller = current_player_controller
			if current_player_controller:
				current_player_controller.queue_free()
			current_player_controller = value
			if current_player_controller:
				add_child(current_player_controller)
				# 设置控制器的游戏模式
				current_player_controller.game_mode = current_game_mode
			player_controller_changed.emit(old_controller, current_player_controller)

# AI控制器列表
var ai_controllers: Array[GameplayAIController] = []

## 设置游戏模式
## [param game_mode] 新的游戏模式实例
## [return] 设置的游戏模式实例
func set_game_mode(game_mode: GameplayGameMode) -> GameplayGameMode:
	current_game_mode = game_mode
	return current_game_mode

## 设置玩家控制器
## [param controller] 新的玩家控制器实例
## [return] 设置的玩家控制器实例
func set_player_controller(controller: GameplayPlayerController) -> GameplayPlayerController:
	current_player_controller = controller
	return current_player_controller

## 创建游戏模式
## [param game_mode_type] 游戏模式类型
## [return] 创建的游戏模式实例
func create_game_mode(game_mode_type: GDScript) -> GameplayGameMode:
	var game_mode = game_mode_type.new()
	set_game_mode(game_mode)
	return game_mode

## 创建玩家控制器
## [param controller_type] 控制器类型
## [return] 创建的控制器实例
func create_player_controller(controller_type: GDScript) -> GameplayPlayerController:
	var controller = controller_type.new()
	set_player_controller(controller)
	return controller

## 创建AI控制器
## [param controller_type] AI控制器类型
## [return] 创建的AI控制器实例
func create_ai_controller(controller_type: GDScript = GameplayAIController) -> GameplayAIController:
	var controller = controller_type.new()
	add_ai_controller(controller)
	return controller

## 添加AI控制器
## [param controller] AI控制器实例
func add_ai_controller(controller: GameplayAIController) -> void:
	if not controller in ai_controllers:
		ai_controllers.append(controller)
		add_child(controller)
		controller.game_mode = current_game_mode
		ai_controller_added.emit(controller)

## 移除AI控制器
## [param controller] 要移除的AI控制器实例
func remove_ai_controller(controller: GameplayAIController) -> void:
	if controller in ai_controllers:
		ai_controllers.erase(controller)
		remove_child(controller)
		controller.queue_free()
		ai_controller_removed.emit(controller)

## 获取所有AI控制器
## [return] AI控制器列表
func get_ai_controllers() -> Array[GameplayAIController]:
	return ai_controllers

## 获取当前游戏模式
## [return] 当前游戏模式实例
func get_game_mode() -> GameplayGameMode:
	return current_game_mode

## 获取当前玩家控制器
## [return] 当前玩家控制器实例
func get_player_controller() -> GameplayPlayerController:
	return current_player_controller
