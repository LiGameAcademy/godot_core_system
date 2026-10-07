extends SceneTree

const Manager: GDScript = preload("../../source/save_system/save_manager.gd")
const Settings: GDScript = preload("../../source/save_system/save_settings.gd")
const Result: GDScript = preload("../../source/save_system/save_slot_result.gd")
const Strategy: GDScript = preload("./failing_resource_strategy.gd")
const Recipient: GDScript = preload("./save_recipient.gd")
const RecipientScene: PackedScene = preload("./save_recipient.tscn")
const ManagerScene: PackedScene = preload("../../source/save_system/save_manager.tscn")
const Probe: GDScript = preload("./restore_probe.gd")
const ProbeScene: PackedScene = preload("./restore_probe.tscn")
var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings: Settings = Settings.new()
	settings.directory = "res://manager-audit"
	settings.auto_save_enabled = false
	var strategy: Strategy = Strategy.new()
	var manager: Manager = Manager.new(settings, strategy)
	root.add_child(manager)
	var world: Node = Node.new()
	world.name = "World"
	root.add_child(world)
	var a: Recipient = RecipientScene.instantiate() as Recipient
	a.save_id = &"hero"
	a.health = 80
	world.add_child(a)
	var b: Recipient = RecipientScene.instantiate() as Recipient
	b.save_id = &"enemy"
	b.health = 20
	world.add_child(b)
	_expect(manager.register_saveable_node(a, a.save_id) == OK and manager.register_saveable_node(b, b.save_id) == OK, "Explicit recipients registered")
	_expect(await manager.create_save("alpha"), "Legacy bool create API works without CoreSystem")
	a.health = 1
	b.health = 2
	world.name = "Level"
	var result: Result = await manager.load_save_result("alpha")
	_expect(result.error == OK and a.health == 80 and b.health == 20, "Stable IDs restore after scene rename")
	_expect(result.applied_count == 2 and result.pending_count == 0, "Applied and pending counts reported")
	a.payload.entries[0].items.append(3)
	_expect(b.payload.entries[0].items == [1, 2], "Restored object resources independent")
	manager.unregister_saveable_node(a)
	manager.unregister_saveable_node(b)
	var directory: String = settings.directory
	var pending_a: Dictionary = {"metadata": {}, "nodes": [{"node_path": "/root/Old/A", "health": 10}]}
	var pending_b: Dictionary = {"metadata": {}, "nodes": [{"node_path": "/root/Old/B", "health": 30}]}
	manager.legacy_path_ids["/root/Old/A"] = &"late-A"
	manager.legacy_path_ids["/root/Old/B"] = &"late-B"
	_expect(strategy.save(strategy.get_save_path(directory, "pending-a"), pending_a) and strategy.save(strategy.get_save_path(directory, "pending-b"), pending_b), "Legacy pending fixtures saved")
	result = await manager.load_save_result("pending-a")
	_expect(result.error == OK and result.pending_identities == ["id:late-A"], "Missing object recorded")
	result = await manager.load_save_result("pending-b")
	_expect(result.error == OK and manager.get_pending_identities() == ["id:late-B"], "Switch replaces old pending cache")
	var future: Dictionary = {"metadata": {"save_format_version": 2, "game_schema_version": 1}, "nodes": []}
	strategy.save(strategy.get_save_path(directory, "future"), future)
	result = await manager.load_save_result("future")
	_expect(result.error == ERR_UNAVAILABLE and manager.get_current_save_id() == "pending-b", "Future input preserves current slot")
	_expect(manager.get_pending_identities() == ["id:late-B"], "Failed load preserves pending state")
	_expect(not await manager.load_save("missing") and manager.get_pending_identities() == ["id:late-B"], "Missing load retains pending state")
	_expect(strategy.save(strategy.get_save_path(directory, "empty"), {"metadata": {}, "nodes": []}), "Empty legacy fixture saved")
	_expect(await manager.load_save("empty") and manager.get_pending_identities().is_empty(), "Successful empty load replaces pending state")
	_expect(await manager.load_save("pending-b"), "Pending B restored for failed write check")
	strategy.fail_write = true
	_expect(not await manager.create_save("failed"), "Failed write reported through old bool API")
	_expect(manager.get_pending_identities() == ["id:late-B"] and manager.get_current_save_id() == "pending-b", "Failed write preserves pending and current slot")
	strategy.fail_write = false
	_expect(await manager.create_save("retained"), "Save while object absent succeeds")
	_expect(await manager.load_save("retained") and manager.get_pending_identities() == ["id:late-B"], "Absent object included in new slot")
	var late: Recipient = RecipientScene.instantiate() as Recipient
	world.add_child(late)
	_expect(manager.register_saveable_node(late, &"late-B") == OK and late.health == 30, "Late registration consumes pending once")
	_expect(manager.register_saveable_node(late, &"late-B") == OK and late.load_count == 1 and manager.get_pending_identities().is_empty(), "Repeated registration does not replay state")
	_expect(manager.register_saveable_node(b, &"late-B") == ERR_ALREADY_IN_USE, "Duplicate stable ID rejected")
	_expect(await manager.load_save("pending-a"), "New successful load")
	_expect(manager.delete_save("pending-a") and manager.get_pending_identities().is_empty(), "Deleting current slot clears pending")
	manager.unregister_saveable_node(late)
	manager.scene_scope = world
	a.add_to_group(&"saveable")
	b.add_to_group(&"saveable")
	_expect(await manager.create_save("scoped"), "Explicit scope collects historical group")
	a.health = 0
	b.health = 0
	var reentrant_codes: Array[Error] = []
	a.after_load = func() -> void: reentrant_codes.append(manager.register_saveable_node(late, &"late-C"))
	result = await manager.load_save_result("scoped")
	_expect(result.error == OK and a.health == 80 and b.health == 20, "Scoped group loads normally")
	_expect(reentrant_codes == [ERR_BUSY], "Game callbacks cannot reenter registration during commit")
	a.after_load = Callable()
	var listed: Array[Dictionary] = await manager.get_save_list()
	_expect(listed.size() == 6, "Old list API preserves slot metadata including empty metadata")
	_expect(not (await manager.create_auto_save()).is_empty(), "Explicit auto-save API works")
	for index: int in range(3):
		_expect(not (await manager.create_auto_save()).is_empty(), "Repeated auto-save succeeds")
	listed = await manager.get_save_list()
	var auto_count: int = 0
	for item: Dictionary in listed:
		if String(item.save_id).begins_with("auto_"):
			auto_count += 1
	_expect(auto_count == 3, "Auto-save retention respects configured limit")
	_expect(manager.save_directory == directory and manager.max_auto_saves == 3, "Legacy configuration accessors retained")
	_expect(settings.directory == directory and settings.format == &"resource", "Settings template retained")
	manager.scene_scope = null
	manager.legacy_path_ids["/root/Old/Only"] = &"only"
	strategy.save(strategy.get_save_path(directory, "only"), {"metadata": {}, "nodes": [{"node_path": "/root/Old/Only", "marker": "restored"}]})
	_expect(await manager.load_save("only"), "Load-only recipient fixture loaded")
	var probe: Probe = ProbeScene.instantiate() as Probe
	world.add_child(probe)
	_expect(manager.register_saveable_node(probe, &"only") == OK and probe.marker == "restored", "Historical load-only recipient still supported")
	_expect(manager.set_save_format(&"json") == ERR_UNAVAILABLE and manager.default_format == &"resource", "Uninstalled format fails without replacing current strategy")
	var replacement: Strategy = Strategy.new()
	_expect(manager.register_save_format_strategy(&"resource", replacement) == OK and manager.set_save_format(&"resource") == OK, "Custom replacement of active format can be selected")
	_expect(strategy.close_calls == 1 and manager.get_current_save_id() == "only", "Format replacement closes old strategy and retains slot state")
	_expect(manager.close() == OK and strategy.close_calls == 1, "Manager closes selected strategy once")
	_expect(replacement.close_calls == 1, "Replacement strategy closed exactly once")
	_expect(not await manager.load_save("scoped"), "Closed manager rejects work")
	manager.free()
	world.free()
	var standalone: Manager = ManagerScene.instantiate() as Manager
	standalone.storage_settings = settings
	root.add_child(standalone)
	_expect(await standalone.create_save("default-strategy"), "Reusable scene lazily creates only Resource strategy")
	standalone.free()
	for file: String in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
	print("SAVE MANAGER CHECKS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _expect(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(description)
