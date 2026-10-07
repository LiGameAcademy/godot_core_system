extends SceneTree

const Adapter: GDScript = preload("../../source/save_system/save_legacy_adapter.gd")
const Manager: GDScript = preload("../../source/save_system/save_manager.gd")
const Config: GDScript = preload("./key_config_probe.gd")
const ConfigScene: PackedScene = preload("./key_config_probe.tscn")
var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	var config: Config = ConfigScene.instantiate() as Config
	config.key = "original-old-key"
	_expect(Adapter.get_encryption_key(config) == "original-old-key" and config.writes == 0, "Existing key reused without rewrite")
	config.key = ""
	config.fail_save = true
	_expect(Adapter.get_encryption_key(config).is_empty() and config.key.is_empty(), "Failed key persistence does not leave usable cached key")
	config.fail_save = false
	var key: String = Adapter.get_encryption_key(config)
	_expect(key.length() == 32, "New key generated only when explicitly requested")
	var disk: ConfigFile = ConfigFile.new()
	_expect(disk.load(config.path) == OK and disk.get_value("save_system", "encryption_key") == key, "New key persisted to real configuration file")
	var writes: int = config.writes
	_expect(Adapter.get_encryption_key(config) == key and config.writes == writes, "Subsequent key read stable")
	_expect(Adapter.get_encryption_key(null).is_empty(), "Missing configuration source fails explicitly")
	var manager: Manager = Manager.new()
	var scope: Node = Node.new()
	ProjectSettings.set_setting("godot_core_system/save_system/save_directory", "res://legacy-saves")
	ProjectSettings.set_setting("godot_core_system/save_system/defaults/serialization_format", "")
	ProjectSettings.set_setting("godot_core_system/save_system/auto_save/max_saves", 5)
	_expect(Adapter.configure(manager, scope) == OK, "Legacy composition configures independent module")
	_expect(manager.save_directory == "res://legacy-saves" and manager.default_format == &"resource" and manager.max_auto_saves == 5, "Old settings and empty default format mapped")
	_expect(manager.scene_scope == scope, "Scope explicitly injected")
	_expect(config.writes == writes, "Resource composition never requests or rewrites key")
	manager.free()
	scope.free()
	DirAccess.remove_absolute(config.path)
	config.free()
	print("SAVE LEGACY ADAPTER CHECKS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _expect(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(description)
