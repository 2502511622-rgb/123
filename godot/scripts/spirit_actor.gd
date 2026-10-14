extends Node2D
var game: Node2D
var record: Dictionary
var cooldown: float = 0
var time: float = 0
const TEXTURE = preload("res://assets/spirits.png")
func _process(delta: float) -> void:
	if game.modal != null: return
	time += delta
	cooldown = maxf(0, cooldown - delta)
	var target: Vector2 = game.player.position + Vector2(-24 - int(record.id) % 3 * 18, 22)
	if game.state.zone == "farm" and game.state.order == "follow" and record.job in ["water", "dig", "clean"] and not game.has_live_boss():
		target = game.world.plot_center((int(time / 6) + int(record.id) * 7) % 48)
	if game.state.order == "guard":
		target = Vector2(180 + int(record.id) % 3 * 28, 275) if game.state.zone == "farm" else Vector2(180, 525)
	position = position.move_toward(target, delta * 70)
	var enemy: YinEnemy = game.nearest_enemy(position, 110 if game.state.order == "focus" else 60)
	if enemy != null and cooldown <= 0:
		enemy.receive_hit(9 + int(record.affinity / 25) + (5 if record.kind == "child" and record.branch == "shadow" else 0), "spirit")
		game.world.effect(enemy.position, Color("91aaa8"))
		cooldown = 1.8
	queue_redraw()
func _draw() -> void:
	var row: int = {"water": 0, "bone": 1, "child": 2}.get(record.kind, 2)
	draw_rect(Rect2(-9, -2, 18, 4), Color(0.1, 0.15, 0.2, 0.25))
	draw_texture_rect_region(TEXTURE, Rect2(-16, -40 + sin(time * 2) * 1.5, 32, 40), Rect2(0, row * 20, 16, 20), Color(1, 1, 1, 0.85))
