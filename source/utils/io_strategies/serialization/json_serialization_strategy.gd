extends "./serialization_strategy.gd"

func serialize(data: Variant) -> Variant:
	var json_str: String = JSON.stringify(data, "\t", false)
	if json_str.is_empty():
		push_error("Failed to serialize data to JSON: %s" % str(data))
		return null
	return json_str.to_utf8_buffer()

func deserialize(bytes: PackedByteArray) -> Variant:
	var json_str: String = bytes.get_string_from_utf8()
	if json_str.is_empty() and bytes.size() > 0:
		# Handle cases where non-utf8 bytes might result in empty string
		push_error("Could not decode bytes as UTF8 string for JSON deserialization.")
		return null
	if json_str.is_empty() and bytes.size() == 0:
		# Handle empty input gracefully (e.g., return empty dict or null)
		return null

	var json: JSON = JSON.new()
	var error: Error = json.parse(json_str)
	if error == OK:
		return json.get_data()
	else:
		push_error("JSON parsing error: %s (Line: %d)" % [json.get_error_message(), json.get_error_line()])
		return null
