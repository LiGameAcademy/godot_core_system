# Deprecated GDScript tag adapters

Use [CoreTags](core_tags.md) for new code and the shared GDScript/C# contract. The old names remain migration adapters; membership operations now delegate to CoreTags. The optional object registry remains a GDScript extension.

## Local ownership

GameplayTagContainer is a Resource, not a scene child. It can be created without CoreSystem. It owns explicit full paths and emits legacy CoreGameplayTag payloads after membership changes are committed.

```gdscript
var container: GameplayTagContainer = GameplayTagContainer.new()
container.add_tag("unit.scout")
var owns_unit: bool = container.has_tag("unit", false)
var owns_tank: bool = container.has_tag("unit.tank", false)
container.remove_tag("unit.scout")
```

New code can replace the container with CoreTags and use its string notifications. Local membership needs no global registration or tree objects.

## Intentional migration changes

| Old behavior | Current behavior |
| --- | --- |
| Non-exact queries match both directions | An owned descendant matches its queried ancestor; owning `unit` does not grant `unit.scout` |
| `get_tags()` returns leaf names | Returns sorted explicit full paths |
| `get_all_tags()` expands registered descendants | Returns sorted explicit record objects only |
| Tag identity changes when reparented or renamed | Validated full path is fixed at creation |
| Repeated owner registration replaces its container | Returns the same live container for that owner |
| Manager keeps a duplicate membership index and cleanup timer | Queries live containers and prunes weak references on access |

Paths follow the CoreTags ASCII path contract. Invalid inputs log English errors and leave membership unchanged. All query paths are validated before evaluation. Empty All is true; empty Any is false. Duplicate additions and absent removals return false without notifications. Equivalent record objects match by full path value.

## Definition metadata

Create standalone records with `CoreGameplayTag.create("unit.scout")`. The `name`, `parent` and `children` properties are read-only through the supported API; children is an isolated snapshot. `add_child` accepts only a record with the corresponding direct-parent full path. A leaf-only record is not renamed by attachment. Parent and child links are weak; callers must retain records they need. Released links are pruned, and full path identity survives parent release.

`CoreSystem.tag_manager.get_tag(path)` registers definition records and ancestors. `get_matching_tags(path)` returns registered exact/descendant records sorted by full path and does not register a missing query. Definition descendants are metadata, not evidence that an owner explicitly possesses them.

## Optional legacy object registry

`CoreSystem.tag_manager` is created lazily when accessed. The registered `godot_core_system/module_enable/gameplay_tag_manager` setting takes precedence. The runtime `module_enable/tag_manager` key is used only when the registered key is absent; see [module setting names](../module_setting_names.md).

Pass an owner to `create_tag_container(owner)` and keep the returned container alive. Both owner and container are held weakly. Repeated requests return the same live container. Queries read its current local membership; released containers, released owners and Nodes queued for deletion are excluded. Empty All returns all live registered owners; empty Any returns none. `create_tag_container_from_strings` validates the complete list before registering or adding anything. Manager exit clears registration metadata. Registry query cost scales with live owners and queried paths; no performance index is claimed.

This registry has no C# counterpart and is not needed by CoreTags. Serialization, source counting and tag stacking are not provided here.

## Examples and verification

The migrated [tag_demo](../../examples/tag_demo/README.md) uses local CoreTags and CoreTimer, with no AutoLoad. The smaller [tags example](../../examples/tags/README.md) demonstrates the shared contract.

```powershell
godot --headless --path . --script res://addons/godot_core_system/test/unit/tag_compatibility_checks.gd
godot --headless --path . --script res://addons/godot_core_system/test/unit/tag_demo_migration_checks.gd
```

Require PASS and zero exit status. Negative-input checks intentionally log errors. Godot 4.7.2: 46 adapter checks and 17 migrated scene checks pass without retained-object shutdown warnings. Full legacy CoreSystem shutdown has separate historical retention issues; these adapters do not claim to repair unrelated modules.
