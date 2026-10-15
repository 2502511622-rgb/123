class_name YinHurtbox
extends Area2D
var actor: CharacterBody2D
func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	monitoring = false
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	var body: Dictionary=YinBodyProfile.spec(actor.record.kind)
	box.size=Vector2(body.size.x+4,body.height*0.62)
	shape.position.y = -box.size.y*0.5
	shape.shape = box
	add_child(shape)
