extends Node

const Payload: GDScript = preload("./mutable_payload.gd")
@export var save_id: StringName = &""
var health: int = 0
var payload: Payload = Payload.new()
var load_count: int = 0
var after_load: Callable = Callable()

func save() -> Dictionary:
	return {"health": health, "payload": payload}

func load_data(data: Dictionary) -> void:
	health = data.get("health", 0)
	if data.get("payload") is Payload:
		payload = data["payload"]
	load_count += 1
	if after_load.is_valid():
		after_load.call()
