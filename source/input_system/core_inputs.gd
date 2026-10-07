class_name CoreInputs
extends RefCounted

## One explicit owner edits keyboard/mouse bindings for an existing action group.
var _defaults: Dictionary[StringName, Array] = {}
static var _owners: Dictionary[StringName, WeakRef] = {}

func register_actions(actions: Array[StringName]) -> Error:
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		return ERR_UNAVAILABLE
	if not _defaults.is_empty():
		return ERR_ALREADY_IN_USE
	if actions.is_empty() or actions.size() > 64:
		return ERR_INVALID_PARAMETER
	var staged: Dictionary[StringName, Array] = {}
	for action: StringName in actions:
		if String(action).is_empty() or String(action).length() > 128 or staged.has(action) or not InputMap.has_action(action):
			return ERR_INVALID_PARAMETER
		if _owners.has(action) and _owners[action].get_ref() != null:
			return ERR_ALREADY_IN_USE
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		for event: InputEvent in events:
			if _editable(event) and _binding(event) == null:
				return ERR_INVALID_DATA
		staged[action] = _copy_events(events)
	_defaults = staged
	var checked: Error = validate_data(to_data())
	if checked != OK:
		_defaults.clear()
	else:
		for action: StringName in _defaults:
			_owners[action] = weakref(self)
	return checked

func to_data() -> Dictionary:
	var actions: Dictionary = {}
	for action: StringName in _defaults:
		if not InputMap.has_action(action):
			continue
		var bindings: Array[Dictionary] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if _editable(event):
				var binding: CoreInputBinding = _binding(event)
				if binding == null:
					return {}
				bindings.append(binding.to_data())
		actions[String(action)] = bindings
	return {"Actions": actions}

func find_conflicts(action: StringName, binding: CoreInputBinding) -> Array[StringName]:
	var result: Array[StringName] = []
	if binding == null or not binding.is_valid():
		return result
	for other: StringName in _defaults:
		if other == action or not InputMap.has_action(other):
			continue
		for event: InputEvent in InputMap.action_get_events(other):
			var existing: CoreInputBinding = _binding(event)
			if existing != null and binding.conflicts(existing):
				result.append(other)
				break
	return result

func rebind(action: StringName, binding: CoreInputBinding) -> Error:
	if not _defaults.has(action) or binding == null or not binding.is_valid():
		return ERR_INVALID_PARAMETER
	var data: Dictionary = to_data()
	if data.is_empty() or not data.Actions.has(String(action)):
		return ERR_DOES_NOT_EXIST
	data.Actions[String(action)] = [binding.to_data()]
	return apply_data(data)

func validate_data(data: Dictionary) -> Error:
	if _defaults.is_empty() or data.size() != 1 or not data.has("Actions") or not data.Actions is Dictionary or data.Actions.size() != _defaults.size():
		return ERR_INVALID_DATA
	var seen: Array[CoreInputBinding] = []
	for action: StringName in _defaults:
		if not InputMap.has_action(action):
			return ERR_DOES_NOT_EXIST
		var name: String = String(action)
		if not data.Actions.has(name) or not data.Actions[name] is Array or data.Actions[name].size() > 16:
			return ERR_INVALID_DATA
		for value: Variant in data.Actions[name]:
			var binding: CoreInputBinding = CoreInputBinding.from_data(value)
			if binding == null:
				return ERR_INVALID_DATA
			for other: CoreInputBinding in seen:
				if binding.conflicts(other):
					return ERR_ALREADY_IN_USE
			seen.append(binding)
	return OK

func apply_data(data: Dictionary) -> Error:
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		return ERR_UNAVAILABLE
	var checked: Error = validate_data(data)
	if checked != OK:
		return checked
	for action: StringName in _defaults:
		for event: InputEvent in InputMap.action_get_events(action):
			if _editable(event):
				InputMap.action_erase_event(action, event)
		for value: Variant in data.Actions[String(action)]:
			InputMap.action_add_event(action, CoreInputBinding.from_data(value).to_event())
	return OK

func restore_defaults() -> Error:
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		return ERR_UNAVAILABLE
	if _defaults.is_empty():
		return ERR_UNCONFIGURED
	for action: StringName in _defaults:
		if not InputMap.has_action(action):
			return ERR_DOES_NOT_EXIST
	for action: StringName in _defaults:
		for event: InputEvent in InputMap.action_get_events(action):
			if _editable(event):
				InputMap.action_erase_event(action, event)
		for event: InputEvent in _copy_events(_defaults[action]):
			if _editable(event):
				InputMap.action_add_event(action, event)
	return OK

func get_registered_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	actions.assign(_defaults.keys())
	return actions

## Release modification rights; keep the user's current global bindings.
func close() -> void:
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		push_error("CoreInputs.close must run on the main thread.")
		return
	for action: StringName in _defaults:
		if _owners.has(action) and _owners[action].get_ref() == self:
			_owners.erase(action)
	_defaults.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(self):
		close()

static func _editable(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventMouseButton

static func _binding(event: InputEvent) -> CoreInputBinding:
	return CoreInputBinding.from_event(event, event is InputEventKey and event.physical_keycode != 0)

static func _copy_events(events: Array) -> Array[InputEvent]:
	var result: Array[InputEvent] = []
	for event: InputEvent in events:
		result.append(event.duplicate(true))
	return result
