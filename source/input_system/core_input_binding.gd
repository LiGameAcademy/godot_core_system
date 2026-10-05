class_name CoreInputBinding
extends RefCounted

## Serializable input identity; transient press state is never retained.
enum Kind { KEY, PHYSICAL_KEY, MOUSE_BUTTON }
const FIELDS: Array[String] = ["Kind", "Code", "Ctrl", "Alt", "Shift", "Meta"]
var kind: int
var code: int
var ctrl: bool
var alt: bool
var shift: bool
var meta: bool

func _init(binding_kind: int, binding_code: int, control: bool = false, alternate: bool = false, shifted: bool = false, command: bool = false) -> void:
	kind = binding_kind
	code = binding_code
	ctrl = control
	alt = alternate
	shift = shifted
	meta = command

func is_valid() -> bool:
	if kind == Kind.MOUSE_BUTTON:
		return code >= MOUSE_BUTTON_LEFT and code <= MOUSE_BUTTON_XBUTTON2
	if kind not in [Kind.KEY, Kind.PHYSICAL_KEY]:
		return false
	var named_range: bool = (code >= 32 and code <= 126) or code in [KEY_YEN, KEY_SECTION] or (code >= KEY_ESCAPE and code <= KEY_JIS_KANA)
	return named_range and OS.find_keycode_from_string(OS.get_keycode_string(code)) == code

func to_data() -> Dictionary:
	return {"Kind": kind, "Code": code, "Ctrl": ctrl, "Alt": alt, "Shift": shift, "Meta": meta}

func to_event() -> InputEventWithModifiers:
	if not is_valid():
		return null
	var event: InputEventWithModifiers
	if kind == Kind.MOUSE_BUTTON:
		var mouse: InputEventMouseButton = InputEventMouseButton.new()
		mouse.button_index = code
		event = mouse
	else:
		var key: InputEventKey = InputEventKey.new()
		if kind == Kind.PHYSICAL_KEY:
			key.physical_keycode = code
		else:
			key.keycode = code
		event = key
	event.ctrl_pressed = ctrl
	event.alt_pressed = alt
	event.shift_pressed = shift
	event.meta_pressed = meta
	return event

func conflicts(other: CoreInputBinding) -> bool:
	return code == other.code and ctrl == other.ctrl and alt == other.alt and shift == other.shift and meta == other.meta and (kind == other.kind or (kind != Kind.MOUSE_BUTTON and other.kind != Kind.MOUSE_BUTTON))

static func from_data(data: Variant) -> CoreInputBinding:
	if not data is Dictionary or data.size() != FIELDS.size():
		return null
	for field: String in FIELDS:
		if not data.has(field) or typeof(data[field]) != (TYPE_INT if field in ["Kind", "Code"] else TYPE_BOOL):
			return null
	var binding: CoreInputBinding = CoreInputBinding.new(data.Kind, data.Code, data.Ctrl, data.Alt, data.Shift, data.Meta)
	return binding if binding.is_valid() else null

static func from_event(event: InputEvent, physical: bool = false, capture: bool = false) -> CoreInputBinding:
	if not event is InputEventWithModifiers or event.command_or_control_autoremap:
		return null
	var kind_value: int
	var code_value: int
	if event is InputEventKey:
		if capture and (not event.pressed or event.echo or event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]):
			return null
		if not capture and (event.location != KEY_LOCATION_UNSPECIFIED or event.key_label != 0 or (event.keycode != 0 and event.physical_keycode != 0)):
			return null
		kind_value = Kind.PHYSICAL_KEY if physical else Kind.KEY
		code_value = event.physical_keycode if physical else event.keycode
	elif event is InputEventMouseButton:
		if capture and not event.pressed:
			return null
		kind_value = Kind.MOUSE_BUTTON
		code_value = event.button_index
	else:
		return null
	var binding: CoreInputBinding = CoreInputBinding.new(kind_value, code_value, event.ctrl_pressed, event.alt_pressed, event.shift_pressed, event.meta_pressed)
	return binding if binding.is_valid() else null
