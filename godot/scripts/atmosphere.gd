extends Control
var state: FarmState
var game: Node2D
var time: float = 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	time += delta
	queue_redraw()
func _draw() -> void:
	if state == null:
		return
	var darkness: float = night_alpha()
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Color(0.09, 0.15, 0.28, darkness))
	if darkness > 0.2 and is_instance_valid(game) and state.zone == "farm":
		var lights: Array = [Vector2(190, 190), Vector2(214, 406), Vector2(600, 450)]
		for placed in state.placements:
			if placed.kind == "paper_lamp" and placed.zone == state.zone: lights.append(Vector2(placed.at[0], placed.at[1]) - Vector2(0, 28))
		for at in lights:
			var screen: Vector2 = game.world.get_global_transform_with_canvas() * at
			draw_circle(screen, 28, Color(0.80, 0.50, 0.33, 0.12))
	if state.weather == "rain":
		draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Color(0.3, 0.4, 0.5, 0.13))
		for i in range(65):
			var x: float = fposmod(i * 97 - time * 45, 640)
			var y: float = fposmod(i * 53 + time * 145, 360)
			draw_line(Vector2(x, y), Vector2(x - 3, y + 7), Color(0.73, 0.85, 0.90, 0.4), 1)

func night_alpha() -> float:
	if state == null or state.zone in ["hall", "shop"]: return 0
	var alpha: float = clampf((state.minutes - 1020) / 300, 0, 0.59)
	return maxf(0.17, alpha) if state.zone == "graveyard" else alpha
