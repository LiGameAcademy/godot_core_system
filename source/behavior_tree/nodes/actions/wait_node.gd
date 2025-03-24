extends BTNode
class_name BTWaitNode

## 等待节点：等待指定时间

## 等待时间（秒）
@export var wait_time: float = 1.0

## 开始时间
var start_time: float = 0.0

func _on_enter() -> void:
	super()
	start_time = Time.get_ticks_msec() / 1000.0

func _update() -> Status:
	if Time.get_ticks_msec() / 1000.0 - start_time >= wait_time:
		return Status.SUCCESS
	return Status.RUNNING
