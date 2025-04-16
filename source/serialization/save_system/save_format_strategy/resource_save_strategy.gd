extends "./save_format_strategy.gd"

const GameStateData = CoreSystem.GameStateData

## 文件名是否有效
func is_valid_save_file(file_name: String) -> bool:
    return file_name.ends_with(".tres")

## 获取存档ID
func get_save_id_from_file(file_name: String) -> String:
    return file_name.trim_suffix(".tres")

## 获取存档路径
func get_save_path(directory: String, save_id: String) -> String:
    return directory.path_join("%s.tres" % save_id)

## 保存存档
func save(path: String, data: Dictionary, callback: Callable) -> void:
    # 创建一个新的GameStateData对象
    var save_data = GameStateData.new(data.metadata.id)
    
    # 添加元数据
    save_data.metadata.version = data.metadata.version
    save_data.metadata.timestamp = data.metadata.timestamp
    save_data.metadata.save_name = data.metadata.id
    
    if data.metadata.has("datetime"):
        save_data.metadata["datetime"] = data.metadata.datetime
    if data.metadata.has("playtime") or data.metadata.has("play_time"):
        save_data.metadata.play_time = data.metadata.get("playtime", data.metadata.get("play_time", 0))
    
    # 添加游戏数据
    for key in data.keys():
        if key != "metadata":
            save_data.set_data(key, data[key])

    # 保存资源
    var resource_data : Dictionary = save_data.serialize()
    
    # 创建和保存自定义资源
    var resource = Resource.new()
    for property in resource_data:
        resource.set_meta(property, resource_data[property])
    
    var error := ResourceSaver.save(resource, path)
    callback.call(error == OK)

## 加载存档
func load(path: String, callback: Callable) -> void:
    if not FileAccess.file_exists(path):
        callback.call(false, {})
        return
        
    var resource = ResourceLoader.load(path)
    if resource:
        var result_data = {}
        
        # 获取元数据
        var metadata = {}
        if resource.has_meta("metadata"):
            metadata = resource.get_meta("metadata")
        
        result_data["metadata"] = metadata
        
        # 获取其他游戏数据
        for meta_name in resource.get_meta_list():
            if meta_name != "metadata":
                result_data[meta_name] = resource.get_meta(meta_name)
        
        callback.call(true, result_data)
    else:
        callback.call(false, {})

func load_metadata(path: String, callback: Callable) -> void:
    if not FileAccess.file_exists(path):
        callback.call(false, {})
        return
        
    var resource = ResourceLoader.load(path)
    if resource and resource.has_meta("metadata"):
        var metadata = resource.get_meta("metadata")
        callback.call(true, metadata)
    else:
        callback.call(false, {})