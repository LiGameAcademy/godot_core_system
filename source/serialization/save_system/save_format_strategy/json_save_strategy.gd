extends "./save_format_strategy.gd"

func _init(p_manager: Node):
    super(p_manager)

func is_valid_save_file(file_name: String) -> bool:
    return file_name.ends_with(".json")

func get_save_id_from_file(file_name: String) -> String:
    return file_name.trim_suffix(".json")

func get_save_path(directory: String, save_id: String) -> String:
    return directory.path_join("%s.json" % save_id)

func save(path: String, data: Dictionary, callback: Callable) -> void:
    var json_str = JSON.stringify(data, "  ")
    var file = FileAccess.open(path, FileAccess.WRITE)
    
    if file:
        file.store_string(json_str)
        file.close()
        callback.call(true)
    else:
        callback.call(false)

func load(path: String, callback: Callable) -> void:
    if not FileAccess.file_exists(path):
        callback.call(false, {})
        return
        
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        callback.call(false, {})
        return
        
    var json_str = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var error = json.parse(json_str)
    
    if error == OK:
        callback.call(true, json.data)
    else:
        callback.call(false, {})

func load_metadata(path: String, callback: Callable) -> void:
    if not FileAccess.file_exists(path):
        callback.call(false, {})
        return
        
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        callback.call(false, {})
        return
        
    var json_str = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var error = json.parse(json_str)
    
    if error == OK and json.data is Dictionary and json.data.has("metadata"):
        callback.call(true, json.data.metadata)
    else:
        callback.call(false, {})
