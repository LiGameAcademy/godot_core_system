extends Node

## 可选的语言偏好服务；TranslationServer 是实际 locale 的唯一权威来源。
const LocaleSelection = preload("./locale_selection.gd")
const ConfigManager = preload("../config_system/config_manager.gd")
const AUTO: String = "auto"
const CONFIG_SECTION: String = "localization"
const CONFIG_KEY: String = "preferred_locale"

signal locale_changed(old_locale: String, new_locale: String)
signal preference_changed(preference: String)
signal preference_save_failed(preference: String, error: Error)

var _config: ConfigManager = null
var _preference: String = AUTO
var _observed_locale: String = ""
var _changing: bool = false
var _startup_error: Error = OK

func _ready() -> void:
	_observed_locale = get_locale()
	_startup_error = restore_preference()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_sync_locale()

## 显式注入已有配置服务；不主动查找或启用 CoreSystem 的其它模块。
func configure_persistence(config: ConfigManager) -> void:
	_config = config

func get_locale() -> String:
	return TranslationServer.get_locale()

func get_preferred_locale() -> String:
	return _preference

func get_available_locales() -> PackedStringArray:
	var locales: PackedStringArray = TranslationServer.get_loaded_locales()
	locales.sort()
	return locales

func get_startup_error() -> Error:
	return _startup_error

## 系统无匹配时尝试项目 fallback；显式选择不偷偷回退到其它语言。
func resolve_locale(preference: String, system_locale: String = "") -> String:
	var available: PackedStringArray = get_available_locales()
	if preference != AUTO:
		return LocaleSelection.match_locale(preference, available)
	var requested: String = OS.get_locale() if system_locale.is_empty() else system_locale
	var matched: String = LocaleSelection.match_locale(requested, available)
	if not matched.is_empty():
		return matched
	var fallback: String = str(ProjectSettings.get_setting("internationalization/locale/fallback", "en"))
	if fallback.is_empty():
		fallback = "en"
	return LocaleSelection.match_locale(fallback, available)

## persist=true 的保存失败不会撤销已完成的语言切换，返回对应错误并发失败信号。
func set_preferred_locale(preference: String, persist: bool = false) -> Error:
	if _changing:
		return ERR_BUSY
	var normalized: String = AUTO if preference == AUTO else LocaleSelection.normalize(preference)
	if normalized.is_empty():
		return ERR_INVALID_PARAMETER
	var target: String = resolve_locale(normalized)
	if target.is_empty():
		return ERR_UNAVAILABLE
	_changing = true
	var preference_was_changed: bool = _preference != normalized
	_preference = normalized
	TranslationServer.set_locale(target)
	_sync_locale()
	var error: Error = save_preference() if persist else OK
	if preference_was_changed:
		preference_changed.emit(_preference)
	_changing = false
	return error

## 从显式配置读取；无配置时仅采用 auto，不持久化。
func restore_preference() -> Error:
	var saved: Variant = AUTO
	if is_instance_valid(_config):
		saved = _config.get_value(CONFIG_SECTION, CONFIG_KEY, AUTO)
	if not saved is String:
		return ERR_INVALID_DATA
	# 恢复偏好但保留调试覆盖的实际语言；手动选择仍可调用 set_preferred_locale。
	if _has_test_override():
		var normalized: String = AUTO if saved == AUTO else LocaleSelection.normalize(saved)
		if normalized.is_empty():
			return ERR_INVALID_PARAMETER
		_preference = normalized
		return OK
	return set_preferred_locale(saved)

func save_preference() -> Error:
	var error: Error = OK
	if not is_instance_valid(_config):
		error = ERR_UNCONFIGURED
	elif not _config.get_value(CONFIG_SECTION, CONFIG_KEY, AUTO) is String:
		# 既有 ConfigManager 的不同类型比较可能报错，损坏配置应显式拒绝。
		error = ERR_INVALID_DATA
	else:
		_config.set_value(CONFIG_SECTION, CONFIG_KEY, _preference)
		if not _config.save_config():
			error = ERR_FILE_CANT_WRITE
	if error != OK:
		preference_save_failed.emit(_preference, error)
	return error

func _sync_locale() -> void:
	var current: String = get_locale()
	if _observed_locale.is_empty():
		_observed_locale = current
	elif current != _observed_locale:
		var previous: String = _observed_locale
		_observed_locale = current
		locale_changed.emit(previous, current)

func _has_test_override() -> bool:
	if not str(ProjectSettings.get_setting("internationalization/locale/test", "")).is_empty():
		return true
	for argument: String in OS.get_cmdline_args():
		if argument == "--language" or argument.begins_with("--language="):
			return true
	return false
