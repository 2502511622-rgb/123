class_name YinAllyHurtbox
extends Area2D
var actor: Node2D
func _ready() -> void:
	collision_layer = 32
	collision_mask = 0
	monitoring = false
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(16, 26)
	shape.position.y = -10
	shape.shape = box
	add_child(shape)
