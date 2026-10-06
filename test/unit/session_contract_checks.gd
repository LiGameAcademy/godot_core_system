extends SceneTree

var _checks: int = 0
var _failed: bool = false
var _active: CoreGameSession
var _observations: Array[int] = []
var _backend: CoreTimeSettings = CoreTimeSettings.new(false, 1.0)
var _write_fails: bool = false
var _adapters: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var commands: Array[StringName] = [&"start", &"pause", &"resume", &"end", &"close"]
	var targets: Array[int] = [1, 2, 1, 3, 4]
	var allowed: Array[Array] = [[true, false, false, false, true], [false, true, false, true, true],
		[false, false, true, true, true], [false, false, false, false, true], [false, false, false, false, false]]
	for phase: int in range(5):
		for index: int in range(5):
			var current: CoreGameSession = _at_phase(phase)
			var notices: Array[int] = []
			current.changed.connect(func(_previous: int, value: int) -> void: notices.append(value))
			var expected: bool = allowed[phase][index]
			_check(current.call(commands[index]) == expected and current.phase == (targets[index] if expected else phase)
				and notices.size() == (1 if expected else 0), "Command matrix %d, %d" % [phase, index])
	var session: CoreGameSession = CoreGameSession.new("caller-identity")
	var original: Dictionary[String, Variant] = session.snapshot()
	_check(original["id"] == "caller-identity" and original["phase"] == CoreGameSession.Phase.PREPARING, "Initial snapshot")
	original["id"] = "changed"
	_check(session.id == "caller-identity", "Snapshot cannot modify identity")
	_active = session
	session.changed.connect(_observe)
	_check(session.start(), "Start notifies")
	_check(_observations == [0, 1], "Notification includes both phases")
	_check(original["phase"] == CoreGameSession.Phase.PREPARING, "Historical snapshot remains unchanged")
	_check(CoreGameSession.new("other").phase == CoreGameSession.Phase.PREPARING, "Independent instance")
	_check(not session.resume(_count_adapter) and _adapters == 0, "Invalid operation skips adapter")
	_check(session.pause(_count_adapter) and _adapters == 1, "Successful adapter")
	_check(not session.resume(_fail_adapter) and session.phase == CoreGameSession.Phase.PAUSED, "Adapter error preserves phase")
	_check(session.resume(), "Adapter error clears protection")
	var owner: Node = Node.new()
	var expired: Callable = Callable(owner, "get_tree")
	owner.free()
	_check(not session.pause(expired) and session.phase == CoreGameSession.Phase.RUNNING, "Expired adapter cannot commit")
	_check(not session.pause(func() -> String: return "invalid"), "Invalid adapter result rejected")
	_check(session.pause(), "Invalid adapter clears protection")
	var invalid: CoreGameSession = CoreGameSession.new("")
	_check(not invalid.start() and not invalid.close(), "Invalid identity cannot operate")
	session.changed.disconnect(_observe)
	_check_time_adapter()
	var count: CoreSessionExampleModel = CoreSessionExampleModel.new()
	_check(not count.progress() and count.points == 0, "Preparing rejects progression")
	count.session.start()
	count.progress()
	count.session.pause()
	_check(not count.progress() and count.points == 1, "Paused count rejects progression")
	count.session.resume()
	count.progress()
	count.progress()
	_check(count.session.phase == CoreGameSession.Phase.ENDED and count.points == 3 and not count.progress(), "Count rule ends independently")
	var old: CoreGameSession = count.session
	_check(count.new_run(true) and old.phase == CoreGameSession.Phase.CLOSED and count.session.id != old.id, "New run permanently closes old instance")
	_check(not old.start() and not old.resume(), "Old instance cannot reactivate")
	count.session.start()
	count.advance(1.0)
	count.session.pause()
	count.advance(100.0)
	_check(count.elapsed == 1.0 and count.points == 0, "Timed rule stops while paused")
	count.session.resume()
	count.advance(2.0)
	_check(count.elapsed == 3.0 and count.session.phase == CoreGameSession.Phase.ENDED, "Same lifecycle supports timed end")
	var nested_count: CoreSessionExampleModel = CoreSessionExampleModel.new()
	var count_observer: Callable = func(_previous: int, current: int) -> void:
		if current == CoreGameSession.Phase.RUNNING:
			for index: int in range(3): nested_count.progress()
	nested_count.session.changed.connect(count_observer)
	nested_count.session.start()
	_check(nested_count.points == 3 and nested_count.session.phase == CoreGameSession.Phase.RUNNING, "Example end waits for notification to finish")
	nested_count.session.changed.disconnect(count_observer)
	nested_count.progress()
	_check(nested_count.points == 3 and nested_count.session.phase == CoreGameSession.Phase.ENDED, "Count completion retries without exceeding target")
	var nested_timer: CoreSessionExampleModel = CoreSessionExampleModel.new("timer", true)
	var timer_observer: Callable = func(_previous: int, current: int) -> void:
		if current == CoreGameSession.Phase.RUNNING: nested_timer.advance(3.0)
	nested_timer.session.changed.connect(timer_observer)
	nested_timer.session.start()
	_check(nested_timer.elapsed == 3.0 and nested_timer.session.phase == CoreGameSession.Phase.RUNNING, "Timer completion respects protection")
	nested_timer.session.changed.disconnect(timer_observer)
	nested_timer.advance(0.0)
	_check(nested_timer.session.phase == CoreGameSession.Phase.ENDED, "Completed timer retries lifecycle end")
	_active = null
	if not _failed:
		print("PASS: %d independent session checks" % _checks)
	quit(1 if _failed else 0)

func _at_phase(phase: int) -> CoreGameSession:
	var session: CoreGameSession = CoreGameSession.new("matrix")
	if phase in [1, 2, 3]: session.start()
	if phase == 2: session.pause()
	if phase == 3: session.end()
	if phase == 4: session.close()
	return session

func _observe(previous: int, current: int) -> void:
	_observations.append(previous)
	_observations.append(current)
	_check(_active.phase == current, "Commit precedes notification")
	_check(not _active.start() and not _active.pause() and not _active.resume() and not _active.end() and not _active.close(), "Notification blocks all lifecycle reentry")

func _count_adapter() -> Error:
	_adapters += 1
	_check(_active.phase == CoreGameSession.Phase.RUNNING and not _active.end() and not _active.close(), "Adapter precedes commit and rejects reentry")
	return OK

func _fail_adapter() -> Error:
	return ERR_UNAVAILABLE

func _read() -> CoreTimeSettings:
	return _backend

func _write(settings: CoreTimeSettings) -> Error:
	if _write_fails: return ERR_UNAVAILABLE
	_backend = settings.copy()
	return OK

func _check_time_adapter() -> void:
	var time: CoreTime = CoreTime.new(_read, _write)
	var scope: CoreTimeScope = time.acquire()
	var session: CoreGameSession = _at_phase(1)
	_write_fails = true
	_check(not session.pause(scope.set_paused.bind(true)) and session.phase == CoreGameSession.Phase.RUNNING
		and not _backend.paused and not scope.current.paused, "Failed world pause preserves both states")
	_write_fails = false
	_check(session.pause(scope.set_paused.bind(true)) and _backend.paused, "Pause commits after world adapter")
	_write_fails = true
	_check(not session.resume(scope.set_paused.bind(false)) and session.phase == CoreGameSession.Phase.PAUSED
		and _backend.paused and scope.current.paused, "Failed world resume preserves both states")
	_write_fails = false
	_check(session.resume(scope.set_paused.bind(false)) and not _backend.paused, "Resume may retry")
	scope.dispose()
	time.dispose()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
