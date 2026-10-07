extends Node2D

@export var definition: ExampleEntityDefinition
@export var palette: Gradient
var health: int = 0

func _ready() -> void:
	# The scene's mutable palette is copied before any activation modifies it.
	palette = palette.duplicate(true) as Gradient

func initialize(config: Resource) -> Error:
	if not config is ExampleEntityDefinition or (config as ExampleEntityDefinition).max_health <= 0:
		return ERR_INVALID_DATA
	definition = config as ExampleEntityDefinition
	health = definition.max_health
	palette.set_color(0, Color.WHITE)
	show()
	queue_redraw()
	return OK

func update(config: Resource) -> Error:
	return initialize(config)

func damage(amount: int) -> void:
	health = maxi(0, health - amount)
	palette.set_color(0, Color.RED)
	queue_redraw()

func destroy() -> void:
	hide()

func _draw() -> void:
	draw_rect(Rect2(-20, -20, 40, 40), palette.get_color(0))

