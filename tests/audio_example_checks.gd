extends Node

const Config: GDScript = preload('../source/config_system/config_manager.gd')

var _checks: int = 0
var _failed: bool = false

func _ready() -> void:
	var demo: Node = (load("res://addons/godot_core_system/examples/audio/audio_example.tscn") as PackedScene).instantiate()
	add_child(demo)
	var config: Config = demo.get("_config")
	config.config_path = "user://audio_example_check_%d.cfg" % Time.get_ticks_usec()
	var path: String = config.config_path
	demo.get_node("Panel/Rows/Play").emit_signal("pressed")
	var music: CoreMusic = demo.get_node("CoreMusic")
	_check(music.is_playing, "Play button")
	demo.get_node("Panel/Rows/Volume").set("value", 0.3)
	_check(is_equal_approx((demo.get("_mix") as CoreAudioBusScope).get_volume("Master"), 0.3), "Volume button")
	demo.get_node("Panel/Rows/Save").emit_signal("pressed")
	_check(FileAccess.file_exists(path), "Save button")
	demo.get_node("Panel/Rows/Volume").set("value", 0.8)
	demo.get_node("Panel/Rows/Restore").emit_signal("pressed")
	_check(is_equal_approx((demo.get("_mix") as CoreAudioBusScope).get_volume("Master"), 0.3), "Restore button")
	demo.get_node("Panel/Rows/Sound").emit_signal("pressed")
	_check((demo.get_node("CoreAudio") as CoreAudio).active_voice_count == 1, "Sound button")
	demo.get_node("Panel/Rows/Stop").emit_signal("pressed")
	_check(music.is_transitioning, "Stop button")
	demo.queue_free()
	await get_tree().process_frame
	var deadline: int = Time.get_ticks_usec() + 150000
	while Time.get_ticks_usec() < deadline:
		await get_tree().process_frame
	DirAccess.remove_absolute(path)
	print("Audio example checks: %d; failed: %s" % [_checks, _failed])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
