extends Node

## 音频类型枚举
enum AudioType {
	MUSIC,				## 背景音乐
	SOUND_EFFECT,		## 音效
	VOICE,				## 语音
	AMBIENT,			## 环境音
}
# 配置键名常量 (推荐)
const MASTER_VOLUME_KEY = "master_volume"
const MUSIC_VOLUME_KEY = "music_volume"
const SFX_VOLUME_KEY = "sfx_volume"
const VOICE_VOLUME_KEY = "voice_volume"
const AMBIENT_VOLUME_KEY = "ambient_volume"

# 将类型映射到配置键 (可选，但有助于一致性)
const TYPE_TO_CONFIG_KEY = {
	AudioType.MUSIC: MUSIC_VOLUME_KEY,
	AudioType.SOUND_EFFECT: SFX_VOLUME_KEY,
	AudioType.VOICE: VOICE_VOLUME_KEY,
	AudioType.AMBIENT: AMBIENT_VOLUME_KEY,
}
## 音频通道配置
const DEFAULT_BUSES = {
	AudioType.MUSIC: "Music",			## 背景音乐通道
	AudioType.SOUND_EFFECT: "SFX",		## 音效通道
	AudioType.VOICE: "Voice",			## 语音通道
	AudioType.AMBIENT: "Ambient",		## 环境音通道
}

## 音频节点根节点
var audio_node_root: Node = null

## 音频播放器池
var _audio_players: Dictionary = {}
## 当前播放的音乐
var _current_music: AudioStreamPlayer = null
## 音频资源缓存
var _audio_cache: Dictionary = {}
## 音量设置
var _volumes: Dictionary = {}
## 主音量设置
var _master_volume: float = 1.0

var _config_manager : CoreSystem.ConfigManager = CoreSystem.config_manager
var _logger : CoreSystem.Logger = CoreSystem.logger

func _ready() -> void:
	# 设置默认值
	audio_node_root = self
	_setup_audio_buses()
	
	# 从配置加载主音量 (使用统一定义的 Key)
	_master_volume = _config_manager.get_value("audio", MASTER_VOLUME_KEY, 1.0)
	set_master_volume(_master_volume) # 应用加载的值 (仅应用到AudioServer和内部变量)

	# 从配置加载分类音量 (使用统一定义的 Key)
	for type in AudioType.values():
		var config_key = TYPE_TO_CONFIG_KEY.get(type)
		if config_key:
			_volumes[type] = _config_manager.get_value("audio", config_key, 1.0)
			set_volume(type, _volumes[type]) # 应用加载的值 (仅应用到AudioServer和内部变量)
		_audio_players[type] = []

## 预加载音频资源
## [param path] 音频路径
## [param type] 音频类型
func preload_audio(path: String, type: AudioType) -> void:
	if not _audio_cache.has(path):
		var audio_resource = load(path)
		if audio_resource:
			_audio_cache[path] = {
				"resource": audio_resource,
				"type": type
			}

## 播放音乐
## [param path] 音频路径
## [param fade_duration] 淡出持续时间
## [param loop] 是否循环 如果音频导入时设置为循环播放，则将一直循环，哪怕loop参数设置为false
func play_music(path: String, fade_duration: float = 1.0, loop: bool = true) -> void:
	if _current_music and _current_music.playing:
		_fade_out_music(fade_duration)
	
	# 断开旧音乐的finished信号连接
	if _current_music and _current_music.is_connected("finished", _on_music_finished):
		_current_music.disconnect("finished", _on_music_finished)
	
	var audio_resource = _get_audio_resource(path)
	if audio_resource:
		if not loop and _is_audio_loop(audio_resource):
			push_warning("The audio is imported with loop enabled, and it will always loop regardless of loop parameter!")
		
		_current_music = _get_audio_player(AudioType.MUSIC)
		_current_music.stream = audio_resource
		_current_music.bus = DEFAULT_BUSES[AudioType.MUSIC]
		_current_music.volume_db = linear_to_db(_volumes[AudioType.MUSIC])
		_current_music.play()
		
		# 连接循环信号
		if loop:
			_current_music.connect("finished", _on_music_finished)
		
		if fade_duration > 0:
			_fade_in_music(fade_duration)

## 播放音效
## [param path] 音频路径
## [param volume] 音量
## [return] 音频播放器
func play_sound(path: String, volume: float = 1.0) -> AudioStreamPlayer:
	var audio_resource = _get_audio_resource(path)
	if audio_resource:
		var player = _get_audio_player(AudioType.SOUND_EFFECT)
		player.stream = audio_resource
		player.bus = DEFAULT_BUSES[AudioType.SOUND_EFFECT]
		player.volume_db = linear_to_db(_volumes[AudioType.SOUND_EFFECT] * volume)
		player.play()
		return player
	return null

