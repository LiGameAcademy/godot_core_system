extends Node

var _checks: int = 0
var _failed: bool = false

func _ready() -> void:
	var mode: String = str(ProjectSettings.get_setting("issue92/mode", "disabled"))
	if mode == "disabled":
		var original: String = TranslationServer.get_locale()
		_check(not CoreSystem.is_module_enabled(&"localization_manager"), "Missing module setting defaults to disabled")
		_check(CoreSystem.localization_manager == null, "Disabled public getter returns null")
		_check(not CoreSystem._modules.has(&"localization_manager"), "Disabled getter does not create the module")
		_check(TranslationServer.get_locale() == original, "Disabled getter does not change the engine locale")
	else:
		var manager: CoreSystem.LocalizationManager = CoreSystem.localization_manager
		_check(manager != null and CoreSystem._modules.has(&"localization_manager"), "Enabled module is created at startup")
		_check(manager.get_startup_error() == OK, "Startup resolves the project translations")
		if mode == "runtime":
			_check(not CoreSystem._modules.has(&"config_manager"), "Localization does not enable a disabled configuration dependency")
			_check(manager.set_preferred_locale("zh_TW", true) == ERR_UNCONFIGURED, "Runtime module reports unavailable persistence")
			_check(manager.get_locale() == "zh_TW", "Runtime switch still applies without configuration")
		else:
			_check(CoreSystem._modules.has(&"config_manager"), "Persistence uses the selected existing configuration module")
			_check(manager.get_preferred_locale() == "zh_TW", "Saved preference is read at startup")
			var overridden: bool = OS.get_cmdline_args().has("--language") or not str(ProjectSettings.get_setting("internationalization/locale/test", "")).is_empty()
			_check(manager.get_locale() == ("en" if overridden else "zh_TW"), "Native test language wins over saved preference only during startup")
	print("%s: %d localization module checks (%s)" % ["FAIL" if _failed else "PASS", _checks, mode])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
