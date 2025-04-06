# Hierarchical State Machine System

## Overview
The Hierarchical State Machine System provides a flexible and extensible state management solution. The system supports state nesting, state history, event handling, and variable sharing, making it particularly suitable for game AI, UI interactions, and game flow control.

## Core Concepts

### State
- Represents a specific behavior or condition
- Can have entry/exit logic
- Supports update (per frame) and physics update (fixed rate)
- Can handle events
- Can access and modify shared variables

### State Machine
- Manages transitions between multiple states
- Maintains current active state
- Handles state transition logic
- Supports state history
- Manages shared variables

### Hierarchical Features
- States can contain sub-state machines
- Child states can access parent state variables
- Events can propagate through state hierarchy
- Supports state inheritance and reuse

## Usage Examples

### 1. Basic State Machine
```gdscript
# Create a simple state
class_name IdleState extends BaseState
func enter(msg := {}):
    super.enter(msg)
    print("Entering idle state")

func update(delta: float):
    if agent.is_moving:
        transition_to("move")

# Use the state machine
var state_machine = BaseStateMachine.new()
state_machine.add_state("idle", IdleState)
state_machine.add_state("move", MoveState)
state_machine.transition_to("idle")
```

### 2. Hierarchical State Machine
```gdscript
# Create a state with sub-state machine
class_name CombatState extends BaseState
var sub_state_machine: BaseStateMachine

func _init():
    sub_state_machine = BaseStateMachine.new(self)
    sub_state_machine.add_state("attack", AttackState)
    sub_state_machine.add_state("defend", DefendState)

func enter(msg := {}):
    super.enter(msg)
    sub_state_machine.transition_to("attack")

# Use in main state machine
main_state_machine.add_state("combat", CombatState)
main_state_machine.add_state("explore", ExploreState)
```

### 3. Event Handling
```gdscript
# Handle events in state
class_name PlayerState extends BaseState
func _on_damage_taken(amount: int):
    if amount > 50:
        transition_to("hurt")
    elif parent_state:
        parent_state.handle_event("damage_taken", [amount])

# Trigger event
state_machine.handle_event("damage_taken", [30])
```

## Best Practices

1. State Organization
   - Organize related states in the same state machine
   - Use meaningful state names
   - Keep state logic simple and clear

2. State Transitions
   - Switch states at appropriate times
   - Use msg parameter to pass necessary transition information
   - Make good use of state history feature

3. Variable Management
   - Use shared variables appropriately
   - Pay attention to variable scope
   - Clean up unnecessary variables

4. Event Handling
   - Use event propagation mechanism appropriately
   - Avoid event handling loops
   - Keep event parameters simple and clear

## Important Notes

1. State Machine Initialization
   - Ensure proper initialization before use
   - Set necessary initial states
   - Configure state machine agent correctly

2. Performance Considerations
   - Avoid intensive calculations in update
   - Use physics update appropriately
   - Clean up unnecessary states and variables

3. Debugging
   - Use state machine signals for debugging
   - Monitor state transitions and event propagation
   - Check variable changes

# State Machine System

The State Machine System provides a robust and flexible way to manage game states and transitions. It's designed to handle complex game logic while maintaining code clarity and maintainability.

## Features

- 🔄 **Hierarchical State Machines**: Support for nested state machines
- 🎮 **Game-Specific States**: Built-in support for common game states (Menu, Gameplay, Pause)
- 📊 **State Management**: Clean API for state transitions and updates
- 🎯 **Input Handling**: Integrated input processing per state
- 🔍 **Debugging**: Built-in debugging features for state tracking

## Core Components

### BaseState

The foundation class for all states. Provides:
- State lifecycle methods (enter, exit, update)
- Input handling
- State transition management

```gdscript
class MyState extends BaseState:
    func _enter(msg := {}) -> void:
        # Called when entering the state
        pass
        
    func _exit() -> void:
        # Called when exiting the state
        pass
        
    func _update(delta: float) -> void:
        # Called every frame
        pass
        
    func _handle_input(event: InputEvent) -> void:
        # Handle input events
        pass
```

### BaseStateMachine

Manages a collection of states and their transitions:
- State registration and switching
- State updates and input propagation
- Support for hierarchical state machines

```gdscript
class MyStateMachine extends BaseStateMachine:
    func _ready() -> void:
        # Register states
        add_state("idle", IdleState.new(self))
        add_state("walk", WalkState.new(self))
        
        # Set initial state
        start("idle")
```

### StateMachineManager

Global manager for all state machines in your game:
- Central registration of state machines
- Global state machine updates
- Debug information and monitoring

```gdscript
# Access the manager through CoreSystem
CoreSystem.state_machine_manager.register_state_machine("player", player_state_machine)
```

## Usage Example

Here's a simple example of a character state machine:

```gdscript
# Character state machine
class CharacterStateMachine extends BaseStateMachine:
    func _ready() -> void:
        add_state("idle", IdleState.new(self))
        add_state("walk", WalkState.new(self))
        add_state("jump", JumpState.new(self))
        start("idle")

# Idle state
class IdleState extends BaseState:
    func _enter(msg := {}) -> void:
        owner.play_animation("idle")
    
    func _handle_input(event: InputEvent) -> void:
        if event.is_action_pressed("move"):
            switch_to("walk")
        elif event.is_action_pressed("jump"):
            switch_to("jump")

# Register with manager
func _ready() -> void:
    var character_sm = CharacterStateMachine.new(self)
    CoreSystem.state_machine_manager.register_state_machine("character", character_sm)
```

## Best Practices

1. **State Organization**
   - Keep states small and focused
   - Use hierarchical state machines for complex behaviors
   - Consider using state factories for dynamic state creation

2. **State Transitions**
   - Use message passing for state communication
   - Validate state transitions
   - Handle cleanup in _exit()

3. **Debugging**
   - Enable debug logging for state transitions
   - Use the built-in state monitoring tools
   - Add state validation checks

## API Reference

### BaseState
- `enter(msg: Dictionary)`: Enter the state
- `exit()`: Exit the state
- `update(delta: float)`: Update state logic
- `handle_input(event: InputEvent)`: Process input
- `switch_to(state_name: String, msg: Dictionary = {})`: Switch to another state

### BaseStateMachine
- `add_state(name: String, state: BaseState)`: Register a new state
- `remove_state(name: String)`: Remove a registered state
- `start(initial_state: String)`: Start the state machine
- `stop()`: Stop the state machine
- `switch_to(state_name: String, msg: Dictionary = {})`: Switch to a state

### StateMachineManager
- `register_state_machine(name: String, state_machine: BaseStateMachine)`: Register a state machine
- `unregister_state_machine(name: String)`: Unregister a state machine
- `get_state_machine(name: String) -> BaseStateMachine`: Get a registered state machine
