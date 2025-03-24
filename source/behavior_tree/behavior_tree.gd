extends Resource
class_name BTTree

## 行为树资源

## 根节点
@export var root_node: BTNode
## 树的名称
@export var tree_name: String = ""
## 树的描述
@export_multiline var description: String = ""
## 自动启动事件
@export var auto_start_events: Array[String] = []
## 自动停止事件
@export var auto_stop_events: Array[String] = []

## 黑板数据
var blackboard: Dictionary = {}
## 是否激活
var is_active: bool = false
## 所属的对象
var agent: Node = null
## 事件总线
var event_bus: CoreSystem.EventBus = CoreSystem.event_bus

## 初始化行为树
func initialize(agent_node: Node = null) -> void:
	agent = agent_node
	if root_node:
		root_node.initialize(self)
	
	if event_bus and not auto_start_events.is_empty():
		for event in auto_start_events:
			event_bus.subscribe(event, func(_e, _p): start(), CoreSystem.EventBus.Priority.NORMAL)
		for event in auto_stop_events:
			event_bus.subscribe(event, func(_e, _p): stop(), CoreSystem.EventBus.Priority.NORMAL)

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
	if event_bus:
		event_bus.push_event("bt_started", [tree_name])

## 停止行为树
func stop() -> void:
	is_active = false
	if root_node:
		root_node.reset()
	if event_bus:
		event_bus.push_event("bt_stopped", [tree_name])

## 重置行为树
func reset() -> void:
	if root_node:
		root_node.reset()

## 设置黑板数据
func set_blackboard_value(key: String, value: Variant) -> void:
	blackboard[key] = value
	if event_bus:
		event_bus.push_event("bt_blackboard_changed", [tree_name, key, value])

## 获取黑板数据
func get_blackboard_value(key: String, default_value: Variant = null) -> Variant:
	return blackboard.get(key, default_value)

## 释放资源
func dispose() -> void:
	if root_node:
		root_node.dispose()
	if event_bus:
		for event in auto_start_events:
			event_bus.unsubscribe(event, start)
		for event in auto_stop_events:
			event_bus.unsubscribe(event, stop)
