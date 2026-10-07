extends Control

const ConfigScript: Script = preload("../../source/config_system/config_manager.gd")
@export var config_path: String = "user://core_config_example/settings.cfg"
@onready var _status: Label = $Panel/Status
var _config: Node

func _ready() -> void:
	_config = ConfigScript.new(config_path, _report)
	add_child(_config)
	$Panel/Edit.pressed.connect(edit)
	$Panel/Save.pressed.connect(save)
	$Panel/Reload.pressed.connect(reload)
	$Panel/Reset.pressed.connect(reset)
	_refresh()

func edit() -> void:
	var count: int = int(_config.get_value("example", "count", 0))
	_config.set_value("example", "count", count + 1)
	_refresh()

func save() -> void:
	_config.save_config()
	_refresh()

func reload() -> void:
	_config.load_config()
	_refresh()

func reset() -> void:
	_config.reset_config()
	_refresh()

func _report(message: String) -> void:
	print(message)

func _refresh() -> void:
	_status.text = "Count: %s | modified: %s | IO: %s\n%s" % [
		_config.get_value("example", "count", 0), _config.is_modified(),
		error_string(_config.last_error), config_path]
