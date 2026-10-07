class_name CoreTriggerExampleModel
extends RefCounted

var tags: CoreTags = CoreTags.new()
var trigger: CoreTrigger
var last_result: CoreTrigger.Result = CoreTrigger.Result.CONDITION_FAILED

func _init() -> void:
	trigger = CoreTrigger.new(_is_ready, 2)

func try_fire() -> void:
	last_result = trigger.try_fire({"tags": tags})

func toggle_ready() -> void:
	if tags.has("state.ready"):
		tags.remove("state.ready")
	else:
		tags.add("state.ready")

static func _is_ready(context: Dictionary) -> bool:
	var current: CoreTags = context.get("tags") as CoreTags
	return current != null and current.has("state.ready")
