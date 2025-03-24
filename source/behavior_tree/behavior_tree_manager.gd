extends Node

## 行为树管理器

# 信号
## 行为树注册
signal tree_registered(id: StringName)
## 行为树注销
signal tree_unregistered(id: StringName)
## 行为树启动
signal tree_started(id: StringName)
## 行为树停止
signal tree_stopped(id: StringName)

## 行为树字典
## key: 行为树ID
## value: 行为树
var _behavior_trees: Dictionary[StringName, BTTree] = {}

## 事件总线引用
var _event_bus: CoreSystem.EventBus = CoreSystem.event_bus

## 注册行为树
## [param id] 行为树ID
## [param tree] 行为树资源
## [param agent] 行为树所属节点
func register_tree(id: StringName, tree: BTTree, agent: Node = null) -> void:
	if _behavior_trees.has(id):
		push_warning("Behavior tree %s already registered" % id)
		return
	
	tree.initialize(agent)
	_behavior_trees[id] = tree
	tree_registered.emit(id)

## 注销行为树
## [param id] 行为树ID
func unregister_tree(id: StringName) -> void:
	if not _behavior_trees.has(id):
		push_warning("Behavior tree %s not registered" % id)
		return
	
	var tree = _behavior_trees[id]
	if tree.is_active:
		stop_tree(id)
	
	tree.dispose()
	_behavior_trees.erase(id)
	tree_unregistered.emit(id)

## 启动行为树
## [param id] 行为树ID
func start_tree(id: StringName) -> void:
	if not _behavior_trees.has(id):
		push_warning("Behavior tree %s not registered" % id)
		return
	
	var tree = _behavior_trees[id]
	tree.start()
	tree_started.emit(id)

## 停止行为树
## [param id] 行为树ID
func stop_tree(id: StringName) -> void:
	if not _behavior_trees.has(id):
		push_warning("Behavior tree %s not registered" % id)
		return
	
	var tree = _behavior_trees[id]
	tree.stop()
	tree_stopped.emit(id)

## 重置行为树
## [param id] 行为树ID
func reset_tree(id: StringName) -> void:
	if not _behavior_trees.has(id):
		push_warning("Behavior tree %s not registered" % id)
		return
	
	var tree = _behavior_trees[id]
	tree.reset()

## 获取行为树
## [param id] 行为树ID
func get_tree(id: StringName) -> BTTree:
	return _behavior_trees.get(id)

## 获取行为树列表
func get_tree_list() -> Array[StringName]:
	return _behavior_trees.keys()
