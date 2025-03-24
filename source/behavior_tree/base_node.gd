extends Resource
class_name BTNode

## 行为树节点基类

enum Status {
	SUCCESS,  # 执行成功
	FAILURE,  # 执行失败
	RUNNING,  # 正在执行
	INVALID   # 无效状态
}

## 节点名称
@export var node_name: String = ""
## 节点描述
@export_multiline var description: String = ""
## 触发事件列表
@export var trigger_events: Array[String] = []

## 当前状态
var current_status: Status = Status.INVALID
## 是否激活
var is_active: bool = false
## 父节点
var parent: BTNode = null
## 黑板 - 用于节点间共享数据
var blackboard: Dictionary = {}
## 所属的行为树
var tree: BTTree = null

## 初始化节点
func initialize(tree_ref: BTTree, parent_node: BTNode = null) -> void:
	tree = tree_ref
	parent = parent_node
	blackboard = tree.blackboard if tree else {}
	_subscribe_events()

## 订阅事件
func _subscribe_events() -> void:
	if not tree or trigger_events.is_empty():
		return
	for event in trigger_events:
		CoreSystem.event_bus.subscribe(event, _on_event, CoreSystem.EventBus.Priority.NORMAL)

## 取消订阅事件
func _unsubscribe_events() -> void:
	if not tree or trigger_events.is_empty():
		return
	for event in trigger_events:
		tree.event_bus.unsubscribe(event, _on_event)

## 事件处理
func _on_event(_event_name: String, _payload: Array) -> void:
	if not is_active:
		_on_enter()
	
	current_status = _update()
	
	if current_status != Status.RUNNING:
		_on_exit()

## 执行节点
## 返回执行状态
func tick() -> Status:
	if not is_active:
		_on_enter()
	
	current_status = _update()
	
	if current_status != Status.RUNNING:
		_on_exit()
	
	return current_status

## 重置节点状态
func reset() -> void:
	current_status = Status.INVALID
	is_active = false
	_on_reset()

## 节点进入时调用
func _on_enter() -> void:
	is_active = true

## 节点退出时调用
func _on_exit() -> void:
	is_active = false

## 节点重置时调用
func _on_reset() -> void:
	pass

## 更新节点
## 由子类实现具体逻辑
func _update() -> Status:
	return Status.SUCCESS

## 中断节点执行
func abort() -> void:
	if is_active:
		_on_exit()
	reset()

## 释放资源
func dispose() -> void:
	_unsubscribe_events()
