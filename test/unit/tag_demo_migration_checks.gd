extends SceneTree

var _checks: int = 0
var _failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://addons/godot_core_system/examples/tag_demo/tag_demo.tscn")
	var demo: Node2D = scene.instantiate()
	root.add_child(demo)
	var player: CoreTagCharacter = demo.get_node("Player")
	var enemy: CoreTagCharacter = demo.get_node("Enemy")
	_check(player.has_tag("character.player") and enemy.has_tag("character.enemy"), "Each child owns its exported classification")
	_check(player.has_tag("character", false) and not player.has_tag("character"), "Implicit ancestor is queried but not stored")
	_press(demo, "MoveButton")
	_check(player.has_tag("state.moving") and enemy.has_tag("state.idle"), "Move button changes only the player")
	_press(demo, "AttackButton")
	_check(player.has_tag("state.attacking"), "Attack button reaches the child rule")
	_check(not player.try_attack(), "Repeated attack is rejected")
	_press(demo, "MoveButton")
	_check(player.get_node("ColorRect").color == Color.RED, "Attack presentation survives movement toggling")
	_check(enemy.get_node("ColorRect").color == enemy.base_color, "A does not change B visual state")
	player._process(player.attack_duration)
	_check(demo.get_node("UI/StatusLabel").text == "Player finished attacking", "Child completion signal updates the parent")
	_check(not player.has_tag("state.attacking"), "Rule result removes its own attack fact")
	_check(player.get_node("ColorRect").color == player.base_color, "Child consumes completion notification")
	_press(demo, "BuffButton")
	_check(player.has_tag("buff", false) and not enemy.has_tag("buff", false), "Buff button changes local facts only")
	_press(demo, "QueryButton")
	_check(demo.get_node("UI/StatusLabel").text.contains("character.player"), "Query button displays full paths")
	var retained: CoreTagCharacterModel = player.model
	_check(player.try_attack(), "Prepare active attack before scene exit")
	demo.queue_free()
	await process_frame
	await process_frame
	_check(retained.tags.tag_added.get_connections().is_empty() and retained.tags.tag_removed.get_connections().is_empty(), "Child exit releases tag observers")
	_check(retained.advance(2.0), "Retained rule model runs independently after scene exit")
	_check(not retained.tags.has("state.attacking"), "Completed rule has no stale UI dependency")
	_check(not root.has_node("CoreSystem"), "Migrated demo needs no global singleton")
	if not _failed:
		print("PASS: %d migrated tag demo checks" % _checks)
	quit(1 if _failed else 0)

func _press(demo: Node2D, name: String) -> void:
	demo.get_node("UI/Panel/VBoxContainer/" + name).emit_signal("pressed")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)