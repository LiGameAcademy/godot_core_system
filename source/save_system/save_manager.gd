extends Node

const GameStateData: GDScript = preload("./game_state_data.gd")
const SaveFormatStrategy: GDScript = preload("./save_format_strategy/save_format_strategy.gd")
const Settings: GDScript = preload("./save_settings.gd")
const Slots: GDScript = preload("./save_slots.gd")
const Result: GDScript = preload("./save_slot_result.gd")
const Restore: GDScript = preload("./save_restore_state.gd")
const Versions: GDScript = preload("./save_version_contract.gd")

signal save_created(save_id: String, metadata: Dictionary)
signal save_loaded(save_id: String, metadata: Dictionary)
signal save_deleted(save_id: String)
signal auto_save_started()
signal auto_save_succeeded(save_id: String)
signal auto_save_failed()
signal operation_finished(result: Result)

@export var storage_settings: Settings = Settings.new()
## Optional group compatibility scope, explicitly supplied by the scene owner.
@export var scene_scope: Node
var migrations: Dictionary[int, Callable] = {}
var legacy_path_ids: Dictionary[String, StringName] = {}
var readonly_resources: Array[Resource] = []
## Optional owner-supplied legacy key source, consulted only for Binary.
var encryption_key_provider: Callable = Callable()
var _slots: Slots
var _restore: Restore = Restore.new()
var _custom_strategies: Dictionary[StringName, SaveFormatStrategy] = {}
var _selected_strategy: SaveFormatStrategy
var _settings: Settings
var _busy: bool = false
var _closed: bool = false
var _auto_save_timer: float = 0.0
var _generated_sequence: int = 0

## Historical read-only accessors; configure storage_settings before first use.
var save_directory: String:
	get:
		return _active_settings().directory
var save_group: StringName:
	get:
		return _active_settings().group
var default_format: StringName:
	get:
		return _active_settings().format
var auto_save_enabled: bool:
	get:
		return _active_settings().auto_save_enabled
var auto_save_interval: float:
	get:
		return _active_settings().auto_save_interval
var auto_save_prefix: String:
	get:
		return _active_settings().auto_save_prefix
var max_auto_saves: int:
	get:
		return _active_settings().max_auto_saves

func _init(settings: Settings = null, strategy: SaveFormatStrategy = null) -> void:
	if settings != null:
		storage_settings = settings
	_selected_strategy = strategy

func _process(delta: float) -> void:
	if _slots == null or _closed or _busy or not _settings.auto_save_enabled or get_current_save_id().is_empty():
		return
	_auto_save_timer += delta
	if _auto_save_timer >= _settings.auto_save_interval:
		_auto_save_timer = 0.0
		create_auto_save()

func _exit_tree() -> void:
	close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		close()

func register_saveable_node(node: Node, save_id: StringName = &"") -> Error:
	if _busy:
		return ERR_BUSY
	if _closed or not Thread.is_main_thread():
		return ERR_UNAVAILABLE
	return _restore.register_node(node, save_id)

func unregister_saveable_node(node: Node) -> void:
	_restore.unregister_node(node)

func get_pending_identities() -> Array[String]:
	return _restore.get_pending_identities()

func clear_pending_states() -> Error:
	if _busy:
		return ERR_BUSY
	_restore.clear_pending()
	return OK

func get_current_save_id() -> String:
	return _slots.get_current_save_id() if _slots != null else ""

func create_save(save_id: String = "") -> bool:
	var result: Result = await create_save_result(save_id)
	return result.error == OK

func create_save_result(save_id: String = "") -> Result:
	var actual_id: String = _generated_id("save_") if save_id.is_empty() else save_id
	var guard: Result = _begin(actual_id)
	if guard != null:
		return guard
	var registration_error: Error = refresh_scene_registration()
	if registration_error != OK:
		return _complete(Result.new(registration_error, "Scene registration failed.", &"capture", actual_id))
	var metadata: Dictionary = Versions.current_metadata({
		"save_id": actual_id, "timestamp": Time.get_unix_time_from_system(),
		"save_date": Time.get_datetime_string_from_system(), "game_version": _settings.game_version,
		"playtime": 0.0,
	}, _settings.schema_version)
	var captured: Result = _restore.capture(metadata)
	if captured.error != OK:
		return _complete(captured)
	var prepared: Restore.Prepared = _restore.prepare(captured.data)
	if prepared.error != OK:
		return _complete(Result.new(prepared.error, prepared.message, &"capture", actual_id))
	var result: Result = await _slots.save_snapshot(actual_id, captured.data)
	if result.error == OK and not _closed:
		_restore.retain_unmatched(prepared)
		save_created.emit(actual_id, metadata.duplicate(true))
	return _complete(result)

