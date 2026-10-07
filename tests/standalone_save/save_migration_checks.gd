extends SceneTree

const Migration: GDScript = preload("../../source/save_system/save_migration.gd")
const Records: GDScript = preload("../../source/save_system/save_record_contract.gd")
const Payload: GDScript = preload("./mutable_payload.gd")
var _passed: int = 0
var _failed: int = 0
var _calls: int = 0

func _initialize() -> void:
	var resource: Payload = Payload.new()
	var legacy: Dictionary = {"metadata": {}, "nodes": [{"node_path": "/root/World/Player", "health": 10, "resource": resource}]}
	var chain: Dictionary[int, Callable] = {1: _first, 2: _second}
	var result: Records.ReadResult = Migration.prepare(legacy, 3, chain)
	_expect(result.error == OK and result.schema_version == 3, "Complete two-step migration succeeds")
	_expect(_calls == 2 and result.data.nodes[0].data.health == 30, "Callbacks run in version order")
	_expect(result.data.nodes[0].data.resource.entries[0].items == [1, 2, 3], "Migration receives mutable resource copy")
	_expect(resource.entries[0].items == [1, 2] and legacy.nodes[0].health == 10, "Original resource and payload unchanged")
	_expect(result.data.metadata.game_schema_version == 3 and result.data.metadata.save_format_version == 1, "Final versions stamped")
	_calls = 0
	chain.erase(2)
	result = Migration.prepare(legacy, 3, chain)
	_expect(result.error == ERR_UNAVAILABLE and _calls == 0 and result.data.is_empty(), "Whole chain checked before any callback")
	chain[2] = func(_data: Dictionary) -> Variant: return null
	result = Migration.prepare(legacy, 3, chain)
	_expect(result.error == ERR_INVALID_DATA and result.data.is_empty(), "Mid-chain failure has no partial output")
	_expect(resource.entries[0].items == [1, 2] and legacy.nodes[0].health == 10, "Failed migration preserves original")
	chain[2] = func(data: Dictionary) -> Dictionary:
		data.nodes.append(data.nodes[0].duplicate(true))
		return data
	_expect(Migration.prepare(legacy, 3, chain).error == ERR_ALREADY_IN_USE, "Migration output identities revalidated")
	chain[2] = func(data: Dictionary) -> Dictionary:
		data.metadata.game_schema_version = 9
		return data
	_expect(Migration.prepare(legacy, 3, chain).error == ERR_UNAVAILABLE, "Unexpected future output refused")
	_calls = 0
	var future: Dictionary = {"metadata": {"save_format_version": 2, "game_schema_version": 1}, "nodes": []}
	_expect(Migration.prepare(future, 3, chain).error == ERR_UNAVAILABLE and _calls == 0, "Future input rejected before callback")
	var no_migration: Records.ReadResult = Migration.prepare(legacy, 1)
	_expect(no_migration.error == OK and no_migration.data.nodes[0].data.resource != resource, "Same-schema restore still owns resources")
	print("SAVE MIGRATION CHECKS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _first(data: Dictionary) -> Dictionary:
	_calls += 1
	data.nodes[0].data.health += 5
	data.nodes[0].data.resource.entries[0].items.append(3)
	return data

func _second(data: Dictionary) -> Dictionary:
	_calls += 1
	data.nodes[0].data.health *= 2
	return data

func _expect(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(description)
