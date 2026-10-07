class_name CoreAudioBusScope
extends RefCounted

static var _claimed: Dictionary[String, bool] = {}
var _original_db: Dictionary[String, float] = {}
var _original_mute: Dictionary[String, bool] = {}
var _closed: bool = false
var is_closed: bool:
	get:
		return _closed
var bus_names: Array[String]:
	get:
		return _original_db.keys()

func _init(buses: Array[String]) -> void:
	var unique: Dictionary[String, bool] = {}
	for bus: String in buses:
		if not Thread.is_main_thread() or bus.is_empty() or unique.has(bus) or _claimed.has(bus) or AudioServer.get_bus_index(bus) < 0:
			_closed = true
			return
		unique[bus] = true
	if buses.is_empty():
		_closed = true
		return
	for bus: String in buses:
		var index: int = AudioServer.get_bus_index(bus)
		_original_db[bus] = AudioServer.get_bus_volume_db(index)
		_original_mute[bus] = AudioServer.is_bus_mute(index)
		_claimed[bus] = true

func set_volume(bus: String, volume: float) -> Error:
	if not Thread.is_main_thread() or _closed:
		return ERR_UNAVAILABLE
	if not is_finite(volume) or volume < 0.0 or volume > 1.0:
		return ERR_INVALID_PARAMETER
	var index: int = _resolve(bus)
	if index < 0:
		return ERR_DOES_NOT_EXIST
	AudioServer.set_bus_volume_db(index, -80.0 if volume == 0.0 else linear_to_db(volume))
	return OK

func set_muted(bus: String, muted: bool) -> Error:
	if not Thread.is_main_thread() or _closed:
		return ERR_UNAVAILABLE
	var index: int = _resolve(bus)
	if index < 0:
		return ERR_DOES_NOT_EXIST
	AudioServer.set_bus_mute(index, muted)
	return OK

func get_volume(bus: String) -> float:
	var index: int = _resolve(bus) if Thread.is_main_thread() else -1
	if index < 0:
		return -1.0
	var db: float = AudioServer.get_bus_volume_db(index)
	return 0.0 if db <= -80.0 else db_to_linear(db)

func close() -> void:
	if not Thread.is_main_thread() or _closed:
		return
	_closed = true
	for bus: String in _original_db:
		var index: int = AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.set_bus_volume_db(index, _original_db[bus])
			AudioServer.set_bus_mute(index, _original_mute[bus])
		_claimed.erase(bus)

func _resolve(bus: String) -> int:
	return AudioServer.get_bus_index(bus) if not _closed and _original_db.has(bus) else -1
