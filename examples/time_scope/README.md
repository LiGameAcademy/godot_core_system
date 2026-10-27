# Engine time ownership example

Run time_scope_example.tscn in a Godot 4.7 host with the plugin installed at addons/godot_core_system. Buttons toggle pause, switch 1x/2x, release the acquired snapshot, and acquire again. The UI processes while paused. Exiting the scene restores the original engine state.

This standalone session owns one CoreTime service. Applications with multiple scenes should keep one service in a persistent owner and give it explicitly to those scenes; do not instantiate competing services for the same engine settings. The private legacy TimeManager and CoreTimer have different responsibilities.

See [API and C# mapping](../../docs/systems/core_time_scope.md), including explicit failure handling and the 37-check standalone runner.
