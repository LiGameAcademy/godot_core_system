extends Control

## Explicit local operations; no global time scope or automatic saving.
var model: CoreSessionExampleModel = CoreSessionExampleModel.new()
@onready var _status: Label = $Layout/Status

func _ready() -> void:
	model.session.changed.connect(_on_changed)
	$Layout/Start.pressed.connect(_start)
	$Layout/Pause.pressed.connect(_pause)
	$Layout/Resume.pressed.connect(_resume)
	$Layout/Progress.pressed.connect(_progress)
	$Layout/Step.pressed.connect(_step)
	$Layout/End.pressed.connect(_end)
	$Layout/Close.pressed.connect(_close)
	$Layout/CountRun.pressed.connect(_new_count_run)
	$Layout/TimedRun.pressed.connect(_new_timed_run)
	_refresh()

func _exit_tree() -> void:
	model.session.changed.disconnect(_on_changed)
	model.session.close()

func _start() -> void:
	model.session.start()
func _pause() -> void:
	model.session.pause()
func _resume() -> void:
	model.session.resume()
func _end() -> void:
	model.session.end()
func _close() -> void:
	model.session.close()
func _progress() -> void:
	model.progress()
	_refresh()
func _step() -> void:
	model.advance(1.0)
	_refresh()
func _new_count_run() -> void:
	_new_run(false)
func _new_timed_run() -> void:
	_new_run(true)
func _new_run(timed: bool) -> void:
	var previous: CoreGameSession = model.session
	previous.changed.disconnect(_on_changed)
	model.new_run(timed)
	model.session.changed.connect(_on_changed)
	_refresh()
func _on_changed(_previous: CoreGameSession.Phase, _current: CoreGameSession.Phase) -> void:
	_refresh()
func _refresh() -> void:
	_status.text = "Run: %s | Phase: %s\nRule: %s | Points: %d / 3 | Local time: %.1f / 3.0" % [
		model.session.id, CoreGameSession.Phase.keys()[model.session.phase],
		"Timer" if model.timed else "Count", model.points, model.elapsed]
