class_name CoreTags
extends RefCounted

## Local, case-sensitive paths. Descendants satisfy a parent query, never the reverse.
signal tag_added(path: String)
signal tag_removed(path: String)

var count: int:
	get:
		return _tags.size()

var _tags: Dictionary[String, bool] = {}

static func is_valid_path(path: String) -> bool:
	if path.is_empty() or path.length() > 128:
		return false
	for segment: String in path.split("."):
		if segment.is_empty():
			return false
		for index: int in range(segment.length()):
			var code: int = segment.unicode_at(index)
			if not (code >= 65 and code <= 90 or code >= 97 and code <= 122
				or code >= 48 and code <= 57 or code == 95):
				return false
	return true

func add(path: String) -> bool:
	if not _validate(path) or _tags.has(path):
		return false
	_tags[path] = true
	tag_added.emit(path)
	return true

func remove(path: String) -> bool:
	if not _validate(path) or not _tags.has(path):
		return false
	_tags.erase(path)
	tag_removed.emit(path)
	return true

func has(path: String, exact: bool = true) -> bool:
	if not _validate(path):
		return false
	return _has_valid(path, exact)

func has_all(paths: Array[String], exact: bool = true) -> bool:
	if not _validate_all(paths):
		return false
	for path: String in paths:
		if not _has_valid(path, exact):
			return false
	return true

func has_any(paths: Array[String], exact: bool = true) -> bool:
	if not _validate_all(paths):
		return false
	for path: String in paths:
		if _has_valid(path, exact):
			return true
	return false

## A sorted copy of explicitly stored paths; implicit ancestors are not inserted.
func snapshot() -> Array[String]:
	var result: Array[String] = []
	result.assign(_tags.keys())
	result.sort()
	return result

## Clear commits before notification. Tags added by observers remain in the collection.
func clear() -> int:
	var removed: Array[String] = snapshot()
	_tags.clear()
	for path: String in removed:
		tag_removed.emit(path)
	return removed.size()

func _has_valid(path: String, exact: bool) -> bool:
	if _tags.has(path):
		return true
	if not exact:
		for stored: String in _tags:
			if stored.begins_with(path + "."):
				return true
	return false

func _validate(path: String) -> bool:
	if is_valid_path(path):
		return true
	push_error("Invalid tag path: use 1-128 ASCII letters, digits, underscores and nonempty dot-separated segments.")
	return false

func _validate_all(paths: Array[String]) -> bool:
	for path: String in paths:
		if not _validate(path):
			return false
	return true
