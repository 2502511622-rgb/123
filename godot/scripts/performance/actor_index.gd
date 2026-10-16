class_name YinActorIndex
extends Node
const CELL=128.0
var world: FarmWorld
var units: Array=[]
var cells: Dictionary={}
var age: float=1
func _physics_process(delta: float) -> void:age+=delta
func invalidate() -> void:age=1
func refresh() -> void:
 if age<0.1:return
 age=0;cells.clear();units.clear()
 for group in ["enemies","faction_guards"]:
  for actor in get_tree().get_nodes_in_group(group):
   if actor.is_queued_for_deletion() or actor.get_parent()!=world.actors or actor.record.dead:continue
   units.append(actor)
   var cell=Vector2i((actor.position/CELL).floor())
   if not cells.has(cell):cells[cell]=[]
   cells[cell].append(actor)
func nearby(at: Vector2,radius: float,hostile_only: bool=false) -> Array:
 refresh()
 var result: Array=[]
 if radius>512:
  for actor in units:
   if not is_instance_valid(actor) or actor.is_queued_for_deletion() or actor.record.dead:continue
   if hostile_only and not actor.is_in_group("enemies"):continue
   if at.distance_squared_to(actor.position)<=radius*radius:result.append(actor)
  return result
 # Actors can cross cell boundaries between snapshots; pad the bucket search.
 var lo=Vector2i(((at-Vector2.ONE*(radius+48))/CELL).floor())
 var hi=Vector2i(((at+Vector2.ONE*(radius+48))/CELL).floor())
 for y in range(lo.y,hi.y+1):
  for x in range(lo.x,hi.x+1):
   for actor in cells.get(Vector2i(x,y),[]):
    if not is_instance_valid(actor) or actor.is_queued_for_deletion() or actor.record.dead:continue
    if hostile_only and not actor.is_in_group("enemies"):continue
    if at.distance_squared_to(actor.position)<=radius*radius:result.append(actor)
 return result
