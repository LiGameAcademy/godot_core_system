extends SceneTree

var _checks: int = 0
var _failed: bool = false
var _backend: CoreTimeSettings = CoreTimeSettings.new(true, 1.5)
var _write_fails: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _read() -> CoreTimeSettings:
	return _backend

func _write(settings: CoreTimeSettings) -> Error:
	if _write_fails:
		return ERR_UNAVAILABLE
	_backend = settings.copy()
	return OK

func _run() -> void:
	var time: CoreTime = CoreTime.new(_read, _write)
	var scope: CoreTimeScope = time.acquire()
	_check(scope != null and scope.current.paused and scope.current.speed == 1.5, "Capture existing settings")
	_check(time.acquire() == null and time.last_error == ERR_BUSY, "Reject a second owner")
	_check(time.apply(scope, null) == ERR_INVALID_PARAMETER, "Reject null settings without a script error")
	_check(scope.set_paused(false) == OK and scope.set_speed(2.0) == OK, "Apply settings")
	_check(not _backend.paused and _backend.speed == 2.0, "Pause and speed are applied together")
	for speed: float in [0.0, -1.0, NAN, INF]:
		_check(scope.set_speed(speed) == ERR_INVALID_PARAMETER, "Reject invalid speed")
	_check(scope.current.speed == 2.0 and _backend.speed == 2.0, "Invalid speed does not commit")
	var exposed: CoreTimeSettings = scope.current
	exposed.speed = 9.0
	exposed.paused = true
	_check(scope.current.speed == 2.0 and not scope.current.paused, "Public snapshots cannot mutate internal settings")
	_write_fails = true
	_check(scope.set_speed(3.0) == ERR_UNAVAILABLE and scope.current.speed == 2.0, "Backend failure does not commit")
	_check(scope.dispose() == ERR_UNAVAILABLE, "Failed restoration is observable")
	_check(time.acquire() == null and time.last_error == ERR_BUSY, "Failed restoration retains ownership")
	_check(time.dispose() == ERR_UNAVAILABLE, "Service disposal propagates restoration failure")
	_write_fails = false
	_check(scope.dispose() == OK and scope.dispose() == OK, "Restoration may be retried and disposal is idempotent")
	_check(_backend.paused and _backend.speed == 1.5, "Restore the acquired snapshot")
	_check(scope.set_paused(false) == ERR_UNAVAILABLE, "Released scope rejects mutation")
	var second: CoreTimeScope = time.acquire()
	_check(second != null and second.set_speed(3.0) == OK, "Acquire a fresh owner")
	_check(scope.dispose() == OK and _backend.speed == 3.0, "Stale disposal cannot release the next owner")
	_check(time.dispose() == OK and _backend.paused and _backend.speed == 1.5, "Service disposal restores its active owner")
	_check(second.set_speed(2.0) == ERR_UNAVAILABLE, "Service disposal invalidates the old scope")
	_check(time.acquire() == null and time.last_error == ERR_UNAVAILABLE and time.dispose() == OK, "Disposed service stays unavailable")
	var unavailable: CoreTime = CoreTime.new(Callable(), _write)
	_check(unavailable.acquire() == null and unavailable.last_error == ERR_UNAVAILABLE, "Reject invalid read callback")
	unavailable.dispose()
	unavailable = CoreTime.new(_read, Callable())
	_check(unavailable.acquire() == null and unavailable.last_error == ERR_UNAVAILABLE, "Reject invalid write callback")
	unavailable.dispose()
	var invalid: CoreTime = CoreTime.new(func() -> CoreTimeSettings: return CoreTimeSettings.new(false, 0.0), _write)
	_check(invalid.acquire() == null and invalid.last_error == ERR_INVALID_PARAMETER, "Validate the acquired baseline")
	invalid.dispose()
	invalid = CoreTime.new(func() -> int: return 42, _write)
	_check(invalid.acquire() == null and invalid.last_error == ERR_INVALID_DATA, "Reject an untyped invalid read result")
	invalid.dispose()
	invalid = CoreTime.new(_read, func(_settings: CoreTimeSettings) -> Variant: return null)
	var bad_scope: CoreTimeScope = invalid.acquire()
	_check(bad_scope.set_speed(2.0) == ERR_INVALID_DATA and bad_scope.current.speed == 1.5, "Write callbacks must return an Error result")
	# The malformed backend cannot restore; explicitly sever test-only ownership.
	invalid = null
	_check(bad_scope.set_paused(false) == ERR_UNAVAILABLE, "A scope does not retain a destroyed service")
	bad_scope.dispose()
	invalid = CoreTime.new(_read, func(_settings: CoreTimeSettings) -> int: return 99)
	bad_scope = invalid.acquire()
	_check(bad_scope.set_speed(2.0) == ERR_INVALID_DATA, "Reject integer results outside the Error enum")
	invalid = null
	bad_scope.dispose()
	await _engine_checks()
	if not _failed:
		print("PASS: %d independent and engine time-scope checks" % _checks)
	quit(1 if _failed else 0)

func _engine_checks() -> void:
	var original_pause: bool = paused
	var original_speed: float = Engine.time_scale
	paused = true
	Engine.time_scale = 1.5
	var time: CoreTime = CoreTime.for_scene_tree(self)
	var scope: CoreTimeScope = time.acquire()
	_check(scope != null and scope.current.paused and scope.current.speed == 1.5, "Engine adapter captures real settings")
	_check(scope.set_paused(false) == OK and scope.set_speed(2.0) == OK and not paused and Engine.time_scale == 2.0, "Engine adapter updates real settings")
	_check(scope.dispose() == OK and paused and Engine.time_scale == 1.5, "Engine adapter restores real settings")
	time.dispose()
	paused = false
	Engine.time_scale = 1.25
	var packed: PackedScene = load("res://addons/godot_core_system/examples/time_scope/time_scope_example.tscn")
	var example: Control = packed.instantiate() as Control
	root.add_child(example)
	example.get_node("Layout/Pause").emit_signal("pressed")
	example.get_node("Layout/Speed").emit_signal("pressed")
	_check(paused and Engine.time_scale == 1.0, "Actual buttons update pause and speed")
	example.get_node("Layout/Release").emit_signal("pressed")
	_check(not paused and Engine.time_scale == 1.25, "Actual release button restores the snapshot")
	example.get_node("Layout/Release").emit_signal("pressed")
	example.get_node("Layout/Speed").emit_signal("pressed")
	_check(Engine.time_scale == 1.0, "Example can acquire again")
	root.remove_child(example)
	example.free()
	_check(not paused and Engine.time_scale == 1.25, "Scene exit restores its owned time")
	paused = original_pause
	Engine.time_scale = original_speed
	await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
