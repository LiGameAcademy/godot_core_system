extends Node

const SETTING_SCRIPT: Script = preload("../../setting.gd")
const SETTING_TRIGGER_SYSTEM := SETTING_SCRIPT.SETTING_TRIGGER_SYSTEM
const SETTING_SUBSCRIBE_EVENT_BUS := SETTING_TRIGGER_SYSTEM + "subscribe_event_bus"

## 触发器集
@export_storage var _event_triggers : Dictionary[StringName, Array]	## 事件触发器
@export_storage var _periodic_triggers : Array[GameplayTrigger]	## 周期触发器
var _condition_types : Dictionary = {
	"composite_trigger_condition": CompositeTriggerCondition,
	"event_type_trigger_condition": EventTypeTriggerCondition,
	"state_trigger_condition": StateTriggerCondition,
}

var _event_bus : Node = CoreSystem.event_bus
## 是否订阅事件总线的事件
var subscribe_event_bus : bool = false:
	get:
		return ProjectSettings.get_setting(SETTING_SUBSCRIBE_EVENT_BUS, true)

signal triggered(trigger: GameplayTrigger, context: Dictionary)


func _process(delta: float) -> void:
	for trigger : GameplayTrigger in _periodic_triggers:
		trigger.update(delta)


## 触发
func handle_event(trigger_type: StringName, context: Dictionary) -> void:
	var triggers : Array = _event_triggers.get(trigger_type, [])
	if triggers.is_empty():
		return
	for trigger : GameplayTrigger in triggers:
		trigger.execute(context)


## 添加触发器
func register_event_trigger(trigger_type: StringName, trigger: GameplayTrigger) -> void:
	trigger.triggered.connect(_on_trigger_triggered.bind(trigger))
	if not _event_triggers.has(trigger_type):
		if subscribe_event_bus:
			# 这里可以订阅事件总线的事件
			_event_bus.subscribe(trigger_type, _on_event_bus_trigger.bind(trigger_type))
		_event_triggers[trigger_type] = []
	_event_triggers[trigger_type].append(trigger)


## 移除触发器
func unregister_event_trigger(trigger_type: StringName, trigger: GameplayTrigger) -> void:
	trigger.triggered.disconnect(_on_trigger_triggered.bind(trigger))
	var triggers : Array[GameplayTrigger] = _event_triggers.get(trigger_type, [])
	if triggers.has(trigger):
		triggers.erase(trigger)
		if triggers.is_empty() and subscribe_event_bus:
			# 这里可以取消订阅事件总线的事件
			_event_bus.unsubscribe(trigger_type, _on_event_bus_trigger.bind(trigger_type))


## 添加周期触发器
func register_periodic_trigger(trigger: GameplayTrigger) -> void:
	_periodic_triggers.append(trigger)


## 移除周期触发器
func unregister_periodic_trigger(trigger: GameplayTrigger) -> void:
	_periodic_triggers.erase(trigger)


## 注册限制器类型
## [param type] 限制器类型
## [param condition_class] 限制器类
func register_condition_type(type: StringName, condition_class: GDScript) -> void:
	_condition_types[type] = condition_class


## 卸载限制器类型
func unregister_condition_type(type: StringName) -> void:
	_condition_types.erase(type)


## 创建限制器
func create_condition(config: Dictionary) -> TriggerCondition:
	var condition_type : StringName = config.get("type")
	if not _condition_types.has(condition_type):
		CoreSystem.logger.error("create condition by type: %s" % condition_type)
		return null
	return _condition_types[condition_type].new(config)


func _on_trigger_triggered(context: Dictionary, trigger: GameplayTrigger) -> void:
	triggered.emit(trigger, context)


func _on_event_bus_trigger(context: Dictionary, trigger_type: StringName) -> void:
	handle_event(trigger_type, context)