func load_save(save_id: String) -> bool:
	var result: Result = await load_save_result(save_id)
	return result.error == OK

func load_save_result(save_id: String) -> Result:
	var guard: Result = _begin(save_id)
	if guard != null:
		return guard
	var result: Result = await _slots.load_snapshot(save_id, false)
	if result.error != OK:
		return _complete(result)
	var prepared: Restore.Prepared = _restore.prepare(result.data)
	if prepared.error != OK:
		return _complete(Result.new(prepared.error, prepared.message, &"restore", save_id))
	var registration_error: Error = refresh_scene_registration()
	if registration_error != OK:
		return _complete(Result.new(registration_error, "Scene registration failed.", &"restore", save_id))
	var adopted: Error = _slots.adopt_snapshot(save_id, result.data)
	if adopted != OK:
		return _complete(Result.new(adopted, "Snapshot adoption failed.", &"restore", save_id))
	_restore.commit(prepared, result)
	if _closed:
		return _complete(Result.new(ERR_UNAVAILABLE, "Save manager closed during game restore.", &"restore", save_id))
	save_loaded.emit(save_id, result.data.metadata.duplicate(true))
	return _complete(result)

func delete_save(save_id: String) -> bool:
	var result: Result = delete_save_result(save_id)
	return result.error == OK

func delete_save_result(save_id: String) -> Result:
	var guard: Result = _begin(save_id)
	if guard != null:
		return guard
	var was_current: bool = get_current_save_id() == save_id
	var result: Result = _slots.delete_slot(save_id)
	if result.error == OK:
		if was_current:
			_restore.clear_pending()
		save_deleted.emit(save_id)
	return _complete(result)

func get_save_list() -> Array[Dictionary]:
	var result: Result = await get_save_list_result()
	return result.saves

func get_save_list_result() -> Result:
	var guard: Result = _begin("")
	if guard != null:
		return guard
	var result: Result = await _slots.list_slots()
	return _complete(result)

func migrate_save(source_id: String, destination_id: String) -> Result:
	var guard: Result = _begin(source_id)
	if guard != null:
		return guard
	var result: Result = await _slots.migrate_slot(source_id, destination_id)
	return _complete(result)

func create_auto_save() -> String:
	if _busy or _closed or _ensure_slots() != OK:
		return ""
	auto_save_started.emit()
	var save_id: String = _generated_id(_settings.auto_save_prefix)
	if not await create_save(save_id):
		auto_save_failed.emit()
		return ""
	var listed: Result = await get_save_list_result()
	if listed.error != OK:
		auto_save_failed.emit()
		return ""
	var retained: int = 0
	for item: Dictionary in listed.saves:
		var slot: String = item.save_id
		if slot.begins_with(_settings.auto_save_prefix):
			retained += 1
			if retained > _settings.max_auto_saves and not delete_save(slot):
				auto_save_failed.emit()
				return ""
	auto_save_succeeded.emit(save_id)
	return save_id

func set_save_format(format: StringName) -> Error:
	if _busy or _closed:
		return ERR_BUSY if _busy else ERR_UNAVAILABLE
	if _slots == null:
		storage_settings = storage_settings.duplicate() as Settings
		storage_settings.format = format
		return _ensure_slots()
	if format == _settings.format and not _custom_strategies.has(format):
		return OK
	var strategy: SaveFormatStrategy = _make_strategy(format)
	if strategy == null:
		return ERR_UNAVAILABLE
	var error: Error = _slots.use_strategy(strategy)
	if error == OK:
		_selected_strategy = strategy
		_settings.format = format
	return error

func register_save_format_strategy(format: StringName, strategy: SaveFormatStrategy) -> Error:
	if _closed or _busy or strategy == null or _custom_strategies.has(format) or strategy == _selected_strategy or _custom_strategies.values().has(strategy):
		return ERR_ALREADY_IN_USE
	_custom_strategies[format] = strategy
	return OK