## 播放语音
## [param path] 音频路径
## [param volume] 音量
## [return] 音频播放器
func play_voice(path: String, volume: float = 1.0) -> AudioStreamPlayer:
	var audio_resource = _get_audio_resource(path)
	if audio_resource:
		var player = _get_audio_player(AudioType.VOICE)
		player.stream = audio_resource
		player.bus = DEFAULT_BUSES[AudioType.VOICE]
		player.volume_db = linear_to_db(_volumes[AudioType.VOICE] * volume)
		player.play()
		return player
	return null

## 设置主音量
## [param volume] 音量
func set_master_volume(volume: float) -> bool:
	var bus_name : String = "Master"
	_master_volume = clamp(volume, 0.0, 1.0)
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(_master_volume))
		return true
	_logger.error("AudioManager: 未找到名为 '%s' 的主音频总线!" % bus_name)
	return false

## 设置音量
## [param type] 音频类型
## [param volume] 音量
func set_volume(type: AudioType, volume: float) -> bool:
	_volumes[type] = clamp(volume, 0.0, 1.0)
	var bus_name : String = DEFAULT_BUSES[type]
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(_volumes[type]))
		return true
	_logger.error("AudioManager: 未找到名为 '%s' 的音频总线!" % bus_name)
	return false

## 获取音量
## [param type] 音频类型
## [return] 音量
func get_volume(type: AudioType) -> float:
	return _volumes[type]

## 获取主音量
## [return] 主音量
func get_master_volume() -> float:
	return _master_volume

## 停止所有音频
func stop_all() -> void:
	if _current_music:
		_current_music.stop()
	
	for type in _audio_players:
		for player in _audio_players[type]:
			player.stop()

## 根据总线名称获取音频类型
## [param bus_name] 音频总线名称 (例如 "Music", "SFX")
## [return] AudioType 枚举值，如果找不到则返回 null
func get_audio_type_from_bus_name(bus_name: String) -> AudioType:
	for type in DEFAULT_BUSES:
		if DEFAULT_BUSES[type] == bus_name:
			return type
	_logger.error("AudioManager: 未找到名为 '%s' 的音频总线!" % bus_name)
	return AudioType.SOUND_EFFECT

## 获取音频资源
## [param path] 音频路径
## [return] 音频资源
func _get_audio_resource(path: String) -> AudioStream:
	if _audio_cache.has(path):
		return _audio_cache[path].resource
	
	var audio_resource = load(path)
	if audio_resource:
		_audio_cache[path] = {
			"resource": audio_resource,
			"type": AudioType.SOUND_EFFECT
		}
		return audio_resource
	return null

## 获取音频播放器
## [param type] 音频类型
## [return] 音频播放器
func _get_audio_player(type: AudioType) -> AudioStreamPlayer:
	# 查找空闲的播放器
	for player in _audio_players[type]:
		if not player.playing:
			return player
	
	# 创建新的播放器
	var new_player = AudioStreamPlayer.new()
	audio_node_root.add_child(new_player)
	_audio_players[type].append(new_player)
	return new_player

## 淡出音乐
## [param duration] 淡出持续时间
func _fade_out_music(duration: float) -> void:
	if _current_music:
		var tween = audio_node_root.create_tween()
		tween.tween_property(_current_music, "volume_db", -80.0, duration)
		tween.tween_callback(_current_music.stop)

## 淡入音乐
## [param duration] 淡入持续时间
func _fade_in_music(duration: float) -> void:
	if _current_music:
		_current_music.volume_db = -80.0
		var tween = audio_node_root.create_tween()
		tween.tween_property(_current_music, "volume_db", 
			linear_to_db(_volumes[AudioType.MUSIC]), duration)

## 设置音频扬声器
func _setup_audio_buses():
	# var audio_bus_layout = AudioServer.get_bus_layout()
	
	for type in DEFAULT_BUSES:
		var bus_name = DEFAULT_BUSES[type]
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var bus_idx = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(bus_idx, bus_name)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(1.0))

## 音乐播放完毕回调
func _on_music_finished() -> void:
	if _current_music:
		_current_music.play()

## 判断音频是否循环
func _is_audio_loop(audio:AudioStream)->bool:
	if audio == null:
		return false
	
	if audio is AudioStreamWAV:
		return audio.loop_mode != AudioStreamWAV.LoopMode.LOOP_DISABLED
	elif audio is AudioStreamMP3 or audio is AudioStreamOggVorbis or audio is AudioStreamPlaylist:
		return audio.loop
	
	return false
