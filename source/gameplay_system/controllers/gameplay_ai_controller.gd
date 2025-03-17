extends GameplayController
class_name GameplayAIController

## AI控制器
## 处理AI行为逻辑
## 管理AI状态和决策
# # 职责：
# - 管理AI的行为逻辑
# - 处理AI决策
# - 控制AI角色的行动
# # 主要接口：
# - _setup_behavior_tree()：设置行为树
# - update_blackboard()：更新黑板数据
# - get_blackboard_value()：获取黑板数据

# 行为树
var behavior_tree: Node

# 黑板数据
var blackboard: Dictionary

func _init(mode: GameplayGameMode = null) -> void:
	super(mode)
	blackboard = {}

## 当接管Pawn时
func _possess() -> void:
	super()
	if possessed_pawn:
		_setup_behavior_tree()

## 当释放Pawn时
func _unpossess() -> void:
	super()
	if behavior_tree:
		behavior_tree.queue_free()
		behavior_tree = null

## 设置行为树
func _setup_behavior_tree() -> void:
	# 这里可以根据AI类型加载不同的行为树
	pass

## 更新黑板数据
func update_blackboard(key: String, value: Variant) -> void:
	blackboard[key] = value

## 获取黑板数据
func get_blackboard_value(key: String, default_value: Variant = null) -> Variant:
	return blackboard.get(key, default_value)
