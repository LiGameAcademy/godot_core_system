extends Resource
class_name BTTree

## 行为树资源

## 根节点
@export var root_node: BTNode
## 树的名称
@export var tree_name: String = ""
## 树的描述
@export_multiline var description: String = ""

## 黑板数据
var blackboard: Dictionary = {}
## 是否激活
var is_active: bool = false
## 所属的对象
var agent: Node = null

## 初始化行为树
func initialize(agent_node: Node = null) -> void:
	agent = agent_node
	if root_node:
		root_node.initialize(self)

## 执行一次tick
func tick() -> void:
	if not is_active or not root_node:
		return
	root_node.tick()

## 启动行为树
func start() -> void:
	if root_node == null:
		push_error("Behavior tree has no root node!")
		return
	
	is_active = true

## 停止行为树
func stop() -> void:
	is_active = false
	if root_node:
		root_node.reset()

## 重置行为树
func reset() -> void:
	if root_node:
		root_node.reset()

## 设置黑板数据
func set_blackboard_value(key: String, value: Variant) -> void:
	blackboard[key] = value

## 获取黑板数据
func get_blackboard_value(key: String, default_value: Variant = null) -> Variant:
	return blackboard.get(key, default_value)
