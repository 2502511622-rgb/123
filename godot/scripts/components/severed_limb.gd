class_name YinSeveredLimb
extends Node2D
var part: String = "arm"
var row: int = 0
var sprite_scale: float = 2.0
var source_density: int = 1
var velocity := Vector2.ZERO
var height: float = 12
var lift: float = 95
var age: float = 0
var source_texture: Texture2D = preload("res://assets/enemies.png")
func _process(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("yintian_game")
	if game != null and game.modal != null: return
	age += delta
	if age >= 9:
		queue_free()
		return
	if age < 0.65:
		position += velocity * delta
		velocity = velocity.move_toward(Vector2.ZERO, delta * 110)
		lift -= delta * 420
		height = maxf(0, height + lift * delta)
		rotation += delta * 8
	else:
		height = 0
	modulate.a = minf(1, 9 - age)
	queue_redraw()
func _draw() -> void:
	var region: Rect2 = {"arm": Rect2(12, row * 24 + 8, 4, 10), "leg": Rect2(8, row * 24 + 18, 8, 6), "head": Rect2(0, row * 24, 16, 8)}[part]
	draw_texture_rect_region(source_texture, Rect2(-region.size * sprite_scale / 2 - Vector2(0, height), region.size * sprite_scale), Rect2(region.position * source_density, region.size * source_density))
