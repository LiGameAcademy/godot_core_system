class_name CoreInstancePool
extends RefCounted

## Owns admitted nodes. Callers stop/reset actors and detach them before recycling.
const OWNER_KEY: StringName = &"_core_instance_pool_owner"
var capacity: int:
	get:
		return _capacity
var cached_count: int:
	get:
		_prune()
		return _idle.size()
var leased_count: int:
	get:
		_prune()
		return _owned.size() - _idle.size()
var is_closed: bool:
	get:
		return _closed

var _capacity: int
var _id: String
var _idle: Array[Node] = []
var _idle_ids: Dictionary[int, bool] = {}
var _owned: Dictionary[int, Node] = {}
var _closed: bool = false
var _clearing: bool = false

func _init(max_cached: int = 256) -> void:
	if max_cached < 0:
		push_error("Pool capacity cannot be negative; using zero.")
	_capacity = maxi(0, max_cached)
	_id = str(get_instance_id())

## Returns a detached cached node, or null; creation remains the caller's responsibility.
func take() -> Node:
	if not _main_thread() or _closed or _clearing:
		return null
	while not _idle.is_empty():
		var entry: Variant = _idle.pop_back()
		if not is_instance_valid(entry):
			continue
		var node: Node = entry as Node
		var id: int = node.get_instance_id()
		_idle_ids.erase(id)
		if node.is_queued_for_deletion() or node.get_parent() != null:
			_forget(node)
			continue
		return node
	return null

## Fresh detached nodes are admitted; foreign leases, attached nodes and duplicates are rejected.
func recycle(node: Node) -> Error:
	if not _main_thread():
		return ERR_INVALID_PARAMETER
	if _closed:
		return ERR_UNAVAILABLE
	if _clearing:
		return ERR_BUSY
	if not is_instance_valid(node) or node.is_queued_for_deletion() or node.get_parent() != null:
		return ERR_INVALID_PARAMETER
	var id: int = node.get_instance_id()
	if node.has_meta(OWNER_KEY) and node.get_meta(OWNER_KEY) != _id:
		return ERR_ALREADY_IN_USE
	if _idle_ids.has(id):
		return ERR_ALREADY_IN_USE
	if _idle.size() >= _capacity:
		_prune()
	if _idle.size() >= _capacity:
		_forget(node)
		_clearing = true
		node.free()
		_clearing = false
		return OK
	node.set_meta(OWNER_KEY, _id)
	_owned[id] = node
	_idle_ids[id] = true
	_idle.append(node)
	return OK

## Clears cached nodes; outstanding leases remain owned until recycled or closed.
func clear() -> void:
	if not _main_thread() or _closed or _clearing:
		return
	_clearing = true
	var nodes: Array[Node] = _idle.duplicate()
	_idle.clear()
	_idle_ids.clear()
	for entry: Variant in nodes:
		if is_instance_valid(entry):
			var node: Node = entry as Node
			_forget(node)
			_release(node)
	_clearing = false

## Final close also releases leases. Attached leases are queued for deletion.
func close() -> void:
	if not _main_thread() or _closed:
		return
	_closed = true
	var nodes: Array[Node] = _owned.values()
	_owned.clear()
	_idle.clear()
	_idle_ids.clear()
	for entry: Variant in nodes:
		if is_instance_valid(entry):
			var node: Node = entry as Node
			if node.has_meta(OWNER_KEY):
				node.remove_meta(OWNER_KEY)
			_release(node)

func _forget(node: Node) -> void:
	_owned.erase(node.get_instance_id())
	if node.has_meta(OWNER_KEY) and node.get_meta(OWNER_KEY) == _id:
		node.remove_meta(OWNER_KEY)

func _release(node: Node) -> void:
	if node.is_queued_for_deletion():
		return
	if node.get_parent() != null:
		node.queue_free()
	else:
		node.free()

func _prune() -> void:
	if not _main_thread():
		return
	for id: int in _owned.keys():
		var entry: Variant = _owned[id]
		if not is_instance_valid(entry) or (entry as Node).is_queued_for_deletion():
			_owned.erase(id)
	var valid: Array[Node] = []
	for entry: Variant in _idle:
		if not is_instance_valid(entry):
			continue
		var node: Node = entry as Node
		if node.is_queued_for_deletion() or node.get_parent() != null:
			_forget(node)
		else:
			valid.append(node)
	_idle = valid
	_idle_ids.clear()
	for node: Node in _idle:
		_idle_ids[node.get_instance_id()] = true

func _main_thread() -> bool:
	if OS.get_thread_caller_id() == OS.get_main_thread_id():
		return true
	push_error("CoreInstancePool requires the main thread.")
	return false
