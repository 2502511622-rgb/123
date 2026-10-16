class_name YinTrailGuide
extends Node2D
var world: FarmWorld
var route: PackedVector2Array=[]
var countdown: float=0
var clock: float=0
func _process(delta: float) -> void:
	if not is_instance_valid(world.player) or world.player.frozen:return
	clock+=delta;countdown-=delta
	if countdown<=0:
		countdown=0.8;route.clear()
		var first: Dictionary=YinFirstJourney.guide(world.state)
		if not first.is_empty() and first.zone==world.state.zone:
			route=world.path_to(world.player.position,first.at)
	queue_redraw()
func _draw() -> void:
	var shown: int=0
	for i in range(2,route.size(),2):
		var distance_value: float=route[i].distance_to(world.player.position)
		if distance_value<22:continue
		if distance_value>105 or shown>=4:break
		draw_circle(route[i],1.7,Color(0.92,0.78,0.48,0.45+sin(clock*3-shown)*0.12))
		shown+=1
