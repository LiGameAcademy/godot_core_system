extends Node

const Config: GDScript = preload("../source/config_system/config_manager.gd")
var _checks: int = 0
var _failed: bool = false

func _ready() -> void:
	var mix: CoreAudioBusScope = CoreAudioBusScope.new(["Master"])
	var original: float = mix.get_volume("Master")
	var duplicate: CoreAudioBusScope = CoreAudioBusScope.new(["Master"])
	_check(duplicate.is_closed, "Shared bus claim rejected")
	_check(mix.set_volume("Master", NAN) == ERR_INVALID_PARAMETER, "Non-finite volume")
	_check(mix.set_volume("Master", -1.0) == ERR_INVALID_PARAMETER, "Out of range volume")
	_check(mix.set_volume("Missing", 1.0) == ERR_DOES_NOT_EXIST, "Missing bus")
	mix.set_volume("Master", 0.5)
	_check(is_equal_approx(mix.get_volume("Master"), 0.5), "Bus gain")
	var audio: CoreAudio = CoreAudio.new()
	audio.max_voices = 1
	var music: CoreMusic = CoreMusic.new()
	add_child(audio)
	add_child(music)
	var tone: AudioStreamWAV = AudioExample.make_tone()
	var voice: AudioStreamPlayer = audio.play_voice(tone)
	_check(voice.volume_db == 0.0 and is_equal_approx(db_to_linear(voice.volume_db) * mix.get_volume("Master"), 0.5), "Category gain applied once")
	_check(not audio.play(tone) and audio.voice_count == 1, "Bounded voices")
	audio.stop_all()
	_check(audio.active_voice_count == 0 and audio.play(tone), "Stop and reuse voice")
	_check(music.play(tone, "Missing") == ERR_DOES_NOT_EXIST, "Music missing bus")
	_check(music.play(tone, "Master", -1.0) == ERR_INVALID_PARAMETER, "Invalid fade")
	_check(music.play(tone, "Master", 0.0, true) == OK, "Music play")
	_check(music.current_stream != tone and (music.current_stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD and tone.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Loop copy isolation")
	_check(music.play(tone, "Master", 0.0, false) == OK and (music.current_stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "Loop disabled explicitly")
	_check(music.play(tone, "Master", 0.04) == OK and music.play(tone, "Master", 0.04) == OK and music.get_child_count() == 2, "Rapid replacement bounded")
	var previous_speed: float = Engine.time_scale
	var previous_pause: bool = get_tree().paused
	Engine.time_scale = 2.0
	get_tree().paused = true
	await _wait_real_time()
	_check(not music.is_transitioning, "Fade independent of pause/speed")
	music.stop(0.04)
	_check(music.is_playing, "Fade-out keeps voice alive")
	await _wait_real_time()
	_check(not music.is_playing and not music.is_transitioning, "Fade-out stops all voices")
	get_tree().paused = previous_pause
	Engine.time_scale = previous_speed
	var path: String = "user://audio_checks_%d.cfg" % Time.get_ticks_usec()
	var config: Config = Config.new(path, func(_message: String) -> void: pass)
	add_child(config)
	_check(CoreAudioPreferences.save(config, mix) == OK, "Explicit preference save")
	mix.set_volume("Master", 0.8)
	config.load_config()
	_check(CoreAudioPreferences.restore(config, mix) == OK and is_equal_approx(mix.get_volume("Master"), 0.5), "Restore persisted preference")
	config.set_value("audio", "master_volume", "bad")
	_check(CoreAudioPreferences.restore(config, mix) == ERR_INVALID_DATA and is_equal_approx(mix.get_volume("Master"), 0.5), "Invalid preference preserves bus")
	config.config_path = "user://"
	_check(CoreAudioPreferences.save(config, mix) != OK and is_equal_approx(mix.get_volume("Master"), 0.5), "Save failure independent of playback")
	config.queue_free()
	DirAccess.remove_absolute(path)
	mix.close()
	mix.close()
	_check(mix.set_volume("Master", 1.0) == ERR_UNAVAILABLE, "Closed scope")
	var fresh: CoreAudioBusScope = CoreAudioBusScope.new(["Master"])
	_check(is_equal_approx(fresh.get_volume("Master"), original), "Close restores and releases claim")
	music.play(tone, "Master", 0.04)
	music.queue_free()
	audio.queue_free()
	await get_tree().process_frame
	_check(not is_instance_valid(music) and not is_instance_valid(audio), "Owner cleanup during transition")
	fresh.close()
	print("Audio checks: %d; failed: %s" % [_checks, _failed])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)

func _wait_real_time() -> void:
	var deadline: int = Time.get_ticks_usec() + 100000
	while Time.get_ticks_usec() < deadline:
		await get_tree().process_frame
	await get_tree().process_frame
