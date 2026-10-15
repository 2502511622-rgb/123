class_name YinRigJoint
extends Node2D
var pose: Dictionary={}
var tint:=Color.WHITE
func _ready() -> void:
	use_parent_material=true
func _draw() -> void:
	if not pose.is_empty():YinActorArt.draw_pose(self,pose,tint)
