extends SceneTree

const Copy: GDScript = preload("../../source/save_system/save_snapshot_copy.gd")
const Payload: GDScript = preload("./mutable_payload.gd")
var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	var template: Payload = Payload.new()
	template.child = Payload.new()
	template.material = StandardMaterial3D.new()
	template.shape = BoxShape3D.new()
	var image: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	template.texture = ImageTexture.create_from_image(image)
	var a_result: Copy.CopyResult = Copy.copy({"payload": template, "alias": template})
	var b_result: Copy.CopyResult = Copy.copy({"payload": template})
	_expect(a_result.error == OK and b_result.error == OK, "Resource graph copied")
	if a_result.error == OK and b_result.error == OK:
		var a: Payload = a_result.data.payload
		var b: Payload = b_result.data.payload
		_expect(a != template and a != b and a.child != b.child, "A B and template independent")
		_expect(a_result.data.alias == a, "Aliases within one graph retained")
		a.entries[0].items.append(3)
		a.child.entries[0].items.append(4)
		_expect(b.entries[0].items == [1, 2] and template.entries[0].items == [1, 2], "Nested containers isolated")
		_expect(b.child.entries[0].items == [1, 2] and template.child.entries[0].items == [1, 2], "Nested resource containers isolated")
		a.material.albedo_color = Color.RED
		a.shape.size = Vector3(3, 4, 5)
		_expect(b.material.albedo_color == template.material.albedo_color and b.material.albedo_color != Color.RED, "Material independent")
		_expect(b.shape.size == template.shape.size and b.shape.size != a.shape.size, "Collision shape independent")
		_expect(a.texture == template.texture and b.texture == template.texture, "Read-only texture shared")
	var static_config: Payload = Payload.new()
	var readonly_config: Array[Resource] = [static_config]
	var shared: Copy.CopyResult = Copy.copy(static_config, readonly_config)
	_expect(shared.error == OK and shared.data == static_config, "Explicit read-only configuration shared")
	var typed_values: Array[int] = [1, 2]
	var packed: PackedByteArray = PackedByteArray([1, 2])
	var copied_values: Copy.CopyResult = Copy.copy({"typed": typed_values, "packed": packed, 7: "integer key"})
	_expect(copied_values.error == OK and copied_values.data.typed.is_typed(), "Typed collections preserved")
	copied_values.data.typed.append(3)
	copied_values.data.packed[0] = 9
	_expect(typed_values == [1, 2] and packed[0] == 1, "Typed and packed values isolated")
	_expect(copied_values.data[7] == "integer key", "Non-string dictionary keys retained")
	var node: Node = Node.new()
	_expect(Copy.copy({"node": node}).error == ERR_INVALID_DATA, "Runtime node rejected")
	node.free()
	var nested: Array = []
	var cursor: Array = nested
	for index: int in range(66):
		var child: Array = []
		cursor.append(child)
		cursor = child
	_expect(Copy.copy(nested).error == ERR_INVALID_DATA, "Excessive nesting rejected before callbacks")
	var cyclic: Payload = Payload.new()
	cyclic.child = cyclic
	var cycle_result: Copy.CopyResult = Copy.copy(cyclic)
	cyclic.child = null
	_expect(cycle_result.error == ERR_INVALID_DATA and cycle_result.data == null, "Mutable resource cycle rejected without partial output")
	print("SAVE COPY CHECKS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _expect(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(description)
