extends Node

const DemoScene: PackedScene = preload("../../examples/localization_demo/localization_demo.tscn")
var _checks: int = 0
var _failed: bool = false

func _ready() -> void:
	await get_tree().process_frame
	var demo: Control = DemoScene.instantiate() as Control
	add_child(demo)
	var remember: CheckButton = demo.get_node("Margin/Content/Remember") as CheckButton
	remember.button_pressed = false
	var english: Button = demo.get_node("Margin/Content/Languages/English") as Button
	var simplified: Button = demo.get_node("Margin/Content/Languages/Simplified") as Button
	var traditional: Button = demo.get_node("Margin/Content/Languages/Traditional") as Button
	var title: Label = demo.get_node("Margin/Content/Title") as Label
	var coins: Label = demo.get_node("Margin/Content/Coins") as Label
	var player_name: LineEdit = demo.get_node("Margin/Content/PlayerName") as LineEdit
	english.pressed.emit()
	_check(TranslationServer.get_locale() == "en" and coins.text == "You have 3 coins.", "English button updates generated text")
	_check(title.text == "LOCALE_DEMO_TITLE" and title.tr(title.text) == "Choose your language", "Static control retains its native translation key")
	simplified.pressed.emit()
	_check(TranslationServer.get_locale() == "zh_CN" and coins.text == "你拥有 3 枚金币。", "Simplified button updates generated text")
	_check(title.tr(title.text) == "选择你的语言", "Static key resolves to simplified Chinese")
	var collect: Button = demo.get_node("Margin/Content/Collect") as Button
	collect.pressed.emit()
	_check(coins.text == "你拥有 4 枚金币。", "Game value remains independent of display language")
	traditional.pressed.emit()
	_check(TranslationServer.get_locale() == "zh_TW" and coins.text == "你擁有 4 枚金幣。", "Traditional button preserves the game value and refreshes text")
	_check(player_name.text == "Hello" and player_name.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED, "Player name has automatic translation disabled")
	var result: Label = demo.get_node("Margin/Content/Result") as Label
	_check(result.text == "語言已切換，僅本次有效。", "Runtime-only result is explained in the current language")
	demo.free()
	_check(TranslationServer.get_loaded_locales().is_empty(), "Demo exit releases only its own translations")
	var project_translation: Translation = preload("../../examples/localization_demo/demo.en.translation")
	TranslationServer.add_translation(project_translation)
	var second_demo: Control = DemoScene.instantiate() as Control
	add_child(second_demo)
	TranslationServer.set_locale("zh_TW")
	second_demo.free()
	_check(TranslationServer.get_loaded_locales() == PackedStringArray(["en"]), "Demo exit preserves a translation already registered by the host")
	_check(TranslationServer.get_translation_object("en") == project_translation, "Host translation retains its resource identity")
	_check(TranslationServer.get_locale() == "zh_TW", "Demo exit does not restore the global locale")
	TranslationServer.remove_translation(project_translation)
	print("%s: %d localization demo checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
