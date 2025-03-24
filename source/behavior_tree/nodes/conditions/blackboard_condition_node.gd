extends BTConditionNode
class_name BTBlackboardConditionNode

## 黑板条件节点：检查黑板中的值

## 键名
@export var key: String = ""
## 操作符
@export_enum("==", "!=", "<", "<=", ">", ">=") var operator: String = "=="
## 比较值
@export var value: Variant

func check_condition() -> bool:
	if key.is_empty() or not tree:
		return false
	
	var bb_value = tree.get_blackboard_value(key)
	match operator:
		"==":
			return bb_value == value
		"!=":
			return bb_value != value
		"<":
			return bb_value < value
		"<=":
			return bb_value <= value
		">":
			return bb_value > value
		">=":
			return bb_value >= value
	
	return false
