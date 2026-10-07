class_name CoreEntities
extends RefCounted

## Owns one scene's activations and an exclusively transferred, initially empty pool.
var is_closed: bool:
	get:
		return _closed
var _closed: bool = false
var active_count: int:
	get:
		return get_leases().size()
var cached_count: int:
	get:
		return _pool.cached_count if _pool != null else 0
var _scene: PackedScene
var _pool: CoreInstancePool
var _active: Dictionary[int, CoreEntityLease] = {}
var _busy: bool = false

func _init(scene: PackedScene, pool: CoreInstancePool) -> void:
	if not Thread.is_main_thread() or not is_instance_valid(scene) or not scene.can_instantiate() \
			or pool == null or pool.is_closed or pool.cached_count != 0 or pool.leased_count != 0:
		_closed = true
		push_error("CoreEntities requires a valid scene and an open, empty, exclusive pool on the main thread.")
		return
	_scene = scene
	_pool = pool

## Attach before initialization. Ready must work with scene defaults. Callbacks return Error.
func create(parent: Node, initialize: Callable) -> CoreEntityResult:
	var gate: Error = _gate()
	if gate != OK:
		return CoreEntityResult.new(gate)
	if not _alive(parent) or not parent.is_inside_tree() or not initialize.is_valid():
		return CoreEntityResult.new(ERR_INVALID_PARAMETER)
	_busy = true
	var instance: Node = _pool.take()
	if instance == null:
		instance = _scene.instantiate()
	var error: Error = ERR_CANT_CREATE
	if _alive(instance):
		parent.add_child(instance)
		if not is_closed and _alive(instance) and instance.get_parent() == parent:
			error = _invoke(initialize, instance)
			if error == OK and (is_closed or not _alive(instance) or instance.get_parent() != parent):
				error = ERR_UNAVAILABLE
		else:
			error = ERR_UNAVAILABLE
	var lease: CoreEntityLease = null
	if error == OK:
		lease = CoreEntityLease.new(instance)
		_active[instance.get_instance_id()] = lease
	else:
		_release(instance)
	_end_operation()
	return CoreEntityResult.new(error, lease)

func update(lease: CoreEntityLease, callback: Callable) -> Error:
	return _apply(lease, callback, false)

func recycle(lease: CoreEntityLease, deactivate: Callable) -> Error:
	return _apply(lease, deactivate, true)

func destroy(lease: CoreEntityLease) -> Error:
	var gate: Error = _gate()
	if gate != OK:
		return gate
	if not _owns(lease):
		return ERR_DOES_NOT_EXIST
	_busy = true
	_active.erase(lease.node.get_instance_id())
	_release(lease.node)
	_end_operation()
	return OK

## Clear releases active and cached nodes while retaining the scene definition.
func clear() -> Error:
	var gate: Error = _gate()
	if gate != OK:
		return gate
	_busy = true
	_drain()
	_pool.clear()
	_end_operation()
	return OK

func close() -> void:
	if not Thread.is_main_thread():
		push_error("CoreEntities requires the main thread.")
		return
	if is_closed:
		return
	_closed = true
	if not _busy:
		_drain()
		_pool.close()

func get_leases() -> Array[CoreEntityLease]:
	if not Thread.is_main_thread():
		return []
	for id: int in _active.keys():
		if not _alive(_active[id].node):
			_active.erase(id)
	return _active.values()

func _apply(lease: CoreEntityLease, callback: Callable, should_recycle: bool) -> Error:
	var gate: Error = _gate()
	if gate != OK:
		return gate
	if not _owns(lease):
		return ERR_DOES_NOT_EXIST
	if not callback.is_valid():
		return ERR_INVALID_PARAMETER
	_busy = true
	var error: Error = _invoke(callback, lease.node)
	if error == OK:
		if is_closed:
			error = ERR_UNAVAILABLE
		elif not _owns(lease):
			error = ERR_DOES_NOT_EXIST
		elif should_recycle:
			var instance: Node = lease.node
			var id: int = instance.get_instance_id()
			if instance.get_parent() != null:
				instance.get_parent().remove_child(instance)
			_active.erase(id)
			if is_closed or not _alive(instance):
				error = ERR_UNAVAILABLE
			else:
				error = _pool.recycle(instance)
			if error != OK:
				_release(instance)
	_end_operation()
	return error

func _owns(lease: CoreEntityLease) -> bool:
	return lease != null and _alive(lease.node) and _active.get(lease.node.get_instance_id()) == lease

func _gate() -> Error:
	if not Thread.is_main_thread():
		return ERR_UNAVAILABLE
	return ERR_UNAVAILABLE if is_closed else ERR_BUSY if _busy else OK

func _end_operation() -> void:
	_busy = false
	if is_closed:
		_drain()
		_pool.close()

func _drain() -> void:
	var leases: Array[CoreEntityLease] = get_leases()
	_active.clear()
	for lease: CoreEntityLease in leases:
		_release(lease.node)

static func _invoke(callback: Callable, instance: Node) -> Error:
	var value: Variant = callback.call(instance)
	if not value is int or int(value) < OK or int(value) > ERR_PRINTER_ON_FIRE:
		return ERR_INVALID_DATA
	return int(value) as Error

# Freed Godot objects must be validated before a typed Node argument conversion.
static func _alive(instance: Variant) -> bool:
	return is_instance_valid(instance) and instance is Node and not (instance as Node).is_queued_for_deletion()

static func _release(instance: Variant) -> void:
	if not _alive(instance):
		return
	var node: Node = instance as Node
	if node.get_parent() != null:
		node.queue_free()
	else:
		node.free()


