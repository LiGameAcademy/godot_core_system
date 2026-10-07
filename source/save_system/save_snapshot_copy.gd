extends RefCounted

## Owned data for migration and restore. Runtime objects/callables cannot be
## snapshot data. Cyclic containers are rejected by a bounded traversal.
class CopyResult extends RefCounted:
	var error: Error = OK
	var message: String = ""
	var data: Variant = null

class Copier extends RefCounted:
	var result: CopyResult = CopyResult.new()
	var readonly_resources: Array[Resource] = []
	var resources: Dictionary[Resource, Resource] = {}
	var active_resources: Dictionary[Resource, bool] = {}

	func copy_value(value: Variant, depth: int = 0) -> Variant:
		if result.error != OK:
			return null
		if value == null:
			return null
		if depth > 64:
			return fail(ERR_INVALID_DATA, "Snapshot contains cyclic or excessively nested containers.")
		if value is Dictionary:
			var source: Dictionary = value
			var copied: Dictionary = source.duplicate(false)
			copied.clear()
			for key: Variant in source:
				var copied_key: Variant = copy_value(key, depth + 1)
				var copied_value: Variant = copy_value(source[key], depth + 1)
				if result.error != OK:
					return null
				copied[copied_key] = copied_value
			return copied
		if value is Array:
			var source: Array = value
			var copied: Array = source.duplicate(false)
			for index: int in range(source.size()):
				var element: Variant = copy_value(source[index], depth + 1)
				if result.error != OK:
					return null
				copied[index] = element
			return copied
		if value is Resource:
			return copy_resource(value, depth)
		var value_type: int = typeof(value)
		if value_type == TYPE_OBJECT or value_type == TYPE_CALLABLE or value_type == TYPE_SIGNAL:
			return fail(ERR_INVALID_DATA, "Runtime objects, callables and signals are not snapshot values.")
		if value_type >= TYPE_PACKED_BYTE_ARRAY and value_type <= TYPE_PACKED_VECTOR4_ARRAY:
			return value.duplicate()
		return value

	func copy_resource(source: Resource, depth: int) -> Resource:
		# These assets are read-only by the save contract. Mutable materials,
		# shapes and custom resources are copied, including external children.
		if source is Texture or source is AudioStream or source is Script or source is Shader or source is PackedScene:
			return source
		if readonly_resources.has(source):
			return source
		if active_resources.has(source):
			fail(ERR_INVALID_DATA, "Mutable resource graphs cannot contain reference cycles.")
			return null
		if resources.has(source):
			return resources[source]
		var copied: Resource = source.duplicate(false)
		if copied == null:
			fail(ERR_CANT_CREATE, "Resource cannot be duplicated: %s" % source.get_class())
			return null
		resources[source] = copied
		active_resources[source] = true
		for descriptor: Dictionary in source.get_property_list():
			var usage: int = descriptor["usage"]
			var property_name: StringName = descriptor["name"]
			if usage & PROPERTY_USAGE_STORAGE == 0 or property_name == &"script":
				continue
			var property_value: Variant = copy_value(source.get(property_name), depth + 1)
			if result.error != OK:
				return null
			copied.set(property_name, property_value)
		active_resources.erase(source)
		return copied

	func fail(code: Error, message: String) -> Variant:
		result.error = code
		result.message = message
		return null

## Custom static configuration can be shared explicitly through readonly_resources.
## Every invocation owns a fresh copy graph; aliases inside one graph are retained.
static func copy(value: Variant, readonly_resources: Array[Resource] = []) -> CopyResult:
	var copier: Copier = Copier.new()
	copier.readonly_resources = readonly_resources
	var copied: Variant = copier.copy_value(value)
	if copier.result.error == OK:
		copier.result.data = copied
	return copier.result
