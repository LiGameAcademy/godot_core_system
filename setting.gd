extends RefCounted


const SETTING_MODULE_ENABLE: String = "godot_core_system/module_enable/"
const SETTING_CONFIG_SYSTEM: String = "godot_core_system/config_system/"

const SETTING_SAVE_SYSTEM: String = "godot_core_system/save_system/"
const SETTING_SAVE_SYSTEM_DEFAULTS := SETTING_SAVE_SYSTEM + "defaults/"
const SETTING_SAVE_SYSTEM_AUTO_SAVE := SETTING_SAVE_SYSTEM + "auto_save/"

const SETTING_TRIGGER_SYSTEM: String = "godot_core_system/trigger_system/"
const SETTING_LOGGER: String = "godot_core_system/logger/"

const SETTING_INFO_DICT: Dictionary[StringName, Dictionary] = {
	"module_enable/event_bus":
	{
		"name": SETTING_MODULE_ENABLE + "event_bus",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/logger":
	{
		"name": SETTING_MODULE_ENABLE + "logger",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/input_manager":
	{
		"name": SETTING_MODULE_ENABLE + "input_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/audio_manager":
	{
		"name": SETTING_MODULE_ENABLE + "audio_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/scene_manager":
	{
		"name": SETTING_MODULE_ENABLE + "scene_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/time_manager":
	{
		"name": SETTING_MODULE_ENABLE + "time_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/resource_manager":
	{
		"name": SETTING_MODULE_ENABLE + "resource_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/save_manager":
	{
		"name": SETTING_MODULE_ENABLE + "save_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/config_manager":
	{
		"name": SETTING_MODULE_ENABLE + "config_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/state_machine":
	{
		"name": SETTING_MODULE_ENABLE + "state_machine",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/entity_manager":
	{
		"name": SETTING_MODULE_ENABLE + "entity_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/trigger_manager":
	{
		"name": SETTING_MODULE_ENABLE + "trigger_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/gameplay_tag_manager":
	{
		"name": SETTING_MODULE_ENABLE + "gameplay_tag_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"config_system/config_path":
	{
		"name": SETTING_CONFIG_SYSTEM + "config_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "配置文件路径",
		"basic": true,
		"default": "user://config.cfg",
	},

	"config_system/auto_save":
	{
		"name": SETTING_CONFIG_SYSTEM + "auto_save",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"trigger_system/subscribe_event_bus":
	{
		"name": SETTING_TRIGGER_SYSTEM + "subscribe_event_bus",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"logger/color_debug":
	{
		"name": SETTING_LOGGER + "color_debug",
		"type": TYPE_COLOR,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": Color.DARK_GRAY,
	},

	"logger/color_info":
	{
		"name": SETTING_LOGGER + "color_info",
		"type": TYPE_COLOR,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": Color.WHITE,
	},

	"logger/color_warning":
	{
		"name": SETTING_LOGGER + "color_warning",
		"type": TYPE_COLOR,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": Color.YELLOW,
	},

	"logger/color_error":
	{
		"name": SETTING_LOGGER + "color_error",
		"type": TYPE_COLOR,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": Color.RED,
	},

	"logger/color_fatal":
	{
		"name": SETTING_LOGGER + "color_fatal",
		"type": TYPE_COLOR,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": Color(0.5, 0, 0),
	},

	"save_system/save_directory":
	{
		"name": SETTING_SAVE_SYSTEM + "save_directory",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"hint_string": "存档路径",
		"basic": true,
		"default": "user://saves",  # 添加默认值
	},

	"save_system/save_group":
	{
		"name": SETTING_SAVE_SYSTEM + "save_group",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": "saveable",
	},

	"save_system/auto_save/enabled":
	{
		"name": SETTING_SAVE_SYSTEM_AUTO_SAVE + "enabled",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},
	"save_system/auto_save/interval_seconds":
	{
		"name": SETTING_SAVE_SYSTEM_AUTO_SAVE + "interval_seconds",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": 300.0,
	},
	"save_system/auto_save/max_saves":
	{
		"name": SETTING_SAVE_SYSTEM_AUTO_SAVE + "max_saves",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": 3,
	},
	"save_system/auto_save/name_prefix":
	{
		"name": SETTING_SAVE_SYSTEM_AUTO_SAVE + "name_prefix",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": "auto_",
	},
	"save_system/defaults/serialization_format":
	{
		"name": SETTING_SAVE_SYSTEM_DEFAULTS + "serialization_format",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "binary,json,resource",
		"basic": true,
		"default": "",
	},
}

## 设置路径和字典名称里只要填对一个就能得到参数的傻瓜方法
static func get_setting_value(setting_name: StringName, default_value: Variant = null) -> Variant:
	var setting_dict: Dictionary = {}

	if SETTING_INFO_DICT.has(setting_name):
		setting_dict = SETTING_INFO_DICT.get(setting_name)
		setting_name = setting_dict.get("name")

	if setting_dict.is_empty():
		for dict in SETTING_INFO_DICT.values():
			if dict.get("name") == setting_name:
				setting_dict = dict
				break

	if setting_dict.has("default") && default_value == null:
		default_value = setting_dict.get("default")

	return ProjectSettings.get_setting(setting_name, default_value)
