extends RefCounted

## One operation owns one result; concurrent callers never read shared last_error.
var error: Error = OK
var message: String = ""
var stage: StringName = &""
var save_id: String = ""
var data: Dictionary = {}
var saves: Array[Dictionary] = []
var applied_count: int = 0
var pending_count: int = 0
var pending_identities: Array[String] = []

func _init(code: Error = OK, detail: String = "", operation: StringName = &"", slot: String = "") -> void:
	error = code
	message = detail
	stage = operation
	save_id = slot
