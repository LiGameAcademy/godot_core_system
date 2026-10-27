extends SceneTree

var _checks: int = 0
var _failed: bool = false
var _added: Array[String] = []
var _removed: Array[String] = []
var _tags: CoreTags = CoreTags.new()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_tags.tag_added.connect(_on_added)
	_tags.tag_removed.connect(func(path: String) -> void: _removed.append(path))
	_check(_tags.count == 0 and not _tags.has("unit"), "Empty collection")
	_check(_tags.add("unit.scout.fast"), "Add descendant")
	_check(not _tags.add("unit.scout.fast") and _added.size() == 1, "Duplicate is silent")
	_check(_tags.has("unit.scout.fast") and not _tags.has("unit.scout"), "Exact matching is default")
	_check(_tags.has("unit", false) and _tags.has("unit.scout", false), "Descendant satisfies parent")
	_check(not _tags.has("uni", false) and not _tags.has("unit.scout.faster", false), "Segment boundary matters")
	_check(not _tags.has("Unit", false), "Case is significant")
	_check(_tags.add("state") and not _tags.has("state.stunned", false), "Parent never satisfies child")
	_check(_tags.has_all(["unit", "state"], false), "All query")
	_check(not _tags.has_all(["unit", "effect"], false), "Missing required query")
	_check(_tags.has_any(["effect", "unit"], false), "Any query")
	_check(not _tags.has_any(["effect"], false), "Missing optional query")
	_check(_tags.has_all([]) and not _tags.has_any([]), "Empty all/any semantics")
	var copy: Array[String] = _tags.snapshot()
	_check(copy == ["state", "unit.scout.fast"], "Sorted full explicit paths")
	copy[0] = "changed"
	_check(_tags.has("state") and not _tags.has("changed"), "Snapshot isolation")
	_check(not _tags.remove("unit") and _removed.is_empty(), "Implicit ancestor removal is silent")
	_check(_tags.remove("state") and _removed.size() == 1 and not _tags.has("state"), "Removal commits and notifies")
	for invalid: String in ["", ".unit", "unit.", "unit..scout", "unit scout", "unit/fast", "unité", "a".repeat(129)]:
		_check(not CoreTags.is_valid_path(invalid), "Invalid path rejected")
		_check(not _tags.add(invalid), "Invalid mutation rejected")
	_check(CoreTags.is_valid_path("a".repeat(128)) and CoreTags.is_valid_path("unit_2.3"), "Accepted boundary and characters")
	_check(not _tags.has_any(["unit.scout.fast", ""]), "Validate whole any query before matching")
	_check(not _tags.has_all(["missing", ""]), "Validate whole all query before matching")
	_check(_tags.count == 1, "Invalid calls do not mutate")
	var other: CoreTags = CoreTags.new()
	_check(not other.has("unit", false), "Independent collections")
	_tags.add("effect.shield")
	_removed.clear()
	_tags.tag_removed.connect(_readd)
	_check(_tags.clear() == 2, "Clear counts committed batch")
	_check(_removed == ["effect.shield", "unit.scout.fast"], "Clear uses snapshot order")
	_check(_tags.count == 1 and _tags.has("effect.shield"), "Observer additions survive clear")
	_tags.tag_removed.disconnect(_readd)
	_check(_tags.clear() == 1 and _tags.clear() == 0, "Empty clear is silent")
	var a: CoreTagExampleModel = CoreTagExampleModel.new()
	var b: CoreTagExampleModel = CoreTagExampleModel.new()
	_check(a.try_act() and a.actions_completed == 1, "Initial rule action")
	a.tags.add("state.stunned")
	_check(not a.try_act() and a.actions_completed == 1 and b.can_act, "Stun blocks its own model only")
	a.reset()
	_check(a.can_act and a.actions_completed == 0, "Rule reset")
	if not _failed:
		print("PASS: %d tag checks" % _checks)
	quit(1 if _failed else 0)

func _on_added(path: String) -> void:
	_check(_tags.has(path), "Add commits before notification")
	_added.append(path)

func _readd(path: String) -> void:
	if path == "effect.shield":
		_tags.add(path)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
