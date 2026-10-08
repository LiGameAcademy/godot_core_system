extends SceneTree

var _failed: bool = false

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var scene: PackedScene = load("res://addons/godot_core_system/examples/state_machine/example.tscn")
	var example: Node = scene.instantiate()
	root.add_child(example)
	var machine: BaseStateMachine = example.state_machine_manager.get_state_machine(&"game")
	var entered: InputEventAction = InputEventAction.new()
	entered.action = &"ui_accept"
	entered.pressed = true
	machine.handle_input(entered)
	_check(machine.get_current_state_name() == &"gameplay", "Menu enters gameplay.")
	var gameplay: BaseStateMachine = machine.current_state as BaseStateMachine
	machine.handle_input(entered)
	_check(gameplay.get_current_state_name() == &"battle", "Explore enters battle.")
	var canceled: InputEventAction = InputEventAction.new()
	canceled.action = &"ui_cancel"
	canceled.pressed = true
	machine.handle_input(canceled)
	_check(machine.get_current_state_name() == &"gameplay" and gameplay.get_current_state_name() == &"explore", "Child cancel is not consumed twice.")
	machine.handle_input(canceled)
	_check(machine.get_current_state_name() == &"pause", "Explore cancel pauses outer gameplay.")
	machine.handle_input(canceled)
	_check(machine.get_current_state_name() == &"gameplay" and gameplay.get_current_state_name() == &"explore", "Pause resumes gameplay history.")
	var external_pause: InputEventAction = InputEventAction.new()
	external_pause.action = &"ui_focus_prev"
	external_pause.pressed = true
	example._unhandled_input(external_pause)
	_check(machine.get_current_state_name() == &"pause", "Shift+Tab invokes the retained manager transition.")
	machine.handle_input(canceled)
	_check(machine.get_current_state_name() == &"gameplay", "Externally paused gameplay resumes.")
	root.remove_child(example)
	_check(example.state_machine_manager.get_state_machine(&"game") == null, "Example exit unregisters machine.")
	example.free()
	print("%s: GDScript hierarchical example scene and input lifecycle" % ("FAIL" if _failed else "PASS"))
	quit(1 if _failed else 0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true
