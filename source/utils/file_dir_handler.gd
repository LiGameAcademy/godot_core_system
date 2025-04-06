extends Node
class_name FileDirHandler

static func get_object_script_dir(object:Object)->String:
	return object.get_script().resource_path.get_base_dir()
