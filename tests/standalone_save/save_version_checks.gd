extends SceneTree

const Contract: GDScript = preload("../../source/save_system/save_version_contract.gd")

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	var legacy: Dictionary = {"game_version": "99.0", "save_id": "old"}
	var before: Dictionary = legacy.duplicate(true)
	var result: Contract.CheckResult = Contract.check(legacy)
	_expect(result.error == OK and result.format_version == 0, "Unversioned legacy accepted")
	_expect(result.schema_version == 1, "Default legacy game schema")
	_expect(legacy == before, "Inspection preserves original metadata")
	result = Contract.check(legacy, 7, 3)
	_expect(result.error == OK and result.schema_version == 3, "Explicit legacy schema")
	_expect(Contract.check(legacy, 2, 3).error == ERR_UNAVAILABLE, "Future legacy schema refused")
	_expect(Contract.check([], 1).error == ERR_INVALID_DATA, "Metadata shape checked")
	_expect(Contract.check({}, 0).error == ERR_INVALID_PARAMETER, "Current schema configuration checked")
	_expect(Contract.check({}, 1, 0).error == ERR_INVALID_PARAMETER, "Legacy schema configuration checked")
	var valid: Dictionary = {"save_format_version": 1, "game_schema_version": 4}
	result = Contract.check(valid, 4)
	_expect(result.error == OK and result.format_version == 1, "Current format accepted")
	_expect(result.schema_version == 4, "Game schema independent of framework format")
	_expect(Contract.check(valid, 3).error == ERR_UNAVAILABLE, "Future game schema refused")
	_expect(Contract.check({"save_format_version": 2, "game_schema_version": 1}).error == ERR_UNAVAILABLE, "Future framework format refused")
	_expect(Contract.check({"save_format_version": 1}).error == ERR_INVALID_DATA, "Versioned save needs game schema")
	var invalid_values: Array[Variant] = [0, -1, true, "1", null, [], {}, 1.5, INF, NAN, 1e30]
	for value: Variant in invalid_values:
		var malformed: Dictionary = {"save_format_version": value, "game_schema_version": 1}
		_expect(Contract.check(malformed).error == ERR_INVALID_DATA, "Invalid format value: %s" % str(value))
		malformed = {"save_format_version": 1, "game_schema_version": value}
		_expect(Contract.check(malformed).error == ERR_INVALID_DATA, "Invalid schema value: %s" % str(value))
	var json_value: Variant = JSON.parse_string('{"save_format_version":1,"game_schema_version":4}')
	_expect(Contract.check(json_value, 4).error == OK, "Actual JSON integer floats supported")
	result = Contract.check({"game_schema_version": 2}, 3)
	_expect(result.error == OK and result.format_version == 0 and result.schema_version == 2, "Legacy format may declare game schema")
	var migrated_metadata: Dictionary = Contract.current_metadata(legacy, 4)
	_expect(migrated_metadata["save_format_version"] == 1 and migrated_metadata["game_schema_version"] == 4, "Current snapshot metadata stamped")
	_expect(migrated_metadata["save_id"] == "old" and migrated_metadata["game_version"] == "99.0", "Other metadata retained")
	_expect(legacy == before, "Stamping does not mutate source")
	_expect(Contract.current_metadata(legacy, 0).is_empty(), "Invalid new schema rejected")
	# A compatibility check is not a migration: the caller must still convert
	# records and provide every game migration before applying older data.
	_expect(Contract.check(valid, 5).error == OK, "Older schema passes preflight only")
	print("SAVE VERSION CHECKS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _expect(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(description)
