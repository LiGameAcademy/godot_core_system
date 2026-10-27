extends RefCounted

## Explicitly registered save recipients. The registry neither owns nor finds
## nodes, and never creates dynamic game objects.
var _nodes: Dictionary[String, WeakRef] = {}

## A stable ID survives scene renaming. An empty ID retains NodePath identity.
## The caller chooses the ID; this class does not inspect node properties.
func register_node(node: Node, save_id: StringName = &"") -> Error:
	if not Thread.is_main_thread():
		return ERR_UNAVAILABLE
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return ERR_INVALID_PARAMETER
	if save_id.is_empty() and not node.is_inside_tree():
		return ERR_UNCONFIGURED
	var key: String = _node_key(node, save_id)
	var existing: Node = resolve_key(key)
	if existing != null:
		return OK if existing == node else ERR_ALREADY_IN_USE
	# One node has one identity. Explicitly unregister before changing it.
	for registered_key: String in _nodes.keys():
		if resolve_key(registered_key) == node:
			return ERR_ALREADY_IN_USE
	_nodes[key] = weakref(node)
	return OK

func unregister_node(node: Node) -> void:
	if not Thread.is_main_thread():
		return
	for key: String in _nodes.keys():
		if resolve_key(key) == node:
			_nodes.erase(key)

## Record identity fields are independent of payload data. Namespacing keeps
## an ID such as '/root/World/Player' distinct from the same literal NodePath.
static func record_key(kind: StringName, identity: String) -> String:
	if identity.is_empty() or (kind != &"id" and kind != &"path"):
		return ""
	if kind == &"path" and not NodePath(identity).is_absolute():
		return ""
	return "%s:%s" % [kind, identity]

func resolve(kind: StringName, identity: String) -> Node:
	return resolve_key(record_key(kind, identity))

func resolve_key(key: String) -> Node:
	if not Thread.is_main_thread() or not _nodes.has(key):
		return null
	var reference: WeakRef = _nodes[key]
	var value: Variant = reference.get_ref()
	if not is_instance_valid(value) or not value is Node:
		_nodes.erase(key)
		return null
	var node: Node = value
	if node.is_queued_for_deletion():
		_nodes.erase(key)
		return null
	# A path recipient must still have its registered path. A stable ID has no
	# dependency on parent names or the object's current position in the tree.
	if key.begins_with("path:"):
		if not node.is_inside_tree() or "path:" + str(node.get_path()) != key:
			_nodes.erase(key)
			return null
	return node

## Callers can iterate a deterministic identity list when building a snapshot.
func get_keys() -> Array[String]:
	var result: Array[String] = []
	if not Thread.is_main_thread():
		return result
	for key: String in _nodes.keys():
		if resolve_key(key) != null:
			result.append(key)
	result.sort()
	return result

func clear() -> void:
	if Thread.is_main_thread():
		_nodes.clear()

static func _node_key(node: Node, save_id: StringName) -> String:
	if not save_id.is_empty():
		return record_key(&"id", String(save_id))
	return record_key(&"path", str(node.get_path()))
