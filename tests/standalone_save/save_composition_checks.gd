extends Node

const Recipient: GDScript = preload("./save_recipient.gd")
const RecipientScene: PackedScene = preload("./save_recipient.tscn")
var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	var manager: CoreSystem.SaveManager = CoreSystem.save_manager
	_expect(manager != null and manager.scene_scope == get_tree().root, "Legacy root injects explicit scope")
	var node: Recipient = RecipientScene.instantiate() as Recipient
	node.health = 75
	node.add_to_group(&"saveable")
	add_child(node)
	_expect(await manager.create_save("composition"), "Legacy root saves grouped recipient")
	node.health = 0
	_expect(await manager.load_save("composition") and node.health == 75, "Legacy root restores path recipient")
	var listed: Array[Dictionary] = await manager.get_save_list()
	_expect(listed.size() == 1 and listed[0].save_id == "composition", "Legacy list returns saved slot")
	_expect(manager.delete_save("composition"), "Legacy delete API")
	node.free()
	print("SAVE COMPOSITION CHECKS: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)

func _expect(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(description)
