extends SceneTree

var _checks: int = 0
var _failed: bool = false
var _prefix: String = "core_input_checks_" + Crypto.new().generate_random_bytes(8).hex_encode()
var _directory: String

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var first: StringName = StringName(_prefix + "_first")
	var second: StringName = StringName(_prefix + "_second")
	var unrelated: StringName = StringName(_prefix + "_unrelated")
	for action: StringName in [first, second, unrelated]:
		InputMap.add_action(action, 0.4)
	var original: InputEventKey = InputEventKey.new()
	original.keycode = KEY_A
	InputMap.action_add_event(first, original)
	InputMap.action_add_event(second, CoreInputBinding.new(CoreInputBinding.Kind.PHYSICAL_KEY, KEY_B).to_event())
	InputMap.action_add_event(unrelated, CoreInputBinding.new(CoreInputBinding.Kind.KEY, KEY_Z).to_event())
	var joypad: InputEventJoypadButton = InputEventJoypadButton.new()
	joypad.button_index = JOY_BUTTON_A
	InputMap.action_add_event(first, joypad)
	var inputs: CoreInputs = CoreInputs.new()
	_check(not CoreInputBinding.new(CoreInputBinding.Kind.KEY, 5000000).is_valid() and not CoreInputBinding.new(CoreInputBinding.Kind.KEY, KEY_UNKNOWN).is_valid(), "Unknown key codes are rejected")
	_check(CoreInputBinding.new(CoreInputBinding.Kind.KEY, 0).to_event() == null, "Invalid bindings cannot construct engine events")
	_check(inputs.register_actions([first, second]) == OK, "Register explicit action group")
	original.keycode = KEY_X
	_check(inputs.restore_defaults() == OK and inputs.to_data().Actions[String(first)][0].Code == KEY_A, "Default snapshot is independent of source resources")
	var before: Dictionary = inputs.to_data()
	var collision: CoreInputBinding = CoreInputBinding.new(CoreInputBinding.Kind.KEY, KEY_B)
	_check(inputs.find_conflicts(first, collision) == [second], "Report a conflicting managed action")
	_check(inputs.rebind(first, collision) == ERR_ALREADY_IN_USE and inputs.to_data() == before, "Conflict rejects without changing any action")
	var keyboard: CoreInputBinding = CoreInputBinding.new(CoreInputBinding.Kind.KEY, KEY_C, true)
	_check(inputs.rebind(first, keyboard) == OK, "Logical key with modifiers rebinds")
	keyboard.code = KEY_D
	_check(inputs.to_data().Actions[String(first)][0].Code == KEY_C, "Stored bindings are independent of caller mutations")
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = KEY_C
	key_event.physical_keycode = KEY_Q
	key_event.ctrl_pressed = true
	key_event.pressed = true
	_check(CoreInputBinding.from_event(key_event) == null, "Configured keys must use one unambiguous identity")
	_check(InputMap.event_is_action(key_event, first, true), "Logical key and exact modifiers match Godot")
	key_event.ctrl_pressed = false
	_check(not InputMap.event_is_action(key_event, first, true), "Exact matching rejects missing modifiers")
	_check(CoreInputBinding.from_event(key_event, false, true).code == KEY_C and CoreInputBinding.from_event(key_event, true, true).code == KEY_Q, "Capture explicitly chooses logical or physical identity")
	key_event.echo = true
	_check(CoreInputBinding.from_event(key_event, false, true) == null, "Capture ignores key repeats")
	key_event.echo = false
	key_event.pressed = false
	_check(CoreInputBinding.from_event(key_event, false, true) == null, "Capture ignores releases")
	key_event.pressed = true
	key_event.keycode = KEY_SHIFT
	_check(CoreInputBinding.from_event(key_event, false, true) == null, "Capture ignores standalone modifiers")
	_check(CoreInputBinding.from_event(InputEventMouseMotion.new(), false, true) == null, "Capture ignores mouse motion")
	_check(inputs.rebind(first, CoreInputBinding.new(CoreInputBinding.Kind.MOUSE_BUTTON, MOUSE_BUTTON_RIGHT)) == OK, "Mouse buttons rebind")
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.pressed = true
	_check(InputMap.event_is_action(mouse, first, true), "Mouse button matches Godot")
	_check(InputMap.action_get_events(first).size() == 2 and InputMap.event_is_action(joypad, first, true), "Rebind preserves joypad inputs")
	_check(is_equal_approx(InputMap.action_get_deadzone(first), 0.4), "Deadzone is unchanged")
	_check(InputMap.action_get_events(unrelated)[0].keycode == KEY_Z, "Unmanaged actions are unchanged")
	var saved: Dictionary = inputs.to_data()
	var mutated: Dictionary = inputs.to_data()
	mutated.Actions[String(first)][0].Code = 0
	_check(inputs.apply_data(mutated) == ERR_INVALID_DATA and inputs.to_data() == saved, "Invalid payload cannot partially apply")
	mutated = saved.duplicate(true)
	mutated.Actions[String(second)][0].Extra = true
	_check(inputs.apply_data(mutated) == ERR_INVALID_DATA and inputs.to_data() == saved, "Unknown binding fields are rejected before mutation")
	mutated = saved.duplicate(true)
	mutated.Actions.erase(String(second))
	_check(inputs.apply_data(mutated) == ERR_INVALID_DATA, "Incomplete action groups are rejected")
	mutated = saved.duplicate(true)
	mutated.Extra = true
	_check(inputs.apply_data(mutated) == ERR_INVALID_DATA, "Unknown profile fields are rejected")
	mutated = saved.duplicate(true)
	mutated.Actions[String(first)] = []
	_check(inputs.apply_data(mutated) == OK and InputMap.action_get_events(first).size() == 1, "Empty keyboard binding list explicitly unbinds and retains joypad")
	_check(inputs.restore_defaults() == OK and inputs.to_data() == before, "Restore all captured default bindings")
	_directory = ProjectSettings.globalize_path("user://" + _prefix)
	var store: CoreSaveStore = CoreSaveDirectory.new(_directory).create_store("bindings", 1, inputs.validate_data)
	_check(store.save(saved).error == OK, "Save a validated profile using the existing store")
	var loaded: CoreSaveResult = store.try_load()
	_check(loaded.error == OK and loaded.found and inputs.apply_data(loaded.data) == OK and inputs.to_data() == saved, "Stored bindings reload and apply")
	var file_path: String = _directory.path_join("bindings.json")
	var valid_bytes: PackedByteArray = FileAccess.get_file_as_bytes(file_path)
	_check(store.save({"Actions": {}}).error == ERR_INVALID_DATA and FileAccess.get_file_as_bytes(file_path) == valid_bytes, "Invalid settings cannot overwrite the saved profile")
	InputMap.erase_action(second)
	before = inputs.to_data()
	_check(inputs.apply_data(saved) == ERR_DOES_NOT_EXIST and inputs.to_data() == before, "Removed actions prevent partial application")
	_check(inputs.restore_defaults() == ERR_DOES_NOT_EXIST and inputs.to_data() == before, "Removed actions prevent partial restoration")
	DirAccess.remove_absolute(file_path)
	DirAccess.remove_absolute(_directory)
	for action: StringName in [first, unrelated]:
		InputMap.erase_action(action)
	inputs.close()
	if not _failed:
		print("PASS: %d input contract checks" % _checks)
	quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
