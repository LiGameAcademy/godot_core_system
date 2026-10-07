extends Control

## Presentation reads the local rule model; no global manager is needed.
var model: CoreTriggerExampleModel = CoreTriggerExampleModel.new()
@onready var _status: Label = $Layout/Status

func _ready() -> void:
	model.tags.tag_added.connect(_on_tag_changed)
	model.tags.tag_removed.connect(_on_tag_changed)
	$Layout/Ready.pressed.connect(_toggle_ready)
	$Layout/Fire.pressed.connect(_fire)
	$Layout/Enabled.pressed.connect(_toggle_enabled)
	$Layout/Reset.pressed.connect(_reset)
	_refresh()

func _exit_tree() -> void:
	model.tags.tag_added.disconnect(_on_tag_changed)
	model.tags.tag_removed.disconnect(_on_tag_changed)

func _toggle_ready() -> void:
	model.toggle_ready()

func _fire() -> void:
	model.try_fire()
	_refresh()

func _toggle_enabled() -> void:
	model.trigger.enabled = not model.trigger.enabled
	_refresh()

func _reset() -> void:
	model.trigger.reset()
	_refresh()

func _on_tag_changed(_path: String) -> void:
	_refresh()

func _refresh() -> void:
	_status.text = "Ready: %s | Enabled: %s\nCommitted triggers: %d / %d\nLast result: %s" % [
		model.tags.has("state.ready"), model.trigger.enabled, model.trigger.count,
		model.trigger.max_triggers, CoreTrigger.Result.keys()[model.last_result]]
