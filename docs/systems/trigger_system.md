# Trigger System

The Trigger System is a flexible and powerful system for managing game triggers and events. It supports various trigger types, conditions, and actions, making it ideal for creating interactive game mechanics.

## Features

- 🎯 **Multiple Trigger Types**: Support for immediate, event-based, and periodic triggers
- 🔄 **Conditional Execution**: Flexible condition system for trigger activation
- 📊 **Probability Control**: Built-in trigger chance control
- ⏱️ **Periodic Triggers**: Support for time-based periodic triggers
- 🔌 **Event Bus Integration**: Optional integration with the event bus system
- 💾 **Persistence**: Support for trigger state serialization

## Quick Start

### 1. Access Trigger Manager

```gdscript
var trigger_manager = CoreSystem.trigger_manager
```

### 2. Create Simple Trigger

```gdscript
# Create an event trigger
var trigger = GameplayTrigger.new({
    "trigger_type": GameplayTrigger.TRIGGER_TYPE.ON_EVENT,
    "trigger_event": "player_entered",
    "conditions": [
        {
            "type": "state_trigger_condition",
            "state_name": "player_in_area",
            "required_state": "true"
        }
    ]
})

# Connect to trigger signal
trigger.triggered.connect(_on_trigger_activated)

# Activate trigger
trigger.activate()
```

### 3. Create Periodic Trigger

```gdscript
# Create a periodic trigger
var periodic_trigger = GameplayTrigger.new({
    "trigger_type": GameplayTrigger.TRIGGER_TYPE.PERIODIC,
    "period": 2.0,  # Trigger every 2 seconds
    "trigger_chance": 0.5  # 50% chance to trigger
})

periodic_trigger.triggered.connect(_on_periodic_trigger)
periodic_trigger.activate()
```

### 4. Handle Events

```gdscript
# Send event to trigger system
trigger_manager.handle_event("player_entered", {
    "state_name": "player_in_area",
    "state_value": "true"
})
```

## Examples

Check the [trigger_demo](../examples/trigger_demo/) directory for a complete example project.

### Area Trigger Example

```gdscript
# Create area trigger
var area_trigger = GameplayTrigger.new({
    "trigger_type": GameplayTrigger.TRIGGER_TYPE.ON_EVENT,
    "trigger_event": "enter_area",
    "conditions": [
        {
            "type": "state_trigger_condition",
            "state_name": "player_in_area",
            "required_state": "true"
        }
    ]
})

# Handle area events
func _on_area_entered(body: Node) -> void:
    trigger_manager.handle_event("enter_area", {
        "state_name": "player_in_area",
        "state_value": "true"
    })
```

## API Reference

### TriggerManager

Global trigger manager responsible for trigger registration and event handling.

- `handle_event(trigger_type: StringName, context: Dictionary) -> void`: Handle trigger event
- `register_event_trigger(trigger_type: StringName, trigger: GameplayTrigger) -> void`: Register event trigger
- `register_periodic_trigger(trigger: GameplayTrigger) -> void`: Register periodic trigger
- `create_condition(config: Dictionary) -> TriggerCondition`: Create trigger condition

### GameplayTrigger

Core trigger class that handles trigger logic and conditions.

#### Properties
- `trigger_type: TRIGGER_TYPE`: Type of trigger (IMMEDIATE, ON_EVENT, PERIODIC)
- `conditions: Array[TriggerCondition]`: List of conditions
- `persistent: bool`: Whether trigger state should persist
- `max_triggers: int`: Maximum number of times trigger can activate
- `trigger_count: int`: Current trigger count
- `trigger_event: StringName`: Event name for event-based triggers
- `period: float`: Time between triggers for periodic triggers
- `trigger_chance: float`: Probability of trigger activation

#### Methods
- `activate(initial_context: Dictionary = {}) -> void`: Activate trigger
- `deactivate() -> void`: Deactivate trigger
- `execute(context: Dictionary) -> void`: Execute trigger
- `should_trigger(context: Dictionary) -> bool`: Check if trigger should activate
- `reset() -> void`: Reset trigger state

### TriggerCondition

Base class for trigger conditions.

- `evaluate(context: Dictionary) -> bool`: Evaluate condition

## Best Practices

1. **Choose Appropriate Trigger Type**
   - Use ON_EVENT for event-driven triggers
   - Use PERIODIC for time-based triggers
   - Use IMMEDIATE for one-shot triggers

2. **Manage Trigger Lifecycle**
   - Activate triggers when needed
   - Deactivate triggers when not needed
   - Reset triggers when reusing

3. **Use Conditions Effectively**
   - Keep conditions simple and focused
   - Combine conditions for complex logic
   - Use appropriate condition types

4. **Performance Considerations**
   - Limit number of active triggers
   - Use appropriate update intervals for periodic triggers
   - Clean up unused triggers

## Common Issues

1. **Trigger Not Firing**
   - Check if trigger is activated
   - Verify event names match exactly
   - Check condition logic
   - Ensure trigger chance is appropriate

2. **Performance Problems**
   - Too many active triggers
   - Too frequent periodic updates
   - Complex condition evaluations

3. **Event Integration Issues**
   - Check event bus subscription setting
   - Verify event names and parameters
   - Check event handler connections
