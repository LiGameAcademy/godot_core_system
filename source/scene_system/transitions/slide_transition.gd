@tool
extends BaseTransition
class_name SlideTransition

## 滑动转场效果

## 执行开始转场
## @param duration 转场持续时间
func _do_start(duration: float) -> void:
	_transition_rect.color.a = 1.0
	_transition_rect.position.x = -_transition_rect.size.x
	
	var tween = _transition_rect.create_tween()
	tween.tween_property(_transition_rect, "position:x", 0, duration)
	await tween.finished

## 执行结束转场
## @param duration 转场持续时间
func _do_end(duration: float) -> void:
	var tween = _transition_rect.create_tween()
	tween.tween_property(_transition_rect, "position:x", _transition_rect.size.x, duration)
	await tween.finished
