extends Node

## Observe input extensions; only the explicitly supplied CoreInputs edits bindings.
const Inputs = preload("./core_inputs.gd")
const Axis = preload("./features/input_virtual_axis.gd")
const Buffer = preload("./features/input_buffer.gd")
const Recorder = preload("./features/input_recorder.gd")
const State = preload("./input_state.gd")
const Processor = preload("./features/input_event_processor.gd")

signal action_triggered(action_name: String, event: InputEvent)
signal axis_changed(axis_name: String, value: Vector2)
signal remap_completed(action: String, event: InputEvent)

@export var tracked_actions: Array[StringName] = []
var virtual_axis: Axis = Axis.new()
var input_buffer: Buffer = Buffer.new()
var input_recorder: Recorder = Recorder.new()
var input_state: State = State.new()
var event_processor: Processor = Processor.new()
## Optional legacy reference, explicitly assigned by the composition owner.
var config_manager: Node
var _bindings: Inputs
var _remap: Processor.KeyRemapHandler = Processor.KeyRemapHandler.new()
var _closed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Empty legacy observer watches existing actions, but cannot edit their bindings.
	if tracked_actions.is_empty():
		tracked_actions.assign(InputMap.get_actions())
	virtual_axis.axis_changed.connect(_on_axis_changed)
	_remap.remap_completed.connect(_on_remap_completed)
	event_processor.add_handler(_remap)

func _process(_delta: float) -> void:
	if _closed:
		return
	input_buffer.clean_expired_buffers()
	for axis_name: String in virtual_axis.get_registered_axes():
		virtual_axis.update_axis(axis_name)
	for action: StringName in tracked_actions:
		if InputMap.has_action(action):
			input_state.update_action(String(action), Input.is_action_pressed(action), Input.get_action_strength(action))

func _input(event: InputEvent) -> void:
	if _closed or _remap.is_remapping() or event_processor.process_event(event) or not event.is_action_type():
		return
	for action: StringName in tracked_actions:
		if not InputMap.has_action(action) or not event.is_action(action):
			continue
		var pressed: bool = event.is_action_pressed(action)
		var released: bool = event.is_action_released(action)
		if pressed or released:
			var strength: float = event.get_action_strength(action)
			input_state.update_action(String(action), pressed, strength)
			if pressed:
				input_buffer.add_buffer(String(action), strength)
			input_recorder.record_input(String(action), pressed, strength)
			action_triggered.emit(String(action), event)

## Capture after GUI handling so a cancel button cannot become the new binding.
func _unhandled_input(event: InputEvent) -> void:
	if not _closed and _remap.is_remapping() and event_processor.process_event(event):
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	close()

## Share one existing binding owner; this observer never claims a second group.
func use_bindings(bindings: Inputs) -> Error:
	if _closed or bindings == null or bindings.get_registered_actions().is_empty():
		return ERR_INVALID_PARAMETER
	cancel_remap()
	_bindings = bindings
	tracked_actions = bindings.get_registered_actions()
	return OK

func start_remap(action: StringName) -> Error:
	if _closed or _bindings == null or not _bindings.get_registered_actions().has(action):
		return ERR_UNCONFIGURED
	_remap.start_remap(String(action))
	return OK

func cancel_remap() -> void:
	_remap.cancel_remap()

## The caller owns supplied bindings and any persistence adapter.
func close() -> void:
	if _closed:
		return
	_closed = true
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	_remap.cancel_remap()
	if _remap.remap_completed.is_connected(_on_remap_completed):
		_remap.remap_completed.disconnect(_on_remap_completed)
	if virtual_axis.axis_changed.is_connected(_on_axis_changed):
		virtual_axis.axis_changed.disconnect(_on_axis_changed)
	event_processor.clear_handlers()
	event_processor.clear_filters()
	input_buffer.clear_all_buffers()
	input_recorder.reset()
	input_state.reset_action()
	virtual_axis.clear_axis()
	_bindings = null
	config_manager = null

func _on_axis_changed(axis_name: String, value: Vector2) -> void:
	axis_changed.emit(axis_name, value)

func _on_remap_completed(action: String, event: InputEvent) -> void:
	if _bindings == null:
		return
	var binding: CoreInputBinding = CoreInputBinding.from_event(event, event is InputEventKey and event.physical_keycode != 0, true)
	if binding != null and _bindings.rebind(StringName(action), binding) == OK:
		remap_completed.emit(action, event)
