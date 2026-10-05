extends SceneTree

func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 2 or arguments[1] not in ["write", "read"]:
		push_error("Supply an absolute fixture path and write/read mode.")
		quit(1)
		return
	var actions: Array[StringName] = [&"core_input_interop_first", &"core_input_interop_second"]
	for action: StringName in actions:
		if InputMap.has_action(action):
			push_error("Interop action identifiers must be unused.")
			quit(1)
			return
	for action: StringName in actions:
		InputMap.add_action(action)
	var inputs: CoreInputs = CoreInputs.new()
	inputs.register_actions(actions)
	var store: CoreSaveStore = CoreSaveStore.new(arguments[0], 1, inputs.validate_data)
	var passed: bool
	if arguments[1] == "write":
		inputs.rebind(actions[0], CoreInputBinding.new(CoreInputBinding.Kind.PHYSICAL_KEY, KEY_Q))
		inputs.rebind(actions[1], CoreInputBinding.new(CoreInputBinding.Kind.MOUSE_BUTTON, MOUSE_BUTTON_RIGHT))
		passed = store.save(inputs.to_data()).error == OK
	else:
		var result: CoreSaveResult = store.try_load()
		passed = result.error == OK and result.found and inputs.apply_data(result.data) == OK
		if passed:
			var binding: Dictionary = inputs.to_data().Actions[String(actions[0])][0]
			passed = binding.Kind == CoreInputBinding.Kind.KEY and binding.Code == KEY_C and binding.Ctrl and inputs.to_data().Actions[String(actions[1])][0].Code == MOUSE_BUTTON_RIGHT
	for action: StringName in actions:
		InputMap.erase_action(action)
	if passed:
		print("PASS: GDScript input profile interop " + arguments[1])
	else:
		push_error("Cross-language input profile verification failed.")
	quit(0 if passed else 1)
