extends RefCounted

const Versions: GDScript = preload("./save_version_contract.gd")
const Registry: GDScript = preload("./save_object_registry.gd")

class ReadResult extends RefCounted:
	var error: Error = OK
	var message: String = ""
	var data: Dictionary = {}
	var schema_version: int = 1
	var converted_legacy: bool = false

	func _init(code: Error = OK, detail: String = "") -> void:
		error = code
		message = detail

## Converts only the framework record envelope, never game payload schemas.
## Output containers are separate; Resource values remain read-only borrowed
## references until the snapshot owner makes mutable resources exclusive.
static func read(
		snapshot: Dictionary,
		current_schema_version: int = 1,
		legacy_schema_version: int = 1,
		legacy_path_ids: Dictionary[String, StringName] = {},
		) -> ReadResult:
	var checked: Versions.CheckResult = Versions.check(
		snapshot.get("metadata"), current_schema_version, legacy_schema_version)
	if checked.error != OK:
		return ReadResult.new(checked.error, checked.message)
	var node_values: Variant = snapshot.get("nodes", [])
	if not node_values is Array:
		return ReadResult.new(ERR_INVALID_DATA, "Save nodes must be an array.")
	for path: String in legacy_path_ids:
		if Registry.record_key(&"path", path).is_empty() or legacy_path_ids[path].is_empty():
			return ReadResult.new(ERR_INVALID_PARAMETER, "Invalid legacy path-to-ID mapping.")
	var records: Array[Dictionary] = []
	var identities: Dictionary[String, bool] = {}
	var index: int = 0
	for value: Variant in node_values:
		if not value is Dictionary:
			return ReadResult.new(ERR_INVALID_DATA, "Record %d is not a dictionary." % index)
		var record: Dictionary = value
		var kind: StringName = &""
		var identity: String = ""
		var payload: Dictionary = {}
		if checked.format_version == 0:
			var path_value: Variant = record.get("node_path")
			if not path_value is String and not path_value is NodePath and not path_value is StringName:
				return ReadResult.new(ERR_INVALID_DATA, "Record %d has an invalid node_path." % index)
			identity = str(path_value)
			if Registry.record_key(&"path", identity).is_empty():
				return ReadResult.new(ERR_INVALID_DATA, "Record %d needs an absolute node_path." % index)
			kind = &"path"
			if legacy_path_ids.has(identity):
				kind = &"id"
				identity = String(legacy_path_ids[identity])
			# Keep node_path in the payload for existing game load_data methods.
			payload = record.duplicate(true)
		else:
			var kind_value: Variant = record.get("identity_kind")
			var identity_value: Variant = record.get("identity")
			var payload_value: Variant = record.get("data")
			if not (kind_value is String or kind_value is StringName):
				return ReadResult.new(ERR_INVALID_DATA, "Record %d has an invalid identity kind." % index)
			if not (identity_value is String or identity_value is StringName) or not payload_value is Dictionary:
				return ReadResult.new(ERR_INVALID_DATA, "Record %d has an invalid identity or payload." % index)
			kind = StringName(kind_value)
			identity = String(identity_value)
			payload = payload_value.duplicate(true)
		var key: String = Registry.record_key(kind, identity)
		if key.is_empty():
			return ReadResult.new(ERR_INVALID_DATA, "Record %d has an unsupported or empty identity." % index)
		if identities.has(key):
			return ReadResult.new(ERR_ALREADY_IN_USE, "Duplicate save identity at record %d: %s" % [index, key])
		identities[key] = true
		records.append({"identity_kind": kind, "identity": identity, "data": payload})
		index += 1
	var result: ReadResult = ReadResult.new()
	result.schema_version = checked.schema_version
	result.converted_legacy = checked.format_version == 0
	# The game schema stays at the source version until game migrations succeed.
	result.data = {
		"metadata": Versions.current_metadata(snapshot["metadata"], checked.schema_version),
		"nodes": records,
	}
	return result
