# Legacy GDScript tag system

For the current local, dual-language contract, use [CoreTags](core_tags.md). The APIs below remain GDScript-specific compatibility extensions. They are not a C# port or the directional CoreTags query model.

CoreGameplayTag is a mutable RefCounted tree element with name, parent and children. GameplayTagContainer is a Resource, not a Node: never pass it to add_child or fetch it as a scene child. CoreSystem.tag_manager is a Node that registers tag paths and optionally indexes tagged owners.

```gdscript
var container: GameplayTagContainer = CoreSystem.tag_manager.create_tag_container()
container.add_tag("unit.scout")
var owns_scout: bool = container.has_tag("unit.scout")
container.remove_tag("unit.scout")
```

To opt into the legacy object index, pass an owner to create_tag_container(owner) and keep the returned Resource alive for that owner's lifetime. The manager listens to additions/removals and queries weak owner references. This registry is not used by CoreTags, which needs no global manager.

## Existing behavior and limits

- get_tag(path) auto-registers the path and its ancestor objects. It does not enforce the CoreTags ASCII path contract.
- has_tag(tag, exact = true) compares full paths in exact mode. Non-exact matching is bidirectional along the registered object tree; it can match a parent against a child query. Do not use that behavior to grant specific abilities from broad classification tags.
- has_all_tags and has_any_tags use container matching. The manager's get_objects_with_all_tags assumes a nonempty query array; the empty-input rules are not CoreTags rules.
- get_tags() returns stored leaf names, not full paths. get_all_tags() expands registered descendants, which does not mean the owner explicitly owns those descendants.
- Signals tag_added and tag_removed carry CoreGameplayTag objects. CoreTags notifications carry full path strings instead.
- No serialization/deserialization API is implemented here. If persistence is needed, design an application-owned data representation and validate it.
- Global indexing, periodic cleanup and mutable hierarchy are legacy features; no claim is made that their ownership or lifecycle equals the standalone CoreTags implementation.

Existing demonstrations remain in [tag_demo](../../examples/tag_demo/). The independent supported local example is [tags](../../examples/tags/README.md). New code should choose its ownership and query semantics explicitly rather than mix the two APIs.