func refresh_scene_registration() -> Error:
	if _settings == null:
		var error: Error = _ensure_slots()
		if error != OK:
			return error
	if not is_instance_valid(scene_scope):
		return OK
	return _register_scope(scene_scope)

func close() -> Error:
	if not Thread.is_main_thread():
		return ERR_UNAVAILABLE
	if not _closed:
		_closed = true
		if _slots != null:
			_slots.close()
		elif _selected_strategy != null:
			_selected_strategy.close()
		for strategy: SaveFormatStrategy in _custom_strategies.values():
			strategy.close()
		_custom_strategies.clear()
		_restore.clear()
		migrations.clear()
		readonly_resources.clear()
		encryption_key_provider = Callable()
		set_process(false)
	return OK

func _ensure_slots() -> Error:
	if _closed:
		return ERR_UNAVAILABLE
	if _slots == null:
		_settings = storage_settings.duplicate() as Settings
		if _settings.schema_version < 1 or _settings.legacy_schema_version < 1 or _settings.directory.is_empty() or _settings.max_auto_saves < 1 or _settings.auto_save_interval <= 0.0:
			return ERR_INVALID_PARAMETER
		if _selected_strategy == null:
			_selected_strategy = _make_strategy(_settings.format)
		if _selected_strategy == null:
			return ERR_UNAVAILABLE
		_slots = Slots.new(_settings.directory, _selected_strategy, _settings.schema_version, _settings.legacy_schema_version)
	_slots.migrations = migrations
	_slots.legacy_path_ids = legacy_path_ids
	_slots.readonly_resources = readonly_resources
	_restore.readonly_resources = readonly_resources
	return OK

func _make_strategy(format: StringName) -> SaveFormatStrategy:
	var path: String = ""
	if not _custom_strategies.has(format):
		if format != &"resource" and format != &"json" and format != &"binary":
			return null
		path = get_script().resource_path.get_base_dir().path_join("save_format_strategy/%s_save_strategy.gd" % format)
		if not ResourceLoader.exists(path):
			return null
	if format == &"binary" and _settings.encryption_key.is_empty():
		if not encryption_key_provider.is_valid():
			return null
		var key: Variant = encryption_key_provider.call()
		if not key is String or key.is_empty():
			return null
		_settings.encryption_key = key
	var strategy: SaveFormatStrategy
	if _custom_strategies.has(format):
		strategy = _custom_strategies[format]
		_custom_strategies.erase(format)
	elif format == &"resource" or format == &"json" or format == &"binary":
		var script: GDScript = load(path) as GDScript
		strategy = script.new() as SaveFormatStrategy if script != null else null
	if strategy != null and strategy.has_method("set_encryption_key"):
		strategy.call("set_encryption_key", _settings.encryption_key)
	return strategy

func _register_scope(node: Node) -> Error:
	if node.is_in_group(_settings.group):
		var save_id: StringName = &""
		for descriptor: Dictionary in node.get_property_list():
			if descriptor.name == "save_id":
				var value: Variant = node.get("save_id")
				if not value is String and not value is StringName:
					return ERR_INVALID_DATA
				save_id = StringName(value)
		var error: Error = _restore.register_node(node, save_id, false)
		if error != OK:
			return error
	for child: Node in node.get_children():
		var error: Error = _register_scope(child)
		if error != OK:
			return error
	return OK

func _begin(save_id: String) -> Result:
	if _busy or not Thread.is_main_thread():
		return Result.new(ERR_BUSY if _busy else ERR_UNAVAILABLE, "Save manager is unavailable.", &"begin", save_id)
	_busy = true
	var error: Error = _ensure_slots()
	if error != OK:
		_busy = false
		return Result.new(error, "Save module configuration is unavailable.", &"begin", save_id)
	return null

func _complete(result: Result) -> Result:
	_busy = false
	operation_finished.emit(result)
	return result

func _generated_id(prefix: String) -> String:
	_generated_sequence += 1
	return "%s%d_%d_%d" % [prefix, int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), _generated_sequence]

func _active_settings() -> Settings:
	return _settings if _settings != null else storage_settings
