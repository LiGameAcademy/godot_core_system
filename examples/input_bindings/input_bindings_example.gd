extends Control

@export var save_name: String = "input_bindings_example"
var inputs: CoreInputs
var capturing: bool = false
var _actions: Array[StringName] = []
var _store: CoreSaveStore
@onready var _status: Label = $Layout/Status
@onready var _action: OptionButton = $Layout/Action
@onready var _physical: CheckButton = $Layout/Physical

func _ready() -> void:
	var prefix: String = "core_input_example_" + str(get_instance_id())
	_actions = [StringName(prefix + "_first"), StringName(prefix + "_second")]
	for index: int in range(_actions.size()):
		InputMap.add_action(_actions[index])
		InputMap.action_add_event(_actions[index], CoreInputBinding.new(CoreInputBinding.Kind.PHYSICAL_KEY, KEY_A + index).to_event())
	inputs = CoreInputs.new()
	var registered: Error = inputs.register_actions(_actions)
	if registered != OK:
		push_error("Failed to register example input actions.")
		return
	# Stable profile names are mapped separately from instance-specific engine actions.
	_store = CoreSaveDirectory.new(ProjectSettings.globalize_path("user://core_system")).create_store(save_name, 1, _validate_saved)
	if _store == null:
		_report("Invalid save identifier; persistence is unavailable.")
		return
	_report("Click Rebind, then press a key or click outside the controls. Escape cancels.")

func _exit_tree() -> void:
	for action: StringName in _actions:
		InputMap.erase_action(action)

func _unhandled_input(event: InputEvent) -> void:
	if capturing:
		handle_capture(event)
		get_viewport().set_input_as_handled()
	else:
		for index: int in range(_actions.size()):
			if event.is_action_pressed(_actions[index], false, true):
				_report("Action %d triggered." % (index + 1))

func handle_capture(event: InputEvent) -> void:
	if not capturing:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel()
		return
	var binding: CoreInputBinding = CoreInputBinding.from_event(event, _physical.button_pressed, true)
	if binding == null:
		return
	var action: StringName = _actions[_action.selected]
	var result: Error = inputs.rebind(action, binding)
	if result == OK:
		capturing = false
	_report("Binding updated." if result == OK else "Binding rejected: " + error_string(result))

func _begin() -> void:
	capturing = true
	_report("Listening. Escape or Cancel stops capture.")

func _cancel() -> void:
	capturing = false
	_report("Capture cancelled; bindings retained.")

func _reset() -> void:
	capturing = false
	_report(error_string(inputs.restore_defaults()))

func _save() -> void:
	capturing = false
	if _store == null:
		_report("Persistence is unavailable.")
		return
	var data: Dictionary = _stable_data(inputs.to_data())
	var result: CoreSaveResult = _store.save(data)
	_report("Bindings saved." if result.error == OK else result.message)

func _load_saved() -> void:
	capturing = false
	if _store == null:
		_report("Persistence is unavailable.")
		return
	var result: CoreSaveResult = _store.try_load()
	if result.error != OK or not result.found:
		_report(result.message if result.error != OK else "No saved bindings; current bindings retained.")
		return
	_report(error_string(inputs.apply_data(_engine_data(result.data))))

func _stable_data(data: Dictionary) -> Dictionary:
	var actions: Dictionary = {}
	for index: int in range(_actions.size()):
		actions[str(index)] = data.Actions[String(_actions[index])]
	return {"Actions": actions}

func _engine_data(data: Dictionary) -> Dictionary:
	var actions: Dictionary = {}
	for index: int in range(_actions.size()):
		if data.Actions.has(str(index)):
			actions[String(_actions[index])] = data.Actions[str(index)]
	return {"Actions": actions}

func _validate_saved(data: Dictionary) -> Error:
	if data.size() != 1 or not data.has("Actions") or not data.Actions is Dictionary or data.Actions.size() != 2 or not data.Actions.has("0") or not data.Actions.has("1"):
		return ERR_INVALID_DATA
	return inputs.validate_data(_engine_data(data))

func _report(message: String) -> void:
	var lines: PackedStringArray = [message]
	for index: int in range(_actions.size()):
		var labels: PackedStringArray = []
		for event: InputEvent in InputMap.action_get_events(_actions[index]):
			labels.append(event.as_text())
		lines.append("Action %d: %s" % [index + 1, ", ".join(labels)])
	_status.text = "\n".join(lines)
