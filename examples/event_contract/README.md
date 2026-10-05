# Scene-owned event subscriptions

Run event_contract_example.tscn in a Godot 4.7 host with the plugin at addons/godot_core_system. Publish notices, remove the listening scene and create a fresh owner; the subscription count drops to zero on exit, and new instances start with their own received count.

The parent owns the bus and injects it into the child before tree entry. The child owns its token, disposes it on exit and emits a local signal to the parent UI. This is independent of the legacy priority/filter/history event module.

See [API, checks and C# mapping](../../docs/systems/core_event_bus.md).
