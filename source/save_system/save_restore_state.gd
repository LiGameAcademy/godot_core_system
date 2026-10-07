extends RefCounted

const Registry: GDScript = preload("./save_object_registry.gd")
const Copy: GDScript = preload("./save_snapshot_copy.gd")
const Result: GDScript = preload("./save_slot_result.gd")

class Prepared extends RefCounted:
	var error: Error = OK
	var message: String = ""
	var states: Dictionary[String, Dictionary] = {}

var registry: Registry = Registry.new()
var readonly_resources: Array[Resource] = []
var _pending: Dictionary[String, Dictionary] = {}

func register_node(node: Node, save_id: StringName = &"", consume_pending: bool = true) -> Error:
	if not is_instance_valid(node) or (not node.has_method("save") and not node.has_method("load_data")):
		return ERR_INVALID_PARAMETER
	var error: Error = registry.register_node(node, save_id)
	if error != OK:
		return error
	if not consume_pending or not node.has_method("load_data"):
		return OK
	# Erase before calling game code so a reentrant registration cannot replay it.
	for key: String in _pending.keys():
		if registry.resolve_key(key) == node:
			var data: Dictionary = _pending[key]
			_pending.erase(key)
			node.call("load_data", data)
	return OK

func unregister_node(node: Node) -> void:
	registry.unregister_node(node)

## All mutable payloads are copied before replacing the previous pending map.
## Records have already passed identity/version validation in SaveSlots.
func prepare(snapshot: Dictionary) -> Prepared:
	var result: Prepared = Prepared.new()
	for record: Dictionary in snapshot["nodes"]:
		var key: String = Registry.record_key(record["identity_kind"], record["identity"])
		var owned: Copy.CopyResult = Copy.copy(record["data"], readonly_resources)
		if owned.error != OK:
			result.error = owned.error
			result.message = owned.message
			result.states.clear()
			return result
		result.states[key] = owned.data
	return result

func commit(prepared: Prepared, result: Result) -> void:
	_pending = prepared.states
	for key: String in _pending.keys():
		if not _pending.has(key):
			continue
		var node: Node = registry.resolve_key(key)
		if node != null and node.has_method("load_data"):
			var data: Dictionary = _pending[key]
			_pending.erase(key)
			node.call("load_data", data)
			result.applied_count += 1
	result.pending_identities = get_pending_identities()
	result.pending_count = result.pending_identities.size()

func capture(metadata: Dictionary) -> Result:
	var result: Result = Result.new(OK, "", &"capture")
	var payloads: Dictionary[String, Dictionary] = _pending.duplicate()
	for key: String in registry.get_keys():
		var node: Node = registry.resolve_key(key)
		if node == null or not node.has_method("save"):
			continue
		var value: Variant = node.call("save")
		if not value is Dictionary:
			return Result.new(ERR_INVALID_DATA, "Save recipient returned a non-dictionary: %s" % key, &"capture")
		payloads[key] = value
	var records: Array[Dictionary] = []
	for key: String in payloads:
		var delimiter: int = key.find(":")
		records.append({"identity_kind": key.left(delimiter), "identity": key.substr(delimiter + 1), "data": payloads[key]})
	result.data = {"metadata": metadata, "nodes": records}
	return result

## Saving keeps absent objects in the new snapshot without replaying game state.
func retain_unmatched(prepared: Prepared) -> void:
	_pending = prepared.states
	for key: String in _pending.keys():
		if registry.resolve_key(key) != null:
			_pending.erase(key)

func get_pending_identities() -> Array[String]:
	var keys: Array[String] = []
	keys.assign(_pending.keys())
	keys.sort()
	return keys

func clear_pending() -> void:
	_pending.clear()

func clear() -> void:
	registry.clear()
	_pending.clear()
	readonly_resources.clear()
