extends BTCompositeNode
class_name BTSelectorNode

## 选择节点：执行子节点直到一个成功或全部失败

func _update() -> Status:
	while current_child_index < children.size():
		var child = children[current_child_index]
		var status = child.tick()
		
		match status:
			Status.RUNNING:
				return Status.RUNNING
			Status.SUCCESS:
				return Status.SUCCESS
			Status.FAILURE:
				current_child_index += 1
	
	return Status.FAILURE
