extends TriggerCondition
class_name EventTypeTriggerCondition

@export var event_type: StringName = &""

func _init(config : Dictionary = {}) -> void:
	event_type = config.get("event_type", "")

func evaluate(context: Dictionary) -> bool:
	return context.get("event_type", "") == event_type
