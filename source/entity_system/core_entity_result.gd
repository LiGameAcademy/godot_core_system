class_name CoreEntityResult
extends RefCounted

var error: Error
var lease: CoreEntityLease

func _init(value: Error, activation: CoreEntityLease = null) -> void:
	error = value
	lease = activation
