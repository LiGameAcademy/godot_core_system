extends Control

## Presentation consumes a local model without an AutoLoad or game assets.
var model: CoreTagExampleModel = CoreTagExampleModel.new()
@onready var _status: Label = $Layout/Status

func _ready() -> void:
	model.tags.tag_added.connect(_on_tag_changed)
	model.tags.tag_removed.connect(_on_tag_changed)
	$Layout/Stun.pressed.connect(func() -> void: _toggle("state.stunned"))
	$Layout/Shield.pressed.connect(func() -> void: _toggle("effect.shield"))
	$Layout/Act.pressed.connect(_act)
	$Layout/Reset.pressed.connect(_reset)
	_refresh()

func _exit_tree() -> void:
	model.tags.tag_added.disconnect(_on_tag_changed)
	model.tags.tag_removed.disconnect(_on_tag_changed)

func _toggle(path: String) -> void:
	if model.tags.has(path):
		model.tags.remove(path)
	else:
		model.tags.add(path)

func _act() -> void:
	model.try_act()
	_refresh()

func _reset() -> void:
	model.reset()
	_refresh()

func _on_tag_changed(_path: String) -> void:
	_refresh()

func _refresh() -> void:
	_status.text = "Explicit tags: " + ", ".join(model.tags.snapshot())
	_status.text += "\nCan act: %s | Actions completed: %d" % [model.can_act, model.actions_completed]
	_status.text += "\nStun blocks the rule; shield only marks an independent effect."
