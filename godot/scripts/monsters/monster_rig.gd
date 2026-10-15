class_name YinMonsterRig
extends Node2D
var joints: Dictionary={}
var actor: Node2D
func _ready() -> void:
	name="MonsterModel"
	use_parent_material=true
func present(kind: String,pose: Dictionary,missing: Array,clock: float,moving: bool,attack: bool,tint: Color) -> void:
	var active: Array=[]
	for part in YinActorArt.posed_parts(kind,pose,clock,moving,attack):
		var cut: Dictionary=part.pose.duplicate()
		var joint_name: String=cut.joint
		active.append(joint_name)
		if not joints.has(joint_name):
			var joint:=YinRigJoint.new()
			joint.name=joint_name
			add_child(joint)
			joints[joint_name]=joint
		var node: YinRigJoint=joints[joint_name]
		node.visible=part.part not in missing
		# Store a genuine pivot transform on each independently animated joint.
		var pivot: Vector2=cut.get("pivot",Vector2.ZERO)
		var angle_value: float=float(cut.get("rotation",0))
		node.scale=Vector2(-1,1) if cut.flip else Vector2.ONE
		node.position=Vector2(-pivot.x,pivot.y) if cut.flip else pivot
		node.rotation=-angle_value if cut.flip else angle_value
		cut.destination.position-=pivot
		cut.flip=false
		cut.erase("pivot");cut.rotation=0
		node.pose=cut
		node.tint=tint
		node.queue_redraw()
	for key in joints:
		if key not in active:joints[key].visible=false
