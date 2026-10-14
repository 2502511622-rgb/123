extends Control
var state: FarmState
var time: float = 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	time += delta
	queue_redraw()
func _draw() -> void:
	if state == null:
		return
	var darkness: float = clampf((state.minutes - 1020) / 300, 0, 0.48)
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Color(0.13, 0.18, 0.31, darkness))
	if state.weather == "rain":
		draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Color(0.3, 0.4, 0.5, 0.13))
		for i in range(65):
			var x: float = fposmod(i * 97 - time * 45, 640)
			var y: float = fposmod(i * 53 + time * 145, 360)
			draw_line(Vector2(x, y), Vector2(x - 3, y + 7), Color(0.73, 0.85, 0.90, 0.4), 1)
