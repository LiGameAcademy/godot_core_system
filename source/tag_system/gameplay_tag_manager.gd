extends Node

## Deprecated compatibility registry. Queries read live containers; there is no tag index.
var _registered_tags: Dictionary[String, CoreGameplayTag] = {}
var _owners: Dictionary[int, WeakRef] = {}
var _containers: Dictionary[int, WeakRef] = {}

func _exit_tree() -> void:
	_owners.clear()
	_containers.clear()
	_registered_tags.clear()

func get_tag(tag_path: String) -> CoreGameplayTag:
	if not _validate_paths([tag_path]):
		return null
	var current_path: String = ""
	var previous: CoreGameplayTag
	for part: String in tag_path.split("."):
		current_path = part if current_path.is_empty() else current_path + "." + part
		if not _registered_tags.has(current_path):
			var tag: CoreGameplayTag = CoreGameplayTag.create(current_path)
			_registered_tags[current_path] = tag
			if previous != null:
				previous.add_child(tag)
		previous = _registered_tags[current_path]
	return _registered_tags[tag_path]

## Exact path and registered descendants only. This query does not register missing paths.
func get_matching_tags(tag_path: String) -> Array[CoreGameplayTag]:
	var result: Array[CoreGameplayTag] = []
	if not _validate_paths([tag_path]):
		return result
	var paths: Array[String] = []
	paths.assign(_registered_tags.keys())
	paths.sort()
	for path: String in paths:
		if path == tag_path or path.begins_with(tag_path + "."):
			result.append(_registered_tags[path])
	return result

## At most one live container per owner. Repeated requests return that same container.
func create_tag_container(tag_owner: Object = null) -> GameplayTagContainer:
	if tag_owner == null:
		return GameplayTagContainer.new()
	if not _is_live_owner(tag_owner):
		push_error("Tag container owner must be alive and not queued for deletion.")
		return null
	_cleanup_invalid_refs()
	var id: int = tag_owner.get_instance_id()
	if _containers.has(id):
		return _containers[id].get_ref() as GameplayTagContainer
	var container: GameplayTagContainer = GameplayTagContainer.new()
	_owners[id] = weakref(tag_owner)
	_containers[id] = weakref(container)
	return container

func create_tag_container_from_strings(tag_strings: Array[String], tag_owner: Object = null) -> GameplayTagContainer:
	if not _validate_paths(tag_strings):
		return null
	var container: GameplayTagContainer = create_tag_container(tag_owner)
	if container == null:
		return null
	for path: String in tag_strings:
		container.add_tag(path)
	return container

func get_objects_with_tag(tag_path: String, exact: bool = true) -> Array[Object]:
	return _query([tag_path], true, exact)

func get_objects_with_all_tags(tag_paths: Array[String], exact: bool = true) -> Array[Object]:
	return _query(tag_paths, true, exact)

func get_objects_with_any_tags(tag_paths: Array[String], exact: bool = true) -> Array[Object]:
	return _query(tag_paths, false, exact)

func _query(paths: Array[String], all: bool, exact: bool) -> Array[Object]:
	var result: Array[Object] = []
	if not _validate_paths(paths):
		return result
	_cleanup_invalid_refs()
	for id: int in _owners:
		var owner: Object = _owners[id].get_ref()
		var container: GameplayTagContainer = _containers[id].get_ref() as GameplayTagContainer
		var matches: bool = container.has_all_tags(paths, exact) if all else container.has_any_tags(paths, exact)
		if matches:
			result.append(owner)
	return result

func _cleanup_invalid_refs() -> void:
	for id: int in _owners.keys():
		if not _is_live_owner(_owners[id].get_ref()) or _containers[id].get_ref() == null:
			_owners.erase(id)
			_containers.erase(id)

func _is_live_owner(owner: Object) -> bool:
	return is_instance_valid(owner) and not (owner is Node and (owner as Node).is_queued_for_deletion())

func _validate_paths(paths: Array[String]) -> bool:
	for path: String in paths:
		if not CoreTags.is_valid_path(path):
			push_error("Invalid tag path; use valid full paths for legacy queries.")
			return false
	return true