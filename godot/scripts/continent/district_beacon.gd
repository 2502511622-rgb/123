class_name YinDistrictBeacon
extends Node2D
var world: FarmWorld
var place_id: String
var refresh: float=0
func _process(delta: float) -> void:
 refresh+=delta
 if refresh<0.12:return
 refresh=0
 visible=is_instance_valid(world.player) and position.distance_squared_to(world.player.position)<10000
 if visible:queue_redraw()
func _draw() -> void:
 if not is_instance_valid(world.player):return
 var place: Dictionary=YinWorldDistricts.PLACES[place_id]
 var known=world.state.world_echoes.has(place_id)
 draw_circle(Vector2(0,-4),2,Color("7f9b8c") if known else Color("dec68b"))
 if position.distance_to(world.player.position)<56:
  var font=load("res://assets/mossfield-font.ttf")
  draw_string(font,Vector2(-38,13),"E · "+place.name,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("d9ceb4"))
