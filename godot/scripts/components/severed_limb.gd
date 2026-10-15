class_name YinSeveredLimb
extends Node2D
var source_region := Rect2()
var draw_size := Vector2.ZERO
var flip_h: bool = false
var part: String = "arm"
var velocity := Vector2.ZERO
var height: float = 12
var lift: float = 95
var age: float = 0
var source_texture: Texture2D = YinActorArt.ROSTER
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
	if not source_region.has_area(): return
	var destination := Rect2(-draw_size / 2 - Vector2(0, height), draw_size)
	if flip_h:
		destination.position.x = destination.end.x
		destination.size.x = -destination.size.x
	draw_texture_rect_region(source_texture, destination, source_region)
