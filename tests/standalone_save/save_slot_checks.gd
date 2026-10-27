extends SceneTree

const Slots: GDScript = preload("../../source/save_system/save_slots.gd")
const Result: GDScript = preload("../../source/save_system/save_slot_result.gd")
const Strategy: GDScript = preload("./failing_resource_strategy.gd")
const Payload: GDScript = preload("./mutable_payload.gd")
var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory: String = "res://slot-audit"
	var strategy: Strategy = Strategy.new()
	var slots: Slots = Slots.new(directory, strategy)
	var template: Payload = Payload.new()
	var snapshot: Dictionary = {"metadata": {"timestamp": 10, "custom": "kept"}, "nodes": [
		{"node_path": "/root/World/Player", "health": 80, "payload": template},
	]}
	var result: Result = await slots.load_snapshot("missing")
	_expect(result.error == ERR_FILE_NOT_FOUND, "Missing slot distinguished")
	result = await slots.save_snapshot("../escape", snapshot)
	_expect(result.error == ERR_INVALID_PARAMETER, "Path traversal slot refused")
	result = await slots.save_snapshot("first", snapshot)
	_expect(result.error == OK and slots.get_current_save_id() == "first", "Independent slot saved")
	var path: String = strategy.get_save_path(directory, "first")
	var first_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	_expect(not first_bytes.is_empty(), "Real Resource file written")
	result = await slots.load_snapshot("first")
	_expect(result.error == OK and result.data.metadata.custom == "kept", "Custom metadata retained")
	_expect(result.data.metadata.save_format_version == 1 and result.data.metadata.game_schema_version == 1, "Resource strategy preserves version fields")
	var a: Payload = result.data.nodes[0].data.payload
	a.entries[0].items.append(3)
	var owned: Variant = slots.get_snapshot()
	_expect(owned.error == OK and owned.data.nodes[0].data.payload.entries[0].items == [1, 2], "Returned restore resource independent of internal snapshot")
	_expect(template.entries[0].items == [1, 2], "Template independent of disk round trip")
	strategy.fail_write = true
	snapshot.nodes[0].health = 20
	result = await slots.save_snapshot("first", snapshot)
	_expect(result.error == ERR_FILE_CANT_WRITE, "Failed staged write distinguished")
	_expect(FileAccess.get_file_as_bytes(path) == first_bytes, "Failed write preserves original file bytes")
	var leftover_files: PackedStringArray = DirAccess.get_files_at(directory)
	_expect(leftover_files.size() == 1 and leftover_files[0] == "first.tres", "Failed staging file cleaned up")
	_expect(slots.get_snapshot().data.nodes[0].data.health == 80, "Failed write preserves owned snapshot")
	strategy.fail_write = false
	result = await slots.save_snapshot("first", snapshot)
	_expect(result.error == OK and FileAccess.get_file_as_bytes(path) != first_bytes, "Existing slot replaced successfully")
	var future: Dictionary = {"metadata": {"save_format_version": 2, "game_schema_version": 1}, "nodes": []}
	var updated_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	result = await slots.save_snapshot("first", future)
	_expect(result.error == ERR_UNAVAILABLE and FileAccess.get_file_as_bytes(path) == updated_bytes, "Rejected future write preserves existing file")
	_expect(strategy.save(strategy.get_save_path(directory, "future"), future), "Future fixture written with real strategy")
	result = await slots.load_snapshot("future")
	_expect(result.error == ERR_UNAVAILABLE and slots.get_current_save_id() == "first", "Future format refused without active slot change")
	_expect(slots.get_snapshot().data.nodes[0].data.health == 20, "Future read preserves in-memory state")
	var other_resource: Resource = Resource.new()
	ResourceSaver.save(other_resource, strategy.get_save_path(directory, "corrupt"))
	result = await slots.load_snapshot("corrupt")
	_expect(result.error == ERR_FILE_CORRUPT, "Wrong resource type distinguished as corrupt")
	result = await slots.list_slots()
	_expect(result.error == OK and result.saves.size() == 2, "Slots listed without corrupt or staging files")
	var old_path: String = strategy.get_save_path(directory, "old")
	_expect(strategy.save(old_path, snapshot), "Unversioned legacy file fixture")
	var old_bytes: PackedByteArray = FileAccess.get_file_as_bytes(old_path)
	var upgrade_strategy: Strategy = Strategy.new()
	var upgrade: Slots = Slots.new(directory, upgrade_strategy, 2)
	upgrade.migrations[1] = func(data: Dictionary) -> Dictionary:
		data.nodes[0].data.health += 10
		return data
	result = await upgrade.migrate_slot("old", "upgraded")
	_expect(result.error == OK and FileAccess.get_file_as_bytes(old_path) == old_bytes, "Migration creates new slot and preserves original bytes")
	_expect(upgrade.get_current_save_id().is_empty(), "Migration does not change active slot")
	result = await upgrade.load_snapshot("upgraded")
	_expect(result.error == OK and result.data.nodes[0].data.health == 30, "Migrated file loads with new game schema")
	_expect(result.data.metadata.game_schema_version == 2, "Migrated Resource file retains schema")
	result = await upgrade.migrate_slot("old", "upgraded")
	_expect(result.error == ERR_ALREADY_EXISTS, "Migration cannot overwrite destination")
	result = await upgrade.migrate_slot("old", "old")
	_expect(result.error == ERR_INVALID_PARAMETER, "Migration cannot overwrite source")
	result = slots.delete_slot("first")
	_expect(result.error == OK and slots.get_current_save_id().is_empty() and slots.get_snapshot().data.is_empty(), "Deleting active slot clears owned state")
	_expect(slots.delete_slot("first").error == ERR_FILE_NOT_FOUND, "Missing deletion distinguished")
	_expect(slots.close() == OK and slots.close() == OK, "Close idempotent")
	_expect(strategy.close_calls == 1, "Selected strategy closed exactly once")
	result = await slots.load_snapshot("old")
	_expect(result.error == ERR_UNAVAILABLE, "Closed owner rejects new work")
	upgrade.close()
	var final_strategy: Strategy = Strategy.new()
	var orphan: Slots = Slots.new(directory, final_strategy)
	var orphan_ref: WeakRef = weakref(orphan)
	orphan = null
	_expect(orphan_ref.get_ref() == null and final_strategy.close_calls == 1, "Owner destruction closes selected strategy directly")
	for slot: String in ["old", "upgraded", "future", "corrupt"]:
		strategy.delete_file(strategy.get_save_path(directory, slot))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("SAVE SLOT CHECKS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _expect(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(description)
