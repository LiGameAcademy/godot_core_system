extends Node2D

## Parent coordinates child APIs; children own their rules and visual state.
const BUFFS: Array[String] = ["buff.speed_up", "buff.attack_up"]
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var _status: Label = $UI/StatusLabel
@onready var _buffs: Label = $UI/BuffLabel
@onready var _player: CoreTagCharacter = $Player
@onready var _enemy: CoreTagCharacter = $Enemy

func _ready() -> void:
	_random.randomize()
	_player.tags_changed.connect(_refresh_buffs)
	_player.attack_finished.connect(_on_attack_finished)
	_refresh_buffs()

func _on_player_move_button_pressed() -> void:
	var moving: bool = _player.toggle_move()
	_status.text = "Player started moving" if moving else "Player stopped moving"

func _on_player_attack_button_pressed() -> void:
	if _player.try_attack():
		_status.text = "Player is attacking!"

func _on_buff_button_pressed() -> void:
	var path: String = BUFFS[_random.randi_range(0, BUFFS.size() - 1)]
	if _player.has_tag(path):
		_player.remove_tag(path)
		_status.text = "Removed buff: " + path
	else:
		_player.add_tag(path)
		_status.text = "Added buff: " + path

func _on_query_button_pressed() -> void:
	_status.text = "Player tags: %s\nEnemy tags: %s" % [_player.get_tags(), _enemy.get_tags()]

func _on_attack_finished() -> void:
	_status.text = "Player finished attacking"

func _refresh_buffs() -> void:
	var active: Array[String] = []
	for path: String in BUFFS:
		if _player.has_tag(path):
			active.append(path)
	_buffs.text = "Active Buffs: " + (", ".join(active) if not active.is_empty() else "None")