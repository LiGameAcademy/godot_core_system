extends "./save_format_strategy.gd"


var _io_manager: CoreSystem.AsyncIOManager
var _encryption_key: String = ""


func _init() -> void:
	_io_manager = CoreSystem.AsyncIOManager.new()


## 设置加密密钥
func set_encryption_key(key: String) -> void:
	_encryption_key = key


## 保存数据
func save(path: String, data: Dictionary) -> bool:
	var processed_data: Dictionary = _process_data_for_save(data)
	var task_id: String = _io_manager.write_file_async(path, processed_data, _encryption_key)
	var result: Array = await _io_manager.io_completed
	return result[1] if result[0] == task_id else false


## 加载数据
func load_save(path: String) -> Dictionary:
	var task_id: String = _io_manager.read_file_async(path, _encryption_key)
	var result: Array = await _io_manager.io_completed
	if result[0] == task_id and result[1]:
		return _process_data_for_load(result[2])
	return {}


## 加载元数据
func load_metadata(path: String) -> Dictionary:
	var data: Dictionary = await load_save(path)
	return data.get("metadata", {}) if data.has("metadata") else {}


## 将函数应用在字典的每一个值上，并返回新的字典
func _process_dictionary(dict: Dictionary, process_func: Callable) -> Dictionary:
	var result: Dictionary = {}
	for key in dict:
		var value: Variant = dict[key]
		result[key] = process_func.call(value)
	return result


## 将函数应用在数组的每一个值上，并返回新的数组
func _process_array(array: Array, process_func: Callable) -> Array:
	return array.map(process_func)


#region process for save
## 处理数据保存
func _process_data_for_save(data: Dictionary) -> Dictionary:
	return _process_dictionary_for_save(data)


## 处理变量保存
func _process_variant_for_save(value: Variant) -> Variant:
	var value_type: int = typeof(value)
	var value_dict: Dictionary = {"_type_": value_type}
	match value_type:
		TYPE_DICTIONARY:
			return _process_dictionary_for_save(value)
		TYPE_ARRAY:
			return _process_array_for_save(value)
		TYPE_OBJECT:
			return _process_object_for_save(value)
		TYPE_INT, TYPE_NODE_PATH:
			return {"v": value}.merged(value_dict)
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return {"x": value.x, "y": value.y}.merged(value_dict)
		TYPE_VECTOR3, TYPE_VECTOR3I:
			return {"x": value.x, "y": value.y, "z": value.z}.merged(value_dict)
		TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_QUATERNION:
			return {"x": value.x, "y": value.y, "z": value.z, "w": value.w}.merged(value_dict)
		TYPE_COLOR:
			return {"r": value.r, "g": value.g, "b": value.b, "a": value.a}.merged(value_dict)
		TYPE_PLANE:
			return {"a": value.x, "b": value.y, "c": value.z, "d": value.d}.merged(value_dict)
		TYPE_RECT2, TYPE_RECT2I:
			return {
				"x": value.position.x, "w": value.size.x,
				"y": value.position.y, "h": value.size.x,
			}.merged(value_dict)
		TYPE_AABB:
			return {
				"px": value.position.x, "sx": value.size.x,
				"py": value.position.y, "sy": value.size.y,
				"pz": value.position.z, "sz": value.size.z,
			}.merged(value_dict)
		TYPE_TRANSFORM2D:
			return {
				"xx": value.x.x, "yx": value.y.x, "ox": value.origin.x,
				"xy": value.x.y, "yy": value.y.y, "oy": value.origin.y,
			}.merged(value_dict)
		TYPE_TRANSFORM3D:
			return {
				"xx": value.basis.x.x, "xy": value.basis.x.y, "xz": value.basis.x.z,
				"yx": value.basis.y.x, "yy": value.basis.y.y, "yz": value.basis.y.z,
				"zx": value.basis.z.x, "zy": value.basis.z.y, "zz": value.basis.z.z,
				"ox": value.origin.x,
				"oy": value.origin.y,
				"oz": value.origin.z,
			}.merged(value_dict)
		TYPE_BASIS:
			return {
				"xx": value.x.x, "xy": value.x.y, "xz": value.x.z,
				"yx": value.y.x, "yy": value.y.y, "yz": value.y.z,
				"zx": value.z.x, "zy": value.z.y, "zz": value.z.z,
			}.merged(value_dict)
		TYPE_PROJECTION:
			return {
				"xx": value.x.x, "xy": value.x.y, "xz": value.x.z, "xw": value.x.w,
				"yx": value.y.x, "yy": value.y.y, "yz": value.y.z, "yw": value.y.w,
				"zx": value.z.x, "zy": value.z.y, "zz": value.z.z, "zw": value.z.w,
				"wx": value.w.x, "wy": value.w.y, "wz": value.w.z, "ww": value.w.w,
			}.merged(value_dict)
	return value


