extends RefCounted

## 默认配置模板

## 获取默认配置
static func get_default_config() -> Dictionary:
	return {
		"game": {
			"language": "zh",
			"difficulty": "normal",
			"first_run": true,
		},
		"graphics": {
			"fullscreen": false,
			"vsync": true,
			"resolution": Vector2i(1920, 1080),
			"quality": "high",
			"show_fps": false,
		},
		"audio": {
			"master_volume": 100,
			"music_volume": 80,
			"sfx_volume": 80,
		},
		"input": {
			"mouse_sensitivity": 1.0,
			"gamepad_enabled": true,
			"vibration_enabled": true,
			"bindings": {
				"ui_up": [
					{
						"type": "key",
						"keycode": KEY_W,
						"physical_keycode": KEY_W,
						"key_label": KEY_W,
						"unicode": KEY_W,
					},
					{
						"type": "key",
						"keycode": KEY_SPACE,
						"physical_keycode": KEY_SPACE,
						"key_label": KEY_SPACE,
						"unicode": KEY_SPACE,
					}
				],
				"ui_down": [
					{
						"type": "key",
						"keycode": KEY_S,
						"physical_keycode": KEY_S,
						"key_label": KEY_S,
						"unicode": KEY_S,
					}
				],
				"ui_left": [
					{
						"type": "key",
						"keycode": KEY_A,
						"physical_keycode": KEY_A,
						"key_label": KEY_A,
						"unicode": KEY_A,
					}
				],
				"ui_right": [
					{
						"type": "key",
						"keycode": KEY_D,
						"physical_keycode": KEY_D,
						"key_label": KEY_D,
						"unicode": KEY_D,
					}
				],
				"ui_attack": [
					{
						"type": "key",
						"keycode": KEY_J,
						"physical_keycode": KEY_J,
						"key_label": KEY_J,
						"unicode": KEY_J,
					}
				],
				"ui_skill": [
					{
						"type": "key",
						"keycode": KEY_K,
						"physical_keycode": KEY_K,
						"key_label": KEY_K,
						"unicode": KEY_K,
					}
				]
			}
		},
		"gameplay": {
			"tutorial_enabled": true,
			"auto_save": true,
			"auto_save_interval": 300,
			"show_damage_numbers": true,
			"show_floating_text": true,
		},
		"accessibility": {
			"subtitles": true,
			"screen_shake": true,
			"text_size": "medium",
		},
		"debug": {
			"logging_enabled": true,
			"log_level": "info",
			"show_debug_info": false,
		}
	}
