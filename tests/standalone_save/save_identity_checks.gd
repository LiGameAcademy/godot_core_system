extends SceneTree

const Registry: GDScript = preload("../../source/save_system/save_object_registry.gd")

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var registry: Registry = Registry.new()
	var world: Node = Node.new()
	world.name = "World"
	root.add_child(world)
	var player: Node = Node.new()
	player.name = "Player"
	world.add_child(player)
	var legacy: Node = Node.new()
	legacy.name = "Legacy"
	world.add_child(legacy)
	var path: String = str(legacy.get_path())
	_expect(registry.register_node(player, &"hero") == OK, "Stable ID registered")
	_expect(registry.register_node(player, &"hero") == OK, "Same registration idempotent")
	_expect(registry.register_node(player, &"another") == ERR_ALREADY_IN_USE, "One identity per object")
	_expect(registry.register_node(legacy) == OK, "Legacy path registered")
	_expect(registry.resolve(&"id", "hero") == player, "Stable recipient resolved")
	_expect(registry.resolve(&"path", path) == legacy, "Legacy recipient resolved")
	world.name = "Level"
	_expect(registry.resolve(&"id", "hero") == player, "Stable ID survives scene rename")
	_expect(registry.resolve(&"path", path) == null, "Old path cannot resolve renamed scene")
	_expect(registry.register_node(legacy) == OK, "Path can be explicitly registered again")
	var duplicate: Node = Node.new()
	_expect(registry.register_node(duplicate, &"hero") == ERR_ALREADY_IN_USE, "Duplicate stable ID refused")
	_expect(registry.register_node(duplicate) == ERR_UNCONFIGURED, "Unattached path recipient refused")
	duplicate.free()
	_expect(registry.resolve(&"id", "missing") == null, "Missing dynamic object remains missing")
	var first: Node = Node.new()
	var second: Node = Node.new()
	_expect(registry.register_node(second, &"spawn-B") == OK, "Reverse creation order B")
	_expect(registry.register_node(first, &"spawn-A") == OK, "Reverse creation order A")
	_expect(registry.resolve(&"id", "spawn-A") == first and registry.resolve(&"id", "spawn-B") == second, "Explicit IDs independent of creation order")
	var first_ref: WeakRef = weakref(first)
	first.free()
	_expect(first_ref.get_ref() == null and registry.resolve(&"id", "spawn-A") == null, "Registry does not retain freed object")
	registry.unregister_node(second)
	_expect(registry.resolve(&"id", "spawn-B") == null, "Explicit unregister")
	second.free()
	_expect(Registry.record_key(&"id", path) != Registry.record_key(&"path", path), "ID and path namespaces distinct")
	_expect(Registry.record_key(&"id", "").is_empty(), "Empty identity refused")
	_expect(Registry.record_key(&"unknown", "hero").is_empty(), "Unknown identity kind refused")
	_expect(Registry.record_key(&"path", "relative/player").is_empty(), "Legacy paths must be absolute")
	var worker: Thread = Thread.new()
	worker.start(func() -> Error: return registry.register_node(player, &"hero"))
	var worker_result: Variant = worker.wait_to_finish()
	_expect(worker_result == ERR_UNAVAILABLE, "Registration restricted to main thread")
	_expect(registry.get_keys() == ["id:hero", "path:" + str(legacy.get_path())], "Live keys deterministic")
	registry.clear()
	_expect(registry.get_keys().is_empty() and is_instance_valid(player), "Clear releases identities without freeing nodes")
	world.free()
	print("SAVE IDENTITY CHECKS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _expect(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(description)
