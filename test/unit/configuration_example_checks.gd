extends SceneTree

var _checks: int = 0
var _failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://addons/godot_core_system/examples/configuration/configuration.tscn")
	var demo: Control = scene.instantiate()
	var folder: String = "user://config_example_checks_" + str(Time.get_ticks_usec())
	demo.set("config_path", folder + "/settings.cfg")
	root.add_child(demo)
	var status: Label = demo.get_node("Panel/Status")
	_check(status.text.contains("Count: 0"), "Fresh scene uses defaults")
	demo.get_node("Panel/Edit").emit_signal("pressed")
	_check(status.text.contains("Count: 1") and status.text.contains("modified: true"), "Edit button changes local memory")
	demo.get_node("Panel/Save").emit_signal("pressed")
	_check(FileAccess.file_exists(folder + "/settings.cfg") and status.text.contains("modified: false"), "Save button persists")
	demo.get_node("Panel/Edit").emit_signal("pressed")
	demo.get_node("Panel/Reload").emit_signal("pressed")
	_check(status.text.contains("Count: 1") and status.text.contains("modified: false"), "Reload discards unsaved change")
	demo.get_node("Panel/Reset").emit_signal("pressed")
	_check(status.text.contains("Count: 0") and status.text.contains("modified: true"), "Reset affects memory only")
	demo.get_node("Panel/Reload").emit_signal("pressed")
	_check(status.text.contains("Count: 1"), "Unsaved reset leaves file intact")
	demo.free()
	DirAccess.remove_absolute(folder + "/settings.cfg")
	DirAccess.remove_absolute(folder)
	print("PASS: %d configuration example checks" % _checks)
	quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
