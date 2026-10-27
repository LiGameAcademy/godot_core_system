extends SceneTree

## Run with the legacy CoreSystem AutoLoad enabled to catch global-class type collisions.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var entry: Node = root.get_node_or_null("CoreSystem")
	if entry == null:
		_fail("Legacy CoreSystem AutoLoad is required")
		return
	if entry.get_node_or_null("tag_manager") != null:
		_fail("Deprecated tag adapter must remain lazy at startup")
		return
	var legacy_key: String = "godot_core_system/module_enable/gameplay_tag_manager"
	var direct_key: String = "godot_core_system/module_enable/tag_manager"
	var previous_legacy: Variant = ProjectSettings.get_setting(legacy_key, null)
	var previous_direct: Variant = ProjectSettings.get_setting(direct_key, null)
	ProjectSettings.set_setting(direct_key, null)
	ProjectSettings.set_setting(legacy_key, false)
	var legacy_disabled: bool = not entry.is_module_enabled(&"tag_manager")
	ProjectSettings.set_setting(direct_key, true)
	var direct_override: bool = entry.is_module_enabled(&"tag_manager")
	ProjectSettings.set_setting(legacy_key, previous_legacy)
	ProjectSettings.set_setting(direct_key, previous_direct)
	if not legacy_disabled or not direct_override:
		_fail("Tag adapter must honor legacy flags and explicit direct overrides")
		return
	var expected: Script = load("res://addons/godot_core_system/source/event_system/event_bus.gd")
	var actual: Node = entry.get("event_bus") as Node
	var constants: Dictionary = entry.get_script().get_script_constant_map()
	if actual == null or actual.get_script() != expected:
		_fail("Legacy event service must retain its Node implementation")
		return
	if constants.get("CoreEventBus") != expected or constants.get("LegacyEventBus") != expected:
		_fail("Legacy type aliases must retain the compatibility constant")
		return
	var demo: Script = load("res://addons/godot_core_system/examples/event_bus_demo/event_bus_demo.gd")
	if demo == null or not demo.can_instantiate():
		_fail("Legacy event example type references must compile")
		return
	print("PASS: legacy event references and lazy tag module flags")
	quit()

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
