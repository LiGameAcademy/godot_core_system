extends BTDecoratorNode
class_name BTTimeoutNode

## 超时节点：限制子节点的执行时间

## 超时时间（秒）
@export var timeout: float = 1.0

## 开始时间
var start_time: float = 0.0

func _on_enter() -> void:
	super()
	start_time = Time.get_ticks_msec() / 1000.0

func _update() -> Status:
	if not child:
		return Status.FAILURE
	
	if Time.get_ticks_msec() / 1000.0 - start_time >= timeout:
		return Status.FAILURE
	
	return child.tick()
