extends Node2D
const TEXTURE = preload("res://assets/chicken.png")
var phase: float = 0
var origin := Vector2.ZERO
var time: float = 0
func _ready() -> void:
	origin = position
func _process(delta: float) -> void:
	time += delta
	position = origin + Vector2(sin(time * 0.3 + phase) * 20, cos(time * 0.21 + phase) * 12)
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(-9, -2, 18, 4), Color(0.2, 0.3, 0.2, 0.15))
	draw_texture_rect_region(TEXTURE, Rect2(-16, -28, 32, 32), Rect2(int(time * 2 + phase) % 2 * 16, 0, 16, 16))