## 处理字典保存
func _process_dictionary_for_save(dict: Dictionary) -> Dictionary:
	if not dict.is_typed():
		return _process_dictionary(dict, _process_variant_for_save)

	var value_dict: Dictionary = {}
	value_dict["key_type"] = dict.get_typed_key_builtin()
	value_dict["key_class"] = dict.get_typed_key_class_name()

	var typed_key_script: Script = dict.get_typed_key_script() as Script
	value_dict["key_script"] = typed_key_script.get_path() if typed_key_script != null else ""

	value_dict["value_type"] = dict.get_typed_value_builtin()
	value_dict["value_class"] = dict.get_typed_value_class_name()

	var typed_value_script: Script = dict.get_typed_value_script() as Script
	value_dict["value_script"] = typed_value_script.get_path() if typed_value_script != null else ""

	value_dict["dictionary"] = _process_dictionary(dict, _process_variant_for_save)
	value_dict["_type_"] = TYPE_DICTIONARY
	return value_dict


## 处理数组保存
func _process_array_for_save(array: Array) -> Variant:
	if not array.is_typed():
		return _process_array(array, _process_variant_for_save)

	var value_dict: Dictionary = {}
	value_dict["value_type"] = array.get_typed_builtin()
	value_dict["class"] = array.get_typed_class_name()

	var array_typed_script: Script = array.get_typed_script() as Script
	value_dict["script"] = array_typed_script.get_path() if array_typed_script != null else ""

	value_dict["array"] = _process_array(array, _process_variant_for_save)
	value_dict["_type_"] = TYPE_ARRAY
	return value_dict


## 英文字符串的首字母为大写
func is_upper_case(text: String) -> bool:
	var first_letter: String = text.left(1)
	if first_letter == "_": return false
	return first_letter == first_letter.to_upper()


## 处理对象保存
func _process_object_for_save(value: Object) -> Dictionary:
	var object_dict: Dictionary
	if value is Node:
		object_dict["v"] = value.get_path()
		object_dict["_type_"] = TYPE_NODE_PATH
		return object_dict

	var prop_dict: Dictionary
	for prop in value.get_property_list():
		var prop_name: String = prop["name"]
		if is_upper_case(prop_name): continue
		var prop_value: Variant = value.get(prop_name)
		var processed_value: Variant = _process_variant_for_save(prop_value)
		prop_dict.set(prop_name, processed_value)

	var script: Script = value.get_script()
	var script_path: String = ""
	var script_file: String = ""
	if script != null:
		script_path = script.get_path()
		script_file = script_path.get_file()
		prop_dict.erase(script_file)
	prop_dict.erase("script")

	if value is Resource:
		prop_dict.erase("resource_path")
		if not value.resource_local_to_scene:
			prop_dict.erase("resource_local_to_scene")
		if value.resource_name.is_empty():
			prop_dict.erase("resource_name")
		if value.resource_scene_unique_id.is_empty():
			prop_dict.erase("resource_scene_unique_id")

		var resource_path: String = value.get_path()
		if not resource_path.is_empty():
			prop_dict.erase("load_path")
			object_dict["resource_path"] = resource_path
			object_dict["props"] = prop_dict
			object_dict["_type_"] = TYPE_OBJECT
			return object_dict

	if script_path.is_empty():
		object_dict["class"] = value.get_class()
	else:
		object_dict["script"] = script_path

	object_dict["props"] = prop_dict
	object_dict["_type_"] = TYPE_OBJECT
	return object_dict
#endregion


#region process for load
## 处理数据加载
func _process_data_for_load(data: Dictionary) -> Dictionary:
	return _process_dictionary(data, _process_variant_for_load)


## 处理变量加载
func _process_variant_for_load(value: Variant) -> Variant:
	if value is Dictionary:
		return _process_dictionary_for_load(value)
	if value is Array:
		return _process_array_for_load(value)
	return value


