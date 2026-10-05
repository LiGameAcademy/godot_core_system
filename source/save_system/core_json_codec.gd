class_name CoreJsonCodec
extends RefCounted

## Strict JSON syntax and duplicate-key validation before handing data to a schema.
var error: Error = OK
var message: String = ""
var _text: String
var _position: int = 0
var _number: RegEx = RegEx.create_from_string(r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?')
var _string: RegEx = RegEx.create_from_string(r'"(?:[^"\\\x00-\x1f]|\\["\\/bfnrt]|\\u[0-9A-Fa-f]{4})*"')

func parse(text: String) -> Variant:
	_text = text
	_position = 0
	error = OK
	message = ""
	var value: Variant = _value(0)
	_space()
	if error == OK and _position != _text.length():
		_fail("Unexpected trailing JSON content.")
	return value

static func is_json_value(value: Variant, depth: int = 0) -> bool:
	if depth > 64:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for item: Variant in value:
				if not is_json_value(item, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			for key: Variant in value:
				if not key is String or not is_json_value(value[key], depth + 1):
					return false
			return true
	return false

func _value(depth: int) -> Variant:
	_space()
	if depth > 64 or _position >= _text.length():
		_fail("JSON is too deep or incomplete.")
		return null
	var character: String = _text[_position]
	if character == "{":
		return _object(depth + 1)
	if character == "[":
		return _array(depth + 1)
	if character == '"':
		return _read_string()
	for literal: String in ["true", "false", "null"]:
		if _text.substr(_position, literal.length()) == literal:
			_position += literal.length()
			return true if literal == "true" else (false if literal == "false" else null)
	var matched: RegExMatch = _number.search(_text, _position)
	if matched == null or matched.get_start() != _position:
		_fail("Invalid JSON value.")
		return null
	var token: String = matched.get_string()
	_position = matched.get_end()
	if not token.contains(".") and not token.to_lower().contains("e"):
		var integer: int = token.to_int()
		if str(integer) != token and token != "-0":
			_fail("JSON integer exceeds the supported 64-bit range.")
		return integer
	var number: float = token.to_float()
	if not is_finite(number):
		_fail("JSON numbers must be finite.")
	return number

func _object(depth: int) -> Dictionary:
	var result: Dictionary = {}
	_position += 1
	_space()
	if _consume("}"):
		return result
	while error == OK:
		_space()
		if _position >= _text.length() or _text[_position] != '"':
			_fail("JSON object keys must be strings.")
			break
		var key: String = _read_string()
		if result.has(key):
			_fail("Duplicate JSON property: " + key)
			break
		_space()
		if not _consume(":"):
			_fail("Missing JSON property separator.")
			break
		result[key] = _value(depth)
		_space()
		if _consume("}"):
			return result
		if not _consume(","):
			_fail("Missing JSON object separator.")
	return result

func _array(depth: int) -> Array[Variant]:
	var result: Array[Variant] = []
	_position += 1
	_space()
	if _consume("]"):
		return result
	while error == OK:
		result.append(_value(depth))
		_space()
		if _consume("]"):
			return result
		if not _consume(","):
			_fail("Missing JSON array separator.")
	return result

func _read_string() -> String:
	var matched: RegExMatch = _string.search(_text, _position)
	if matched == null or matched.get_start() != _position:
		_fail("Invalid JSON string or escape.")
		return ""
	_position = matched.get_end()
	var json: JSON = JSON.new()
	if json.parse(matched.get_string()) != OK or not json.data is String:
		_fail("Invalid Unicode JSON string.")
		return ""
	return json.data

func _space() -> void:
	while _position < _text.length() and _text[_position] in [" ", "\t", "\r", "\n"]:
		_position += 1

func _consume(character: String) -> bool:
	if _position < _text.length() and _text[_position] == character:
		_position += 1
		return true
	return false

func _fail(detail: String) -> void:
	error = ERR_INVALID_DATA
	message = detail
