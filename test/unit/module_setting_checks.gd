extends Node

var _failed: bool = false
var _checks: int = 0

func _ready() -> void:
	_check(not CoreSystem._modules.has(&"state_machine_manager"), "Startup state_machine=false prevents module creation")
	_check(not CoreSystem._modules.has(&"tag_manager"), "Startup gameplay_tag_manager=false prevents module creation")
	var settings: Dictionary[StringName, StringName] = {
		&"state_machine_manager": &"state_machine", &"tag_manager": &"gameplay_tag_manager"
	}
	for module_id: StringName in CoreSystem._module_scripts:
		var setting_id: StringName = settings.get(module_id, module_id)
		var path: String = "godot_core_system/module_enable/" + setting_id
		ProjectSettings.set_setting(path, false)
		_check(not CoreSystem.is_module_enabled(module_id), "Registered switch disables %s" % module_id)
		ProjectSettings.set_setting(path, true)
		_check(CoreSystem.is_module_enabled(module_id), "Registered switch enables %s" % module_id)
	for module_id: StringName in settings:
		var canonical: String = "godot_core_system/module_enable/" + settings[module_id]
		var legacy: String = "godot_core_system/module_enable/" + module_id
		ProjectSettings.set_setting(canonical, null)
		ProjectSettings.set_setting(legacy, false)
		_check(not CoreSystem.is_module_enabled(module_id), "Old runtime-ID key still works when canonical key is absent")
		ProjectSettings.set_setting(canonical, true)
		_check(CoreSystem.is_module_enabled(module_id), "Registered canonical key wins if both are configured")
		ProjectSettings.set_setting(legacy, null)
	print("%s: %d module setting checks" % ["FAIL" if _failed else "PASS", _checks])
	get_tree().quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
