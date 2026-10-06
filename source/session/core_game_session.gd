class_name CoreGameSession
extends RefCounted

## One caller-owned run. Closed instances never restart.
enum Phase { PREPARING, RUNNING, PAUSED, ENDED, CLOSED }
signal changed(previous: Phase, current: Phase)

var id: String:
	get: return _id
var phase: Phase:
	get: return _flow.current if _flow != null else Phase.PREPARING
var _id: String
var _flow: CoreStateMachine
var _changing: bool = false

func _init(session_id: String) -> void:
	_id = session_id
	if session_id.is_empty():
		push_error("A session requires a non-empty caller-provided identity.")
		return
	var values: Array[int] = [Phase.PREPARING, Phase.RUNNING, Phase.PAUSED, Phase.ENDED, Phase.CLOSED]
	# A static predicate does not retain this RefCounted through its state machine.
	_flow = CoreStateMachine.new(Phase.PREPARING, values, CoreGameSession._can_transition)

func snapshot() -> Dictionary[String, Variant]:
	return {"id": _id, "phase": phase}

func start() -> bool:
	return _change(Phase.RUNNING) if phase == Phase.PREPARING else false

## Optional adapters return Error and must preserve external state on failure.
func pause(before_commit: Callable = Callable()) -> bool:
	return _change(Phase.PAUSED, before_commit)

func resume(before_commit: Callable = Callable()) -> bool:
	return _change(Phase.RUNNING, before_commit) if phase == Phase.PAUSED else false

func end() -> bool:
	return _change(Phase.ENDED)

func close() -> bool:
	return _change(Phase.CLOSED)

func _change(next: Phase, before_commit: Callable = Callable()) -> bool:
	if _flow == null or _changing or not _can_transition(phase, next):
		return false
	_changing = true
	if not before_commit.is_null():
		if not before_commit.is_valid():
			_changing = false
			return false
		var result: Variant = before_commit.call()
		if not result is int or result != OK:
			_changing = false
			return false
	var previous: Phase = phase
	var committed: bool = _flow.try_transition(next)
	if committed:
		changed.emit(previous, phase)
	_changing = false
	return committed

static func _can_transition(current: int, next: int) -> bool:
	if next == Phase.CLOSED:
		return current != Phase.CLOSED
	match current:
		Phase.PREPARING: return next == Phase.RUNNING
		Phase.RUNNING: return next == Phase.PAUSED or next == Phase.ENDED
		Phase.PAUSED: return next == Phase.RUNNING or next == Phase.ENDED
	return false
