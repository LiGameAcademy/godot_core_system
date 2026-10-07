class_name CoreAudio
extends Node

@export_range(1, 64) var max_voices: int = 8
var _voices: Array[AudioStreamPlayer] = []
var _active: Array[AudioStreamPlayer] = []
var _capacity: int = 0
var active_voice_count: int:
	get:
		return _active.size()
var voice_count: int:
	get:
		return _voices.size()

func _ready() -> void:
	_capacity = clampi(max_voices, 1, 64)

func _exit_tree() -> void:
	stop_all()
	for voice: AudioStreamPlayer in _voices:
		voice.queue_free()
	_voices.clear()
	_capacity = 0

func play(stream: AudioStream, bus: String = "Master", volume_db: float = 0.0) -> bool:
	return play_voice(stream, bus, volume_db) != null

func play_voice(stream: AudioStream, bus: String = "Master", volume_db: float = 0.0) -> AudioStreamPlayer:
	if not is_instance_valid(stream) or not is_finite(volume_db) or AudioServer.get_bus_index(bus) < 0 or _capacity == 0 or not is_inside_tree() or not can_process():
		return null
	var voice: AudioStreamPlayer = null
	for candidate: AudioStreamPlayer in _voices:
		if not _active.has(candidate):
			voice = candidate
			break
	if voice == null:
		if _voices.size() >= _capacity:
			return null
		voice = AudioStreamPlayer.new()
		voice.finished.connect(_release.bind(voice))
		add_child(voice)
		_voices.append(voice)
	voice.stream = stream
	voice.bus = bus
	voice.volume_db = volume_db
	voice.pitch_scale = 1.0
	_active.append(voice)
	voice.play()
	return voice

func stop_all() -> void:
	for voice: AudioStreamPlayer in _voices:
		_release(voice)
	_active.clear()

func _release(voice: AudioStreamPlayer) -> void:
	voice.stop()
	voice.stream = null
	_active.erase(voice)
