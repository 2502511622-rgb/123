class_name YinInteractionBeacon
extends Node2D
var world: FarmWorld
var point: Dictionary
var clock: float=0
func _process(delta: float) -> void:
	if not is_instance_valid(world.player):return
	if world.player.frozen:return
	clock+=delta
	visible=world.player.position.distance_to(position)<70
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(world.player) or not world.can_interact(point.at,point.range):return
	draw_set_transform(Vector2(0,-18-sin(clock*3)*1.5))
	draw_colored_polygon(PackedVector2Array([Vector2(-3,0),Vector2(0,-4),Vector2(3,0),Vector2(0,4)]),Color("dfc995"))
	draw_set_transform(Vector2.ZERO)
