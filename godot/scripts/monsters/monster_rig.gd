class_name YinMonsterRig
extends Node2D
var joints: Dictionary={}
var actor: Node2D
var modular: YinModularRig
var target_stance: float=0
func _ready() -> void:
	name="MonsterModel"
	use_parent_material=true
	if actor!=null and actor.get("record")!=null:
		target_stance=20 if YinEnemyPack.movement_factor(actor.record.get("kind","bone"),actor.record.get("severed",[]))<.3 else 0
		position.y=target_stance
func present(kind: String,pose: Dictionary,missing: Array,clock: float,moving: bool,attack: bool,tint: Color) -> void:
	if modular==null:
		modular=YinModularRig.new();add_child(modular);modular.setup(kind)
		var bleeding=YinBloodFX.new();bleeding.emitter=modular;add_child(bleeding)
	var gait_clock: float=float(pose.get("motion",{}).get("gait",clock*10))/10 if moving else clock
	target_stance=20 if YinEnemyPack.movement_factor(kind,missing)<.3 else 0
	var aim: Vector2=pose.get("aim",Vector2.RIGHT)
	modular.aim_angle=atan2(aim.y,absf(aim.x))
	if pose.get("motion",{}).get("state","") not in ["contact","frozen","stagger"]:
		modular.action_progress=YinMonsterArt.action_for(pose.get("motion",{}),attack)
	modular.present(kind,missing,gait_clock,moving,attack,pose.flip,tint)
	joints=modular.joints

func _process(delta: float) -> void:
	if not is_visible_in_tree():return
	var game=get_tree().get_first_node_in_group("yintian_game")
	if game!=null and game.modal!=null:return
	if actor!=null:
		for key in ["hit_stop","freeze_lock"]:
			var remaining=actor.get(key)
			if remaining!=null and remaining>0:return
	position.y=move_toward(position.y,target_stance,delta*65)
