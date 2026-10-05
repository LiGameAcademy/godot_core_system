extends BaseStateMachine
class_name ExampleGameStateMachine

func _ready() -> void:
	add_state(&"menu", MenuState.new())
	add_state(&"gameplay", GameplayState.new())
	add_state(&"pause", PauseState.new())

class MenuState extends BaseState:
	func _enter(_msg: Dictionary = {}) -> void:
		print("Entered menu state")
	func _handle_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_accept"):
			transition_to(&"gameplay")

class GameplayState extends BaseStateMachine:
	func _ready() -> void:
		add_state(&"explore", ExploreState.new())
		add_state(&"battle", BattleState.new())
		add_state(&"dialog", DialogState.new())
	func _enter(msg: Dictionary = {}) -> void:
		print("Entered gameplay state")
		start(&"explore", {}, bool(msg.get("resume", false)))
	func _handle_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			# The owner chooses the outer layer; transition_local selects this table.
			state_machine.transition_to(&"pause", {"resume": true})
	func _exit() -> void:
		print("Exited gameplay state")

	class ExploreState extends BaseState:
		func _enter(_msg: Dictionary = {}) -> void:
			print("Entered explore state")
		func _handle_input(event: InputEvent) -> void:
			if event.is_action_pressed("ui_accept"):
				transition_to(&"battle")
			elif event.is_action_pressed("ui_focus_next"):
				transition_to(&"dialog")

	class BattleState extends BaseState:
		func _enter(_msg: Dictionary = {}) -> void:
			print("Entered battle state")
		func _exit() -> void:
			print("Exited battle state")
		func _handle_input(event: InputEvent) -> void:
			if event.is_action_pressed("ui_cancel"):
				transition_to(&"explore")

	class DialogState extends BaseState:
		func _enter(_msg: Dictionary = {}) -> void:
			print("Entered dialog state")
		func _handle_input(event: InputEvent) -> void:
			if event.is_action_pressed("ui_cancel"):
				transition_to(&"explore")

class PauseState extends BaseState:
	func _enter(_msg: Dictionary = {}) -> void:
		print("Entered pause state")
	func _handle_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			transition_to(&"gameplay", {"resume": true})
		elif event.is_action_pressed("ui_home"):
			transition_to(&"menu")
