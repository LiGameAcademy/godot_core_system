extends RefCounted

const Records: GDScript = preload("./save_record_contract.gd")
const Versions: GDScript = preload("./save_version_contract.gd")
const SnapshotCopy: GDScript = preload("./save_snapshot_copy.gd")

## Each vN callback receives an owned current-format snapshot and returns the
## complete snapshot for vN+1, or null to fail. No file or live-node work occurs
## here; callbacks must also avoid external side effects.
static func prepare(
		snapshot: Dictionary,
		current_schema: int,
		migrations: Dictionary[int, Callable] = {},
		legacy_schema: int = 1,
		legacy_path_ids: Dictionary[String, StringName] = {},
		readonly_resources: Array[Resource] = [],
		) -> Records.ReadResult:
	var initial: Records.ReadResult = Records.read(snapshot, current_schema, legacy_schema, legacy_path_ids)
	if initial.error != OK:
		return initial
	# Check the entire chain before running even the first callback.
	for version: int in range(initial.schema_version, current_schema):
		if not migrations.has(version) or not migrations[version].is_valid():
			return Records.ReadResult.new(ERR_UNAVAILABLE, "Missing game migration from schema %d." % version)
	var owned: SnapshotCopy.CopyResult = SnapshotCopy.copy(initial.data, readonly_resources)
	if owned.error != OK:
		return Records.ReadResult.new(owned.error, owned.message)
	var current: Dictionary = owned.data
	for version: int in range(initial.schema_version, current_schema):
		var migrated: Variant = migrations[version].call(current)
		if not migrated is Dictionary:
			return Records.ReadResult.new(ERR_INVALID_DATA, "Game migration from schema %d failed." % version)
		var checked: Records.ReadResult = Records.read(migrated, version + 1)
		if checked.error != OK:
			return checked
		if checked.converted_legacy or checked.schema_version < version:
			return Records.ReadResult.new(ERR_INVALID_DATA, "Migration returned an unexpected source version.")
		# Callbacks may leave the input version or declare the next version.
		# Framework validation happens first, then the successful step is stamped.
		# A callback can return newly introduced resources. Own those too before
		# another callback or the eventual restore can modify them.
		owned = SnapshotCopy.copy(checked.data, readonly_resources)
		if owned.error != OK:
			return Records.ReadResult.new(owned.error, owned.message)
		current = owned.data
		current["metadata"] = Versions.current_metadata(current["metadata"], version + 1)
	var result: Records.ReadResult = Records.ReadResult.new()
	result.data = current
	result.schema_version = current_schema
	result.converted_legacy = initial.converted_legacy
	return result
