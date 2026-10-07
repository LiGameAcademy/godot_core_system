class_name PoolActor
extends Node2D

@export var palette: Gradient
var _private_palette: Gradient

func _ready() -> void:
	_private_palette = palette.duplicate() as Gradient

func activate(at: Vector2) -> void:
	position = at
	_private_palette.set_color(0, palette.get_color(0))
	show()
	queue_redraw()

func tint(color: Color) -> void:
	_private_palette.set_color(0, color)
	queue_redraw()

func current_color() -> Color:
	return _private_palette.get_color(0)

func _draw() -> void:
	if _private_palette != null:
		draw_circle(Vector2.ZERO, 24.0, current_color())
