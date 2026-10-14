class_name YinPlacementController
extends Node2D
var game: Node2D
var selected: String = ""
var point := Vector2.ZERO
func snap(at: Vector2) -> Vector2:
	return (at / 32).floor() * 32 + Vector2(16, 16)
func allowed(at: Vector2) -> bool:
	if game.state.zone != "farm" or selected not in ["paper_lamp", "ward_stake"]: return false
	if game.state.container_count("bag", selected) < 1 or at.distance_to(game.player.position) > 80: return false
	if game.world.plot_at(at) >= 0 or not game.world.is_safe_position(at): return false
	var footprint := Rect2(at - Vector2(12, 12), Vector2(24, 24))
	for rect in game.world.obstacles:
		if footprint.intersects(rect): return false
	return not game.state.placements.any(func(p): return p.zone == "farm" and Vector2(p.at[0], p.at[1]).distance_to(at) < 30)
func place(at: Vector2) -> bool:
	var target: Vector2 = snap(at)
	if not allowed(target): return false
	game.state.set_container_count("bag", selected, game.state.container_count("bag", selected) - 1)
	var record: Dictionary = {"id": game.state.next_id, "kind": selected, "at": [target.x, target.y], "zone": "farm"}
	game.state.next_id += 1
	game.state.placements.append(record)
	if selected == "ward_stake": game.state.ward = mini(100, game.state.ward + 5)
	game.world.install_placement(record)
	selected = ""
	return true
func _process(_delta: float) -> void:
	visible = selected != "" and game.modal == null
	if visible:
		point = snap(game.world.get_global_mouse_position())
		queue_redraw()
func _draw() -> void:
	if selected == "": return
	var local_point := to_local(point)
	draw_rect(Rect2(local_point - Vector2(15, 15), Vector2(30, 30)), Color("92ba92") if allowed(point) else Color("c78978"), false, 2)
