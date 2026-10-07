extends Control

## An Always-processing UI owns a scope and explicitly restores time on exit.
var _time: CoreTime
var _scope: CoreTimeScope
@onready var _status: Label = $Layout/Status

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_time = CoreTime.for_scene_tree(get_tree())
	_scope = _time.acquire()
	$Layout/Pause.pressed.connect(_toggle_pause)
	$Layout/Speed.pressed.connect(_toggle_speed)
	$Layout/Release.pressed.connect(_release)
	_refresh()

func _exit_tree() -> void:
	if _time != null:
		var result: Error = _time.dispose()
		if result != OK:
			push_error("Failed to restore engine time: %s" % error_string(result))

func _toggle_pause() -> void:
	if _scope != null:
		_report(_scope.set_paused(not _scope.current.paused))

func _toggle_speed() -> void:
	if _scope != null:
		_report(_scope.set_speed(2.0 if _scope.current.speed == 1.0 else 1.0))

func _release() -> void:
	if _scope != null:
		var result: Error = _scope.dispose()
		if result == OK:
			_scope = null
		_report(result)
	else:
		_scope = _time.acquire()
		_report(_time.last_error)

func _report(result: Error) -> void:
	if result != OK:
		push_error("Time scope operation failed: %s" % error_string(result))
	_refresh()

func _refresh() -> void:
	_status.text = "Owned: %s | Paused: %s | Speed: %.2f" % [_scope != null, get_tree().paused, Engine.time_scale]
	$Layout/Release.text = "Release and restore snapshot" if _scope != null else "Acquire again"
