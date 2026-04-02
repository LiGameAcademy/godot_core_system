@tool
extends EditorPlugin


const SYSTEM_NAME: String = "CoreSystem"
var SYSTEM_PATH: String = FileDirHandler.get_object_script_dir(self) + "/source/core_system.gd"

const SETTING_SCRIPT: Script = preload("./setting.gd")
const SETTING_INFO_DICT: Dictionary[StringName, Dictionary] = SETTING_SCRIPT.SETTING_INFO_DICT

## 在插件运行时添加项目设置
func _enter_tree() -> void:
	_add_project_settings()
	add_autoload_singleton(SYSTEM_NAME, SYSTEM_PATH)
	ProjectSettings.save()

## 在禁用插件时恢复项目配置
func _disable_plugin() -> void:
	remove_autoload_singleton(SYSTEM_NAME)
	_remove_project_settings()
	ProjectSettings.save()

## 添加配置脚本中的设置项
func _add_project_settings() -> void:
	for setting_dict in SETTING_INFO_DICT.values():
		_add_setting_dict(setting_dict)

## 移除配置脚本中的设置项
func _remove_project_settings() -> void:
	for setting_dict in SETTING_INFO_DICT.values():
		_remove_setting_dict(setting_dict)

## 使用hint_dictionary添加选项
func _add_setting_dict(info_dict: Dictionary) -> void:
	var setting_name: String = info_dict["name"]
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, info_dict["default"])

	ProjectSettings.set_as_basic(setting_name, info_dict["basic"])
	ProjectSettings.set_initial_value(setting_name, info_dict["default"])
	ProjectSettings.add_property_info(info_dict)

## 使用hint_dictionary移除选项
func _remove_setting_dict(info_dict: Dictionary) -> void:
	var setting_name: String = info_dict["name"]
	if ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, null)

## 添加单个设置项
func _add_setting(name: String, default_value, type: int, hint: int, hint_string: String = "") -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)

	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.add_property_info({
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	})


## 确保项目设置中有我们的分类
func _ensure_project_settings_category() -> void:
	if not ProjectSettings.has_setting("godot_core_system/modules"):
		ProjectSettings.set_setting("godot_core_system/modules", {})
		ProjectSettings.set_as_basic("godot_core_system/modules", true)
		ProjectSettings.add_property_info({
			"name": "godot_core_system/modules",
			"type": TYPE_DICTIONARY,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "Core System Modules"
		})
