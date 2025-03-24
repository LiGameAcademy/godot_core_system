extends BTNode
class_name BTConditionNode

## 条件节点：检查条件是否满足

## 检查条件
## 由子类实现
func check_condition() -> bool:
	return true

func _update() -> Status:
	return Status.SUCCESS if check_condition() else Status.FAILURE
