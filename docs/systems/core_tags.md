# CoreTags: local hierarchical tags

CoreTags is an instance-owned set of paths for classification and rule conditions. It has no AutoLoad, object index, registry, tree of tag objects, timers or implicit IO. Create one collection per owner and let game rules decide what its tags mean. A tag is a fact used by a rule; adding state.stunned does not itself pause nodes or change engine time.

## Common contract

Paths are case-sensitive, 1-128 characters long, with nonempty dot-separated segments containing only ASCII letters, digits and underscores. There is no trimming, case folding or automatic ancestor registration. unit.scout and Unit.scout are different paths. Use IsValidPath / is_valid_path to validate an external string without logging or throwing.

| C# | GDScript | Behavior |
| --- | --- | --- |
| Count | count | Number of explicit paths |
| Add(path) | add(path) | Returns true on insertion, false for a duplicate |
| Remove(path) | remove(path) | Returns true on removal, false when absent |
| Has(path, exact = true) | has(path, exact = true) | Exact by default; false enables directional ancestor queries |
| HasAll(paths, exact = true) | has_all(paths, exact = true) | All queries must match; empty input is true |
| HasAny(paths, exact = true) | has_any(paths, exact = true) | Any query must match; empty input is false |
| Snapshot() | snapshot() | Fresh sorted array of full explicit paths |
| Clear() | clear() | Removes current explicit paths and returns the size of that batch |
| TagAdded / TagRemoved | tag_added / tag_removed | Synchronous notifications carrying the full path |

With only unit.scout stored, Has("unit", false) is true, Has("unit") is false, and Has("unit.scout.fast", false) is false. A stored parent never grants a more specific child condition. Segment boundaries matter: unit.scout does not match uni or unit.scouter. Removing unit cannot remove an explicitly stored unit.scout; no hierarchical delete is performed.

All/Any validate every supplied path before matching. Invalid inputs do not change state. GDScript methods report an English engine error and return false. C# throws ArgumentException for an invalid path, including null; null query collections throw ArgumentNullException. This is a language-specific failure mechanism, not an alternative match result.

## Ownership and notifications

Snapshots are detached arrays sorted by ordinal path order. Changing a snapshot does not change its source collection. Independent instances share no mutable state.

Add and Remove commit before notification; duplicate Add and missing Remove do not notify. Clear snapshots the removed batch, clears the set, then notifies each removed path in snapshot order. Callbacks may mutate the collection: their additions survive Clear. Removed notifications describe the committed batch, so a later callback may see paths re-added by an earlier callback. Do not use callbacks as a transaction approval step.

Use one owning thread. When callbacks touch Godot nodes, call from the Godot main thread. Subscribe for the owning scene's lifetime and disconnect on exit. C# observers use normal .NET events: exceptions propagate, the mutation remains committed, and remaining callbacks/clear notifications may not run. GDScript uses normal Godot signals: callback failures are engine errors and do not roll back the mutation. Neither language promises rollback or successful delivery to every failing observer.

## Rule usage

```csharp
using GodotCoreSystem;

CoreTags tags = new();
tags.Add("unit.scout");
tags.Add("state.stunned");
bool canAct = tags.Has("unit", exact: false) && !tags.Has("state.stunned");
string[] explicitPaths = tags.Snapshot();
```

```gdscript
var tags: CoreTags = CoreTags.new()
tags.add("unit.scout")
tags.add("state.stunned")
var can_act: bool = tags.has("unit", false) and not tags.has("state.stunned")
var explicit_paths: Array[String] = tags.snapshot()
```

Keep configuration tags in application-owned resources and runtime tags in each owner's instance. If persistence is needed, save the snapshot in an application DTO and validate the complete path list before rebuilding a collection. CoreTags is not a save format, buff stack/counter, ability system, wildcard query language or replacement for a state machine.

## Example and verification

examples/tags/tags_example.tscn runs without an AutoLoad or game assets. The independent rule model stores unit.scout, allows actions unless stunned, and tracks completed actions. Toggle stun, toggle shield, try an action and reset; shield and stun are independent facts. UI only consumes the rule model and notifications. Two-instance checks verify that A cannot affect B and that a retained model remains usable after UI exit.

C# plugin checks:

```powershell
dotnet run --project tests/unit/TagChecks.csproj
```

In an imported Godot .NET host that excludes the plugin's tests/unit sources:

```powershell
dotnet build
godot --headless --path . res://addons/godot_core_system_cs/examples/checks/tag_example_checks.tscn --quit-after 300
```

GDScript checks in an imported Godot host:

```powershell
godot --headless --path . --script res://addons/godot_core_system/test/unit/tag_contract_checks.gd
godot --headless --path . --script res://addons/godot_core_system/test/unit/tag_example_checks.gd
```

Require PASS and a zero exit code; a timeout alone is not success. Invalid-path GDScript cases intentionally log errors. Verified on Godot 4.7.2: C# 50 rule checks, GDScript 49 corresponding checks (C# additionally verifies observer exception propagation), and 11 example checks per language. The C# plugin-only host builds with zero warnings/errors. These checks do not replace exported-build acceptance, which remains deferred.

## Legacy GDScript boundary

CoreGameplayTag, GameplayTagContainer and CoreSystem.tag_manager are deprecated GDScript adapters. Local membership now delegates to CoreTags, including directional matching, validation and explicit full-path snapshots. The manager is lazy and queries live weakly registered owners/containers without a duplicate tag index or cleanup timer. Its object registry has no C# counterpart. Intentional behavior changes and migration guidance are documented in [legacy adapters](tag_system.md).

The migrated [character demo](../../examples/tag_demo/README.md) uses CoreTags directly, independent models and signals, with no AutoLoad. Adapter checks (46) and scene migration checks (17) pass on Godot 4.7.2. The separate test/unit/legacy_event_entry_checks.gd requires the old CoreSystem AutoLoad and verifies legacy event types and lazy tag module flags. Full legacy startup still reports retained objects/resources at shutdown; independent tag checks exit cleanly. Export acceptance remains deferred.
