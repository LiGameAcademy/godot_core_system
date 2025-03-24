extends BTCompositeNode
class_name BTSequenceNode

## 序列节点：按顺序执行所有子节点，直到一个失败或全部成功

func _update() -> Status:
	while current_child_index < children.size():
		var child = children[current_child_index]
		var status = child.tick()
		
		match status:
			Status.RUNNING:
				return Status.RUNNING
			Status.FAILURE:
				return Status.FAILURE
			Status.SUCCESS:
				current_child_index += 1
	
	return Status.SUCCESS
