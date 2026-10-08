extends Node

## 插件单例

# 系统类
const AudioManager = preload("./audio_system/audio_manager.gd")
const CoreEventBus = preload("./event_system/event_bus.gd")
const InputManager = preload("./input_system/input_manager.gd")
const CoreLogger = preload("./logger/core_logger.gd")
const ResourceManager = preload("./resource_system/resource_manager.gd")
const CoreSceneManager = preload("./scene_system/scene_manager.gd")
const TimeManager = preload("./time_system/time_manager.gd")
const SaveManager = preload("./save_system/save_manager.gd")
const ConfigManager = preload("./config_system/config_manager.gd")
const LocalizationManager = preload("./localization_system/localization_manager.gd")
const StateMachineManager = preload("./state_machine/state_machine_manager.gd")
const EntityManager = preload("./entity_system/entity_manager.gd")
const TriggerManager = preload("./trigger_system/trigger_manager.gd")
const GameplayTagManager = preload("./tag_system/gameplay_tag_manager.gd")
# 工具类
const FrameSplitter = preload("./utils/frame_splitter.gd")
const SingleThread = preload("./utils/threading/single_thread.gd")
const ModuleThread = preload("./utils/threading/module_thread.gd")
const RandomPicker = preload("./utils/random_picker.gd")
const AsyncIOManager = preload("./utils/async_io_manager.gd")

const CoreGameplayTag = preload("./tag_system/gameplay_tag.gd")

@onready var logger : CoreLogger = _get_module("logger"):								## 日志管理器
	get:
		if not logger:
			logger = _get_module("logger")
		return logger
@onready var resource_manager : ResourceManager = _get_module("resource_manager"):			## 资源管理器
	get:
		if not resource_manager:
			resource_manager = _get_module("resource_manager")
		return resource_manager
@onready var audio_manager : AudioManager = _get_module("audio_manager"):			## 音频管理器
	get:
		if not audio_manager:
			audio_manager = _get_module("audio_manager")
		return audio_manager
@onready var event_bus : CoreEventBus = _get_module("event_bus"):						## 事件总线
	get:
		if not event_bus:
			event_bus = _get_module("event_bus")
		return event_bus
@onready var input_manager : InputManager = _get_module("input_manager"):			## 输入管理器
	get:
		if not input_manager:
			input_manager = _get_module("input_manager")
		return input_manager
@onready var config_manager : ConfigManager = _get_module("config_manager"):			## 配置管理器
	get:
		if not config_manager:
			config_manager = _get_module("config_manager")
		return config_manager
@onready var scene_manager : CoreSceneManager = _get_module("scene_manager"):			## 场景管理器
	get:
		if not scene_manager:
			scene_manager = _get_module("scene_manager")
		return scene_manager
@onready var time_manager : TimeManager = _get_module("time_manager"):				## 时间管理器
	get:
		if not time_manager:
			time_manager = _get_module("time_manager")
		return time_manager
@onready var save_manager : SaveManager = _get_module("save_manager") if is_module_enabled("save_manager") else null:				## 存档管理器
	get:
		if not save_manager:
			save_manager = _get_module("save_manager")
		return save_manager
@onready var state_machine_manager : StateMachineManager = _get_module("state_machine_manager"):		## 状态机管理器
	get:
		if not state_machine_manager:
			state_machine_manager = _get_module("state_machine_manager")
		return state_machine_manager
@onready var entity_manager : EntityManager = _get_module("entity_manager"):							## 实体管理器
	get:
		if not entity_manager:
			entity_manager = _get_module("entity_manager")
		return entity_manager
@onready var trigger_manager : TriggerManager = _get_module("trigger_manager"):						## 触发器管理器
	get:
		if not trigger_manager:
			trigger_manager = _get_module("trigger_manager")
		return trigger_manager
@onready var tag_manager : GameplayTagManager = _get_module("tag_manager"):							## 标签管理器
	get:
		if not tag_manager:
			tag_manager = _get_module("tag_manager")
		return tag_manager

## 可选语言偏好模块；默认关闭，禁用时不查找其它服务。
@onready var localization_manager: LocalizationManager = _get_module("localization_manager") if is_module_enabled(&"localization_manager") else null:
	get:
		if not is_module_enabled(&"localization_manager"):
			return null
		if not is_instance_valid(localization_manager):
			localization_manager = _get_module("localization_manager")
		return localization_manager

## 模块实例
var _modules: Dictionary[StringName, Node] = {}
var _module_scripts: Dictionary[StringName, Script] = {
	"audio_manager": AudioManager,
	"event_bus": CoreEventBus,
	"input_manager": InputManager,
	"logger": CoreLogger,
	"resource_manager": ResourceManager,
	"scene_manager": CoreSceneManager,
	"time_manager": TimeManager,
	"save_manager": SaveManager,
	"config_manager": ConfigManager,
	"localization_manager": LocalizationManager,
	"state_machine_manager": StateMachineManager,
	"entity_manager": EntityManager,
	"trigger_manager": TriggerManager,
	"tag_manager": GameplayTagManager,
}

## Runtime IDs whose editor switches retain historical names.
const MODULE_SETTING_IDS: Dictionary[StringName, StringName] = {
	&"state_machine_manager": &"state_machine",
	&"tag_manager": &"gameplay_tag_manager",
}

## 检查模块是否启用
func is_module_enabled(module_id: StringName) -> bool:
	var setting_id: StringName = MODULE_SETTING_IDS.get(module_id, module_id)
	var setting_name: String = "godot_core_system/module_enable/" + setting_id
	# Keep old hand-written runtime-ID keys as a fallback without renaming editor settings.
	if not ProjectSettings.has_setting(setting_name) and setting_id != module_id:
		setting_name = "godot_core_system/module_enable/" + module_id
	# 旧模块保持默认开启；新多语言模块需要明确启用。
	if not ProjectSettings.has_setting(setting_name):
		return module_id != &"localization_manager"
	return ProjectSettings.get_setting(setting_name, true)

## 创建模块实例
func _create_module(module_id: StringName) -> Node:
	var script: Script = _module_scripts[module_id]
	if not script:
		push_error("无法加载模块脚本：" + module_id)
		return null

	var module: Node = script.new() as Node
	if not module:
		push_error("无法创建模块实例：" + module_id)
		return null
	_modules[module_id] = module
	module.name = module_id
	if module_id == &"localization_manager" and is_module_enabled(&"config_manager"):
		var localization: LocalizationManager = module as LocalizationManager
		localization.configure_persistence(config_manager)
	add_child(module)
	return module

## 获取模块
func _get_module(module_id: StringName) -> Node:
	if not _modules.has(module_id):
		if is_module_enabled(module_id):
			var module : Node = _create_module(module_id)
			_modules[module_id] = module
		else:
			logger.warning("模块未启用：" + module_id)
			return null
	return _modules[module_id]
