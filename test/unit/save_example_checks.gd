extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://addons/godot_core_system/examples/save_contract/save_contract_example.tscn")
	var example: Control = scene.instantiate()
	root.add_child(example)
	var directory: String = ProjectSettings.globalize_path("user://save-example-check-" + Crypto.new().generate_random_bytes(12).hex_encode())
	example.set("_store", CoreSaveDirectory.new(directory).create_store("counter", 1, example.get("_validate")))
	example.get_node("Layout/Increment").emit_signal("pressed")
	example.get_node("Layout/Save").emit_signal("pressed")
	example.get_node("Layout/Increment").emit_signal("pressed")
	example.get_node("Layout/Load").emit_signal("pressed")
	var passed: bool = example.get("_count") == 1
	example.get_node("Layout/Increment").emit_signal("pressed")
	example.get_node("Layout/Save").emit_signal("pressed")
	example.get_node("Layout/Increment").emit_signal("pressed")
	example.get_node("Layout/Load").emit_signal("pressed")
	passed = passed and example.get("_count") == 2
	example.free()
	DirAccess.remove_absolute(directory.path_join("counter.json"))
	DirAccess.remove_absolute(directory)
	if passed:
		print("PASS: save example buttons create, overwrite and restore a draft")
	else:
		push_error("Save example draft restoration failed.")
	quit(0 if passed else 1)
