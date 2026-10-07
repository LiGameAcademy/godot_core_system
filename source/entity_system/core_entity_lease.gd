class_name CoreEntityLease
extends RefCounted

## A capability for one activation. CoreEntities checks lease identity, not only node identity.
var node: Node:
	get:
		return _node if is_instance_valid(_node) else null
var _node: Node

func _init(value: Node) -> void:
	_node = value

