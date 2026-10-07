extends SceneTree

const TagManager = preload("res://addons/godot_core_system/source/tag_system/gameplay_tag_manager.gd")
var _checks: int = 0
var _failed: bool = false
var _observed: GameplayTagContainer
var _notifications: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var manager: TagManager = TagManager.new()
	root.add_child(manager)
	_check(manager.get_child_count() == 0, "Compatibility registry creates no cleanup timer")
	var container: GameplayTagContainer = GameplayTagContainer.new()
	_observed = container
	container.tag_added.connect(_on_added)
	container.tag_removed.connect(_on_removed)
	_check(container.add_tag("unit.scout.fast"), "Facade stores a local full path")
	_check(container.has_tag("unit", false) and not container.has_tag("unit"), "Facade uses directional matching")
	_check(not container.has_tag("unit.scout.faster", false), "A parent never grants a child fact")
	_check(not container.add_tag("unit.scout.fast") and _notifications.size() == 1, "Duplicates are silent")
	var same_path: CoreGameplayTag = CoreGameplayTag.create("unit.scout.fast")
	_check(container.remove_tag(same_path) and _notifications.size() == 2, "Equivalent path records remove by value")
	container.add_tag("unit.fast")
	container.add_tag("effect.fast")
	manager.get_tag("unit.fast.child")
	_check(container.get_tags() == ["effect.fast", "unit.fast"], "Full paths preserve leaf-name identity")
	_check(container.get_all_tags().size() == 2, "Object snapshots include only explicit ownership")
	_check(container.has_all_tags([]) and not container.has_any_tags([]), "Facade empty all/any parity")
	_check(not container.has_any_tags(["unit.fast", 42]), "All arguments validate before any matching")
	_check(not container.add_tag(null) and not container.add_tag("unit..bad"), "Invalid values cannot mutate")
	_check(container.get_tags().size() == 2, "Invalid mutations preserve membership")
	container.tag_added.disconnect(_on_added)
	container.tag_removed.disconnect(_on_removed)
	_observed = null

	var leaf: CoreGameplayTag = manager.get_tag("unit.scout.fast")
	var top: CoreGameplayTag = manager.get_tag("unit")
	_check(leaf.name == "fast" and leaf.get_full_path() == "unit.scout.fast", "Legacy records have stable full-path identity")
	_check(leaf.matches(top, false) and not top.matches(leaf, false), "Record matching is directional")
	_check(leaf.matches(same_path), "Exact records compare by path rather than identity")
	_check(not top.add_child(top), "Self cycles are rejected")
	_check(not leaf.add_child(top), "Ancestor cycles are rejected")
	_check(not top.add_child(CoreGameplayTag.create("other.child")), "Unrelated paths cannot reparent")
	var children: Array[CoreGameplayTag] = top.children
	children.clear()
	_check(not top.children.is_empty(), "Child metadata snapshot is isolated")
	leaf.name = "changed"
	_check(leaf.get_full_path() == "unit.scout.fast", "Path identity cannot be renamed")
	var matches: Array[CoreGameplayTag] = manager.get_matching_tags("unit.scout")
	_check(matches.size() == 2 and matches[0].get_full_path() == "unit.scout", "Definition query includes exact and descendants only")
	_check(manager.get_matching_tags("missing").is_empty(), "Definition queries do not register missing paths")
	_check(manager.get_tag("invalid..path") == null, "Invalid registry path rejected")

	var owner: RefCounted = RefCounted.new()
	var owned: GameplayTagContainer = manager.create_tag_container(owner)
	_check(owned == manager.create_tag_container(owner), "One live container per owner")
	owned.add_tag("unit.scout")
	_check(manager.get_objects_with_tag("unit", false) == [owner], "Object queries consume current local collection")
	_check(manager.get_objects_with_all_tags(["unit.scout"]) == [owner], "Single and all queries agree")
	_check(manager.get_objects_with_all_tags([]) == [owner] and manager.get_objects_with_any_tags([]).is_empty(), "Registry empty all/any semantics")
	_check(manager.create_tag_container_from_strings(["effect.valid", "invalid..path"], owner) == null, "Factory validates whole input before mutation")
	_check(not owned.has_tag("effect.valid"), "Invalid factory input retains existing owner state")
	var container_ref: WeakRef = weakref(owned)
	owned = null
	_check(container_ref.get_ref() == null, "Registry does not retain containers")
	_check(manager.get_objects_with_tag("unit.scout").is_empty(), "Released container removes its owner from every query")
	owned = manager.create_tag_container(owner)
	owned.add_tag("unit.scout")
	var owner_ref: WeakRef = weakref(owner)
	owner = null
	_check(owner_ref.get_ref() == null, "Container callbacks cannot keep a RefCounted owner alive")
	_check(manager.get_objects_with_tag("unit.scout").is_empty(), "Released owner disappears while its container remains alive")

	var node_owner: Node = Node.new()
	root.add_child(node_owner)
	var node_tags: GameplayTagContainer = manager.create_tag_container(node_owner)
	node_tags.add_tag("unit.scout")
	node_owner.queue_free()
	_check(manager.get_objects_with_tag("unit.scout").is_empty(), "Queued nodes are excluded before deletion")
	_check(manager.create_tag_container(node_owner) == null, "Queued owner registration is rejected")
	await process_frame
	var weak_metadata: CoreGameplayTag = CoreGameplayTag.create("weak")
	var transient_child: CoreGameplayTag = CoreGameplayTag.create("weak.child")
	weak_metadata.add_child(transient_child)
	var child_ref: WeakRef = weakref(transient_child)
	transient_child = null
	_check(child_ref.get_ref() == null, "Child metadata does not retain abandoned records")
	_check(weak_metadata.children.is_empty() and weak_metadata.get("_children_refs").is_empty(), "Expired child wrappers are pruned on metadata access")
	var orphan: CoreGameplayTag = CoreGameplayTag.create("standalone.child")
	var temporary_parent: CoreGameplayTag = CoreGameplayTag.create("standalone")
	_check(temporary_parent.add_child(orphan), "Direct full-path metadata attaches")
	var parent_ref: WeakRef = weakref(temporary_parent)
	temporary_parent = null
	_check(parent_ref.get_ref() == null and orphan.parent == null, "Weak parent links do not retain abandoned records")
	_check(orphan.get_full_path() == "standalone.child", "Path survives metadata release")
	matches.clear()
	var registered_ref: WeakRef = weakref(top)
	top = null
	manager.queue_free()
	await process_frame
	await process_frame
	_check(registered_ref.get_ref() == null, "Registry exit releases definition records")
	_check(leaf.parent == null and leaf.get_full_path() == "unit.scout.fast", "Retained leaf identity survives registry exit")
	if not _failed:
		print("PASS: %d tag compatibility checks" % _checks)
	quit(1 if _failed else 0)

func _on_added(tag: CoreGameplayTag) -> void:
	_check(_observed.has_tag(tag), "Facade addition commits before notification")
	_notifications.append("add:" + tag.get_full_path())

func _on_removed(tag: CoreGameplayTag) -> void:
	_check(not _observed.has_tag(tag), "Facade removal commits before notification")
	_notifications.append("remove:" + tag.get_full_path())

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)