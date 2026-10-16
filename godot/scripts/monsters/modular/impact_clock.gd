class_name YinImpactClock
extends Node
## Real time expiry prevents slow motion extending itself or leaving the game slow.
var deadline: int=0
var previous: float=1
static func pulse(tree: SceneTree) -> void:
 var clock=tree.get_first_node_in_group("impact_clock")
 if clock==null:
  clock=YinImpactClock.new();tree.root.add_child(clock);clock.add_to_group("impact_clock")
 if clock.deadline==0:clock.previous=Engine.time_scale
 clock.deadline=Time.get_ticks_usec()+45000;Engine.time_scale=minf(clock.previous,0.4)
func _process(_delta: float) -> void:
 if deadline>0 and Time.get_ticks_usec()>=deadline:
  Engine.time_scale=previous;deadline=0;queue_free()
func _exit_tree() -> void:
 if deadline>0:Engine.time_scale=previous
