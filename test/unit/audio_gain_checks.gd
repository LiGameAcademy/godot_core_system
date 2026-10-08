extends Node

const AUDIO_PATH: String = "res://addons/godot_core_system/examples/audio_demo/assets/sfx/click.ogg"
var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	var audio: CoreSystem.AudioManager = CoreSystem.audio_manager
	audio.set_master_volume(0.8)
	audio.set_volume(audio.AudioType.SOUND_EFFECT, 0.5)
	var first: AudioStreamPlayer = audio.play_sound(AUDIO_PATH, 0.6)
	_check(is_equal_approx(_gain(first), 0.24), "SFX gain is master x category x per-call volume")
	audio.set_volume(audio.AudioType.SOUND_EFFECT, 0.2)
	var second: AudioStreamPlayer = audio.play_sound(AUDIO_PATH, 0.6)
	_check(is_equal_approx(_gain(first), 0.096) and is_equal_approx(_gain(second), 0.096), "Category adjustment treats old and new SFX equally")
	audio.set_volume(audio.AudioType.VOICE, 0.5)
	var voice: AudioStreamPlayer = audio.play_voice(AUDIO_PATH, 0.3)
	_check(is_equal_approx(_gain(voice), 0.12), "Voice applies category gain once")
	audio.set_volume(audio.AudioType.MUSIC, 0.4)
	audio.play_music(AUDIO_PATH, 0.0, false)
	_check(is_equal_approx(_gain(audio._current_music), 0.32), "Music applies category gain once without fade")
	audio.play_music(AUDIO_PATH, 0.01, false)
	for frame: int in range(20):
		await get_tree().process_frame
	_check(is_equal_approx(_gain(audio._current_music), 0.32), "Music fade-in returns to neutral player gain")
	audio.set_volume(audio.AudioType.MUSIC, 0.2)
	_check(is_equal_approx(_gain(audio._current_music), 0.16), "Music bus changes affect playing music")
	var muted: AudioStreamPlayer = audio.play_sound(AUDIO_PATH, 0.0)
	_check(is_instance_valid(muted) and is_zero_approx(_gain(muted)), "Per-call zero volume is silent")
	audio.stop_all()
	print("%s: %d audio gain checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _gain(player: AudioStreamPlayer) -> float:
	if player == null:
		return -1.0
	var bus_gain: float = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(player.bus)))
	var master_gain: float = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	return db_to_linear(player.volume_db) * bus_gain * master_gain

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
