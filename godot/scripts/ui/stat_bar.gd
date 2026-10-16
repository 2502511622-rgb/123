class_name YinStatBar
extends Range
var fill_color := Color("81a79a")
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 value_changed.connect(func(_value): queue_redraw())
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO, size), Color("0d1421"))
 var filled: float = floor((size.x - 2) * clampf(value / max_value, 0, 1))
 draw_rect(Rect2(1, 1, filled, size.y - 2), fill_color)
 draw_line(Vector2(1, 1), Vector2(filled, 1), fill_color.lightened(0.18), 1)
 for x in range(24, int(size.x), 24): draw_line(Vector2(x, 1), Vector2(x, size.y - 1), Color("1c253a55"), 1)
