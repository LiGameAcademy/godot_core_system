extends Node2D

const AudioManager = CoreSystem.AudioManager

@onready var audio_manager : AudioManager = CoreSystem.audio_manager

# 预加载的音频资源路径
var AUDIO_PATHS := {
	"bgm": FileDirHandler.get_object_script_dir(self) + "/assets/music/bgm.ogg",
	"click": FileDirHandler.get_object_script_dir(self) + "/assets/sfx/click.ogg",
	"voice": FileDirHandler.get_object_script_dir(self) + "/assets/voice/congratulations.ogg"
}

func _ready():
	# 预加载音频资源
	audio_manager.preload_audio(AUDIO_PATHS.bgm, AudioManager.AudioType.MUSIC)
	audio_manager.preload_audio(AUDIO_PATHS.click, AudioManager.AudioType.SOUND_EFFECT)
	audio_manager.preload_audio(AUDIO_PATHS.voice, AudioManager.AudioType.VOICE)
	
	# 延迟1秒后开始演示
	await get_tree().create_timer(1.0).timeout
	_start_demo()

## 开始演示
func _start_demo():
	print("\n=== 开始音频系统演示 ===")
	
	# 1. 播放背景音乐（带淡入效果）
	print("\n1. 播放背景音乐（2秒淡入）：")
	audio_manager.play_music(AUDIO_PATHS.bgm, 2.0)
	
	await get_tree().create_timer(3.0).timeout
	
	# 2. 调整音乐音量
	print("\n2. 调整音乐音量至50%：")
	audio_manager.set_volume(AudioManager.AudioType.MUSIC, 0.5)
	
	await get_tree().create_timer(2.0).timeout
	
	# 3. 播放音效
	print("\n3. 播放音效：")
	for i in range(3):
		audio_manager.play_sound(AUDIO_PATHS.click, 1.0)
		await get_tree().create_timer(0.5).timeout
	
	# 4. 播放语音
	print("\n4. 播放语音：")
	audio_manager.play_voice(AUDIO_PATHS.voice, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	
	# 5. 切换背景音乐（带淡出淡入效果）
	print("\n5. 切换背景音乐（1秒淡出淡入）：")
	audio_manager.play_music(AUDIO_PATHS.bgm, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	
	# 6. 停止所有音频
	print("\n6. 停止所有音频：")
	audio_manager.stop_all()
	
	print("\n=== 音频系统演示结束 ===")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			# 按空格键重新开始演示
			KEY_SPACE:
				print("\n按下空格键，重新开始演示")
				audio_manager.stop_all()
				_start_demo()
			# 按ESC键停止所有音频
			KEY_ESCAPE:
				print("\n按下ESC键，停止所有音频")
				audio_manager.stop_all()
