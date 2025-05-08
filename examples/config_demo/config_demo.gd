extends Node2D

@onready var status_label: Label = $UI/StatusLabel
@onready var config_tree: Tree = $UI/ConfigTree
@onready var auto_save_label: Label = %AutoSaveLabel

# --- Demo 特定的默认值 ---
# 游戏项目应该定义自己的默认值
var demo_defaults := {
	"game": { "language": "en", "difficulty": "normal" },
	"graphics": { "fullscreen": false, "vsync": true, "resolution": Vector2i(1280, 720), "quality": "medium", "show_fps": false },
	"audio": { "master_volume": 80, "music_volume": 70, "sfx_volume": 70 },
	"input": { "sensitivity": 1.0, "invert_y": false, "bindings": {"jump": "ui_accept", "attack": "ui_select"} },
	"gameplay": { "show_hints": true, "camera_shake": 0.5 },
	"accessibility": { "subtitles": false, "colorblind_mode": "none" },
	"debug": { "log_level": 1, "enable_cheats": false }
}

var _config_manager : CoreSystem.ConfigManager = CoreSystem.config_manager
var _logger : CoreSystem.Logger = CoreSystem.logger

func _ready():
	# 1. 连接信号 (可选，但对于UI反馈有用)
	_config_manager.config_loaded.connect(_on_config_loaded)
	_config_manager.config_saved.connect(_on_config_saved)
	_config_manager.config_reset.connect(_on_config_reset)
	
	# 2. 加载配置（同步）
	status_label.text = "加载配置..."
	var loaded_ok = _config_manager.load_config() # 同步加载
	if loaded_ok:
		status_label.text = "配置加载成功"
		# 可以在这里检查版本或进行迁移（如果需要）
	else:
		# 加载失败（非文件不存在）会记录错误，但仍可使用
		status_label.text = "配置加载失败 (文件存在但无法解析?)"
		# 如果文件不存在，load_config 会返回 true，不会到这里

	# 3. 检查文件是否首次加载（或为空），如果是，应用默认值
	if _config_manager.get_sections().is_empty():
		_log("配置文件为空或首次加载，应用Demo默认值...")
		_apply_demo_defaults()
		# 可选：立即保存一次默认配置
		# if not config_manager.auto_save:
		#     config_manager.save_config()

	# 4. 更新 UI
	_update_ui()
	
## 应用 Demo 特定的默认值
func _apply_demo_defaults():
	for section in demo_defaults:
		for key in demo_defaults[section]:
			# 检查是否需要设置（通常在清空后都需要）
			# if config_manager.get_value(section, key, null) != demo_defaults[section][key]:
			_config_manager.set_value(section, key, demo_defaults[section][key])
	_log("Demo 默认值已应用。")
	# 注意：set_value 会触发自动保存（如果启用）

## 更新 UI 显示 (配置树和标签)
func _update_ui():
	# 更新配置树
	config_tree.clear()
	var root = config_tree.create_item()
	root.set_text(0, "当前配置 (包括默认值)")

	# 遍历 Demo 定义的所有段落和键
	for section in demo_defaults:
		var section_item = config_tree.create_item(root)
		section_item.set_text(0, section)

		for key in demo_defaults[section]:
			# 获取当前有效值（从文件读取，如果不存在则使用 demo_defaults 中的值）
			var current_value = _config_manager.get_value(section, key, demo_defaults[section][key])

			var value_item = config_tree.create_item(section_item)
			value_item.set_text(0, "%s: %s" % [key, str(current_value)]) # 显示当前有效值

	# 更新自动保存标签
	auto_save_label.text = "自动保存: %s" % ("是" if _config_manager.auto_save else "否")

	# (可选) 显示一些特定的值，演示 get_value 的用法 (这段保持不变)
	var fs_val = _config_manager.get_value("graphics", "fullscreen", demo_defaults.graphics.fullscreen)
	var mv_val = _config_manager.get_value("audio", "master_volume", demo_defaults.audio.master_volume)
	_log("示例值: fullscreen = %s, master_volume = %s" % [str(fs_val), str(mv_val)])

## 修改配置按钮回调
func _on_modify_button_pressed():
	# 修改一些配置值作为演示
	# 使用 Demo 的默认值作为参考或比较
	var new_fullscreen = not _config_manager.get_value("graphics", "fullscreen", demo_defaults.graphics.fullscreen)
	var new_volume = _config_manager.get_value("audio", "master_volume", demo_defaults.audio.master_volume) - 10
	if new_volume < 0: new_volume = 100

	_log("修改配置: fullscreen -> %s, master_volume -> %d" % [str(new_fullscreen), new_volume])
	_config_manager.set_value("graphics", "fullscreen", new_fullscreen)
	_config_manager.set_value("audio", "master_volume", new_volume)

	status_label.text = "配置已修改 (自动保存: %s)" % ("是" if _config_manager.auto_save else "否")
	# UI 会在下次读取或信号回调时更新，如果 auto_save=true，保存信号会触发
	# _update_ui() # 可以立即更新 UI，但不等待保存完成

## 保存配置按钮回调 (仅在 auto_save = false 时有意义)
func _on_save_button_pressed():
	if _config_manager.auto_save:
		status_label.text = "自动保存已启用，无需手动保存。"
		return

	status_label.text = "手动保存配置..."
	var saved_ok = _config_manager.save_config() # 同步保存
	if saved_ok:
		status_label.text = "配置手动保存成功"
	else:
		status_label.text = "配置手动保存失败"

## 重置配置按钮回调
func _on_reset_button_pressed():
	status_label.text = "重置配置..."
	_config_manager.reset_config() # 同步清空
	# reset_config 会发出 config_reset 信号，连接到 _on_config_reset
	# status_label.text = "配置已清空，正在应用默认值..." (由 _on_config_reset 处理)

# --- 信号处理 ---

## 配置加载回调
func _on_config_loaded():
	_log("信号: 配置已加载")
	_update_ui() # 加载后更新 UI

## 配置保存回调
func _on_config_saved():
	_log("信号: 配置已保存")
	status_label.text = "配置已保存 (时间: %s)" % Time.get_time_string_from_system()
	_update_ui() # 保存后也更新一下 UI

## 配置重置回调 (非常重要)
func _on_config_reset():
	_log("信号: 配置已重置 (清空)")
	status_label.text = "配置已清空，应用 Demo 默认值..."
	# 在这里应用游戏的默认值
	_apply_demo_defaults()
	# 默认值应用后，如果 auto_save=true，会再次触发保存
	# 如果 auto_save=false，则保持未保存状态，直到手动保存
	_update_ui() # 应用默认值后更新 UI

# --- 简单的日志记录到 UI ---
func _log(message: String) -> void:
	_logger.debug(message) # 打印到控制台
	# 可以在这里添加逻辑将日志输出到 UI 上的 Label 或 RichTextLabel
