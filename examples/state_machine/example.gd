extends Node

## Optional manager example; the owner unregisters when leaving the tree.
var state_machine_manager: CoreSystem.StateMachineManager = CoreSystem.state_machine_manager
@onready var state_label: Label = $StateLabel

func _ready() -> void:
	var machine: ExampleGameStateMachine = ExampleGameStateMachine.new()
	state_machine_manager.register_state_machine(&"game", machine, self, &"menu")

## Shift+Tab demonstrates an external transition through the optional manager.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_focus_prev"):
		return
	if state_machine_manager.transition_state_machine(&"game", &"pause", {}):
		print("transition_state_machine: game -> pause (via manager)")

func _process(_delta: float) -> void:
	update_state_display()

func _exit_tree() -> void:
	state_machine_manager.unregister_state_machine(&"game")

func update_state_display() -> void:
	var text: String = "当前状态: "
	var machine: BaseStateMachine = state_machine_manager.get_state_machine(&"game")
	if machine and machine.is_active:
		text += machine.get_current_state_name()
		var gameplay: BaseStateMachine = machine.current_state as BaseStateMachine
		if gameplay and gameplay.current_state:
			text += " > " + gameplay.get_current_state_name()
	else:
		text += "无"
	state_label.text = text
