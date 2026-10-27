class_name CoreSessionExampleModel
extends RefCounted

## Two project rules compose the same lifecycle without nodes or UI.
var session: CoreGameSession:
	get: return _session
var points: int:
	get: return _points
var timed: bool:
	get: return _timed
var elapsed: float:
	get: return _timer.elapsed
var _session: CoreGameSession
var _timer: CoreTimer = CoreTimer.new(3.0)
var _prefix: String
var _sequence: int = 0
var _points: int = 0
var _timed: bool = false

func _init(identity_prefix: String = "example", timed_end: bool = false) -> void:
	_prefix = identity_prefix
	new_run(timed_end)

func new_run(timed_end: bool = false) -> bool:
	if _session != null and _session.phase != CoreGameSession.Phase.CLOSED and not _session.close():
		return false
	_sequence += 1
	_session = CoreGameSession.new("%s-%d" % [_prefix, _sequence])
	_points = 0
	_timed = timed_end
	_timer.reset()
	return true

func progress() -> bool:
	if _timed or session.phase != CoreGameSession.Phase.RUNNING:
		return false
	_points = mini(3, _points + 1)
	if _points >= 3:
		session.end()
	return true

func advance(delta: float) -> void:
	if not _timed or session.phase != CoreGameSession.Phase.RUNNING:
		return
	_timer.advance(delta)
	if _timer.completed:
		session.end()
