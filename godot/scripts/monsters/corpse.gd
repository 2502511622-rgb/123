class_name YinCorpse
extends Node2D
var record: Dictionary
var parts: Array=[]
var age: float=0.45
var selected: bool=false
var side: float=1
static func snapshot(enemy: YinEnemy) -> Dictionary:
 var pose: Dictionary=enemy.art_pose()
 return {"key":pose.part_key,"source":[pose.source.position.x,pose.source.position.y,pose.source.size.x,pose.source.size.y],"destination":[pose.destination.position.x,pose.destination.position.y,pose.destination.size.x,pose.destination.size.y],"flip":pose.flip,"gait":float(pose.motion.get("gait",0)),"action":float(pose.motion.get("action",0)),"moving":enemy.velocity.length()>2,"attacking":enemy.art_strike>0,"clock":enemy.art_clock,"missing":enemy.record.get("severed",[]).duplicate(),"human":enemy.record.get("faction","")=="village","face":-1 if enemy.art_facing.x<0 else 1}
static func valid(value: Variant,kind: String) -> bool:
 if not value is Dictionary:return false
 if value.get("key") not in YinActorArt.part_index():return false
 if value.key!=kind and not (kind=="daitengu" and value.key.begins_with("daitengu:")):return false
 for key in ["source","destination"]:
  if not value.get(key) is Array or value[key].size()!=4:return false
  for n in value[key]:
   if not (n is float or n is int) or not is_finite(float(n)) or absf(float(n))>4096:return false
  if value[key][2]<=0 or value[key][3]<=0:return false
 for key in ["clock","gait","action"]:
  var n=value.get(key)
  if not (n is float or n is int) or not is_finite(float(n)) or absf(float(n))>100000000:return false
 for key in ["flip","moving","attacking","human"]:
  if not value.get(key) is bool:return false
 var facing_value=value.get("face")
 if not (facing_value is int or facing_value is float) or (facing_value!=-1.0 and facing_value!=1.0) or not value.get("missing") is Array:return false
 for part in value.missing:
  if part not in ["head","arm","leg"]:return false
 return true
func bind(data: Dictionary,falling: bool=false) -> void:
 record=data;position=Vector2(data.at[0],data.at[1]);age=0 if falling else 0.45
 side=-1 if int(data.id)%2==0 else 1
 var pose=YinActorArt.enemy_pose(data.kind,Vector2.LEFT if side<0 else Vector2.RIGHT,0,false,false,data.kind in YinAbilities.BOSSES)
 var death: Dictionary=data.get("death_pose",{})
 var missing: Array=data.get("severed",[])
 var clock=0.0;var moving=false;var attacking=false
 if valid(death,data.kind):
  pose.part_key=death.key;pose.source=YinActorArt.rect_from(death.source);pose.destination=YinActorArt.rect_from(death.destination);pose.flip=death.flip
  pose.motion={"gait":death.gait,"action":death.action};clock=death.clock;moving=death.moving;attacking=death.attacking;missing=death.missing;side=death.face
 if death.get("human",false):
  parts=[{"part":"body","pose":YinActorArt.npc_pose(int(data.id)%6+1,0,false,false)}]
 else:
  parts=YinActorArt.posed_parts(data.kind,pose,clock,moving,attacking).filter(func(p):return p.part not in missing)
 for piece in parts:piece.pose.rigid=true
 set_process(falling);queue_redraw()
func _ready() -> void:
 add_to_group("remains");set_process(age<0.45)
func _process(delta: float) -> void:
 var game=get_tree().get_first_node_in_group("yintian_game")
 if game!=null and game.modal!=null:return
 age=minf(0.45,age+delta);queue_redraw()
 if age>=0.45:set_process(false)
func highlight(value: bool) -> void:
 if selected==value:return
 selected=value;queue_redraw()
func _draw() -> void:
 if parts.is_empty():return
 var progress=clampf(age/0.45,0,1)
 var fall=1-pow(1-progress,3)
 draw_set_transform(Vector2(0,2),0,Vector2(1,0.28))
 draw_circle(Vector2.ZERO,18 if record.kind in YinAbilities.BOSSES else 13,Color("18232870"))
 # Rotate the body first, then project onto the ground plane.
 # Scaling before rotation leaves winged and wide-bodied monsters standing tall.
 var projection=Transform2D(0,Vector2(1,1-0.5*fall),0,Vector2(0,-7*(1-fall)))
 draw_set_transform_matrix(projection*Transform2D(side*1.38*fall,Vector2.ZERO))
 var tint=Color("aaa99b") if record.integrity>=60 else Color("817f78")
 for piece in parts:YinActorArt.draw_pose(self,piece.pose,tint)
 draw_set_transform(Vector2.ZERO)
 if selected:
  draw_arc(Vector2.ZERO,21,0,TAU,24,Color("dfc78d"),1)
  draw_string(ThemeDB.fallback_font,Vector2(-24,22),"E 处理 · V 炼化",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("edddae"))
