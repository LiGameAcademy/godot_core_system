extends Node

var _checks: int = 0
var _failed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var mode_value: Variant = ProjectSettings.get_setting("localization_acceptance/mode", "")
	var scene_value: Variant = ProjectSettings.get_setting("localization_acceptance/scene", "")
	if not mode_value is String or not scene_value is String:
		push_error("Localization acceptance settings must be strings.")
		get_tree().quit(1)
		return
	var mode: String = mode_value
	var scene_path: String = scene_value
	if mode not in ["tower", "arpg"] or scene_path.is_empty():
		push_error("Configure the isolated tower or ARPG host before running this scene.")
		get_tree().quit(1)
		return
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		get_tree().quit(1)
		return
	var world: Node = scene.instantiate()
	add_child(world)
	for frame: int in range(3):
		await get_tree().process_frame
	get_tree().paused = true
	var manager: CoreSystem.LocalizationManager = CoreSystem.localization_manager
	if manager == null:
		push_error("Enable localization_manager in the isolated host.")
		get_tree().quit(1)
		return
	_check(manager.get_startup_error() == OK, "Host startup resolves its native translation resources")
	_check(manager.set_preferred_locale("en") == OK, "Existing game can select English")
	await get_tree().process_frame
	if mode == "tower":
		await _check_tower(world, manager)
	else:
		await _check_arpg(world, manager)
	_check(manager.set_preferred_locale("zh_TW", true) == OK, "Existing game's configuration can save its language preference")
	var file: ConfigFile = ConfigFile.new()
	_check(file.load("res://localization-checks.cfg") == OK and file.get_value("localization", "preferred_locale", "") == "zh_TW", "Preference is actually written to the isolated game's configuration")
	get_tree().paused = false
	world.free()
	print("%s: %d localization host checks (%s)" % ["FAIL" if _failed else "PASS", _checks, mode])
	get_tree().quit(1 if _failed else 0)

func _check_tower(world: Node, manager: CoreSystem.LocalizationManager) -> void:
	var form: Control = world.get_node("CanvasLayer/GameForm") as Control
	var coin_label: Label = form.get_node("%lab_coin") as Label
	var health_label: Label = form.get_node("%lab_health") as Label
	var original_coins: int = int(world.get("coin"))
	var original_health: float = float(world.get("current_health"))
	var health_text: String = health_label.text
	_check(coin_label.text == "Coins: %d" % original_coins, "Tower HUD refreshes its generated coin text")
	_check(manager.set_preferred_locale("zh_TW") == OK, "Tower can select traditional Chinese")
	await get_tree().process_frame
	_check(coin_label.text == "金幣：%d" % original_coins, "Language notification refreshes the tower HUD without another coin event")
	_check(int(world.get("coin")) == original_coins and float(world.get("current_health")) == original_health, "Language switching does not change the actual tower game state")
	_check(health_label.text == health_text, "Numeric health display remains unchanged")
	world.set("coin", original_coins + 7)
	_check(coin_label.text == "金幣：%d" % (original_coins + 7), "Subsequent coin updates still use the existing game API")
	manager.set_preferred_locale("en")
	await get_tree().process_frame
	_check(coin_label.text == "Coins: %d" % (original_coins + 7), "Switching back preserves the updated coin value")

func _check_arpg(world: Node, manager: CoreSystem.LocalizationManager) -> void:
	var health_bar: Control = world.get_node("UILayer/HUD/VitalHUD/VBoxContainer/HealthBar") as Control
	var mana_bar: Control = world.get_node("UILayer/HUD/VitalHUD/VBoxContainer/ManaBar") as Control
	var health_name: Label = health_bar.get_node("%NameLabel") as Label
	var health_value: Label = health_bar.get_node("%ValueLabel") as Label
	var mana_name: Label = mana_bar.get_node("%NameLabel") as Label
	var mana_value: Label = mana_bar.get_node("%ValueLabel") as Label
	var value_before: String = health_value.text
	var mana_before: String = mana_value.text
	var progress: ProgressBar = health_bar.get_node("%ProgressBar") as ProgressBar
	var progress_before: float = progress.value
	_check(health_name.tr(health_name.text) == "Health" and mana_name.tr(mana_name.text) == "Mana", "Existing ARPG resource names use native control translation")
	_check(manager.set_preferred_locale("zh_TW") == OK, "ARPG can select traditional Chinese")
	await get_tree().process_frame
	_check(health_name.tr(health_name.text) == "生命值" and mana_name.tr(mana_name.text) == "魔法值", "Existing ARPG resource names resolve in the selected language")
	_check(health_value.text == value_before and mana_value.text == mana_before and progress.value == progress_before, "ARPG language switching preserves numeric HUD state")
	manager.set_preferred_locale("en")
	await get_tree().process_frame
	_check(health_name.tr(health_name.text) == "Health" and health_value.text == value_before, "ARPG can switch back without recalculating game values")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
