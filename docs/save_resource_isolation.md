# Mutable resource restoration (#66)

When a saved resource_path includes mutable props, the JSON/binary shared
loader uses ResourceLoader.CACHE_MODE_IGNORE_DEEP before applying properties.
Root resources, subresources and external resource dependencies are restored
independently of the cached template. This avoids shallow-copy assumptions for
resource references nested inside arrays and dictionaries. A path with empty
props remains a shared read-only reference.

This changes resource identity and may add load/allocation cost for dependency
trees. Paths must be loadable from stored/imported resources; cache-only objects
with no backing file are not a persistence mechanism. Custom loaders should be
tested for their cache-mode support. Saved mutable state should not depend on
reference equality with the original cached resource.

In a writable host with CoreSystem, run:

```sh
godot --headless --path /path/to/host res://addons/godot_core_system/test/unit/resource_restore_checks.tscn
```

Expect PASS and exit 0. It tests real tres caching, A/B PackedScene instances,
the original template, root and external resources, arrays/dictionaries,
repeated restoration, and empty-props read-only sharing. Full game-level save
graphs and custom ResourceFormatLoaders require manual acceptance.

The cache mode is available in the project's documented Godot 4.4+ baseline:
[Godot ResourceLoader cache modes](https://docs.godotengine.org/en/4.4/classes/class_resourceloader.html#enum-resourceloader-cachemode).
