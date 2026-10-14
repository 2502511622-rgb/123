class_name YinHurtbox
extends Area2D
var actor: CharacterBody2D
func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	monitoring = false
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(18, 30)
	shape.position.y = -15
	shape.shape = box
	add_child(shape)
