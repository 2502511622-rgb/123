class_name YinPixelBurst
extends Node2D
var tint := Color.WHITE
var age: float = 0
func _process(delta: float) -> void:
 age += delta
 if age >= 0.4: queue_free(); return
 queue_redraw()
func _draw() -> void:
 var color := tint
 color.a = 1 - age / 0.4
 for i in range(8):
  var offset := Vector2.from_angle(i * TAU / 8) * (4 + age * 52)
  draw_rect(Rect2(offset.round(), Vector2(2, 2)), color)
