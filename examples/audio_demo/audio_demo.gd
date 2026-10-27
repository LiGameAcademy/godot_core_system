extends Node2D

const Manager: GDScript = preload("../../source/audio_system/audio_manager.gd")
const BUSES: Array[String] = ["Master", "Music", "SFX", "Voice", "Ambient"]
const MUSIC: String = "res://addons/godot_core_system/examples/audio_demo/assets/music/bgm.ogg"
const SOUND: String = "res://addons/godot_core_system/examples/audio_demo/assets/sfx/click.ogg"
const VOICE: String = "res://addons/godot_core_system/examples/audio_demo/assets/voice/congratulations.ogg"
var _manager: Manager
var _mix: CoreAudioBusScope
var _created: Array[String] = []

func _ready() -> void:
	# Only this standalone demo creates missing buses; the plugin never changes layouts.
	for bus: String in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, bus)
			_created.append(bus)
	_mix = CoreAudioBusScope.new(BUSES)
	if _mix.is_closed:
		push_error("Audio demo requires exclusive bus ownership.")
		return
	_manager = Manager.new()
	_manager.configure_mix(_mix)
	add_child(_manager)
	_manager.preload_audio(MUSIC, Manager.AudioType.MUSIC)
	_manager.play_music(MUSIC, 1.0)
	print("Audio demo: Space replaces music, S plays sound, V plays voice, M toggles music volume, Escape stops.")

func _exit_tree() -> void:
	if _manager != null:
		_manager.stop_all()
	if _mix != null:
		_mix.close()
	for bus: String in _created:
		var index: int = AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.remove_bus(index)

func _input(event: InputEvent) -> void:
	if _manager == null or not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	match (event as InputEventKey).keycode:
		KEY_SPACE:
			_manager.play_music(MUSIC, 1.0)
		KEY_S:
			_manager.play_sound(SOUND)
		KEY_V:
			_manager.play_voice(VOICE)
		KEY_M:
			_manager.set_volume(Manager.AudioType.MUSIC, 0.5 if _manager.get_volume(Manager.AudioType.MUSIC) > 0.5 else 1.0)
		KEY_ESCAPE:
			_manager.stop_all()
