extends RefCounted

const Strategy: GDScript = preload("./save_format_strategy/save_format_strategy.gd")
const Result: GDScript = preload("./save_slot_result.gd")
const Migration: GDScript = preload("./save_migration.gd")
const Records: GDScript = preload("./save_record_contract.gd")
const SnapshotCopy: GDScript = preload("./save_snapshot_copy.gd")

## This owner receives exactly one strategy. No formats or workers are created
## implicitly. Game/node restore is separate from validated file operations.
var migrations: Dictionary[int, Callable] = {}
var legacy_path_ids: Dictionary[String, StringName] = {}
var readonly_resources: Array[Resource] = []
var _directory: String
var _strategy: Strategy
var _schema: int
var _legacy_schema: int
var _current_save_id: String = ""
var _snapshot: Dictionary = {}
var _busy: bool = false
var _closed: bool = false

func _init(directory: String, strategy: Strategy, schema: int = 1, legacy_schema: int = 1) -> void:
	_directory = ProjectSettings.globalize_path(directory).simplify_path()
	_strategy = strategy
	_schema = schema
	_legacy_schema = legacy_schema

func get_current_save_id() -> String:
	return _current_save_id

func get_snapshot() -> SnapshotCopy.CopyResult:
	return SnapshotCopy.copy(_snapshot, readonly_resources)

## A failed write never deletes the old slot. Staging keeps its format extension.
func save_snapshot(save_id: String, snapshot: Dictionary) -> Result:
	var guard: Result = _reserve(save_id)
	if guard != null:
		return guard
	var prepared: Records.ReadResult = _prepare(snapshot)
	if prepared.error != OK:
		return _finish(Result.new(prepared.error, prepared.message, &"validate", save_id))
	prepared.data.metadata["save_id"] = save_id
	var written: Result = await _write(save_id, prepared.data)
	if written.error == OK:
		_current_save_id = save_id
		_snapshot = prepared.data
	return _finish(written)

func load_snapshot(save_id: String, adopt: bool = true) -> Result:
	var guard: Result = _reserve(save_id)
	if guard != null:
		return guard
	var loaded: Result = await _read(save_id)
	if loaded.error == OK and adopt:
		var owned: SnapshotCopy.CopyResult = SnapshotCopy.copy(loaded.data, readonly_resources)
		if owned.error != OK:
			return _finish(Result.new(owned.error, owned.message, &"copy", save_id))
		_current_save_id = save_id
		_snapshot = owned.data
	return _finish(loaded)

## The Node facade prepares every restore payload before adopting this state.
func adopt_snapshot(save_id: String, data: Dictionary) -> Error:
	if _closed or _busy or not Thread.is_main_thread():
		return ERR_UNAVAILABLE
	if not _valid_id(save_id):
		return ERR_INVALID_PARAMETER
	var checked: Records.ReadResult = Records.read(data, _schema, _legacy_schema)
	if checked.error != OK:
		return checked.error
	if checked.converted_legacy or checked.schema_version != _schema:
		return ERR_INVALID_DATA
	var owned: SnapshotCopy.CopyResult = SnapshotCopy.copy(checked.data, readonly_resources)
	if owned.error != OK:
		return owned.error
	_snapshot = owned.data
	_current_save_id = save_id
	return OK

func use_strategy(strategy: Strategy) -> Error:
	if _closed or _busy or not Thread.is_main_thread() or strategy == null:
		return ERR_UNAVAILABLE
	if strategy != _strategy:
		if _strategy != null:
			_strategy.close()
		_strategy = strategy
	return OK

## Upgrade into a different, unused slot. Reading never rewrites the original.
func migrate_slot(source_id: String, destination_id: String) -> Result:
	var guard: Result = _reserve(source_id)
	if guard != null:
		return guard
	if not _valid_id(destination_id) or source_id == destination_id:
		return _finish(Result.new(ERR_INVALID_PARAMETER, "Migration needs a different destination slot.", &"validate", destination_id))
	if FileAccess.file_exists(_path(destination_id)):
		return _finish(Result.new(ERR_ALREADY_EXISTS, "Migration destination already exists.", &"write", destination_id))
	var loaded: Result = await _read(source_id)
	if loaded.error != OK:
		return _finish(loaded)
	loaded.data.metadata["save_id"] = destination_id
	var written: Result = await _write(destination_id, loaded.data)
	# Migration does not change the active slot or its in-memory snapshot.
	return _finish(written)

func delete_slot(save_id: String) -> Result:
	var guard: Result = _reserve(save_id)
	if guard != null:
		return guard
	var path: String = _path(save_id)
	if not FileAccess.file_exists(path):
		return _finish(Result.new(ERR_FILE_NOT_FOUND, "Slot does not exist.", &"delete", save_id))
	if not _strategy.delete_file(path):
		return _finish(Result.new(ERR_FILE_CANT_WRITE, "Slot deletion failed.", &"delete", save_id))
	if _current_save_id == save_id:
		_current_save_id = ""
		_snapshot.clear()
	return _finish(Result.new(OK, "", &"delete", save_id))

