class_name YinMinimap
extends Control
var game: Node2D
var expanded: bool = false
const NAMES = {"village": "青槐村", "farm": "义庄田园", "graveyard": "乱葬坡", "forest": "后山铳林", "sunken": "沉水村", "theatre": "废戏台", "hall": "义庄", "shop": "杂货铺"}
func _process(_delta: float) -> void: queue_redraw()
func point(at: Vector2) -> Vector2: return Vector2(5, 17) + at / game.world.level_size * (size - Vector2(10, 23))
func _draw() -> void:
	if not is_instance_valid(game.world): return
	draw_rect(Rect2(Vector2.ZERO, size), Color("182c2de8"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("758b75"), false, 1)
	draw_string(ThemeDB.fallback_font, Vector2(5, 12), NAMES.get(game.state.zone, game.state.zone), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d3d0b0"))
	for rect in game.world.obstacles:
		draw_rect(Rect2(point(rect.position), rect.size / game.world.level_size * (size - Vector2(10, 23))), Color("52664f"))
	for gate in gates():
		draw_rect(Rect2(point(gate) - Vector2(2, 2), Vector2(4, 4)), Color("e9c47b"))
	for enemy in game.get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_queued_for_deletion(): draw_rect(Rect2(point(enemy.position) - Vector2.ONE, Vector2(2, 2)), Color("d8776b"))
	for spirit in game.get_tree().get_nodes_in_group("companions"):
		if not spirit.is_queued_for_deletion(): draw_rect(Rect2(point(spirit.position) - Vector2.ONE, Vector2(2, 2)), Color("82bbc3"))
	for villager in game.get_tree().get_nodes_in_group("villagers"):
		if not villager.is_queued_for_deletion(): draw_rect(Rect2(point(villager.position) - Vector2.ONE, Vector2(2, 2)), Color("d5b784"))
	draw_rect(Rect2(point(game.player.position) - Vector2(2, 2), Vector2(4, 4)), Color("fff1c1"))
func gates() -> Array:
	match game.state.zone:
		"village": return [Vector2(155, 820)]
		"forest": return [Vector2(155, 1140), Vector2(1760, 250), Vector2(1760, 1050)]
		"sunken", "theatre": return [Vector2(155, 820)]
		"graveyard": return [Vector2(155, 547), Vector2(850, 530)]
		"farm": return [Vector2(160, 209), Vector2(784, 225), Vector2(810, 538), Vector2(900, 350)]
	return [Vector2(480, 461)]
