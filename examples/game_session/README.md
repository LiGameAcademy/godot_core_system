# Caller-owned session example

Run game_session_example.tscn with F6 in a Godot 4.7.2 host containing this plugin. No game assets, AutoLoad, global time ownership or persistence are required. The scene is part of the host, not a nested Godot project.

| Operation | Expected result |
| --- | --- |
| Start / Pause / Resume | Valid lifecycle transitions; repeated/illegal operations do nothing |
| Add one point | Count mode ends at three points; paused/preparing/ended runs reject progression |
| Advance local time by one second | Timer mode ends after three running seconds; pause does not consume time |
| End manually / Close | End or permanently close this instance |
| New count run / New timed run | Close/unbind old core, reset local rules, create a new identity in Preparing |

CoreSessionExampleModel owns the independent rules/CoreTimer and composes CoreGameSession. game_session_example.gd owns presentation, observes committed phases and disconnects/closes on exit. The two rules share one lifecycle implementation. Count saturates at three; a condition reached during a lifecycle notification retries End on the next operation, respecting reentry protection. Time is explicitly stepped, without wall-clock scheduling.

Identities use a prefix and local sequence for demonstration; callers ensure uniqueness where needed. Multiple scene instances own independent sessions even if their example identities coincide. Closing only one instance must not affect the other.

Import the required scripts and run actual button checks:

```powershell
godot --headless --path . --script res://addons/godot_core_system/test/unit/session_example_checks.gd
```

Require zero exit code and `PASS: 13 session example checks`; timeout alone is not a pass. Coverage includes both end rules, pause/resume, manual end/close, fresh identity, A/B isolation and owner exit. Pure rule checks and failure semantics are described in [the API document](../../docs/systems/core_game_session.md). The example has been verified in a isolated host with the module and its necessary dependencies; visual experience and exported packages are separate acceptance items.
