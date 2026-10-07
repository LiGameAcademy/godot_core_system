extends SceneTree

const Records: GDScript = preload("../../source/save_system/save_record_contract.gd")
var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	var legacy: Dictionary = {"metadata": {"save_id": "old"}, "nodes": [
		{"node_path": NodePath("/root/World/Player"), "health": 80, "inventory": [1, 2]},
		{"node_path": "/root/World/Enemy", "health": 20},
	]}
	var before: Dictionary = legacy.duplicate(true)
	var result: Records.ReadResult = Records.read(legacy)
	_expect(result.error == OK and result.converted_legacy, "Legacy converted")
	_expect(result.data.nodes[0].identity_kind == &"path", "Unmapped legacy retains path")
	_expect(result.data.nodes[0].data.health == 80 and result.data.nodes[0].data.node_path == NodePath("/root/World/Player"), "Legacy payload preserved")
	var aliases: Dictionary[String, StringName] = {"/root/World/Player": &"hero"}
	result = Records.read(legacy, 3, 1, aliases)
	_expect(result.error == OK and result.data.nodes[0].identity == "hero", "Explicit old path mapped to ID")
	_expect(result.data.nodes[1].identity_kind == &"path", "Unmapped objects not guessed")
	_expect(result.schema_version == 1 and result.data.metadata.game_schema_version == 1, "Game schema not prematurely upgraded")
	result.data.nodes[0].data.inventory.append(3)
	_expect(legacy == before, "Converted containers independent of original")
	var bad_aliases: Dictionary[String, StringName] = {"relative": &"hero"}
	_expect(Records.read(legacy, 1, 1, bad_aliases).error == ERR_INVALID_PARAMETER, "Invalid mapping rejected")
	aliases["/root/World/Enemy"] = &"hero"
	result = Records.read(legacy, 1, 1, aliases)
	_expect(result.error == ERR_ALREADY_IN_USE and result.data.is_empty(), "Mapping collision rejects entire snapshot")
	var current: Dictionary = {"metadata": {"save_format_version": 1, "game_schema_version": 1}, "nodes": [
		{"identity_kind": "id", "identity": "hero", "data": {"health": 70}},
		{"identity_kind": "path", "identity": "/root/World/Player", "data": {}},
	]}
	_expect(Records.read(current).error == OK and not Records.read(current).converted_legacy, "Current records accepted")
	current.nodes.append(current.nodes[0].duplicate(true))
	result = Records.read(current)
	_expect(result.error == ERR_ALREADY_IN_USE and result.message.contains("record 2"), "Duplicate identifies conflict index")
	current.nodes.pop_back()
	current.nodes[0].identity = ""
	_expect(Records.read(current).error == ERR_INVALID_DATA, "Empty current ID rejected")
	current.nodes[0].identity = "hero"
	current.nodes[0].identity_kind = "unknown"
	_expect(Records.read(current).error == ERR_INVALID_DATA, "Unknown identity kind rejected")
	_expect(Records.read({"metadata": {}, "nodes": [7]}).error == ERR_INVALID_DATA, "Malformed record rejected")
	_expect(Records.read({"metadata": {}, "nodes": {}}).error == ERR_INVALID_DATA, "Malformed nodes rejected")
	_expect(Records.read({"metadata": {}, "nodes": [{"node_path": "relative"}]}).error == ERR_INVALID_DATA, "Relative old path rejected")
	_expect(Records.read({"metadata": {}}).data.nodes.is_empty(), "Valid empty legacy snapshot")
	_expect(Records.read({"metadata": {"save_format_version": 2, "game_schema_version": 1}, "nodes": []}).error == ERR_UNAVAILABLE, "Future format rejected before conversion")
	_expect(legacy == before, "All rejected conversions preserve source")
	print("SAVE RECORD CHECKS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _expect(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(description)
