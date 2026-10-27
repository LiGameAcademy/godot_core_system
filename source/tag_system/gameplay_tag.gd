@tool
extends RefCounted
class_name CoreGameplayTag

## Deprecated path record. Use CoreTags for runtime ownership and rule queries.
var name: String:
	get:
		return _path.get_slice(".", _path.get_slice_count(".") - 1)
	set(_value):
		push_error("Tag identity is read-only; create a new full-path record.")
var parent: CoreGameplayTag:
	get:
		return _parent_ref.get_ref() as CoreGameplayTag if _parent_ref != null else null
	set(_value):
		push_error("Use add_child/remove_child to update legacy metadata.")
var children: Array[CoreGameplayTag]:
	get:
		var result: Array[CoreGameplayTag] = []
		for reference: WeakRef in _children_refs.duplicate():
			var child: CoreGameplayTag = reference.get_ref() as CoreGameplayTag
			if child == null:
				_children_refs.erase(reference)
			else:
				result.append(child)
		return result
	set(_value):
		push_error("Child metadata is a read-only snapshot.")

var _path: String = ""
var _parent_ref: WeakRef
var _children_refs: Array[WeakRef] = []

static func create(full_path: String) -> CoreGameplayTag:
	if not CoreTags.is_valid_path(full_path):
		push_error("Invalid tag path; use a valid full path.")
		return null
	var tag: CoreGameplayTag = CoreGameplayTag.new()
	tag._path = full_path
	return tag

## Weak metadata links never change path identity. Only direct full-path children fit.
func add_child(child: CoreGameplayTag) -> bool:
	if child == null or child == self or _path.is_empty():
		push_error("Cannot attach a null or self tag.")
		return false
	var separator: int = child._path.rfind(".")
	if separator < 0 or child._path.substr(0, separator) != _path:
		push_error("Child path must be a direct descendant of the parent path.")
		return false
	if child in children:
		return false
	var previous: CoreGameplayTag = child.parent
	if previous != null:
		previous.remove_child(child)
	_children_refs.append(weakref(child))
	child._parent_ref = weakref(self)
	return true

func remove_child(child: CoreGameplayTag) -> bool:
	for reference: WeakRef in _children_refs.duplicate():
		var existing: CoreGameplayTag = reference.get_ref() as CoreGameplayTag
		if existing == null:
			_children_refs.erase(reference)
		elif existing == child:
			_children_refs.erase(reference)
			if child.parent == self:
				child._parent_ref = null
			return true
	return false

func get_full_path() -> String:
	return _path

func get_all_children() -> Array[CoreGameplayTag]:
	var result: Array[CoreGameplayTag] = []
	for child: CoreGameplayTag in children:
		result.append(child)
		result.append_array(child.get_all_children())
	return result

func matches(other: CoreGameplayTag, exact: bool = true) -> bool:
	if other == null or not CoreTags.is_valid_path(_path) or not CoreTags.is_valid_path(other._path):
		return false
	return _path == other._path or (not exact and _path.begins_with(other._path + "."))