## 处理字典加载
func _process_dictionary_for_load(dict: Dictionary) -> Variant:
	if dict.has("_type_"): match int(dict._type_):
		TYPE_INT:
			return int(dict.v)
		TYPE_VECTOR2:
			return Vector2(dict.x, dict.y)
		TYPE_VECTOR2I:
			return Vector2i(dict.x, dict.y)
		TYPE_RECT2:
			return Rect2(dict.x, dict.y, dict.w, dict.h)
		TYPE_RECT2I:
			return Rect2i(dict.x, dict.y, dict.w, dict.h)
		TYPE_VECTOR3:
			return Vector3(dict.x, dict.y, dict.z)
		TYPE_VECTOR3I:
			return Vector3i(dict.x, dict.y, dict.z)
		TYPE_TRANSFORM2D:
			return Transform2D(
				Vector2(dict.xx, dict.xy),
				Vector2(dict.yx, dict.yy),
				Vector2(dict.ox, dict.oy),
			)
		TYPE_VECTOR4:
			return Vector4(dict.x, dict.y, dict.z, dict.w)
		TYPE_VECTOR4I:
			return Vector4i(dict.x, dict.y, dict.z, dict.w)
		TYPE_PLANE:
			return Plane(dict.a, dict.b, dict.c, dict.d)
		TYPE_QUATERNION:
			return Quaternion(dict.x, dict.y, dict.z, dict.w)
		TYPE_AABB:
			return AABB(
				Vector3(dict.px, dict.py, dict.pz),
				Vector3(dict.sx, dict.sy, dict.sz),
			)
		TYPE_BASIS:
			return Basis(
				Vector3(dict.xx, dict.xy, dict.xz),
				Vector3(dict.yx, dict.yy, dict.yz),
				Vector3(dict.zx, dict.zy, dict.zz),
			)
		TYPE_TRANSFORM3D:
			return Transform3D(
				Vector3(dict.xx, dict.xy, dict.xz),
				Vector3(dict.yx, dict.yy, dict.yz),
				Vector3(dict.zx, dict.zy, dict.zz),
				Vector3(dict.ox, dict.oy, dict.oz),
			)
		TYPE_PROJECTION:
			return Projection(
				Vector4(dict.xx, dict.xy, dict.xz, dict.xw),
				Vector4(dict.yx, dict.yy, dict.yz, dict.yw),
				Vector4(dict.zx, dict.zy, dict.zz, dict.zw),
				Vector4(dict.wx, dict.wy, dict.wz, dict.ww),
			)
		TYPE_COLOR:
			return Color(dict.r, dict.g, dict.b, dict.a)
		TYPE_NODE_PATH:
			return NodePath(dict.v)
		TYPE_OBJECT:
			return _process_object_for_load(dict)
		TYPE_DICTIONARY:
			return _process_typed_dictionary_for_load(dict)
		TYPE_ARRAY:
			return _process_typed_array_for_load(dict)
	return _process_dictionary(dict, _process_variant_for_load)


## 处理类型字典加载
func _process_typed_dictionary_for_load(dict: Dictionary) -> Dictionary:
	var dict_value: Dictionary = _process_dictionary_for_load(dict.dictionary)
	var dict_key_type: int = int(dict.key_type)
	var dict_key_class: StringName = ""
	var dict_key_script: Script = null
	var dict_value_type: int = int(dict.value_type)
	var dict_value_class: StringName = ""
	var dict_value_script: Script = null
	if dict_key_type == TYPE_OBJECT:
		var dict_script_path: String = dict.key_script
		dict_key_class = dict.key_class
		dict_key_script = ResourceLoader.load(dict_script_path, "Script")\
			if not dict_script_path.is_empty() else null
	if dict_value_type == TYPE_OBJECT:
		var dict_script_path: String = dict.value_script
		dict_value_class = dict.value_class
		dict_value_script = ResourceLoader.load(dict_script_path, "Script")\
			if not dict_script_path.is_empty() else null
	return Dictionary(dict_value, dict_key_type, dict_key_class, dict_key_script,
		dict_value_type, dict_value_class, dict_value_script)


## 处理数组加载
func _process_array_for_load(array: Array) -> Array:
	return _process_array(array, _process_variant_for_load)


## 处理类型数组加载
func _process_typed_array_for_load(array: Dictionary) -> Array:
	var array_value: Array = _process_array_for_load(array.array)
	var array_type: int = int(array.value_type)
	var array_class: StringName = ""
	var array_script: Script = null
	if array_type == TYPE_OBJECT:
		var array_script_path: String = array.script
		array_class = array.class
		array_script = ResourceLoader.load(array_script_path, "Script")\
			if not array_script_path.is_empty() else null
	return Array(array_value, array_type, array_class, array_script)


## 处理对象加载
func _process_object_for_load(value: Dictionary) -> Object:
	var object: Object
	if value.has("class"):
		object = ClassDB.instantiate(value.class)
	if value.has("script"):
		object = ResourceLoader.load(value.script, "Script").new()
	if value.has("resource_path"):
		object = ResourceLoader.load(value.resource_path, "Resource")

	var prop_dict: Dictionary = value.props
	for prop_key in prop_dict:
		var prop_value: Variant = prop_dict.get(prop_key)
		var processed_value: Variant = _process_variant_for_load(prop_value)
		object.set(prop_key, processed_value)
	return object
#endregion