func list_slots() -> Result:
	var guard: Result = _reserve("", false)
	if guard != null:
		return guard
	if not DirAccess.dir_exists_absolute(_directory):
		return _finish(Result.new(ERR_FILE_NOT_FOUND, "Save directory does not exist.", &"list"))
	var result: Result = Result.new(OK, "", &"list")
	var files: Array = _strategy.list_files(_directory)
	for file: Variant in files:
		if not file is String:
			return _finish(Result.new(ERR_INVALID_DATA, "Strategy returned an invalid filename.", &"list"))
		var slot: String = _strategy.get_save_id_from_file(file)
		if not _valid_id(slot):
			continue
		var metadata: Dictionary = await _strategy.load_metadata(_path(slot))
		var valid_metadata: bool = not metadata.is_empty()
		if not valid_metadata:
			# Legacy metadata may legitimately be empty. Distinguish that case
			# from the old strategy API's empty-dictionary failure sentinel.
			var snapshot: Dictionary = await _strategy.load_save(_path(slot))
			var fields: Variant = snapshot.get("metadata")
			if fields is Dictionary:
				metadata = fields
				valid_metadata = true
		if _closed:
			return _finish(Result.new(ERR_UNAVAILABLE, "Save owner closed.", &"list"))
		if valid_metadata:
			result.saves.append({"save_id": slot, "metadata": metadata.duplicate(true)})
	result.saves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.metadata.get("timestamp", 0)) > float(b.metadata.get("timestamp", 0)))
	return _finish(result)

func close() -> Error:
	if not Thread.is_main_thread():
		return ERR_UNAVAILABLE
	if not _closed:
		_closed = true
		if _strategy != null:
			_strategy.close()
		_snapshot.clear()
		migrations.clear()
		readonly_resources.clear()
	return OK

func _notification(what: int) -> void:
	# RefCounted is already invalid for self-method calls during PREDELETE.
	# Release the owned strategy directly, on the required main thread.
	if what == NOTIFICATION_PREDELETE and not _closed and Thread.is_main_thread():
		_closed = true
		if _strategy != null:
			_strategy.close()

func _prepare(snapshot: Dictionary) -> Records.ReadResult:
	return Migration.prepare(snapshot, _schema, migrations, _legacy_schema, legacy_path_ids, readonly_resources)

func _read(save_id: String) -> Result:
	var path: String = _path(save_id)
	if not FileAccess.file_exists(path):
		return Result.new(ERR_FILE_NOT_FOUND, "Slot does not exist.", &"read", save_id)
	var data: Dictionary = await _strategy.load_save(path)
	if _closed:
		return Result.new(ERR_UNAVAILABLE, "Save owner closed.", &"read", save_id)
	if data.is_empty():
		return Result.new(ERR_FILE_CORRUPT, "Slot could not be decoded.", &"decode", save_id)
	var prepared: Records.ReadResult = _prepare(data)
	if prepared.error != OK:
		return Result.new(prepared.error, prepared.message, &"validate", save_id)
	var result: Result = Result.new(OK, "", &"read", save_id)
	result.data = prepared.data
	return result

func _write(save_id: String, data: Dictionary) -> Result:
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(_directory)
	if directory_error != OK:
		return Result.new(directory_error, "Save directory could not be created.", &"write", save_id)
	var stage_id: String = ".core_stage_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var stage_path: String = _path(stage_id)
	var success: bool = await _strategy.save(stage_path, data)
	if not success or _closed:
		if FileAccess.file_exists(stage_path):
			_strategy.delete_file(stage_path)
		return Result.new(ERR_UNAVAILABLE if _closed else ERR_FILE_CANT_WRITE, "Staged save failed.", &"write", save_id)
	var committed: Error = DirAccess.rename_absolute(stage_path, _path(save_id))
	if committed != OK:
		_strategy.delete_file(stage_path)
		return Result.new(committed, "Staged save could not replace the slot.", &"commit", save_id)
	return Result.new(OK, "", &"write", save_id)

func _reserve(save_id: String, require_id: bool = true) -> Result:
	if not Thread.is_main_thread() or _closed or _strategy == null:
		return Result.new(ERR_UNAVAILABLE, "Save owner is unavailable.", &"begin", save_id)
	if _busy:
		return Result.new(ERR_BUSY, "Another slot operation is in progress.", &"begin", save_id)
	if require_id and not _valid_id(save_id):
		return Result.new(ERR_INVALID_PARAMETER, "Invalid slot ID.", &"begin", save_id)
	_busy = true
	return null

func _finish(result: Result) -> Result:
	_busy = false
	return result

func _path(save_id: String) -> String:
	return _strategy.get_save_path(_directory, save_id)

func _valid_id(save_id: String) -> bool:
	return not save_id.is_empty() and not save_id.begins_with(".") and save_id.is_valid_filename()
