extends Node

## Compatibility facade. Playback has no implicit configuration/logger dependency.
enum AudioType { MUSIC, SOUND_EFFECT, VOICE, AMBIENT }
const MASTER_VOLUME_KEY: String = "master_volume"
const MUSIC_VOLUME_KEY: String = "music_volume"
const SFX_VOLUME_KEY: String = "sfx_volume"
const VOICE_VOLUME_KEY: String = "voice_volume"
const AMBIENT_VOLUME_KEY: String = "ambient_volume"
const DEFAULT_BUSES: Dictionary[int, String] = {
	AudioType.MUSIC: "Music", AudioType.SOUND_EFFECT: "SFX", AudioType.VOICE: "Voice", AudioType.AMBIENT: "Ambient"
}
var _audio: CoreAudio
var _music: CoreMusic
var _mix: CoreAudioBusScope
var _cache: Dictionary[String, AudioStream] = {}
var audio_node_root: Node:
	get:
		return self

func _ready() -> void:
	_audio = CoreAudio.new()
	_audio.max_voices = 32
	add_child(_audio)
	_music = CoreMusic.new()
	add_child(_music)

func _exit_tree() -> void:
	stop_all()
	_cache.clear()

## The caller owns and closes this scope; the facade only borrows it.
func configure_mix(scope: CoreAudioBusScope) -> void:
	_mix = scope

func preload_audio(path: String, _type: AudioType) -> void:
	_get_audio_resource(path)

func play_music(path: String, fade_duration: float = 1.0, loop: bool = true) -> Error:
	var stream: AudioStream = _get_audio_resource(path)
	return _music.play(stream, "Music", fade_duration, loop) if stream != null and _music != null else ERR_CANT_OPEN

func play_sound(path: String, volume: float = 1.0) -> AudioStreamPlayer:
	return _play(path, AudioType.SOUND_EFFECT, volume)

func play_voice(path: String, volume: float = 1.0) -> AudioStreamPlayer:
	return _play(path, AudioType.VOICE, volume)

func play_ambient(path: String, volume: float = 1.0) -> AudioStreamPlayer:
	return _play(path, AudioType.AMBIENT, volume)

func set_master_volume(volume: float) -> bool:
	return _mix != null and _mix.set_volume("Master", volume) == OK

func set_volume(type: AudioType, volume: float) -> bool:
	return _mix != null and DEFAULT_BUSES.has(type) and _mix.set_volume(DEFAULT_BUSES[type], volume) == OK

func get_volume(type: AudioType) -> float:
	return _mix.get_volume(DEFAULT_BUSES[type]) if _mix != null and DEFAULT_BUSES.has(type) else -1.0

func get_master_volume() -> float:
	return _mix.get_volume("Master") if _mix != null else -1.0

func stop_all() -> void:
	if is_instance_valid(_audio):
		_audio.stop_all()
	if is_instance_valid(_music):
		_music.stop_all()

func get_audio_type_from_bus_name(bus: String) -> AudioType:
	for type: int in DEFAULT_BUSES:
		if DEFAULT_BUSES[type] == bus:
			return type as AudioType
	push_error("Unknown audio category bus: %s" % bus)
	return AudioType.SOUND_EFFECT

func _play(path: String, type: AudioType, volume: float) -> AudioStreamPlayer:
	if not is_finite(volume) or volume < 0.0 or volume > 1.0:
		return null
	var stream: AudioStream = _get_audio_resource(path)
	if stream == null or _audio == null:
		return null
	# Category gain is applied exactly once by the bus, never by the player.
	return _audio.play_voice(stream, DEFAULT_BUSES[type], -80.0 if volume == 0.0 else linear_to_db(volume))

func _get_audio_resource(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path) as AudioStream
	if stream != null:
		_cache[path] = stream
	return stream
