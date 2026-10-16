class_name YinMonsterRig
extends Node2D
var joints: Dictionary={}
var actor: Node2D
var modular: YinModularRig
func _ready() -> void:
	name="MonsterModel"
	use_parent_material=true
func present(kind: String,pose: Dictionary,missing: Array,clock: float,moving: bool,attack: bool,tint: Color) -> void:
	if modular==null:
		modular=YinModularRig.new();add_child(modular);modular.setup(kind)
		var bleeding=YinBloodFX.new();bleeding.emitter=modular;add_child(bleeding)
	var gait_clock: float=float(pose.get("motion",{}).get("gait",clock*10))/10 if moving else clock
	var phase: String=pose.get("motion",{}).get("state","")
	modular.position=Vector2(-float(pose.get("motion",{}).get("action",0))*2,0) if phase=="anticipation" else Vector2.ZERO
	modular.present(kind,missing,gait_clock,moving,attack and phase!="anticipation",pose.flip,tint)
	joints=modular.joints
