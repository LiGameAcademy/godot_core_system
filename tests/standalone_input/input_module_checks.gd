extends Node

const Manager = preload("../../source/input_system/input_manager.gd")
const Inputs = preload("../../source/input_system/core_inputs.gd")
const Binding = preload("../../source/input_system/core_input_binding.gd")
const Adapter = preload("../../source/input_system/config/input_config_adapter.gd")
const Processor = preload("../../source/input_system/features/input_event_processor.gd")
const State = preload("../../source/input_system/input_state.gd")

var _checks: int = 0
var _failed: bool = false
var _actions: int = 0
var _remaps: int = 0
var _saved: Dictionary = {}
var _staged: Dictionary = {}

func _ready() -> void:
	await _check_extensions()
	_check_configuration()
	_check_debounce()
	await get_tree().process_frame
	print("%s: %d standalone input checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check_extensions() -> void:
	for action: StringName in [&"module_jump", &"module_right", &"module_other"]:
		InputMap.add_action(action)
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_SPACE
	InputMap.action_add_event(&"module_jump", key)
	var pad: InputEventJoypadButton = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	InputMap.action_add_event(&"module_jump", pad)
	var bindings: Inputs = Inputs.new()
	_check(bindings.register_actions([&"module_jump", &"module_right"]) == OK, "Explicit action owner registers")
	var duplicate: Inputs = Inputs.new()
	_check(duplicate.register_actions([&"module_jump"]) == ERR_ALREADY_IN_USE, "A second writer cannot claim the same action")
	var background: Thread = Thread.new()
	background.start(func() -> Error: return duplicate.register_actions([&"module_other"]))
	_check(background.wait_to_finish() == ERR_UNAVAILABLE, "Worker registration cannot mutate the global action map")
	var manager: Manager = Manager.new()
	_check(manager.use_bindings(bindings) == OK, "Observer shares the existing writer")
	manager.action_triggered.connect(_on_action)
	manager.remap_completed.connect(_on_remap)
	add_child(manager)
	manager.set_process(false)
	manager.set_process_input(false)
	manager.input_recorder.start_recording()
	var event: InputEventAction = InputEventAction.new()
	event.action = &"module_jump"
	event.pressed = true
	manager._input(event)
	_check(_actions == 1, "An unconsumed action reaches the observer without persistence")
	_check(manager.input_buffer.has_buffer("module_jump"), "Press enters the input buffer")
	_check(manager.input_state.is_just_pressed("module_jump"), "Press updates the input state")
	_check(manager.input_recorder.get_record_count() == 1, "Press is recorded")
	event.pressed = false
	manager._input(event)
	_check(manager.input_state.is_just_released("module_jump"), "Release updates state")
	manager.input_recorder.stop_recording()
	manager.input_recorder.start_playback()
	_check(manager.input_recorder.get_playback_data(Time.get_ticks_msec() / 1000.0).get("pressed", false), "Recorded input can be consumed by playback")
	_check(manager.input_recorder.save_records_to_file("res://recording.json"), "Recorder stores a file independently")
	manager.input_recorder.clear_records()
	_check(manager.input_recorder.load_records_from_file("res://recording.json"), "Recorder reloads its file")
	_check(manager.input_recorder.get_record_count() == 2, "Recorder preserves both edges")
	var corrupted: FileAccess = FileAccess.open("res://recording.json", FileAccess.WRITE)
	corrupted.store_string('{"records":[{"action":"jump","pressed":"invalid"}]}')
	corrupted.close()
	_check(not manager.input_recorder.load_records_from_file("res://recording.json") and manager.input_recorder.get_record_count() == 2, "Invalid recording preserves existing records")
	manager.input_recorder.set_max_records(-1)
	_check(manager.input_recorder.get_record_count() == 1, "Invalid record capacity is bounded without an infinite loop")
	DirAccess.remove_absolute("res://recording.json")
	event.action = &"module_other"
	event.pressed = true
	manager._input(event)
	_check(_actions == 2, "Undeclared action is not observed")
	manager.virtual_axis.register_axis("move", "module_right")
	Input.action_press(&"module_right")
	manager.virtual_axis.update_axis("move")
	_check(manager.virtual_axis.get_axis_value("move").x > 0.9, "Virtual axis consumes explicit actions")
	Input.action_release(&"module_right")
	manager.virtual_axis.update_axis("move")
	_check(manager.virtual_axis.get_axis_value("move") == Vector2.ZERO, "Virtual axis releases")
	var filter: Processor.ActionFilter = Processor.ActionFilter.new()
	filter.block_action("module_jump")
	manager.event_processor.add_filter(filter)
	event.action = &"module_jump"
	manager._input(event)
	_check(_actions == 2, "Filters prevent action propagation")
	manager.event_processor.remove_filter(filter)
	var gesture: Processor.GestureHandler = Processor.GestureHandler.new()
	gesture.register_gesture(["right", "up"], "module_right")
	manager.event_processor.add_handler(gesture)
	manager.set_process_input(true)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.velocity = Vector2(50, 0)
	manager._input(motion)
	motion.velocity = Vector2(0, -50)
	manager._input(motion)
	await get_tree().process_frame
	_check(manager.input_state.is_pressed("module_right"), "Registered gesture generates the selected action")
	Input.action_release(&"module_right")
	manager.event_processor.remove_handler(gesture)
	var combo: Processor.KeyComboHandler = Processor.KeyComboHandler.new()
	combo.register_combo([KEY_Z, KEY_X], "module_right")
	manager.event_processor.add_handler(combo)
	var combo_key: InputEventKey = InputEventKey.new()
	combo_key.keycode = KEY_Z
	combo_key.pressed = true
	manager._input(combo_key)
	combo_key = InputEventKey.new()
	combo_key.keycode = KEY_X
	combo_key.pressed = true
	manager._input(combo_key)
	await get_tree().process_frame
	_check(manager.input_state.is_pressed("module_right"), "Registered key combo generates the selected action")
	Input.action_release(&"module_right")
	manager.event_processor.remove_handler(combo)
	manager.set_process_input(false)
	_check(manager.start_remap(&"module_other") == ERR_UNCONFIGURED, "Remap cannot edit an undeclared action")
	_check(manager.start_remap(&"module_jump") == OK, "Owned action can enter capture")
	key = InputEventKey.new()
	key.keycode = KEY_J
	key.physical_keycode = KEY_J
	key.pressed = true
	manager._unhandled_input(key)
	_check(_remaps == 1 and InputMap.action_has_event(&"module_jump", key), "Capture delegates one successful edit to the owner")
	_check(InputMap.action_has_event(&"module_jump", pad), "Remap preserves joypad events")
	var later_pad: InputEventJoypadButton = InputEventJoypadButton.new()
	later_pad.button_index = JOY_BUTTON_B
	InputMap.action_add_event(&"module_jump", later_pad)
	_check(bindings.restore_defaults() == OK, "Defaults restore succeeds")
	_check(InputMap.action_has_event(&"module_jump", pad) and InputMap.action_has_event(&"module_jump", later_pad), "Defaults preserve existing joypad events")
	_check(bindings.rebind(&"module_other", Binding.new(Binding.Kind.KEY, KEY_K)) == ERR_INVALID_PARAMETER, "Writer rejects foreign actions")
	manager.start_remap(&"module_jump")
	manager.close()
	manager.close()
	manager._input(key)
	_check(_remaps == 1, "Close cancels capture and rejects subsequent events")
	_check(not manager.input_recorder.is_recording and not manager.input_recorder.is_playing and not manager.input_buffer.has_buffer("module_jump"), "Close clears recorder and buffer state")
	_check(not manager.virtual_axis.axis_changed.is_connected(manager._on_axis_changed), "Close disconnects the owned axis subscription")
	manager.free()
	bindings.close()
	_check(duplicate.register_actions([&"module_jump"]) == OK, "Released group can be claimed again")
	duplicate.close()
	for action: StringName in [&"module_jump", &"module_right", &"module_other"]:
		InputMap.erase_action(action)
	await get_tree().process_frame

func _check_configuration() -> void:
	var memory: Adapter = Adapter.new()
	memory.set_deadzone(0.4)
	_check(is_equal_approx(memory.get_deadzone(), 0.4), "Input configuration works without persistence")
	_check(memory.save_config() == ERR_UNCONFIGURED, "Missing persistence has an explicit result")
	var persistent: Adapter = Adapter.new(null, _read_section, _write_section, _save_file)
	persistent.set_deadzone(0.6)
	_check(persistent.save_config() == OK, "Explicit callbacks save configuration")
	_check(is_equal_approx(float(_saved.input_settings.deadzone), 0.6), "Save sees the latest section before it writes")
	persistent.set_deadzone(0.2)
	_check(persistent.reload_config() == OK and is_equal_approx(persistent.get_deadzone(), 0.6), "Reload applies saved values over defaults")
	_check(is_equal_approx(memory.get_deadzone(), 0.4), "Separate configuration instances do not share state")
	_check(persistent.get_input_config().update_config({"input_settings": []}) == ERR_INVALID_DATA and is_equal_approx(persistent.get_deadzone(), 0.6), "Invalid section types preserve live input configuration")
	var file: ConfigFile = ConfigFile.new()
	file.set_value("input", "data", _saved)
	_check(file.save("res://preferences.cfg") == OK, "Input section can persist in a real ConfigFile")
	var loaded: ConfigFile = ConfigFile.new()
	_check(loaded.load("res://preferences.cfg") == OK and loaded.get_value("input", "data") == _saved, "ConfigFile input data roundtrips")
	DirAccess.remove_absolute("res://preferences.cfg")
	var reference: WeakRef = weakref(persistent)
	var config: Resource = persistent.get_input_config()
	persistent.close()
	_check(persistent.save_config() == ERR_UNCONFIGURED, "Closed adapter rejects persistence")
	persistent = null
	_check(reference.get_ref() == null and config.config_changed.get_connections().is_empty(), "Closed adapter releases subscriptions and captures")
	memory.close()

func _check_debounce() -> void:
	var state: State = State.new()
	state.edge_debounce_ms = 100000.0
	state.update_action("jump", true, 1.0)
	_check(state.is_just_pressed("jump"), "First debounce edge is accepted")
	state.update_action("jump", false, 0.0)
	_check(not state.is_just_released("jump") and not state.is_pressed("jump"), "Rapid release keeps physical state but suppresses its edge")
	state.update_action("jump", true, 1.0)
	_check(not state.is_just_pressed("jump") and state.is_pressed("jump"), "Rapid press suppresses its repeated edge")
	state.reset_action()
	state.update_action("jump", true, 1.0)
	_check(state.is_just_pressed("jump"), "Reset removes debounce history")

func _read_section() -> Dictionary:
	return _saved.duplicate(true)

func _write_section(section: Dictionary) -> void:
	_staged = section.duplicate(true)

func _save_file() -> Error:
	_saved = _staged.duplicate(true)
	return OK

func _on_action(_action: String, _event: InputEvent) -> void:
	_actions += 1

func _on_remap(_action: String, _event: InputEvent) -> void:
	_remaps += 1

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)

