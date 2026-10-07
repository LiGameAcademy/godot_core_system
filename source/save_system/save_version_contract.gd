extends RefCounted

## Checks compatibility before the caller changes live state or writes files.
## Format 0 means an unversioned legacy snapshot. Conversion is a separate step.
const CURRENT_FORMAT_VERSION: int = 1

class CheckResult extends RefCounted:
	var error: Error = OK
	var message: String = ""
	var format_version: int = 0
	var schema_version: int = 1

	func _init(code: Error = OK, detail: String = "") -> void:
		error = code
		message = detail

## game_version remains display information; it never selects a migration.
static func check(
		metadata: Variant,
		current_schema_version: int = 1,
		legacy_schema_version: int = 1,
		) -> CheckResult:
	if current_schema_version < 1 or legacy_schema_version < 1:
		return CheckResult.new(ERR_INVALID_PARAMETER, "Schema versions must be positive.")
	if not metadata is Dictionary:
		return CheckResult.new(ERR_INVALID_DATA, "Save metadata must be a dictionary.")
	var fields: Dictionary = metadata
	var format_version: int = 0
	var schema_version: int = legacy_schema_version
	if fields.has("save_format_version"):
		format_version = _read_version(fields["save_format_version"])
		if format_version < 1:
			return CheckResult.new(ERR_INVALID_DATA, "Invalid save_format_version.")
	if fields.has("game_schema_version"):
		schema_version = _read_version(fields["game_schema_version"])
		if schema_version < 1:
			return CheckResult.new(ERR_INVALID_DATA, "Invalid game_schema_version.")
	elif format_version > 0:
		return CheckResult.new(ERR_INVALID_DATA, "Versioned saves require game_schema_version.")
	var result: CheckResult = CheckResult.new()
	result.format_version = format_version
	result.schema_version = schema_version
	if format_version > CURRENT_FORMAT_VERSION:
		result.error = ERR_UNAVAILABLE
		result.message = "Unsupported future save format."
	elif schema_version > current_schema_version:
		result.error = ERR_UNAVAILABLE
		result.message = "Unsupported future game schema."
	return result

## Produces metadata for a newly encoded current-format snapshot.
## Call this only after legacy record conversion and any game migrations succeed.
static func current_metadata(metadata: Dictionary, schema_version: int) -> Dictionary:
	if schema_version < 1:
		return {}
	var result: Dictionary = metadata.duplicate(true)
	result["save_format_version"] = CURRENT_FORMAT_VERSION
	result["game_schema_version"] = schema_version
	return result

## JSON numbers decode as floats. Accept exact finite integers, never coerce
## strings, bools, fractional values or overflow into a supported version.
static func _read_version(value: Variant) -> int:
	if value is int:
		return value if value > 0 else -1
	if value is float:
		var number: float = value
		# All practical schema versions fit exactly in both JSON and int64.
		if is_finite(number) and number >= 1.0 and number <= 2147483647.0:
			if floor(number) == number:
				return int(number)
	return -1
