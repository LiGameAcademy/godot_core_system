class_name CoreMusic
extends Node

var _players: Array[AudioStreamPlayer] = []
var _current: int = -1
var _starts: Array[float] = [0.0, 0.0]
var _elapsed: float = 0.0
var _duration: float = 0.0
var _target_db: float = 0.0
var _last_tick: int = 0
var is_playing: bool:
	get:
		return not _players.is_empty() and (_players[0].playing or _players[1].playing)
var is_transitioning: bool:
	get:
		return _duration > 0.0
var current_stream: AudioStream:
	get:
		return _players[_current].stream if _current >= 0 else null

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	for index: int in range(2):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	set_process(false)

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	_elapsed += float(now - _last_tick) / 1000000.0
	_last_tick = now
	var weight: float = clampf(_elapsed / _duration, 0.0, 1.0)
	for index: int in range(2):
		var player: AudioStreamPlayer = _players[index]
		if not player.playing:
			continue
		var start: float = _starts[index]
		var end: float = _target_db if index == _current else -80.0
		player.volume_db = lerpf(start, end, weight)
	if weight < 1.0:
		return
	for index: int in range(2):
		if index != _current:
			_release(_players[index])
	_duration = 0.0
	set_process(false)

func _exit_tree() -> void:
	stop_all()

func play(stream: AudioStream, bus: String = "Master", fade_seconds: float = 0.5, loop: bool = true, volume_db: float = 0.0) -> Error:
	if not is_inside_tree() or not is_node_ready():
		return ERR_UNAVAILABLE
	if not is_instance_valid(stream) or not is_finite(fade_seconds) or fade_seconds < 0.0 or not is_finite(volume_db):
		return ERR_INVALID_PARAMETER
	if AudioServer.get_bus_index(bus) < 0:
		return ERR_DOES_NOT_EXIST
	var copy: AudioStream = stream.duplicate(true) as AudioStream
	if copy is AudioStreamWAV:
		var wav: AudioStreamWAV = copy as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif copy is AudioStreamOggVorbis or copy is AudioStreamMP3 or copy is AudioStreamPlaylist:
		copy.set("loop", loop)
	else:
		return ERR_UNAVAILABLE
	for index: int in range(2):
		_starts[index] = _players[index].volume_db
	var next: int = 0 if _current < 0 else 1 - _current
	_release(_players[next])
	_current = next
	var player: AudioStreamPlayer = _players[next]
	player.stream = copy
	player.bus = bus
	player.volume_db = -80.0 if fade_seconds > 0.0 else volume_db
	_starts[next] = player.volume_db
	player.play()
	_elapsed = 0.0
	_duration = fade_seconds
	_target_db = volume_db
	_last_tick = Time.get_ticks_usec()
	if fade_seconds == 0.0:
		_release(_players[1 - next])
	set_process(fade_seconds > 0.0)
	return OK

func stop(fade_seconds: float = 0.0) -> Error:
	if not is_finite(fade_seconds) or fade_seconds < 0.0:
		return ERR_INVALID_PARAMETER
	if not is_inside_tree() or not is_node_ready():
		return ERR_UNAVAILABLE
	if fade_seconds == 0.0:
		stop_all()
		return OK
	for index: int in range(2):
		_starts[index] = _players[index].volume_db
	_current = -1
	_elapsed = 0.0
	_duration = fade_seconds
	_last_tick = Time.get_ticks_usec()
	set_process(true)
	return OK

func stop_all() -> void:
	for player: AudioStreamPlayer in _players:
		_release(player)
	_current = -1
	_duration = 0.0
	set_process(false)

static func _release(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null
