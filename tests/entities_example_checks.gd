extends Node

var _checks: int = 0
var _failed: bool = false

func _ready() -> void:
	var demo: Node = (load("res://addons/godot_core_system/examples/entities/entities_example.tscn") as PackedScene).instantiate()
	add_child(demo)
	demo.get_node("Panel/Rows/Create").emit_signal("pressed")
	var a: Node = demo.get("_a").node
	var b: Node = demo.get("_b").node
	_check(a.get("health") == 100 and b.get("health") == 150, "Buttons create distinct configurations")
	demo.get_node("Panel/Rows/Damage").emit_signal("pressed")
	_check(a.get("health") == 75 and b.get("health") == 150, "Damage button isolates A")
	_check((a.get("palette") as Gradient).get_color(0) == Color.RED and (b.get("palette") as Gradient).get_color(0) == Color.WHITE, "Tint button isolates A")
	demo.get_node("Panel/Rows/Recycle").emit_signal("pressed")
	_check(demo.get("_a").node == a and a.get("health") == 100, "Button reuses and resets A")
	_check((demo.get_node("Panel/Rows/Status") as Label).text.contains("stale lease"), "Button shows stale lease result")
	demo.get_node("Panel/Rows/Clear").emit_signal("pressed")
	await get_tree().process_frame
	_check(not is_instance_valid(a) and not is_instance_valid(b), "Clear button releases actors")
	demo.queue_free()
	await get_tree().process_frame
	print("Entities example checks: %d; failed: %s" % [_checks, _failed])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
