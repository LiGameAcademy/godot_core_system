extends Resource
class_name GameplayTagContainer

## Deprecated compatibility facade. CoreTags is the sole membership authority.
signal tag_added(tag: CoreGameplayTag)
signal tag_removed(tag: CoreGameplayTag)

var _tags: CoreTags = CoreTags.new()
var _records: Dictionary[String, CoreGameplayTag] = {}

func add_tag(tag: Variant) -> bool:
	var path: String = _path_from(tag)
	if not _validate(path) or _tags.has(path):
		return false
	var record: CoreGameplayTag = tag as CoreGameplayTag if tag is CoreGameplayTag else CoreGameplayTag.create(path)
	_records[path] = record
	_tags.add(path)
	tag_added.emit(record)
	return true

func remove_tag(tag: Variant) -> bool:
	var path: String = _path_from(tag)
	if not _validate(path) or not _tags.has(path):
		return false
	var record: CoreGameplayTag = _records[path]
	_records.erase(path)
	_tags.remove(path)
	tag_removed.emit(record)
	return true

func has_tag(tag: Variant, exact: bool = true) -> bool:
	return _tags.has(_path_from(tag), exact)

func has_all_tags(required_tags: Array, exact: bool = true) -> bool:
	return _tags.has_all(_paths_from(required_tags), exact)

func has_any_tags(required_tags: Array, exact: bool = true) -> bool:
	return _tags.has_any(_paths_from(required_tags), exact)

## Full explicit paths; no leaf-name truncation or implicit ancestor insertion.
func get_tags() -> Array[String]:
	return _tags.snapshot()

## Legacy object payloads for explicit membership only, in sorted path order.
func get_all_tags() -> Array[CoreGameplayTag]:
	var result: Array[CoreGameplayTag] = []
	for path: String in _tags.snapshot():
		result.append(_records[path])
	return result

func _path_from(tag: Variant) -> String:
	if tag is String:
		return tag
	if tag is CoreGameplayTag:
		return (tag as CoreGameplayTag).get_full_path()
	return ""

func _paths_from(tags: Array) -> Array[String]:
	var result: Array[String] = []
	for tag: Variant in tags:
		result.append(_path_from(tag))
	return result

func _validate(path: String) -> bool:
	if CoreTags.is_valid_path(path):
		return true
	push_error("Expected a valid full path or initialized CoreGameplayTag record.")
	return false