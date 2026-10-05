extends RefCounted
class_name CoreTimer

## Deterministic countdown driven by elapsed seconds, without a global clock.
const MAX_COMPLETIONS: int = 2147483647
var duration: float:
	get:
		return _duration
var repeating: bool:
	get:
		return _repeating
var paused: bool = false
var elapsed: float:
	get:
		return _elapsed
var completed: bool:
	get:
		return _completed
var _duration: float = 0.0
var _repeating: bool = false
var _elapsed: float = 0.0
var _completed: bool = false
var _valid: bool = false

func _init(seconds: float, repeats: bool = false) -> void:
	if not is_finite(seconds) or seconds <= 0.0:
		push_error("Duration must be finite and positive.")
		return
	_duration = seconds
	_repeating = repeats
	_valid = true

## Returns all completed intervals in O(1), preserving repeating overshoot.
func advance(delta: float) -> int:
	if not is_finite(delta) or delta < 0.0:
		push_error("Delta must be finite and nonnegative.")
		return 0
	if not _valid or paused or completed:
		return 0
	var total: float = elapsed + delta
	if not is_finite(total):
		push_error("Elapsed time overflowed.")
		return 0
	if total < duration:
		_elapsed = total
		return 0
	if not repeating:
		_elapsed = duration
		_completed = true
		return 1
	var intervals: float = floor(total / duration)
	if not is_finite(intervals) or intervals > MAX_COMPLETIONS:
		push_error("Completion count overflowed.")
		return 0
	_elapsed = fmod(total, duration)
	return int(intervals)

func reset() -> void:
	_elapsed = 0.0
	_completed = false

func get_remaining() -> float:
	return maxf(0.0, duration - elapsed)
