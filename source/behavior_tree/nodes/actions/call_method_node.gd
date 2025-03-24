extends BTNode
class_name BTCallMethodNode

## 调用方法节点：调用指定对象的方法

## 方法名
@export var method: String = ""
## 参数列表
@export var args: Array = []
## 目标对象路径（相对于agent）
@export var target_path: NodePath

## 获取目标对象
func get_target() -> Node:
	if tree and tree.agent:
		if target_path.is_empty():
			return tree.agent
		return tree.agent.get_node(target_path)
	return null

func _update() -> Status:
	var target = get_target()
	if not target or method.is_empty():
		return Status.FAILURE
	
	if not target.has_method(method):
		push_error("Object %s has no method named %s" % [target.name, method])
		return Status.FAILURE
	
	var result = target.callv(method, args)
	if result is bool:
		return Status.SUCCESS if result else Status.FAILURE
	return Status.SUCCESS
