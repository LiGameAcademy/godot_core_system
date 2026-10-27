extends ResourceFormatLoader

## Test-only native worker fixture: deterministic delay and a genuine loader failure.
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["corecheck"])

func _get_resource_type(_path: String) -> String:
	return "Gradient"

func _handles_type(type: StringName) -> bool:
	return type == &"Gradient" or type == &"Resource"

func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	OS.delay_msec(150)
	if path.contains("failure"):
		return ERR_CANT_OPEN
	return Gradient.new()
