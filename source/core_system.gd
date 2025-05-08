extends Node

## 插件单例

# 系统类
const AudioManager = preload("./audio_system/audio_manager.gd")
const EventBus = preload("./event_system/event_bus.gd")
const InputManager = preload("./input_system/input_manager.gd")
const Logger = preload("./logger/logger.gd")
const ResourceManager = preload("./resource_system/resource_manager.gd")
const SceneManager = preload("./scene_system/scene_manager.gd")
const TimeManager = preload("./time_system/time_manager.gd")
const SaveManager = preload("./save_system/save_manager.gd")
const ConfigManager = preload("./config_system/config_manager.gd")
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

@onready var logger : Logger = _get_module("logger"):								## 日志管理器
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
@onready var event_bus : EventBus = _get_module("event_bus"):						## 事件总线
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
@onready var scene_manager : SceneManager = _get_module("scene_manager"):			## 场景管理器
	get:
		if not scene_manager:
			scene_manager = _get_module("scene_manager")
		return scene_manager
@onready var time_manager : TimeManager = _get_module("time_manager"):				## 时间管理器
	get:
		if not time_manager:
			time_manager = _get_module("time_manager")
		return time_manager
@onready var save_manager : SaveManager = _get_module("save_manager"):				## 存档管理器
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

## 模块实例
var _modules: Dictionary[StringName, Node] = {}
var _module_scripts: Dictionary[StringName, Script] = {
	"audio_manager": AudioManager,
	"event_bus": EventBus,
	"input_manager": InputManager,
	"logger": Logger,
	"resource_manager": ResourceManager,
	"scene_manager": SceneManager,
	"time_manager": TimeManager,
	"save_manager": SaveManager,
	"config_manager": ConfigManager,
	"state_machine_manager": StateMachineManager,
	"entity_manager": EntityManager,
	"trigger_manager": TriggerManager,
	"tag_manager": GameplayTagManager,
}

## 检查模块是否启用
func is_module_enabled(module_id: StringName) -> bool:
	var setting_name = "godot_core_system/module_enable/" + module_id
	# 如果设置不存在，默认为启用
	if not ProjectSettings.has_setting(setting_name):
		return true
	return ProjectSettings.get_setting(setting_name, true)

## 创建模块实例
func _create_module(module_id: StringName) -> Node:
	var script = _module_scripts[module_id]
	if not script:
		push_error("无法加载模块脚本：" + module_id)
		return null

	var module = script.new()
	if not module:
		push_error("无法创建模块实例：" + module_id)
		return null
	_modules[module_id] = module
	module.name = module_id
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
