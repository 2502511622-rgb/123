class_name YinCorpse
extends StaticBody2D
var record: Dictionary
var parts: Array=[]
var age: float=0.45
var selected: bool=false
var side: float=1
var modular: YinModularRig
var footprint: CollisionShape2D
var step_time: float=0
var lifetime: float=0 # Zero means permanent; positive values fade and remove the body.
var push_distance: float=0
static func snapshot(enemy: YinEnemy) -> Dictionary:
 var pose: Dictionary=enemy.art_pose()
 var rig_pose: Dictionary={}
 if YinEnemyPack.enabled(enemy) and enemy.model.modular!=null:
  for part in enemy.model.modular.joints:
   var t: Transform2D=enemy.model.modular.joints[part].transform
   rig_pose[part]=[t.origin.x,t.origin.y,t.get_rotation()]
 return {"rig_pose":rig_pose,"modular":YinEnemyPack.enabled(enemy),"key":pose.part_key,"source":[pose.source.position.x,pose.source.position.y,pose.source.size.x,pose.source.size.y],"destination":[pose.destination.position.x,pose.destination.position.y,pose.destination.size.x,pose.destination.size.y],"flip":pose.flip,"gait":float(pose.motion.get("gait",0)),"action":float(pose.motion.get("action",0)),"moving":enemy.velocity.length()>2,"attacking":enemy.art_strike>0,"clock":enemy.art_clock,"missing":enemy.record.get("severed",[]).duplicate(),"human":enemy.record.get("faction","")=="village","face":-1 if enemy.art_facing.x<0 else 1}
static func valid(value: Variant,kind: String) -> bool:
 if not value is Dictionary:return false
 if value.has("modular") and not value.modular is bool:return false
 if value.has("rig_pose"):
  if not value.rig_pose is Dictionary:return false
  for part in value.rig_pose:
   if part not in YinEnemyPack.PARTS or not value.rig_pose[part] is Array or value.rig_pose[part].size()!=3:return false
   for n in value.rig_pose[part]:
    if not (n is int or n is float) or not is_finite(float(n)) or absf(float(n))>4096:return false
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
  if part not in YinEnemyPack.ALLOWED:return false
 return true
func bind(data: Dictionary,falling: bool=false) -> void:
 record=data;position=Vector2(data.at[0],data.at[1]);age=0 if falling else 0.45
 side=-1 if int(data.id)%2==0 else 1
 var pose=YinActorArt.enemy_pose(data.kind,Vector2.LEFT if side<0 else Vector2.RIGHT,0,false,false,data.kind in YinAbilities.BOSSES)
 var death: Dictionary=data.get("death_pose",{})
 var missing: Array=data.get("severed",[])
 var clock=0.0;var moving=false;var attacking=false
 var valid_death=valid(death,data.kind)
 if valid_death:
  pose.part_key=death.key;pose.source=YinActorArt.rect_from(death.source);pose.destination=YinActorArt.rect_from(death.destination);pose.flip=death.flip
  pose.motion={"gait":death.gait,"action":death.action};clock=death.clock;moving=death.moving;attacking=death.attacking;missing=death.missing;side=death.face
 if death.get("human",false):
  parts=[{"part":"body","pose":YinActorArt.npc_pose(int(data.id)%6+1,0,false,false)}]
 else:
  parts=YinActorArt.posed_parts(data.kind,pose,clock,moving,attacking).filter(func(p):return p.part not in missing)
 if valid_death and death.get("modular",false):
  modular=YinModularRig.new();modular.name="ResidualTorso";add_child(modular)
  modular.setup(data.kind);modular.present(data.kind,missing,clock,moving,attacking,side<0,Color("aaa99b"))
  for part in death.get("rig_pose",{}):
   var t: Array=death.rig_pose[part]
   modular.joints[part].transform=Transform2D(t[2],Vector2(t[0],t[1]))
  modular.align_stumps()
  modular.animation.stop();modular.animation.set_process(false)
  parts=[]
  for part in YinEnemyPack.PARTS:
   if modular.joints[part].visible:parts.append({"part":part})
 for piece in parts:
  if piece.has("pose"):piece.pose.rigid=true
 set_process(falling);queue_redraw()
