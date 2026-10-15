class_name YinTreasureChest
extends Node2D
var game: Node2D
var chest_id: String
func _ready() -> void:
	add_to_group("treasure_chests")
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	var opened: bool = chest_id in game.state.opened_chests
	draw_texture_rect(preload("res://assets/chest.png"), Rect2(-20, -30, 40, 32), false, Color("8a9383") if opened else Color.WHITE)
	if opened:
		draw_rect(Rect2(-14, -22, 28, 8), Color("283b37"))
	else:
		draw_rect(Rect2(-2, -18, 4, 6), Color("f1cf83"))
		if is_instance_valid(game.player) and position.distance_to(game.player.position) < 60:
			draw_string(ThemeDB.fallback_font, Vector2(-20, -36), "E 宝箱", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f1cf83"))
