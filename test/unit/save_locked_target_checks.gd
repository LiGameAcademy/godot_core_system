extends SceneTree

func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 1:
		push_error("Supply the absolute path of the externally locked test file.")
		quit(1)
		return
	var path: String = arguments[0]
	var original: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var store: CoreSaveStore = CoreSaveStore.new(path, 1, func(_data: Dictionary) -> Error: return OK)
	var result: CoreSaveResult = store.save({"Count": 9})
	var passed: bool = result.error != OK and result.cleanup_error == OK and FileAccess.get_file_as_bytes(path) == original and DirAccess.get_files_at(path.get_base_dir()).size() == 1
	if passed:
		print("PASS: native locked target preserves original bytes and cleans temporary data")
	else:
		push_error("Native locked-target replacement contract failed.")
	quit(0 if passed else 1)
