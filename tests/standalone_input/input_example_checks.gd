extends Node

const Example = preload("../../examples/input_extensions/input_extensions.tscn")
const ManagerScene = preload("../../source/input_system/input_manager.tscn")

var _checks: int = 0
var _failed: bool = false

func _ready() -> void:
	var component: Node = ManagerScene.instantiate()
	_check(component.name == &"InputManager", "Reusable input scene instantiates")
	component.free()
	var example: Control = Example.instantiate()
	example.preferences_path = "res://example-preferences.cfg"
	add_child(example)
	_check(example._ready_for_input, "Example runs without CoreSystem")
	example.get_node("Layout/Record").emit_signal("pressed")
	var event: InputEventAction = InputEventAction.new()
	event.action = &"extension_jump"
	event.pressed = true
	example.observer._input(event)
	_check(example.observer.input_recorder.get_record_count() == 1, "Record button and input event produce a record")
	example.get_node("Layout/Playback").emit_signal("pressed")
	_check(example.observer.input_recorder.is_playing, "Playback button starts consumption")
	example.get_node("Layout/Rebind").emit_signal("pressed")
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	example.observer._input(click)
	_check(example.bindings.to_data().Actions.extension_jump[0].Code == KEY_SPACE, "Raw UI click cannot become a captured binding")
	example.get_node("Layout/Cancel").emit_signal("pressed")
	_check(not example.observer._remap.is_remapping(), "Cancel button ends capture")
	example.get_node("Layout/Rebind").emit_signal("pressed")
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_K
	key.physical_keycode = KEY_K
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().process_frame
	_check(not example.observer._remap.is_remapping() and example.bindings.to_data().Actions.extension_jump[0].Code == KEY_K, "Actual unhandled dispatch captures a physical key")
	var release: InputEventKey = key.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	example.get_node("Layout/Save").emit_signal("pressed")
	_check(FileAccess.file_exists(example.preferences_path), "Save button creates preferences")
	example.bindings.restore_defaults()
	_check(example.bindings.to_data().Actions.extension_jump[0].Code == KEY_SPACE, "Restore defaults changes the live binding")
	example.get_node("Layout/Load").emit_signal("pressed")
	_check(example.bindings.to_data().Actions.extension_jump[0].Code == KEY_K, "Load button restores the saved binding")
	var stored: PackedByteArray = FileAccess.get_file_as_bytes(example.preferences_path)
	example.get_node("Layout/Rebind").emit_signal("pressed")
	example.free()
	_check(not InputMap.has_action(&"extension_jump") and not InputMap.has_action(&"extension_right"), "Exiting a capture releases owned actions")
	example = Example.instantiate()
	example.preferences_path = "res://example-preferences.cfg"
	add_child(example)
	example.get_node("Layout/Load").emit_signal("pressed")
	_check(example.bindings.to_data().Actions.extension_jump[0].Code == KEY_K, "A fresh example reloads stable preferences")
	_check(FileAccess.get_file_as_bytes(example.preferences_path) == stored, "Reload does not rewrite the preferences file")
	example.free()
	DirAccess.remove_absolute("res://example-preferences.cfg")
	await get_tree().process_frame
	print("%s: %d input extension example checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
