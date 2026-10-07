extends Control

const LocalizationManager = preload("../../source/localization_system/localization_manager.gd")
## 演示自行拥有翻译资源；退出时只移除自己添加的资源。
@export var translations: Array[Translation] = []
var _added_translations: Array[Translation] = []
@onready var _manager: LocalizationManager = $LocalizationManager
@onready var _coins_label: Label = $Margin/Content/Coins
@onready var _status: Label = $Margin/Content/Status
@onready var _result: Label = $Margin/Content/Result
@onready var _remember: CheckButton = $Margin/Content/Remember
var _coins: int = 3
var _last_error: Error = OK
var _last_saved: bool = false
var _has_result: bool = false

func _enter_tree() -> void:
	for translation: Translation in translations:
		# 项目设置可能已注册同一资源，演示不能在退出时移除它。
		if TranslationServer.get_translation_object(translation.locale) != translation:
			TranslationServer.add_translation(translation)
			_added_translations.append(translation)
	var manager: LocalizationManager = $LocalizationManager
	if CoreSystem.is_module_enabled(&"config_manager"):
		manager.configure_persistence(CoreSystem.config_manager)

func _ready() -> void:
	_manager.locale_changed.connect(_on_locale_changed)
	_manager.preference_changed.connect(_on_preference_changed)
	$Margin/Content/Languages/English.pressed.connect(_select.bind("en"))
	$Margin/Content/Languages/Simplified.pressed.connect(_select.bind("zh_CN"))
	$Margin/Content/Languages/Traditional.pressed.connect(_select.bind("zh_TW"))
	$Margin/Content/Languages/Auto.pressed.connect(_select.bind("auto"))
	$Margin/Content/Collect.pressed.connect(_collect)
	_refresh_text()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_text()

func _exit_tree() -> void:
	for translation: Translation in _added_translations:
		TranslationServer.remove_translation(translation)
	_added_translations.clear()

func _select(preference: String) -> void:
	_last_saved = _remember.button_pressed
	_last_error = _manager.set_preferred_locale(preference, _last_saved)
	_has_result = true
	_refresh_text()

func _collect() -> void:
	_coins += 1
	_refresh_text()

func _on_locale_changed(_old_locale: String, _new_locale: String) -> void:
	_refresh_text()

func _on_preference_changed(_preference: String) -> void:
	_refresh_text()

func _refresh_text() -> void:
	_coins_label.text = tr("LOCALE_DEMO_COINS").format({"count": _coins})
	_status.text = tr("LOCALE_DEMO_STATUS").format({"preference": _manager.get_preferred_locale(), "locale": _manager.get_locale()})
	if not _has_result:
		_result.text = ""
	elif _last_error != OK:
		_result.text = tr("LOCALE_DEMO_ERROR").format({"error": error_string(_last_error), "locale": _manager.get_locale()})
	else:
		_result.text = tr("LOCALE_DEMO_SAVED" if _last_saved else "LOCALE_DEMO_RUNTIME")
