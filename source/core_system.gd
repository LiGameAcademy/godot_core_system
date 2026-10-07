extends Node

## Plugin composition root

# System classes
const AudioManager = preload("./audio_system/audio_manager.gd")
const LegacyEventBus = preload("./event_system/event_bus.gd")
const CoreEventBus = LegacyEventBus
const InputManager = preload("./input_system/input_manager.gd")
const CoreLogger = preload("./logger/core_logger.gd")
const ResourceManager = preload("./resource_system/resource_manager.gd")
const CoreSceneManager = preload("./scene_system/scene_manager.gd")
const TimeManager = preload("./time_system/time_manager.gd")
const SaveManager = preload("./save_system/save_manager.gd")
const ConfigManager = preload("./config_system/config_manager.gd")
const StateMachineManager = preload("./state_machine/state_machine_manager.gd")
const EntityManager = preload("./entity_system/entity_manager.gd")
const TriggerManager = preload("./trigger_system/trigger_manager.gd")
const GameplayTagManager = preload("./tag_system/gameplay_tag_manager.gd")
# Utilities
const FrameSplitter = preload("./utils/frame_splitter.gd")
const SingleThread = preload("./utils/threading/single_thread.gd")
const ModuleThread = preload("./utils/threading/module_thread.gd")
const RandomPicker = preload("./utils/random_picker.gd")
const AsyncIOManager = preload("./utils/async_io_manager.gd")

const CoreGameplayTag = preload("./tag_system/gameplay_tag.gd")

@onready var logger : CoreLogger = _get_module("logger"):								## Logger
	get:
		if not logger:
			logger = _get_module("logger")
		return logger
@onready var resource_manager : ResourceManager = _get_module("resource_manager"):			## Resource manager
	get:
		if not resource_manager:
			resource_manager = _get_module("resource_manager")
		return resource_manager
@onready var audio_manager : AudioManager = _get_module("audio_manager"):			## Audio manager
	get:
		if not audio_manager:
			audio_manager = _get_module("audio_manager")
		return audio_manager
@onready var event_bus : LegacyEventBus = _get_module("event_bus"):						## Legacy event node
	get:
		if not event_bus:
			event_bus = _get_module("event_bus")
		return event_bus
@onready var input_manager : InputManager = _get_module("input_manager"):			## Input manager
	get:
		if not input_manager:
			input_manager = _get_module("input_manager")
		return input_manager
@onready var config_manager : ConfigManager = _get_module("config_manager"):			## Configuration
	get:
		if not config_manager:
			config_manager = _get_module("config_manager")
		return config_manager
@onready var scene_manager : CoreSceneManager = _get_module("scene_manager"):			## Scene manager
	get:
		if not scene_manager:
			scene_manager = _get_module("scene_manager")
		return scene_manager
@onready var time_manager : TimeManager = _get_module("time_manager"):				## Time manager
	get:
		if not time_manager:
			time_manager = _get_module("time_manager")
		return time_manager
@onready var save_manager : SaveManager = _get_module("save_manager"):				## Save manager
	get:
		if not save_manager:
			save_manager = _get_module("save_manager")
		return save_manager
@onready var state_machine_manager : StateMachineManager = _get_module("state_machine_manager"):		## State machine manager
	get:
		if not state_machine_manager:
			state_machine_manager = _get_module("state_machine_manager")
		return state_machine_manager
@onready var entity_manager : EntityManager = _get_module("entity_manager"):							## Entity manager
	get:
		if not entity_manager:
			entity_manager = _get_module("entity_manager")
		return entity_manager
@onready var trigger_manager : TriggerManager = _get_module("trigger_manager"):						## Trigger manager
	get:
		if not trigger_manager:
			trigger_manager = _get_module("trigger_manager")
		return trigger_manager
var tag_manager : GameplayTagManager:							## Deprecated lazy tag compatibility adapter
	get:
		if not tag_manager:
			tag_manager = _get_module("tag_manager")
		return tag_manager

## Module instances
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

## Checks whether a module is enabled
func is_module_enabled(module_id: StringName) -> bool:
	var setting_id: StringName = MODULE_SETTING_IDS.get(module_id, module_id)
	var setting_name: String = "godot_core_system/module_enable/" + String(setting_id)
	# Keep old hand-written runtime-ID keys as a fallback without renaming editor settings.
	if not ProjectSettings.has_setting(setting_name) and setting_id != module_id:
		setting_name = "godot_core_system/module_enable/" + String(module_id)
	# Missing switches default to enabled
	if not ProjectSettings.has_setting(setting_name):
		return true
	return ProjectSettings.get_setting(setting_name, true)

## 创建Module instances
func _create_module(module_id: StringName) -> Node:
	var script: Script = _module_scripts[module_id]
	if not script:
		push_error("Cannot load module script: " + module_id)
		return null

	var module: Node = script.new()
	if not module:
		push_error("Cannot create module instance: " + module_id)
		return null
	if module_id == &"entity_manager":
		var resources: ResourceManager = _get_module(&"resource_manager")
		if resources == null:
			module.free()
			push_error("EntityManager requires an enabled ResourceManager.")
			return null
		(module as EntityManager).configure(resources.get_resource_service())
	_modules[module_id] = module
	module.name = module_id
	add_child(module)
	return module

## Gets a module
func _get_module(module_id: StringName) -> Node:
	if not _modules.has(module_id):
		if is_module_enabled(module_id):
			var module : Node = _create_module(module_id)
			_modules[module_id] = module
		else:
			logger.warning("Module disabled: " + module_id)
			return null
	return _modules[module_id]
