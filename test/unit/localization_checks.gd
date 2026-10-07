extends Node

const LocalizationManager = preload("../../source/localization_system/localization_manager.gd")
const LocaleSelection = preload("../../source/localization_system/locale_selection.gd")
const ConfigManager = preload("../../source/config_system/config_manager.gd")
var _translations: Array[Translation] = []
var _changes: Array[Array] = []
var _checks: int = 0
var _failed: bool = false

class FailingConfig extends ConfigManager:
	func save_config(_path: String = "") -> bool:
		return false

func _ready() -> void:
	await get_tree().process_frame
	var original: String = TranslationServer.get_locale()
	var fallback: Variant = ProjectSettings.get_setting("internationalization/locale/fallback", "en")
	ProjectSettings.set_setting("internationalization/locale/fallback", "en")
	for locale: String in ["en_US", "en_GB", "zh_CN", "zh_TW"]:
		var translation: Translation = Translation.new()
		translation.locale = locale
		translation.add_message(&"LOCALE_TEST_GREETING", &"Hello" if locale.begins_with("en") else &"你好")
		TranslationServer.add_translation(translation)
		_translations.append(translation)
	TranslationServer.set_locale("en_US")
	var manager: LocalizationManager = LocalizationManager.new()
	manager.locale_changed.connect(func(old: String, current: String) -> void: _changes.append([old, current]))
	add_child(manager)
	_changes.clear()
	_check(manager.get_available_locales().size() == 4, "Available locales come from loaded resources")
	_check(LocaleSelection.normalize("en-US") == "en_US", "Locale spelling is standardized")
	_check(LocaleSelection.normalize("not a locale").is_empty(), "Malformed locale is rejected")
	_check(manager.resolve_locale("en_US") == "en_US", "Exact locale wins")
	_check(manager.resolve_locale("en_AU") == "en_GB", "Regional ties have a deterministic native-score match")
	_check(manager.resolve_locale("zh_Hant") == "zh_TW", "Traditional script does not select simplified Chinese")
	_check(manager.resolve_locale("zh_Hans") == "zh_CN", "Simplified script does not select traditional Chinese")
	_check(LocaleSelection.match_locale("zh_TW", PackedStringArray(["zh_CN"])).is_empty(), "Explicit opposite Chinese script is not a candidate")
	_check(manager.resolve_locale("auto", "zh_HK") == "zh_TW", "Auto mode retains system region and script information")
	_check(manager.resolve_locale("auto", "ja_JP") == "en_GB", "Unsupported system locale uses the project fallback")
	_check(LocaleSelection.match_locale("de_1996", PackedStringArray(["de_Latn_DE"])) == "de_Latn_DE", "Numeric locale variant is not mistaken for a writing system")
	manager.set_preferred_locale("en_US")
	_changes.clear()
	_check(manager.set_preferred_locale("zh-CN") == OK and manager.get_locale() == "zh_CN", "Switch applies the native locale")
	_check(_changes.size() == 1 and _changes[0] == ["en_US", "zh_CN"], "One change emits the old and new actual locales")
	_check(manager.set_preferred_locale("zh_CN") == OK and _changes.size() == 1, "Identical locale does not emit twice")
	_check(manager.set_preferred_locale("zh_Hans") == OK and manager.get_preferred_locale() == "zh_Hans" and _changes.size() == 1, "Preference can change without another actual-locale signal")
	manager.set_preferred_locale("zh_CN")
	_check(tr("LOCALE_TEST_GREETING") == "你好", "Native tr resolves the selected translation")
	_check(manager.set_preferred_locale("bad value") == ERR_INVALID_PARAMETER and manager.get_locale() == "zh_CN", "Invalid selection leaves locale unchanged")
	_check(manager.set_preferred_locale("ja") == ERR_UNAVAILABLE and manager.get_locale() == "zh_CN", "Unavailable explicit language leaves locale unchanged")
	TranslationServer.set_locale("zh_TW")
	await get_tree().process_frame
	_check(manager.get_locale() == "zh_TW" and _changes.size() == 2, "External native switch is observed without polling")
	_check(manager.get_preferred_locale() == "zh_CN", "External switch does not rewrite the saved user choice")
	var save_errors: Array[Error] = []
	manager.preference_save_failed.connect(func(_preference: String, error: Error) -> void: save_errors.append(error))
	_check(manager.set_preferred_locale("en_US", true) == ERR_UNCONFIGURED and manager.get_locale() == "en_US", "Without persistence the switch succeeds but saving reports failure")
	_check(save_errors == [ERR_UNCONFIGURED], "Persistence failure is observable")
	var bad_config: FailingConfig = FailingConfig.new()
	manager.configure_persistence(bad_config)
	_check(manager.set_preferred_locale("zh_TW", true) == ERR_FILE_CANT_WRITE and manager.get_locale() == "zh_TW", "Failed disk save does not roll back a valid runtime switch")
	var directory: String = "res://locale_checks_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	var path: String = directory.path_join("preferences.cfg")
	var previous_path: Variant = ProjectSettings.get_setting("godot_core_system/config_system/config_path", "user://config.cfg")
	ProjectSettings.set_setting("godot_core_system/config_system/config_path", path)
	var config: ConfigManager = ConfigManager.new()
	manager.configure_persistence(config)
	_check(manager.set_preferred_locale("auto", true) == OK, "Auto preference can be saved")
	var disk: ConfigFile = ConfigFile.new()
	_check(disk.load(path) == OK and disk.get_value("localization", "preferred_locale") == "auto", "Disk stores auto, not the resolved locale")
	_check(manager.set_preferred_locale("zh_TW", true) == OK, "Explicit preference persists")
	var fresh_config: ConfigManager = ConfigManager.new()
	var restarted: LocalizationManager = LocalizationManager.new()
	restarted.configure_persistence(fresh_config)
	add_child(restarted)
	_check(restarted.get_startup_error() == OK and restarted.get_preferred_locale() == "zh_TW" and restarted.get_locale() == "zh_TW", "New service restores the disk preference at startup")
	disk.set_value("localization", "preferred_locale", 42)
	disk.save(path)
	config.load_config()
	_check(manager.restore_preference() == ERR_INVALID_DATA and manager.get_locale() == "zh_TW", "Invalid persisted type does not mutate the current locale")
	_check(manager.set_preferred_locale("zh_CN", true) == ERR_INVALID_DATA and manager.get_locale() == "zh_CN", "Malformed existing preference reports save failure without a ConfigManager type error")
	var reentry_results: Array[Error] = []
	manager.locale_changed.connect(func(_old: String, _new: String) -> void: reentry_results.append(manager.set_preferred_locale("zh_CN")), CONNECT_ONE_SHOT)
	_check(manager.set_preferred_locale("en_US") == OK and reentry_results == [ERR_BUSY], "Reentrant preference change reports busy instead of overwriting an in-progress choice")
	restarted.free()
	manager.free()
	config.free()
	fresh_config.free()
	bad_config.free()
	for translation: Translation in _translations:
		TranslationServer.remove_translation(translation)
	_check(TranslationServer.get_loaded_locales().is_empty(), "Cleanup removes only fixture translations")
	var empty_manager: LocalizationManager = LocalizationManager.new()
	add_child(empty_manager)
	_check(empty_manager.get_startup_error() == ERR_UNAVAILABLE, "Missing catalogs are reported at startup")
	empty_manager.free()
	TranslationServer.set_locale(original)
	ProjectSettings.set_setting("internationalization/locale/fallback", fallback)
	ProjectSettings.set_setting("godot_core_system/config_system/config_path", previous_path)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("%s: %d localization checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
