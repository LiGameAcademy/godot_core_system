extends Node

const Config: GDScript = preload('../source/config_system/config_manager.gd')

const Manager: GDScript = preload("../source/audio_system/audio_manager.gd")
var _checks: int = 0
var _failed: bool = false

func _ready() -> void:
	var buses: Array[String] = ["Music", "SFX", "Voice", "Ambient", "music"]
	for bus: String in buses:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, bus)
	var scope: CoreAudioBusScope = CoreAudioBusScope.new(buses)
	var manager: Manager = Manager.new()
	manager.configure_mix(scope)
	add_child(manager)
	var path: String = "user://legacy_audio_%d.tres" % Time.get_ticks_usec()
	var tone: AudioStreamWAV = AudioExample.make_tone()
	ResourceSaver.save(tone, path)
	_check(manager.set_volume(Manager.AudioType.SOUND_EFFECT, 0.5), "SFX volume accepted")
	var sound: AudioStreamPlayer = manager.play_sound(path)
	_check(sound != null and sound.volume_db == 0.0 and is_equal_approx(scope.get_volume("SFX"), 0.5), "Legacy SFX gain once")
	manager.set_volume(Manager.AudioType.VOICE, 0.5)
	var voice: AudioStreamPlayer = manager.play_voice(path, 0.5)
	_check(voice != null and is_equal_approx(db_to_linear(voice.volume_db) * scope.get_volume("Voice"), 0.25), "Voice category and per-play gains independent")
	_check(manager.play_ambient(path) != null, "Ambient category supported")
	manager.set_volume(Manager.AudioType.MUSIC, 0.5)
	_check(manager.play_music(path, 0.0, false) == OK, "Legacy music uses explicit bus")
	_check(manager.play_music("res://missing.ogg") == ERR_CANT_OPEN, "Missing path result")
	var config: Config = Config.new("user://collision.cfg")
	_check(CoreAudioPreferences.save(config, scope) == ERR_INVALID_PARAMETER, "Colliding preference keys rejected")
	config.free()
	manager.queue_free()
	await get_tree().process_frame
	scope.close()
	DirAccess.remove_absolute(path)
	for bus: String in buses:
		AudioServer.remove_bus(AudioServer.get_bus_index(bus))
	var deadline: int = Time.get_ticks_usec() + 150000
	while Time.get_ticks_usec() < deadline:
		await get_tree().process_frame
	print("Legacy audio checks: %d; failed: %s" % [_checks, _failed])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
