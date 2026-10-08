extends "./serialization_strategy.gd"

## 默认保持原有排版；JSONL调用者可选择紧凑、键排序输出。
var indent: String = "\t"
var sort_keys: bool = false

func serialize(data: Variant) -> Variant:
	last_error = ""
	var json_str: String = JSON.stringify(data, indent, sort_keys)
	if json_str.is_empty() and data != null:
		last_error = "Failed to serialize data to JSON."
		return null
	return json_str.to_utf8_buffer()

func deserialize(bytes: PackedByteArray) -> Variant:
	last_error = ""
	var json_str: String = bytes.get_string_from_utf8()
	if json_str.is_empty() and bytes.size() > 0:
		# Handle cases where non-utf8 bytes might result in empty string
		last_error = "Could not decode bytes as UTF8 string for JSON deserialization."
		return null
	if json_str.is_empty() and bytes.size() == 0:
		# Handle empty input gracefully (e.g., return empty dict or null)
		return null

	var json: JSON = JSON.new()
	var error: Error = json.parse(json_str)
	if error == OK:
		return json.get_data()
	else:
		last_error = "JSON parsing error: %s (Line: %d)" % [json.get_error_message(), json.get_error_line()]
		return null
