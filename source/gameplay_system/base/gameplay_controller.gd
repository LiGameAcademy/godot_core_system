extends Node
class_name GameplayController

## 控制器基类
## 负责控制Pawn的行为
# # 职责：
# - 定义控制 Pawn 的基本接口
# - 管理 Pawn 的持有和释放
# - 提供控制权转换的机制
# # 主要接口：
# - possess()：接管 Pawn 的控制
# - unpossess()：释放 Pawn 的控制
# - _possess()：接管时的具体实现
# - _unpossess()：释放时的具体实现

# 信号
signal possessed_pawn_changed(old_pawn: GameplayPawn, new_pawn: GameplayPawn)

# 当前控制的Pawn
var possessed_pawn: GameplayPawn:
	set(value):
		var old_pawn = possessed_pawn
		if old_pawn:
			_unpossess()
		possessed_pawn = value
		if possessed_pawn:
			_possess()
		emit_signal("possessed_pawn_changed", old_pawn, value)

# 游戏模式引用
var game_mode: GameplayGameMode

func _init(mode: GameplayGameMode = null) -> void:
	game_mode = mode

## 接管Pawn
func possess(pawn: GameplayPawn) -> void:
	if pawn and pawn != possessed_pawn:
		possessed_pawn = pawn

## 释放Pawn
func unpossess() -> void:
	possessed_pawn = null

## 接管时调用
func _possess() -> void:
	pass

## 释放时调用
func _unpossess() -> void:
	pass
