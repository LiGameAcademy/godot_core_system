extends Node

## 清理间隔时间(秒)
const CLEANUP_INTERVAL := 30.0

## 所有注册的标签
var _registered_tags: Dictionary = {}

## 标签到对象的映射
## 结构: { tag_path: { object_id: weak_ref } }
var _tag_to_objects: Dictionary = {}

## 对象到标签容器的映射
## 结构: { object_id: weak_ref_to_tag_container }
var _object_to_tags: Dictionary = {}

## 清理定时器
var _cleanup_timer: Timer

func _ready() -> void:
	# 创建并启动清理定时器
	_cleanup_timer = Timer.new()
	_cleanup_timer.wait_time = CLEANUP_INTERVAL
	_cleanup_timer.timeout.connect(_on_cleanup_timer_timeout)
	add_child(_cleanup_timer)
	_cleanup_timer.start()

func _exit_tree() -> void:
	if _cleanup_timer:
		_cleanup_timer.queue_free()
		_cleanup_timer = null

## 从路径注册标签
func _register_tag_from_path(path: String) -> void:
	var parts := path.split(".")
	var current_path := ""
	var parent: CoreGameplayTag
	
	for part in parts:
		if current_path.is_empty():
			current_path = part
		else:
			current_path += "." + part
			
		if not _registered_tags.has(current_path):
			var tag := CoreGameplayTag.create(part)
			if parent:
				parent.add_child(tag)
			_registered_tags[current_path] = tag
			
		parent = _registered_tags[current_path]

## 获取标签
## 如果标签不存在，会自动注册
func get_tag(tag_path: String) -> CoreGameplayTag:
	var tag := _registered_tags.get(tag_path)
	if not tag:
		_register_tag_from_path(tag_path)
		tag = _registered_tags.get(tag_path)
	return tag


## 获取所有匹配的标签
## 包括父标签和子标签
func get_matching_tags(tag_path: String) -> Array[CoreGameplayTag]:
	var result: Array[CoreGameplayTag] = []
	var target_tag := get_tag(tag_path)  # 先精确获取目标标签
	if not target_tag:
		return result
		
	# 添加所有父标签
	var current := target_tag
	while current:
		result.append(current)
		current = current.parent
	
	# 添加所有子标签
	result.append_array(target_tag.get_all_children())
	
	return result

## 创建标签容器
## owner: 容器所属的对象，用于自动注册
func create_tag_container(owner: Object = null) -> GameplayTagContainer:
	var container := GameplayTagContainer.new()
	if owner:
		container.owner = owner
		container.tag_added.connect(_on_container_tag_added.bind(owner))
		container.tag_removed.connect(_on_container_tag_removed.bind(owner))
		_object_to_tags[owner.get_instance_id()] = weakref(container)
	return container

## 从字符串数组创建标签容器
func create_tag_container_from_strings(tag_strings: Array, owner: Object = null) -> GameplayTagContainer:
	var container := create_tag_container(owner)
	for tag_string in tag_strings:
		container.add_tag(tag_string)
	return container

## 获取具有指定标签的所有对象
func get_objects_with_tag(tag_path: String, exact: bool = true) -> Array:
	_cleanup_invalid_refs()
	var result = []
	
	if exact:
		# 精确匹配
		if _tag_to_objects.has(tag_path):
			for object_ref in _tag_to_objects[tag_path].values():
				var object = object_ref.get_ref()
				if object:
					result.append(object)
	else:
		# 获取所有匹配的标签
		var matching_tags := get_matching_tags(tag_path)
		for tag in matching_tags:
			var tag_path_str := tag.get_full_path()
			if _tag_to_objects.has(tag_path_str):
				for object_ref in _tag_to_objects[tag_path_str].values():
					var object = object_ref.get_ref()
					if object and not object in result:
						result.append(object)
	
	return result

## 获取具有所有指定标签的对象
func get_objects_with_all_tags(tag_paths: Array[String], exact: bool = true) -> Array:
	_cleanup_invalid_refs()
	var result = []
	var first_tag = tag_paths[0]
	var candidates = get_objects_with_tag(first_tag, exact)
	
	for object in candidates:
		var container_ref = _object_to_tags.get(object.get_instance_id())
		if not container_ref:
			continue
			
		var tag_container = container_ref.get_ref()
		if not tag_container:
			continue
			
		if tag_container.has_all_tags(tag_paths, exact):
			result.append(object)
	
	return result

## 获取具有任意指定标签的对象
func get_objects_with_any_tags(tag_paths: Array[String], exact: bool = true) -> Array:
	_cleanup_invalid_refs()
	var result = []
	
	for tag_path in tag_paths:
		for object in get_objects_with_tag(tag_path, exact):
			if not object in result:
				result.append(object)
	
	return result

## 当容器添加标签时
func _on_container_tag_added(tag: CoreGameplayTag, owner: Object) -> void:
	var object_id = owner.get_instance_id()
	var tag_path = tag.get_full_path()
	
	if not _tag_to_objects.has(tag_path):
		_tag_to_objects[tag_path] = {}
	_tag_to_objects[tag_path][object_id] = weakref(owner)

## 当容器移除标签时
func _on_container_tag_removed(tag: CoreGameplayTag, owner: Object) -> void:
	var object_id = owner.get_instance_id()
	var tag_path = tag.get_full_path()
	
	if _tag_to_objects.has(tag_path):
		_tag_to_objects[tag_path].erase(object_id)
		if _tag_to_objects[tag_path].is_empty():
			_tag_to_objects.erase(tag_path)

## 当定时器超时时
func _on_cleanup_timer_timeout() -> void:
	_cleanup_invalid_refs()

## 清理无效引用
func _cleanup_invalid_refs() -> void:
	for tag_path in _tag_to_objects.keys():
		var objects = _tag_to_objects[tag_path]
		for object_id in objects.keys():
			if not objects[object_id].get_ref():
				objects.erase(object_id)
		if objects.is_empty():
			_tag_to_objects.erase(tag_path)
	
	for object_id in _object_to_tags.keys():
		if not _object_to_tags[object_id].get_ref():
			_object_to_tags.erase(object_id)
