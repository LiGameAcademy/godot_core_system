extends Node

const LocalizationManager = preload("../../source/localization_system/localization_manager.gd")
const ENGLISH_TRANSLATION: Translation = preload("./fixtures/localization/native_en.po")
const FRENCH_TRANSLATION: Translation = preload("./fixtures/localization/native_fr.po")

class DynamicLabel extends Label:
	var notifications: int = 0

	func _ready() -> void:
		text = tr("NATIVE_STATUS")

	func _notification(what: int) -> void:
		if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
			notifications += 1
			text = tr("NATIVE_STATUS")

var _checks: int = 0
var _failed: bool = false
var _changes: int = 0

func _ready() -> void:
	await get_tree().process_frame
	var original_locale: String = TranslationServer.get_locale()
	TranslationServer.add_translation(ENGLISH_TRANSLATION)
	TranslationServer.add_translation(FRENCH_TRANSLATION)
	TranslationServer.set_locale("en")
	var manager: LocalizationManager = LocalizationManager.new()
	add_child(manager)
	manager.locale_changed.connect(_on_locale_changed)
	var label: DynamicLabel = DynamicLabel.new()
	add_child(label)
	var player_name: LineEdit = LineEdit.new()
	player_name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	player_name.text = "NATIVE_STATUS"
	add_child(player_name)
	_check(manager.set_preferred_locale("en") == OK, "English catalog is selectable")
	_check(tr("Open", "action") == "Open menu" and tr("Open", "state") == "Open state", "PO contexts select different translations")
	_check(tr_n("%d apple", "%d apples", 0) % 0 == "0 apples", "English zero uses the plural form")
	_check(tr_n("%d apple", "%d apples", 1) % 1 == "1 apple", "English one uses the singular form")
	_check(tr_n("%d apple", "%d apples", 2) % 2 == "2 apples", "English two uses the plural form")
	_check(manager.set_preferred_locale("fr") == OK, "French catalog is selectable")
	await get_tree().process_frame
	_check(tr("Open", "action") == "Ouvrir" and tr("Open", "state") == "Ouvert", "Switch preserves the PO context")
	_check(tr_n("%d apple", "%d apples", 0) % 0 == "0 pomme", "French zero follows the PO rule rather than English")
	_check(tr_n("%d apple", "%d apples", 1) % 1 == "1 pomme", "French one uses the singular form")
	_check(tr_n("%d apple", "%d apples", 2) % 2 == "2 pommes", "French two uses the plural form")
	_check(tr("NATIVE_FALLBACK") == "English fallback", "Missing French message uses native project fallback")
	_check(tr("NEVER_TRANSLATED") == "NEVER_TRANSLATED", "Unknown text remains the source text")
	_check(label.text == "Prêt", "Dynamic text refreshes from native translation notification")
	_check(player_name.text == "NATIVE_STATUS" and player_name.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED, "Player input remains untranslated even when it equals a message key")
	var before_changes: int = _changes
	var before_notifications: int = label.notifications
	var replacement: Translation = Translation.new()
	replacement.locale = "fr"
	replacement.add_message(&"NATIVE_STATUS", &"Mis à jour")
	TranslationServer.remove_translation(FRENCH_TRANSLATION)
	TranslationServer.add_translation(replacement)
	# 资源拥有方广播原生刷新；不依赖同值 set_locale 自动刷新缓存。
	get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
	await get_tree().process_frame
	_check(label.notifications > before_notifications and label.text == "Mis à jour", "Same-locale native refresh updates a cached message")
	_check(_changes == before_changes and manager.get_locale() == "fr", "Resource replacement does not emit an actual-locale change")
	var pseudolocalization_before: bool = TranslationServer.pseudolocalization_enabled
	TranslationServer.pseudolocalization_enabled = true
	_check(TranslationServer.translate(&"NATIVE_STATUS") != &"Mis à jour", "Native pseudolocalization remains available")
	_check(manager.get_locale() == "fr" and manager.get_preferred_locale() == "fr", "Pseudolocalization does not change locale authority or preference")
	TranslationServer.pseudolocalization_enabled = pseudolocalization_before
	label.free()
	player_name.free()
	manager.free()
	TranslationServer.remove_translation(ENGLISH_TRANSLATION)
	TranslationServer.remove_translation(replacement)
	TranslationServer.set_locale(original_locale)
	_check(TranslationServer.get_loaded_locales().is_empty(), "Cleanup does not leave fixture translations registered")
	print("%s: %d native localization checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _on_locale_changed(_old: String, _new: String) -> void:
	_changes += 1

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
