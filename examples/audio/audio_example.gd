class_name AudioExample
extends Node

const Config: GDScript = preload("../../source/config_system/config_manager.gd")
@onready var _music: CoreMusic = $CoreMusic
@onready var _audio: CoreAudio = $CoreAudio
@onready var _status: Label = $Panel/Rows/Status
var _mix: CoreAudioBusScope
var _config: Config
var _tone: AudioStreamWAV

func _ready() -> void:
	_mix = CoreAudioBusScope.new(["Master"])
	_config = Config.new("user://core_audio_example.cfg")
	add_child(_config)
	_tone = make_tone()
	$Panel/Rows/Play.pressed.connect(func() -> void: _report(_music.play(_tone, "Master", 0.1)))
	$Panel/Rows/Stop.pressed.connect(func() -> void: _report(_music.stop(0.1)))
	$Panel/Rows/Sound.pressed.connect(func() -> void: _status.text = "Sound accepted: %s" % _audio.play(_tone))
	$Panel/Rows/Volume.value_changed.connect(func(value: float) -> void: _report(_mix.set_volume("Master", value)))
	$Panel/Rows/Save.pressed.connect(func() -> void: _report(CoreAudioPreferences.save(_config, _mix)))
	$Panel/Rows/Restore.pressed.connect(_restore)

func _restore() -> void:
	var error: Error = CoreAudioPreferences.restore(_config, _mix)
	_report(error)
	if error == OK:
		$Panel/Rows/Volume.set_value_no_signal(_mix.get_volume("Master"))

func _exit_tree() -> void:
	if _mix != null:
		_mix.close()

func _report(error: Error) -> void:
	_status.text = error_string(error)

static func make_tone() -> AudioStreamWAV:
	var tone: AudioStreamWAV = AudioStreamWAV.new()
	tone.format = AudioStreamWAV.FORMAT_16_BITS
	tone.mix_rate = 8000
	var data: PackedByteArray = PackedByteArray()
	data.resize(8000)
	for sample: int in range(4000):
		data.encode_s16(sample * 2, int(sin(float(sample) * TAU * 220.0 / 8000.0) * 1800.0))
	tone.data = data
	return tone
