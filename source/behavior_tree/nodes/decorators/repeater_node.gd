extends BTDecoratorNode
class_name BTRepeaterNode

## 重复节点：重复执行子节点指定次数

## 重复次数，-1表示无限重复
@export var repeat_count: int = -1
## 当子节点失败时是否中止
@export var abort_on_failure: bool = false

## 当前重复次数
var current_count: int = 0

func reset() -> void:
	super()
	current_count = 0

func _update() -> Status:
	if not child:
		return Status.FAILURE
	
	if repeat_count >= 0 and current_count >= repeat_count:
		return Status.SUCCESS
	
	var status = child.tick()
	match status:
		Status.SUCCESS, Status.FAILURE:
			if status == Status.FAILURE and abort_on_failure:
				return Status.FAILURE
			child.reset()
			current_count += 1
			return Status.RUNNING if repeat_count < 0 or current_count < repeat_count else Status.SUCCESS
		_:
			return status
