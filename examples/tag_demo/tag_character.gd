extends Node2D
class_name CoreTagCharacter

signal tags_changed
signal attack_finished

@export var category: String = "character"
@export var display_name: String = "Character"
@export var base_color: Color = Color(0.2, 0.6, 1.0)
@export var attack_duration: float = 2.0
var model: CoreTagCharacterModel
@onready var _visual: ColorRect = $ColorRect
@onready var _label: Label = $Label

func _ready() -> void:
	model = CoreTagCharacterModel.new(category)
	model.tags.tag_added.connect(_on_tag_changed)
	model.tags.tag_removed.connect(_on_tag_changed)
	_label.text = display_name
	_refresh_visual()

func _process(delta: float) -> void:
	if model.advance(delta):
		attack_finished.emit()

func _exit_tree() -> void:
	model.tags.tag_added.disconnect(_on_tag_changed)
	model.tags.tag_removed.disconnect(_on_tag_changed)

func toggle_move() -> bool:
	return model.toggle_move()

func try_attack() -> bool:
	return model.begin_attack(attack_duration)

func add_tag(path: String) -> bool:
	return model.tags.add(path)

func remove_tag(path: String) -> bool:
	return model.tags.remove(path)

func has_tag(path: String, exact: bool = true) -> bool:
	return model.tags.has(path, exact)

func get_tags() -> Array[String]:
	return model.tags.snapshot()

func _on_tag_changed(_path: String) -> void:
	_refresh_visual()
	tags_changed.emit()

func _refresh_visual() -> void:
	_visual.color = Color.RED if model.tags.has("state.attacking") else (
		Color.GREEN if model.tags.has("state.moving") else base_color)