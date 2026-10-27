extends SceneTree

var _checks: int = 0
var _failed: bool = false

class ReleaseProbe extends Node:
	var pool: CoreInstancePool
	var result: Array[Error]
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			result.append(pool.recycle(self))

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var pool: CoreInstancePool = CoreInstancePool.new(2)
	var other: CoreInstancePool = CoreInstancePool.new(2)
	_check(pool.take() == null and pool.cached_count == 0, "Empty take is safe")
	_check(pool.recycle(null) == ERR_INVALID_PARAMETER, "Null rejected")
	var first: Node = Node.new()
	root.add_child(first)
	_check(pool.recycle(first) == ERR_INVALID_PARAMETER, "Attached instance rejected without detaching")
	root.remove_child(first)
	_check(pool.recycle(first) == OK and pool.cached_count == 1, "Detached instance admitted")
	_check(pool.recycle(first) == ERR_ALREADY_IN_USE and pool.cached_count == 1, "Duplicate recycle rejected")
	_check(other.recycle(first) == ERR_ALREADY_IN_USE, "Foreign cached instance rejected")
	_check(pool.take() == first and pool.leased_count == 1, "Take preserves identity and tracks lease")
	_check(other.recycle(first) == ERR_ALREADY_IN_USE, "Foreign lease rejected")
	pool.clear()
	_check(is_instance_valid(first) and pool.leased_count == 1, "Clear retains outstanding lease")
	_check(pool.recycle(first) == OK, "Lease can return after clear")
	var second: Node = Node.new()
	var overflow: Node = Node.new()
	pool.recycle(second)
	_check(pool.recycle(overflow) == OK and not is_instance_valid(overflow), "Capacity overflow released")
	_check(pool.cached_count == 2, "Capacity is bounded")
	second.free()
	_check(pool.cached_count == 1 and pool.take() == first, "Externally freed cached instance skipped")
	pool.recycle(first)
	first.queue_free()
	_check(pool.take() == null, "Queued cached instance skipped")
	await process_frame
	await process_frame
	_check(pool.cached_count == 0 and pool.leased_count == 0, "Invalid entries pruned from counts")
	var zero: CoreInstancePool = CoreInstancePool.new(0)
	var ephemeral: Node = Node.new()
	_check(zero.recycle(ephemeral) == OK and not is_instance_valid(ephemeral), "Zero capacity consumes returned node")
	zero.close()
	var releasing: CoreInstancePool = CoreInstancePool.new(0)
	var reentry: Array[Error] = []
	var probe: ReleaseProbe = ReleaseProbe.new()
	probe.pool = releasing
	probe.result = reentry
	releasing.recycle(probe)
	_check(reentry == [ERR_BUSY] and releasing.cached_count == 0, "Overflow release rejects reentrant return")
	releasing.close()
	var lease: Node = Node.new()
	pool.recycle(lease)
	pool.take()
	root.add_child(lease)
	pool.close()
	_check(pool.is_closed and pool.cached_count == 0 and pool.leased_count == 0, "Close commits empty final state")
	_check(lease.is_queued_for_deletion(), "Attached owned lease queued for release")
	pool.close()
	_check(pool.take() == null, "Closed pool does not reopen")
	var rejected: Node = Node.new()
	_check(pool.recycle(rejected) == ERR_UNAVAILABLE and is_instance_valid(rejected), "Rejected return retains caller ownership")
	rejected.free()
	await process_frame
	await process_frame
	_check(not is_instance_valid(lease), "Attached lease released after frame")
	var template: Gradient = Gradient.new()
	var a: Node = Node.new()
	var b: Node = Node.new()
	var gradient_a: Gradient = template.duplicate() as Gradient
	var gradient_b: Gradient = template.duplicate() as Gradient
	a.set_meta(&"palette", gradient_a)
	b.set_meta(&"palette", gradient_b)
	other.recycle(a)
	other.recycle(b)
	var original: Color = template.get_color(0)
	gradient_a.set_color(0, Color.RED)
	_check(gradient_b.get_color(0) == original and template.get_color(0) == original, "Caller duplicates isolate A/B/template")
	other.clear()
	_check(not is_instance_valid(a) and not is_instance_valid(b), "Clear frees cached nodes")
	other.close()
	var invalid_pool: CoreInstancePool = CoreInstancePool.new(2)
	var invalid: Node = Node.new()
	invalid_pool.recycle(invalid)
	invalid.free()
	invalid_pool.clear()
	_check(invalid_pool.cached_count == 0, "Clear tolerates externally freed cache")
	invalid = Node.new()
	invalid_pool.recycle(invalid)
	invalid.free()
	invalid_pool.close()
	_check(invalid_pool.is_closed, "Close tolerates externally freed ownership")
	var reparented_pool: CoreInstancePool = CoreInstancePool.new(1)
	var reparented: Node = Node.new()
	reparented_pool.recycle(reparented)
	root.add_child(reparented)
	_check(reparented_pool.take() == null and reparented_pool.leased_count == 0, "Externally attached cache is relinquished")
	reparented_pool.close()
	reparented.queue_free()
	var legacy: Node = load("res://addons/godot_core_system/source/resource_system/resource_manager.gd").new()
	root.add_child(legacy)
	_check(legacy.get_instance(&"actor") == null, "Legacy empty pool is safe")
	var legacy_node: Node = Node.new()
	root.add_child(legacy_node)
	legacy.recycle_instance(&"actor", legacy_node)
	_check(legacy.get_instance_count() == 1 and legacy.get_instance(&"actor") == legacy_node, "Legacy detach and take delegate to pool")
	legacy.recycle_instance(&"actor", legacy_node)
	legacy.clear_instance_pool()
	_check(not is_instance_valid(legacy_node) and legacy.get_instance_count() == 0, "Legacy clear releases nodes")
	legacy.queue_free()
	await process_frame
	await process_frame
	print("Instance pool checks: %d %s" % [_checks, "FAIL" if _failed else "PASS"])
	quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
