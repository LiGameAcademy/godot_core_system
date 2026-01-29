extends Resource
class_name GameplayTagContainer

## 标签列表
var _tags: Array[CoreGameplayTag] = []

## 当添加标签时发出
signal tag_added(tag: CoreGameplayTag)
## 当移除标签时发出
signal tag_removed(tag: CoreGameplayTag)

var _tag_manager : CoreSystem.GameplayTagManager:
	get:
		if not _tag_manager:
			_tag_manager = CoreSystem.tag_manager
		return _tag_manager


## 添加标签
## 可以直接传入标签路径字符串或CoreGameplayTag对象
func add_tag(tag) -> void:
	var tag_obj: CoreGameplayTag
	if tag is String:
		tag_obj = _tag_manager.get_tag(tag)
		if not tag_obj:
			push_error("Tag not found: %s" % tag)
			return
	else:
		tag_obj = tag
	
	if not has_tag(tag_obj):
		_tags.append(tag_obj)
		tag_added.emit(tag_obj)


## 移除标签
## 可以直接传入标签路径字符串或CoreGameplayTag对象
func remove_tag(tag) -> void:
	var tag_obj: CoreGameplayTag
	if tag is String:
		tag_obj = _tag_manager.get_tag(tag)
		if not tag_obj:
			push_error("Tag not found: %s" % tag)
			return
	else:
		tag_obj = tag
	
	if _tags.has(tag_obj):
		_tags.erase(tag_obj)
		tag_removed.emit(tag_obj)


## 是否有指定标签
## 可以直接传入标签路径字符串或CoreGameplayTag对象
func has_tag(tag, exact: bool = true) -> bool:
	var tag_obj: CoreGameplayTag
	if tag is String:
		tag_obj = _tag_manager.get_tag(tag)
		if not tag_obj:
			push_error("Tag not found: %s" % tag)
			return false
	else:
		tag_obj = tag
		
	for existing_tag in _tags:
		if existing_tag.matches(tag_obj, exact):
			return true
	return false


## 是否有所有指定标签
## 可以直接传入标签路径字符串数组或CoreGameplayTag数组
func has_all_tags(required_tags: Array, exact: bool = true) -> bool:
	for tag in required_tags:
		if not has_tag(tag, exact):
			return false
	return true


## 是否有任意指定标签
## 可以直接传入标签路径字符串数组或CoreGameplayTag数组
func has_any_tags(required_tags: Array, exact: bool = true) -> bool:
	for tag in required_tags:
		if has_tag(tag, exact):
			return true
	return false


## 获取所有标签
func get_tags() -> Array:
	return _tags.map(func(tag: CoreGameplayTag): return tag.name)


## 获取所有标签(包括子标签)
func get_all_tags() -> Array[CoreGameplayTag]:
	var result: Array[CoreGameplayTag] = []
	for tag in _tags:
		result.append(tag)
		result.append_array(tag.get_all_children())
	return result
