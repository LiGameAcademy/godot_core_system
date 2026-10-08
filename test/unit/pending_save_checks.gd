extends Node

class SaveProbe extends Node:
	var marker: String = ""
	func load_data(data: Dictionary) -> void:
		marker = data.marker

var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	var manager: CoreSystem.SaveManager = CoreSystem.save_manager
	manager.set_save_format(&"json")
	var strategy: CoreSystem.SaveManager.JSONSaveStrategy = manager._strategies.json
	var unique: String = "pending_probe_%d" % Time.get_ticks_usec()
	var node_path: String = "/root/" + unique
	var path_a: String = manager._get_save_path(unique + "_A")
	var path_b: String = manager._get_save_path(unique + "_B")
	var path_c: String = manager._get_save_path(unique + "_C")
	_check(await strategy.save(path_a, {"metadata": {}, "nodes": [{"node_path": node_path, "marker": "A"}]}), "Create real save A")
	_check(await strategy.save(path_b, {"metadata": {}, "nodes": []}), "Create real save B")
	_check(await strategy.save(path_c, {"metadata": {}, "nodes": [{"node_path": node_path, "marker": "C"}]}), "Create real save C")
	_check(await manager.load_save(unique + "_A"), "Load A")
	_check(not await manager.load_save(unique + "_missing"), "Missing load fails")
	var probe: SaveProbe = SaveProbe.new()
	probe.name = unique
	get_tree().root.add_child(probe)
	manager.register_saveable_node(probe)
	_check(probe.marker == "A", "Failed load retains pending A state")
	probe.free()
	_check(await manager.load_save(unique + "_A"), "Reload A")
	_check(await manager.load_save(unique + "_B"), "Accept B with empty nodes")
	probe = SaveProbe.new()
	probe.name = unique
	get_tree().root.add_child(probe)
	manager.register_saveable_node(probe)
	_check(probe.marker.is_empty(), "B cannot consume state from A")
	probe.free()
	_check(await manager.load_save(unique + "_A"), "Load pending A again")
	_check(await manager.load_save(unique + "_C"), "Replace with C")
	probe = SaveProbe.new()
	probe.name = unique
	get_tree().root.add_child(probe)
	manager.register_saveable_node(probe)
	_check(probe.marker == "C", "Delayed registration consumes only C")
	_check(not manager._pending_node_states.has(node_path), "Consumed state is removed")
	probe.free()
	_check(await strategy.save(path_b, {"metadata": {}}), "Create save with absent nodes")
	_check(await manager.load_save(unique + "_A"), "Pending A before absent-node save")
	_check(await manager.load_save(unique + "_B"), "Accept save without nodes")
	_check(manager._pending_node_states.is_empty(), "Absent nodes also replaces pending state")
	for path: String in [path_a, path_b, path_c]:
		DirAccess.remove_absolute(path)
	print("%s: %d pending save checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
