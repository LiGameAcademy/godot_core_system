extends SceneTree

const Config: Script = preload("../../source/config_system/config_manager.gd")
const LogScript: Script = preload("../../source/logger/core_logger.gd")
var _checks: int = 0
var _failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var folder: String = "user://independent_config_" + str(Time.get_ticks_usec())
	var reports: Array[String] = []
	var report: Callable = func(message: String) -> void: reports.append(message)
	var a: Node = Config.new(folder + "/a.cfg", report)
	var b: Node = Config.new(folder + "/b.cfg", report)
	root.add_child(a)
	root.add_child(b)
	_check(root.get_node_or_null("CoreSystem") == null, "No AutoLoad installed")
	_check(a.last_error == OK and a.get_value("game", "speed", 2) == 2, "Missing file uses caller defaults")
	a.set_value("game", "speed", 4)
	_check(a.is_modified() and b.get_value("game", "speed", 2) == 2, "Independent states")
	_check(a.save_config() and not a.is_modified(), "Explicit save commits clean state")
	var template: Node = Config.new()
	template.config_path = folder + "/a.cfg"
	var scene: PackedScene = PackedScene.new()
	_check(scene.pack(template) == OK, "Configuration node packs with an exported path")
	template.free()
	var configured: Node = scene.instantiate()
	root.add_child(configured)
	_check(configured.get_value("game", "speed", 0) == 4, "Serialized path is applied before initial load")
	configured.free()
	a.set_value("game", "speed", 4)
	_check(not a.is_modified(), "Equal update retains clean state")
	_check(b.load_config(folder + "/a.cfg") and b.get_value("game", "speed", 0) == 4, "Independent reader loads persisted data")
	a.set_section("game", {"nested": {"items": [1, 2]}})
	var snapshot: Dictionary = a.get_section("game")
	snapshot["nested"]["items"][0] = 8
	_check(a.get_value("game", "nested", {})["items"][0] == 1, "Section snapshot isolates nested values")
	_check(a.has_key("game", "speed"), "Section update preserves omitted keys")
	var blocker: FileAccess = FileAccess.open(folder + "/blocker", FileAccess.WRITE)
	blocker.store_string("not a directory")
	blocker.close()
	_check(not a.save_config(folder + "/blocker/out.cfg") and a.last_error != OK, "Save failure exposes IO result without logger")
	_check(a.is_modified() and a.get_value("game", "speed", 0) == 4 and reports.size() == 1, "Save failure retains state and reports once")
	var corrupt: FileAccess = FileAccess.open(folder + "/corrupt.cfg", FileAccess.WRITE)
	corrupt.store_string("[invalid")
	corrupt.close()
	_check(not a.load_config(folder + "/corrupt.cfg") and a.is_modified(), "Failed load retains dirty state")
	_check(a.get_value("game", "speed", 0) == 4 and reports.size() == 2, "Failed load retains values and reports once")
	_check(a.save_config(), "Recovery save succeeds")
	a.reset_config()
	_check(a.is_modified() and not a.has_section("game"), "Reset clears only local state")
	_check(b.get_value("game", "speed", 0) == 4, "Reset A preserves B")
	root.remove_child(b)
	root.add_child(b)
	_check(b.get_value("game", "speed", 0) == 4, "Detach and reattach preserve local state")
	var logger: Node = LogScript.new()
	root.add_child(logger)
	logger.set_level(LogScript.LogLevel.ERROR)
	logger.set_file_path(folder + "/logs/check.log")
	logger.enable_file_logging(true)
	_check(logger.last_file_error == OK, "Logger creates explicit nested path without setting.gd")
	logger.info("filtered")
	logger.set_level(LogScript.LogLevel.INFO)
	logger.info("persisted")
	logger.enable_file_logging(false)
	var log_text: String = FileAccess.get_file_as_string(folder + "/logs/check.log")
	_check(log_text.contains("persisted") and not log_text.contains("filtered"), "Filtering and close flush the log")
	logger.free()
	a.free()
	b.free()
	for file: String in ["a.cfg", "blocker", "corrupt.cfg", "logs/check.log"]:
		DirAccess.remove_absolute(folder + "/" + file)
	DirAccess.remove_absolute(folder + "/logs")
	DirAccess.remove_absolute(folder)
	print("PASS: %d independent config/logger checks" % _checks)
	quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
