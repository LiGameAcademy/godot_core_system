class_name CoreResourceResult
extends RefCounted

## A completed load result. Cached resources are shared and should be treated as read-only.
var error: Error:
	get:
		return _error
var resource: Resource:
	get:
		return _resource

var _error: Error
var _resource: Resource

func _init(load_error: Error, loaded_resource: Resource = null) -> void:
	_error = load_error
	_resource = loaded_resource
