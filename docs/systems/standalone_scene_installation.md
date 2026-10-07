# Install only the native scene module (#94)

CoreScenes needs Godot's SceneTree and CoreSceneRequest. The optional fade
presentation additionally needs CoreSceneTransition, CoreSceneTransitionOperation
and its scene. No CoreSystem, legacy ResourceManager, logger, configuration,
state machine or other module is required. Keep the addon-relative paths below;
the presentation loads its scene from that location.

The complete source/UID manifest is in `tools/create_scene_module_host.ps1`:

- `source/scene_system/core_scenes.gd` and its `.uid`
- `source/scene_system/core_scene_request.gd` and its `.uid`
- `source/scene_system/core_scene_transition.gd` and its `.uid`
- `source/scene_system/core_scene_transition_operation.gd` and its `.uid`
- `source/scene_system/core_scene_transition.tscn`

Copy these 9 files under `addons/godot_core_system/` in a Godot project. Do not
install or enable `plugin.cfg` for this selective installation. Import the
project so Godot registers the four script classes before running it.

## Reproduce the minimal host

Until baseline PR #106 and this issue's PR are merged, use this issue's branch
`feat/issue-94-scenes-isolation`, rather than claiming the files are already
available on main. Checkout or clone that branch, then from its repository:

```powershell
git switch feat/issue-94-scenes-isolation
./tools/create_scene_module_host.ps1 -Destination 'D:/GodotTests/scene-only-host'
godot --headless --editor --path 'D:/GodotTests/scene-only-host' --import
godot --headless --verbose --path 'D:/GodotTests/scene-only-host'
```

Use your actual Godot executable and a new writable destination. The script
rejects an existing directory, validates all source files first, and copies an
explicit manifest; it never recursively installs the addon. It adds only three
check fixtures plus project/manifest files. The project has SceneModuleChecks
as its persistent check owner, with no CoreSystem AutoLoad or editor plugin.

Expected: 21 checks PASS, exit 0, no script errors or ObjectDB/Resource retention.
The runtime checks absence of the full entry, logger and resource directories;
actual A→B switching and B→A presentation; missing paths; duplicate/busy requests;
one completion; release of the old main scene; fade-owner exit; service-owner
exit; and no scene change from a canceled deferred request.

Verified source baseline: `161179347dab9c9d80fd69143db0734302a5835d`, with this
branch adding the script, fixtures and instructions. Godot 4.7.2 stable mono,
Windows, imported headless host. Sandbox user log directory/certificate errors
and Mono's absent project assembly diagnostic are recorded independently of
script behavior. This is editor/headless runtime evidence; exports and other
platforms are not verified here and remain part of #103.

## Ownership and existing examples

An application owner explicitly creates `CoreScenes.new(get_tree())`, keeps it
alive across main-scene replacement, and calls dispose() on exit. A request is
a completion handle; wait() is safe on an already-completed result. Keep the
navigation coroutine in that persistent owner. Main-scene controls may bind a
completion callback owned by their scene; they must not await work that needs
to resume after that scene is freed.

For the existing colored button demo, copy `examples/native_scenes/` as well and
register its `scene_example_host.gd` as SceneExampleHost, following its README.
That explicit example owner is optional and has no CoreSystem dependency. The
minimal host above uses check fixtures instead of the interactive demo; its
results do not certify the legacy scene stack or custom transitions. Those
different APIs stay in #100.

Module contract for this boundary: startup requires only a live SceneTree;
CoreScenes owns its pending request and SceneTree signal subscription; its owner
disposes it. Transition owns presentation and completes interrupted fades as
ERR_UNAVAILABLE. No inferred module is enabled or constructed. This establishes
only the scene-module slice of #75, not the complete startup dependency matrix.
