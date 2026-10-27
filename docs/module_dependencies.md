# Independent module contract: configuration prerequisite

This records the implemented configuration/logging boundary for #95 and the current remaining
dependency work from #75. It does not replace the [startup proposal](https://github.com/LiGameAcademy/godot_core_system/pull/90),
change every legacy module's startup policy or claim all module combinations are supported.

For independently installed consumers: dependencies are explicit, state belongs to an instance,
diagnostics are optional, unavailable dependencies return a failure rather than creating an
unrequested global service, and one owner modifies each shared file/global engine setting.
Use Godot on the main thread. Owners release the nodes, subscriptions, scopes and tasks they create.
No DI container, automatic dependency enabling or runtime hot unloading is introduced.

## Current source inventory

This table is source inspection, not new runtime acceptance of every row. C# equivalents cover
the shared core; a matching service name does not imply complete legacy extension parity.

| Responsibility | Independent core / direct dependency | Legacy boundary or remaining work |
| --- | --- | --- |
| Configuration | GD ConfigFile adapter / C# CoreConfig: Godot only; optional failure callback | #95 now independent; manual persistence and one writer per path |
| Logging | GD logger: engine, optional project colors; C# CoreLogger: caller sink | #95 removes setting.gd dependency; legacy consumers still need individual migration |
| Resources | CoreResources: ResourceLoader and local request/cache state | ResourceManager delegates; callers own loader lifetime and borrowed Resource references |
| Instances | CoreInstancePool: engine Nodes, per-pool ownership marker | Pool owns admitted nodes; callers initialize/stop/detach; close releases leases |
| Entities | No shared entity core yet | EntityManager still obtains ResourceManager through CoreSystem; #101 next |
| Scenes | CoreScenes: supplied SceneTree, optional transition | Legacy SceneManager uses global resource/log services; #94/#100 and P4 |
| Audio | Local CoreAudio node / player graph | Legacy AudioManager gets config/log services; #96 and P3 |
| Input bindings | CoreInputs: action group and InputMap | Global InputMap group has one writer; legacy config/runtime features require #97/P4 |
| Input buffer/recording/axes | GD engine helpers; no shared complete C# runtime extension yet | Local clock and recorder ownership remain P4; recording is not deterministic game replay |
| JSON persistence | Local save directory/store, codecs; GD Windows replacement extension | Explicit path and schema ownership; exported native extension acceptance deferred |
| Legacy save slots/strategies | Slot state, IO, format and config dependencies | SaveManager/strategies still use globals and precreated workers; #98/#99, P6/P7 |
| Events | CoreEventBus and subscription tokens | Local event authority; legacy Node entry remains an adapter |
| State machines | Value/behavior machine, local states | Legacy registry/driver expansion remains P5 |
| Time and timers | Explicitly stepped timer; scoped pause/speed adapters | One owner for global engine time; private clock extensions remain P4 |
| Session | Local identity/state with explicit pause adapter | No gameplay economics or global level lookup; owner rejects stale callbacks |
| Tags | CoreTags local set; GD weak legacy registry extension | No C# global owner registry; remaining P5 extensions are separate |
| Triggers | CoreTrigger local quota/conditions | Old activation/condition managers still use event/log globals; P5 |
| Random selection | GD RandomPicker and caller data | Shared seeded randomness/weight behavior still P6 |
| Frame splitting | Old GD helper awaits CoreSystem tree | Explicit owner tree/budget/cancellation still P6; not independently installed yet |
| Directory helper | Object script path in GD | C# path mapping and no-script behavior remain P6 |
| Thread/async IO/encoding | Godot Thread, strategies and callbacks | Legacy helpers still reference CoreSystem logger/types; #98 before save expansion |
| CoreSystem assembly | GD preloads old modules; C# optional application entry | All-disabled, missing dependency and startup/worker matrix remain #75/#102 |

## Acceptance boundary

| Selected installation | Evidence from this prerequisite |
| --- | --- |
| GD configuration and logger scripts only; no CoreSystem or setting.gd | 20 core checks, including failure IO, nested snapshot, exported path and reattachment |
| C# CoreConfig and checks only; no runtime or logger | 18 core checks; complete minimal-host build has zero warnings/errors |
| Two language configuration scenes | 6 real button checks each; memory changes, explicit save, reload and unsaved reset |
| Complete C# plugin installed without AutoLoad | Build zero warnings/errors; same 18 core + 6 button checks |
| C# existing pure logger and JSON store | 10 and 68 independent regressions respectively |
| Full legacy CoreSystem with all switches disabled/missing dependencies | Not executed or fixed here; #75/#102 remain open |
| Scene-only installation, resource-only legacy saves and actual worker counts | Not claimed here; #94/#98/#99 and startup matrix remain open |

Next, #101 must supply explicit resource/pool dependencies and failure cleanup without calling the
old logger/config entry. Broad startup implementation and independent packaging remain separate.
