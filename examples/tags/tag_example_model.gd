class_name CoreTagExampleModel
extends RefCounted

## Example rules consume local tags without finding nodes or UI.
var tags: CoreTags = CoreTags.new()
var actions_completed: int = 0
var can_act: bool:
	get:
		return tags.has("unit", false) and not tags.has("state.stunned")

func _init() -> void:
	reset()

func try_act() -> bool:
	if not can_act:
		return false
	actions_completed += 1
	return true

func reset() -> void:
	actions_completed = 0
	tags.clear()
	tags.add("unit.scout")
