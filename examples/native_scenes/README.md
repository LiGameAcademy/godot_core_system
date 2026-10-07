# Native scene example

Install the plugin at addons/godot_core_system in a Godot 4.7 project. Register SceneExampleHost as an AutoLoad using this directory's scene_example_host.gd. Run scene_a.tscn or scene_b.tscn; the button switches through a persistent fade between differently colored scenes.

The example host owns CoreScenes and CoreSceneTransition. Main scenes own only their controls and bound completion callbacks. They never await a navigation coroutine that must resume after their own destruction. No game assets, saved data or legacy managers are required.

See [native scene API](../../docs/systems/native_scenes.md) for the C# mapping, failure behavior and the dedicated automated checks. This example does not replace the legacy scene_demo, which demonstrates different scene-stack and transition APIs.
