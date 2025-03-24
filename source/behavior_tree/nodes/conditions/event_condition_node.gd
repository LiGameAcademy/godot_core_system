extends BTConditionNode
class_name BTEventConditionNode

## 事件条件节点：检查事件是否触发

## 等待的事件名称
@export var event_name: String = ""
## 超时时间（秒），0表示永不超时
@export var timeout: float = 0.0
## 是否只触发一次
@export var once: bool = true

var _event_triggered: bool = false
var _start_time: float = 0.0

func _on_enter() -> void:
	super()
	_event_triggered = false
	_start_time = Time.get_ticks_msec() / 1000.0
	if CoreSystem.event_bus and not event_name.is_empty():
		CoreSystem.event_bus.subscribe(event_name, _on_event_triggered, CoreSystem.EventBus.Priority.HIGH)

func _on_exit() -> void:
	super()
	if CoreSystem.event_bus and not event_name.is_empty():
		CoreSystem.event_bus.unsubscribe(event_name, _on_event_triggered)

func _on_event_triggered(_event_name: String, _payload: Array) -> void:
	_event_triggered = true

func check_condition() -> bool:
	if timeout > 0:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - _start_time >= timeout:
			return false
	
	if _event_triggered and once:
		_on_exit()
	
	return _event_triggered
