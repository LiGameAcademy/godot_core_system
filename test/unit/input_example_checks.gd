extends SceneTree

var _checks: int = 0
var _failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://addons/godot_core_system/examples/input_bindings/input_bindings_example.tscn")
	var name: String = "input_example_checks_" + Crypto.new().generate_random_bytes(8).hex_encode()
	var path: String = ProjectSettings.globalize_path("user://core_system/" + name + ".json")
	var first: Control = scene.instantiate()
	var second: Control = scene.instantiate()
	first.save_name = name
	second.save_name = name
	root.add_child(first)
	root.add_child(second)
	_check(not FileAccess.file_exists(path), "Example startup does not save defaults")
	var first_actions: Array[StringName] = first.get("_actions")
	var second_actions: Array[StringName] = second.get("_actions")
	_check(first_actions[0] != second_actions[0], "Instances own distinct engine action identifiers")
	_press(first, "Rebind")
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_B
	key.physical_keycode = KEY_B
	key.pressed = true
	first.handle_capture(key)
	_check(first.capturing and _code(first, first_actions[0]) == KEY_A, "Conflict retains previous binding and capture")
	_press(first, "Cancel")
	_check(not first.capturing, "Cancel button stops capture")
	_press(first, "Rebind")
	key.keycode = KEY_ESCAPE
	first.handle_capture(key)
	_check(not first.capturing and _code(first, first_actions[0]) == KEY_A, "Escape cancels without mutation")
	_press(first, "Rebind")
	key.keycode = KEY_Q
	key.physical_keycode = KEY_Q
	await process_frame
	Input.parse_input_event(key)
	await process_frame
	_check(not first.capturing and _code(first, first_actions[0]) == KEY_Q, "Actual unhandled-input dispatch captures a physical key")
	key.pressed = false
	Input.parse_input_event(key)
	_check(_code(second, second_actions[0]) == KEY_A, "Rebind in A does not change B")
	_press(first, "Save")
	_check(FileAccess.file_exists(path), "Save button creates a profile")
	_press(first, "Reset")
	_check(_code(first, first_actions[0]) == KEY_A, "Reset button restores defaults")
	_press(first, "Load")
	_check(_code(first, first_actions[0]) == KEY_Q, "Load button restores saved binding")
	_press(second, "Load")
	_check(_code(second, second_actions[0]) == KEY_Q, "Stable profile names load in a different instance")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"Version":1,"Data":{"Actions":{}}}')
	file.close()
	var malformed: PackedByteArray = FileAccess.get_file_as_bytes(path)
	_press(first, "Load")
	_check(_code(first, first_actions[0]) == KEY_Q and FileAccess.get_file_as_bytes(path) == malformed, "Invalid saved profile retains live bindings and disk bytes")
	first.free()
	_check(not InputMap.has_action(first_actions[0]) and InputMap.has_action(second_actions[0]), "Exiting A cleans only its own actions")
	second.free()
	_check(not InputMap.has_action(second_actions[0]), "Exiting B cleans remaining example actions")
	DirAccess.remove_absolute(path)
	if not _failed:
		print("PASS: %d input example checks" % _checks)
	quit(1 if _failed else 0)

func _code(example: Control, action: StringName) -> int:
	return example.inputs.to_data().Actions[String(action)][0].Code

func _press(example: Control, name: String) -> void:
	example.get_node("Layout/" + name).emit_signal("pressed")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
