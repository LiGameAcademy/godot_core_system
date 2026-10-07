extends Node

const Manager: GDScript = preload("res://addons/godot_core_system/source/entity_system/entity_manager.gd")
const ACTOR: String = "res://addons/godot_core_system/tests/entity_release_actor.tscn"
var _checks: int = 0
var _failed: bool = false
var _unloaded: int = 0
var _blocked: bool = false

func _ready() -> void:
	var resources: CoreResources = CoreResources.new()
	add_child(resources)
	var manager: Node = Manager.new()
	add_child(manager)
	manager.configure(resources)
	manager.entity_unloaded.connect(func(_id: StringName) -> void: _unloaded += 1)
	manager.load_entity(&"a", ACTOR, 1)
	manager.load_entity(&"b", ACTOR, 1)
	_check(resources.pending_count == 1, "Alias paths share one pending job")
	manager.unload_entity(&"a")
	for frame: int in range(120):
		if resources.inflight_count == 0:
			break
		await get_tree().process_frame
	_check(manager.get_entity_scene(&"a") == null and manager.get_entity_scene(&"b") != null, "Unload one pending alias retains B")
	_check(resources.pending_count == 0 and resources.inflight_count == 0, "No pending residue")
	var actor: Node = manager.create_entity(&"b", null, self)
	_check(actor != null, "Legacy create")
	manager.destroy_entity(&"b", actor)
	_check(actor.get_parent() == null, "Legacy destroy detaches")
	actor.set("on_release", func() -> void:
		manager.unload_entity(&"b")
		var replacement: PackedScene = manager.load_entity(&"b", ACTOR)
		_blocked = replacement == null and manager.last_error == ERR_UNAVAILABLE)
	manager.unload_entity(&"b")
	_check(_blocked and _unloaded == 2 and manager.get_entity_scene(&"b") == null, "Unload release reentry is blocked")
	_check(not is_instance_valid(actor) and resources.cache_count == 1, "Unload frees idle actor, preserves loader cache")
	manager.load_entity(&"plain", "res://addons/godot_core_system/tests/entity_plain.tscn")
	_check(manager.create_entity(&"plain", null, self) == null and manager.last_error == ERR_METHOD_NOT_FOUND, "Legacy missing initialize cleans up")
	manager.unload_entity(&"plain")
	manager.load_entity(&"b", ACTOR)
	actor = manager.create_entity(&"b", null, self)
	manager.clear_entities()
	_check(actor.is_queued_for_deletion() and manager.get_entity_scene(&"b") != null, "Legacy clear releases active and keeps definition")
	await get_tree().process_frame
	actor = manager.create_entity(&"b", null, self)
	manager.destroy_entity(&"b", actor)
	_blocked = false
	actor.set("on_release", func() -> void:
		_blocked = manager.load_entity(&"other", ACTOR) == null and manager.last_error == ERR_UNAVAILABLE)
	manager.queue_free()
	await get_tree().process_frame
	_check(_blocked and not is_instance_valid(actor), "Owner exit rejects release reentry")
	var missing: Node = Node.new()
	var scene: PackedScene = PackedScene.new()
	scene.pack(missing)
	missing.free()
	var group: CoreEntities = CoreEntities.new(scene, CoreInstancePool.new())
	var failed: CoreEntityResult = group.create(self, func(instance: Node) -> Error:
		return OK if instance.has_method("initialize") else ERR_METHOD_NOT_FOUND)
	_check(failed.error == ERR_METHOD_NOT_FOUND and group.active_count == 0, "Missing initialize does not publish a lease")
	group.close()
	resources.queue_free()
	await get_tree().process_frame
	print("Legacy entity checks: %d; failed: %s" % [_checks, _failed])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)

