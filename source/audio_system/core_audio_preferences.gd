class_name CoreAudioPreferences
extends RefCounted

const Config: GDScript = preload("../config_system/config_manager.gd")

static func restore(config: Config, scope: CoreAudioBusScope) -> Error:
	if scope.is_closed:
		return ERR_UNAVAILABLE
	var keys: Dictionary[String, bool] = {}
	for bus: String in scope.bus_names:
		if keys.has(bus.to_lower()):
			return ERR_INVALID_PARAMETER
		keys[bus.to_lower()] = true
	var values: Dictionary[String, float] = {}
	for bus: String in scope.bus_names:
		if AudioServer.get_bus_index(bus) < 0:
			return ERR_DOES_NOT_EXIST
		var value: Variant = config.get_value("audio", bus.to_lower() + "_volume", 1.0)
		if not value is float and not value is int:
			return ERR_INVALID_DATA
		var volume: float = float(value)
		if not is_finite(volume) or volume < 0.0 or volume > 1.0:
			return ERR_INVALID_DATA
		values[bus] = volume
	for bus: String in values:
		scope.set_volume(bus, values[bus])
	return OK

static func save(config: Config, scope: CoreAudioBusScope) -> Error:
	if scope.is_closed:
		return ERR_UNAVAILABLE
	var keys: Dictionary[String, bool] = {}
	for bus: String in scope.bus_names:
		if keys.has(bus.to_lower()):
			return ERR_INVALID_PARAMETER
		keys[bus.to_lower()] = true
	for bus: String in scope.bus_names:
		if AudioServer.get_bus_index(bus) < 0:
			return ERR_DOES_NOT_EXIST
	for bus: String in scope.bus_names:
		config.set_value("audio", bus.to_lower() + "_volume", scope.get_volume(bus))
	return OK if config.save_config() else config.last_error
