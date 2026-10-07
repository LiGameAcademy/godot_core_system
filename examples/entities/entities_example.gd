extends Node2D

const ACTOR_PATH: String = "res://addons/godot_core_system/examples/entities/entity_actor.tscn"
@onready var _resources: CoreResources = $CoreResources
@onready var _status: Label = $Panel/Rows/Status
var _entities: CoreEntities
var _a: CoreEntityLease
var _b: CoreEntityLease
var _definition: ExampleEntityDefinition = ExampleEntityDefinition.new()
var _other_definition: ExampleEntityDefinition = ExampleEntityDefinition.new()

func _ready() -> void:
	_other_definition.max_health = 150
	var result: CoreResourceResult = _resources.load_resource(ACTOR_PATH)
	if result.error != OK or not result.resource is PackedScene:
		_status.text = "Actor scene load failed: %s" % error_string(result.error)
		return
	_entities = CoreEntities.new(result.resource as PackedScene, CoreInstancePool.new(2))
	$Panel/Rows/Create.pressed.connect(_create_pair)
	$Panel/Rows/Damage.pressed.connect(_damage_a)
	$Panel/Rows/Recycle.pressed.connect(_reuse_a)
	$Panel/Rows/Clear.pressed.connect(_clear)
	_refresh()

func _exit_tree() -> void:
	if _entities != null:
		_entities.close()

func _create_pair() -> void:
	_clear()
	_a = _entities.create(self, _initialize.bind(Vector2(260, 300), _definition)).lease
	_b = _entities.create(self, _initialize.bind(Vector2(360, 300), _other_definition)).lease
	_refresh()

func _damage_a() -> void:
	if _a != null:
		_entities.update(_a, _damage)
	_refresh()

func _reuse_a() -> void:
	if _a == null:
		return
	var old: CoreEntityLease = _a
	var instance: Node = old.node
	_entities.recycle(old, _stop)
	_a = _entities.create(self, _initialize.bind(Vector2(260, 300), _definition)).lease
	var stale: Error = _entities.recycle(old, _stop)
	_refresh()
	_status.text += "\nSame node: %s; stale lease: %s" % [_a.node == instance, error_string(stale)]

func _clear() -> void:
	_entities.clear()
	_a = null
	_b = null
	_refresh()

func _refresh() -> void:
	_status.text = "Active: %d  Cached: %d" % [_entities.active_count, _entities.cached_count]
	if _a != null and _b != null:
		_status.text += "\nA health: %d  B health: %d  Definition: %d" % [_a.node.get("health"), _b.node.get("health"), _definition.max_health]

func _initialize(instance: Node, position: Vector2, definition: ExampleEntityDefinition) -> Error:
	(instance as Node2D).position = position
	return int(instance.call("initialize", definition)) as Error

static func _damage(instance: Node) -> Error:
	instance.call("damage", 25)
	return OK

static func _stop(instance: Node) -> Error:
	instance.call("destroy")
	return OK


