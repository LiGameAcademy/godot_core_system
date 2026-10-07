extends Control

@export var actor_scene: PackedScene
@onready var _actors: Node2D = $Actors
@onready var _status: Label = $Panel/Status
var _pool: CoreInstancePool = CoreInstancePool.new(2)
var _created: int = 0
var _reused: int = 0

func _ready() -> void:
	$Panel/Spawn.pressed.connect(spawn_pair)
	$Panel/Tint.pressed.connect(tint_first)
	$Panel/Recycle.pressed.connect(recycle_all)
	$Panel/Clear.pressed.connect(clear_pool)
	_refresh()

func spawn_pair() -> void:
	if _actors.get_child_count() != 0:
		return
	for index: int in range(2):
		var actor: PoolActor = _pool.take() as PoolActor
		if actor == null:
			actor = actor_scene.instantiate() as PoolActor
			_created += 1
		else:
			_reused += 1
		_actors.add_child(actor)
		actor.activate(Vector2(70.0 + index * 80.0, 260.0))
	_refresh()

func tint_first() -> void:
	if _actors.get_child_count() > 0:
		(_actors.get_child(0) as PoolActor).tint(Color.RED)

func recycle_all() -> void:
	for child: Node in _actors.get_children():
		var actor: PoolActor = child as PoolActor
		actor.hide()
		_actors.remove_child(actor)
		var result: Error = _pool.recycle(actor)
		if result != OK:
			push_error("Example recycling failed: %s" % error_string(result))
	_refresh()

func clear_pool() -> void:
	_pool.clear()
	_refresh()

func _exit_tree() -> void:
	_pool.close()

func _refresh() -> void:
	_status.text = "Created: %d | Reused: %d | Cached: %d | Leased: %d" % [
		_created, _reused, _pool.cached_count, _pool.leased_count]
