extends Node

const JSONSaveStrategy = preload("../../source/save_system/save_format_strategy/json_save_strategy.gd")
const ResourceSaveProbe = preload("./resource_save_probe.gd")

var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	var directory: String = "res://resource_restore_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	var material_path: String = directory.path_join("material.tres")
	var template: StandardMaterial3D = StandardMaterial3D.new()
	template.roughness = 0.8
	_check(ResourceSaver.save(template, material_path) == OK, "Save material template")
	var original: StandardMaterial3D = ResourceLoader.load(material_path)
	var sibling: StandardMaterial3D = ResourceLoader.load(material_path)
	var strategy: JSONSaveStrategy = JSONSaveStrategy.new()
	var data: Dictionary = {"_type_": TYPE_OBJECT, "resource_path": material_path, "props": {"roughness": 0.2}}
	var restored: StandardMaterial3D = strategy._process_object_for_load(data)
	_check(restored != original, "Restored material owns its mutable state")
	_check(is_equal_approx(restored.roughness, 0.2), "Restored material receives saved properties")
	_check(is_equal_approx(sibling.roughness, 0.8) and is_equal_approx(original.roughness, 0.8), "Sibling and cached template remain unchanged")
	var scene_template: MeshInstance3D = MeshInstance3D.new()
	scene_template.material_override = original
	var scene: PackedScene = PackedScene.new()
	_check(scene.pack(scene_template) == OK, "Pack reusable scene template")
	var first: MeshInstance3D = scene.instantiate()
	var second: MeshInstance3D = scene.instantiate()
	first.material_override = restored
	restored.roughness = 0.1
	_check(is_equal_approx(second.material_override.roughness, 0.8), "Modifying scene A does not affect scene B")
	_check(is_equal_approx(scene_template.material_override.roughness, 0.8), "Scene template remains unchanged")
	first.free()
	second.free()
	scene_template.free()

	var container: Resource = ResourceSaveProbe.new()
	container.material = original
	var items: Array[Resource] = [original]
	container.items = items
	container.mapping = {"nested": [original]}
	var container_path: String = directory.path_join("container.tres")
	_check(ResourceSaver.save(container, container_path) == OK, "Save container with external resource references")
	var cached: Resource = ResourceLoader.load(container_path)
	var a: Resource = strategy._process_object_for_load({
		"_type_": TYPE_OBJECT, "resource_path": container_path, "props": {"resource_name": "A"}})
	var b: Resource = strategy._process_object_for_load({
		"_type_": TYPE_OBJECT, "resource_path": container_path, "props": {"resource_name": "B"}})
	a.items[0].roughness = 0.3
	_check(a != b and a != cached, "Repeated restores use independent root resources")
	_check(is_equal_approx(b.material.roughness, 0.8) and is_equal_approx(cached.material.roughness, 0.8), "External nested resources stay isolated")
	_check(is_equal_approx(b.mapping.nested[0].roughness, 0.8), "Resource references nested in dictionaries/arrays stay isolated")
	a.mapping["extra"] = [1]
	_check(not b.mapping.has("extra") and not cached.mapping.has("extra"), "Nested containers are independent")
	var reference: Resource = strategy._process_object_for_load({
		"_type_": TYPE_OBJECT, "resource_path": material_path, "props": {}})
	_check(reference == original, "Read-only path without saved properties can keep sharing")
	strategy._io_manager._shutdown()
	DirAccess.remove_absolute(container_path)
	DirAccess.remove_absolute(material_path)
	DirAccess.remove_absolute(directory)
	print("%s: %d resource restore checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
