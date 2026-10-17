class_name YinPropCulling30
extends Node
# Visibility only. Static physics bodies, navigation, interactions and lights
# keep their original identity and collision state across every camera move.
var world: FarmWorld
var active: Array=[]
var last_view=Rect2()
var revision=-1
func _ready():
 for bucket in world.prop_chunks30.values():
  for body in bucket:
   if is_instance_valid(body):body.visible=false
func _process(_delta):
 var view=world.screen_bounds()
 if revision==world.environment_revision and last_view.size==view.size and last_view.position.distance_to(view.position)<32:return
 last_view=view;revision=world.environment_revision
 var next=world.visible_props30()
 for body in active:
  if is_instance_valid(body) and body not in next:body.visible=false
 for body in next:body.visible=true
 active=next