func _ready() -> void:
 add_to_group("remains");add_to_group("corpses")
 collision_layer=8;collision_mask=1|8
 footprint=CollisionShape2D.new();footprint.name="CorpseVolume"
 var capsule=CapsuleShape2D.new();capsule.radius=6;capsule.height=40
 footprint.shape=capsule;footprint.rotation=PI/2;footprint.position=Vector2(side*22,-2);add_child(footprint)
 lifetime=float(record.get("corpse_lifetime",0))
 if lifetime>0:
  var timer=Timer.new();timer.one_shot=true;timer.wait_time=lifetime;add_child(timer);timer.start()
  timer.timeout.connect(fade_out)
 if modular!=null and age<0.45:
  var blood=YinBloodFX.new();blood.emitter=modular;blood.duration=8;add_child(blood)
 update_pose();set_process(age<0.45)
func _process(delta: float) -> void:
 var game=get_tree().get_first_node_in_group("yintian_game")
 if game!=null and game.modal!=null:return
 age=minf(0.45,age+delta);step_time=maxf(0,step_time-delta);update_pose();queue_redraw()
 if age>=0.45 and step_time<=0:
  set_process(false)
  if push_distance>0 and game!=null:game.queue_save();push_distance=0
func update_pose() -> void:
 if modular==null:return
 var fall=1-pow(1-clampf(age/0.45,0,1),3)
 modular.transform=Transform2D(0,Vector2(1,1-0.5*fall-minf(0.07,step_time*0.35)),0,Vector2(0,-7*(1-fall)))*Transform2D(side*1.38*fall,Vector2.ZERO)*Transform2D(0,Vector2(side,1),0,Vector2.ZERO)
 modular.modulate=Color("aaa99b").lerp(Color("ddd3bc"),minf(1,step_time*4))
func push_and_step(direction: Vector2,delta: float) -> void:
 # StaticBody2D is moved deliberately, using a sweep against terrain and other bodies.
 # Player movement itself stays unobstructed, so low remains can also be stepped over.
 var motion=direction.limit_length(1)*delta*26
 if not test_move(global_transform,motion):
  position+=motion;push_distance+=motion.length();record.at=[position.x,position.y]
 step_time=0.18;set_process(true)
func fade_out() -> void:
 collision_layer=0
 var tween=create_tween();tween.tween_property(self,"modulate:a",0.0,2)
 tween.tween_callback(func():
  var game=get_tree().get_first_node_in_group("yintian_game")
  if game!=null:game.state.remains.erase(record);game.queue_save()
  queue_free())
func highlight(value: bool) -> void:
 if selected==value:return
 selected=value;queue_redraw()
func _draw() -> void:
 if parts.is_empty():return
 var progress=clampf(age/0.45,0,1)
 var fall=1-pow(1-progress,3)
 draw_set_transform(Vector2(side*22*fall,2),0,Vector2(1,0.28))
 draw_circle(Vector2.ZERO,18 if record.kind in YinAbilities.BOSSES else 13,Color("18232870"))
 # Rotate the body first, then project onto the ground plane.
 # Scaling before rotation leaves winged and wide-bodied monsters standing tall.
 var projection=Transform2D(0,Vector2(1,1-0.5*fall),0,Vector2(0,-7*(1-fall)))
 draw_set_transform_matrix(projection*Transform2D(side*1.38*fall,Vector2.ZERO))
 var tint=Color("aaa99b") if record.integrity>=60 else Color("817f78")
 if modular==null:
  for piece in parts:YinActorArt.draw_pose(self,piece.pose,tint)
 draw_set_transform(Vector2.ZERO)
 if selected:
  draw_arc(Vector2.ZERO,21,0,TAU,24,Color("dfc78d"),1)
  draw_string(ThemeDB.fallback_font,Vector2(-24,22),"E 处理 · V 炼化",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("edddae"))
