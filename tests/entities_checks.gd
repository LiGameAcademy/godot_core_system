extends Node

var _checks: int = 0
var _failed: bool = false

func _ready() -> void:
	await _run()
	print("Entity checks: %d; failed: %s" % [_checks, _failed])
	get_tree().quit(1 if _failed else 0)

func _run() -> void:
	var resources: CoreResources = CoreResources.new()
	add_child(resources)
	_check(resources.load_resource("res://missing.tscn").error == ERR_CANT_OPEN, "Missing scene")
	var result: CoreResourceResult = resources.load_resource("res://addons/godot_core_system/examples/entities/entity_actor.tscn")
	_check(result.error == OK, "Explicit loading")
	var scene: PackedScene = result.resource as PackedScene
	var group: CoreEntities = CoreEntities.new(scene, CoreInstancePool.new(2))
	var other: CoreEntities = CoreEntities.new(scene, CoreInstancePool.new(2))
	var detached: Node = Node.new()
	_check(group.create(detached, _ok).error == ERR_INVALID_PARAMETER, "Detached parent")
	detached.free()
	_check(group.create(self, _fail).error == ERR_INVALID_DATA and group.active_count == 0, "Initialization failure")
	_check(group.create(self, _void_callback).error == ERR_INVALID_DATA, "Missing callback result")
	var definition: ExampleEntityDefinition = ExampleEntityDefinition.new()
	var a: CoreEntityLease = group.create(self, _initialize.bind(definition)).lease
	var other_definition: ExampleEntityDefinition = ExampleEntityDefinition.new()
	other_definition.max_health = 150
	var b: CoreEntityLease = group.create(self, _initialize.bind(other_definition)).lease
	_check(a != null and b != null and group.active_count == 2, "Create A/B")
	var template: Node = scene.instantiate()
	var palette: Gradient = a.node.get("palette") as Gradient
	_check(palette != b.node.get("palette") and palette != template.get("palette"), "Exclusive palette")
	group.update(a, _damage)
	_check(a.node.get("health") == 75 and b.node.get("health") == 150 and definition.max_health == 100, "Health isolation")
	_check((b.node.get("palette") as Gradient).get_color(0) == Color.WHITE and (template.get("palette") as Gradient).get_color(0) == Color.WHITE, "Palette isolation")
	template.free()
	_check(group.update(a, _fail) == ERR_INVALID_DATA and group.active_count == 2, "Failed update retains lease")
	_check(other.recycle(a, _ok) == ERR_DOES_NOT_EXIST, "Foreign lease")
	_check(group.recycle(CoreEntityLease.new(a.node), _ok) == ERR_DOES_NOT_EXIST, "Forged lease")
	var node: Node = a.node
	_check(group.recycle(a, _stop) == OK and group.cached_count == 1, "Recycle")
	_check(group.recycle(a, _stop) == ERR_DOES_NOT_EXIST, "Duplicate recycle")
	var reused: CoreEntityLease = group.create(self, _initialize.bind(definition)).lease
	_check(reused.node == node and reused != a and reused.node.get("health") == 100, "Reuse reset and new lease")
	_check(group.destroy(a) == ERR_DOES_NOT_EXIST and group.active_count == 2, "Stale lease")
	_check(group.update(reused, func(_instance: Node) -> Error: return group.clear()) == ERR_BUSY, "Reentry")
	_check(group.clear() == OK and group.active_count == 0 and group.cached_count == 0, "Clear all")
	await get_tree().process_frame
	_check(not is_instance_valid(node) and not is_instance_valid(b.node), "Released nodes")
	var external: CoreEntityLease = group.create(self, _initialize.bind(definition)).lease
	external.node.queue_free()
	_check(group.active_count == 0, "Prune externally queued node")
	var freed: CoreEntityLease = group.create(self, _initialize.bind(definition)).lease
	freed.node.free()
	_check(group.active_count == 0 and group.update(freed, _ok) == ERR_DOES_NOT_EXIST, "Prune externally freed node")
	var closing: CoreEntities = CoreEntities.new(scene, CoreInstancePool.new())
	_check(closing.create(self, func(_instance: Node) -> Error:
		closing.close()
		return OK).error == ERR_UNAVAILABLE and closing.active_count == 0, "Close in callback")
	var zero: CoreEntities = CoreEntities.new(scene, CoreInstancePool.new(0))
	var consumed: CoreEntityLease = zero.create(self, _ok).lease
	_check(zero.recycle(consumed, _ok) == OK and not is_instance_valid(consumed.node), "Zero capacity")
	zero.close()
	var survivor: CoreEntityLease = other.create(self, _initialize.bind(definition)).lease
	group.close()
	group.close()
	_check(group.create(self, _ok).error == ERR_UNAVAILABLE, "Closed group")
	_check(other.active_count == 1 and is_instance_valid(survivor.node) and resources.cache_count == 1, "Other owner survives")
	other.close()
	await get_tree().process_frame
	resources.queue_free()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)

static func _ok(_instance: Node) -> Error:
	return OK
static func _fail(_instance: Node) -> Error:
	return ERR_INVALID_DATA
static func _void_callback(_instance: Node) -> void:
	pass
static func _initialize(instance: Node, definition: ExampleEntityDefinition) -> Error:
	return int(instance.call("initialize", definition)) as Error
static func _damage(instance: Node) -> Error:
	instance.call("damage", 25)
	return OK
static func _stop(instance: Node) -> Error:
	instance.call("destroy")
	return OK



