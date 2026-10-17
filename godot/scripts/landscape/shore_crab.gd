class_name YinShoreCrab29
extends Node2D
# Ambient tidal crabs: local scuttling, not a new combat/loot species.
var world: FarmWorld
var home: Vector2
var clock=0.0
var moving=false
func _ready():home=position;scale=Vector2(1.4,1.4);add_to_group("shore_crabs29")
func _process(delta):
 if not is_instance_valid(world.player) or position.distance_squared_to(world.player.position)>700*700:return
 var game=get_tree().get_first_node_in_group("yintian_game")
 if game!=null and game.modal!=null:return
 clock+=delta
 var away=world.player.position.direction_to(position)
 var scared=world.player.position.distance_to(position)<70
 var direction=away if scared else Vector2(sin(clock*.45+home.x),cos(clock*.37+home.y))*.4
 var next=position+direction*delta*(23 if scared else 7)
 moving=scared or sin(clock)>.2
 if moving and next.distance_to(home)<52 and world.is_safe_position(next):position=next
 queue_redraw()
func _draw():
 for side in [-1,1]:
  for i in range(3):
   var step=sin(clock*14+i*PI*.7)*.7 if moving else 0.0
   draw_line(Vector2(side*2,i-1),Vector2(side*(4+step),i*2-2),Color("594d42"),1)
  draw_line(Vector2(side*2,-1),Vector2(side*4,-4),Color("735743"),1)
  draw_rect(Rect2(Vector2(side*4-1,-5),Vector2(2,2)),Color("87644b"))
 draw_rect(Rect2(-3,-2,6,4),Color("645c4f"));draw_line(Vector2(-2,-2),Vector2(2,-2),Color("8c8067"),1)
