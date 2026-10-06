extends RefCounted
class_name CoreTagCharacterModel

## Local demonstration rules. Tags are the single authority for action state.
var tags: CoreTags = CoreTags.new()
var _attack_timer: CoreTimer

func _init(category: String) -> void:
	if tags.add(category):
		tags.add("state.idle")

func toggle_move() -> bool:
	if tags.has("state.moving"):
		tags.remove("state.moving")
		tags.add("state.idle")
		return false
	tags.remove("state.idle")
	tags.add("state.moving")
	return true

func begin_attack(seconds: float) -> bool:
	if tags.has("state.attacking"):
		return false
	if not is_finite(seconds) or seconds <= 0.0:
		push_error("Attack duration must be finite and positive.")
		return false
	_attack_timer = CoreTimer.new(seconds)
	tags.add("state.attacking")
	return true

func advance(delta: float) -> bool:
	if _attack_timer == null or _attack_timer.advance(delta) == 0:
		return false
	_attack_timer = null
	tags.remove("state.attacking")
	return true