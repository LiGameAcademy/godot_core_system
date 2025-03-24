extends BTDecoratorNode
class_name BTInverterNode

## 反转节点：反转子节点的执行结果

func _update() -> Status:
	if not child:
		return Status.FAILURE
	
	var status = child.tick()
	match status:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			return Status.SUCCESS
		_:
			return status
