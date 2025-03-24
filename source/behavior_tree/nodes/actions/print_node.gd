extends BTNode
class_name BTPrintNode

## 打印节点：用于调试

## 打印的消息
@export_multiline var message: String = ""

func _update() -> Status:
	print(message)
	return Status.SUCCESS
