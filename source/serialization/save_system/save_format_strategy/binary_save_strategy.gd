extends "./save_format_strategy.gd"

func _init(p_manager: Node):
    super(p_manager)

func is_valid_save_file(file_name: String) -> bool:
    return file_name.ends_with(".save")

func get_save_id_from_file(file_name: String) -> String:
    return file_name.trim_suffix(".save")

func get_save_path(directory: String, save_id: String) -> String:
    return directory.path_join("%s.save" % save_id)

func save(path: String, data: Dictionary, callback: Callable) -> void:
    var io_manager = manager._io_manager
    io_manager.write_file_async(
        path, 
        data, 
        manager.compression_enabled, 
        manager._encryption_key if manager.encryption_enabled else "",
        func(success: bool, _result): callback.call(success)
    )

func load(path: String, callback: Callable) -> void:
    var io_manager = manager._io_manager
    io_manager.read_file_async(
        path,
        manager.compression_enabled,
        manager._encryption_key if manager.encryption_enabled else "",
        func(success: bool, result):
            if success:
                callback.call(true, result)
            else:
                callback.call(false, {})
    )

func load_metadata(path: String, callback: Callable) -> void:
    var io_manager = manager._io_manager
    io_manager.read_file_async(
        path,
        manager.compression_enabled,
        manager._encryption_key if manager.encryption_enabled else "",
        func(success: bool, result):
            if success and result is Dictionary and result.has("metadata"):
                callback.call(true, result.metadata)
            else:
                callback.call(false, {})
    )
