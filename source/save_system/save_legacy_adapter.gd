extends RefCounted

const Manager: GDScript = preload("./save_manager.gd")
const Settings: GDScript = preload("./save_settings.gd")

## Only the optional composition root reads historical global preferences.
## The save module receives concrete configuration, scope and an existing key.
static func configure(manager: Manager, scope: Node) -> Error:
	var settings: Settings = Settings.new()
	var prefix: String = "godot_core_system/save_system/"
	settings.directory = str(ProjectSettings.get_setting(prefix + "save_directory", settings.directory))
	settings.group = StringName(ProjectSettings.get_setting(prefix + "save_group", settings.group))
	var format: String = str(ProjectSettings.get_setting(prefix + "defaults/serialization_format", "resource"))
	settings.format = StringName(format if not format.is_empty() else "resource")
	settings.auto_save_enabled = bool(ProjectSettings.get_setting(prefix + "auto_save/enabled", settings.auto_save_enabled))
	settings.auto_save_interval = float(ProjectSettings.get_setting(prefix + "auto_save/interval_seconds", settings.auto_save_interval))
	settings.auto_save_prefix = str(ProjectSettings.get_setting(prefix + "auto_save/name_prefix", settings.auto_save_prefix))
	settings.max_auto_saves = int(ProjectSettings.get_setting(prefix + "auto_save/max_saves", settings.max_auto_saves))
	settings.game_version = str(ProjectSettings.get_setting("application/config/version", settings.game_version))
	manager.storage_settings = settings
	manager.scene_scope = scope
	return OK

static func get_encryption_key(config: Node) -> String:
	if config == null or not config.has_method("get_value") or not config.has_method("set_value") or not config.has_method("save_config"):
		return ""
	var key: Variant = config.call("get_value", "save_system", "encryption_key", "")
	if not key is String:
		return ""
	if not key.is_empty():
		return key
	var generated: String = Crypto.new().generate_random_bytes(16).hex_encode()
	if generated.is_empty():
		return ""
	config.call("set_value", "save_system", "encryption_key", generated)
	var saved: Variant = config.call("save_config")
	if saved is bool and saved:
		return generated
	# A failed persistence attempt must not leave a seemingly usable cached key.
	config.call("set_value", "save_system", "encryption_key", "")
	return ""
