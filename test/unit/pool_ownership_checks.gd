extends Node

const ResourceManager = preload("../../source/resource_system/resource_manager.gd")

class RecycleProbe extends Node:
	var pool: ResourceManager
	func _exit_tree() -> void:
		pool.recycle_instance(&"reentrant", self)

var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	var pool: ResourceManager = ResourceManager.new()
	add_child(pool)
	var item: Node = Node.new()
	pool.recycle_instance(&"one", item)
	pool.clear_instance_pool(&"one")
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not is_instance_valid(item), "Clearing a pool destroys its orphan nodes")
	if is_instance_valid(item):
		item.free()
	var duplicate: Node = Node.new()
	pool.recycle_instance(&"duplicate", duplicate)
	pool.recycle_instance(&"duplicate", duplicate)
	_check(pool.get_instance_count(&"duplicate") == 1, "Duplicate recycle is rejected")
	var first: Node = pool.get_instance(&"duplicate")
	var second: Node = pool.get_instance(&"duplicate")
	_check(first == duplicate and second == null, "One instance cannot be borrowed twice")
	first.free()
	var shared: Node = Node.new()
	pool.recycle_instance(&"a", shared)
	pool.recycle_instance(&"b", shared)
	first = pool.get_instance(&"a")
	second = pool.get_instance(&"b")
	_check(first == shared and second == null, "One instance cannot belong to multiple pools")
	first.free()
	var borrowed: Node = Node.new()
	pool.recycle_instance(&"borrowed", borrowed)
	pool.get_instance(&"borrowed")
	var a: Node = Node.new()
	var b: Node = Node.new()
	pool.recycle_instance(&"a", a)
	pool.recycle_instance(&"b", b)
	pool.clear_instance_pool()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not is_instance_valid(a) and not is_instance_valid(b), "All-pool clear destroys owned nodes")
	_check(is_instance_valid(borrowed), "Clearing pools does not destroy a borrowed instance")
	borrowed.free()
	var queued: Node = Node.new()
	queued.queue_free()
	pool.recycle_instance(&"invalid", queued)
	_check(pool.get_instance(&"invalid") == null, "Queued-for-deletion nodes cannot enter the pool")
	await get_tree().process_frame
	var stale: Node = Node.new()
	pool.recycle_instance(&"stale", stale)
	stale.free()
	_check(pool.get_instance(&"stale") == null, "Freed cached nodes are skipped safely")
	stale = Node.new()
	pool.recycle_instance(&"stale_clear", stale)
	stale.free()
	pool.clear_instance_pool(&"stale_clear")
	_check(pool.get_instance_count(&"stale_clear") == 0, "Clear safely drops externally freed nodes")
	var reentrant: RecycleProbe = RecycleProbe.new()
	reentrant.pool = pool
	add_child(reentrant)
	pool.recycle_instance(&"outer", reentrant)
	_check(pool.get_instance_count(&"outer") == 1 and pool.get_instance_count(&"reentrant") == 0, "Exit callback cannot recycle a reserved instance twice")
	pool.clear_instance_pool(&"outer")
	var exiting: Node = Node.new()
	pool.recycle_instance(&"exit", exiting)
	remove_child(pool)
	pool.free()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not is_instance_valid(exiting), "Manager exit destroys its pooled nodes")
	var detached_pool: ResourceManager = ResourceManager.new()
	var detached_item: Node = Node.new()
	detached_pool.recycle_instance(&"detached", detached_item)
	detached_pool.free()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not is_instance_valid(detached_item), "Deleting a manager that never entered the tree also clears owned nodes")
	print("%s: %d pool ownership checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
