extends SceneTree
class Probe extends Node2D:
 var pose: Dictionary
 func _draw():YinActorArt.draw_pose(self,pose)
var checks=0
var failures=0
var game
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","1");OS.set_environment("YINTIAN_SILENT","1");call_deferred("run")
func check(ok: bool,label: String):
 checks+=1;print("FOOTSTEP ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func frames(n=3):
 for i in range(n):await physics_frame
func read_probe(viewport: SubViewport,probe: Probe,phase: float) -> Image:
 probe.pose.gait_phase=phase;probe.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 return viewport.get_texture().get_image()
func foot_bottom(image: Image,x0: int,x1: int) -> int:
 var bottom=-1
 for y in range(112,160):
  for x in range(x0,x1):
   if image.get_pixel(x,y).a>.7:bottom=maxi(bottom,y)
 return bottom
func rendered_feet():
 if DisplayServer.get_name()=="headless":return
 var viewport=SubViewport.new();viewport.size=Vector2i(160,160);viewport.transparent_bg=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var probe=Probe.new();probe.position=Vector2(80,140);probe.scale=Vector2(2,2)
 # Side view has two separately visible soles; a front neutral pose occludes
 # one boot behind the other, so splitting that image in half cannot track feet.
 # Retain the old deformation helper GPU check for historical compatibility.
 # Both live outfits now use new authored pixel poses (test_pixel30.gd).
 var legacy=YinActorArt.atlas().hero_walk_alt[3][0]
 probe.pose=YinActorArt.framed_pose(YinActorArt.HERO_WALK_ALT,legacy,legacy,50)
 probe.pose.gait_phase=0;probe.pose.gait_strength=1.0;probe.pose.gait_row=3;viewport.add_child(probe)
 var split=int(80+(probe.pose.destination.position.x+probe.pose.destination.size.x*.5)*2)
 var left_up=await read_probe(viewport,probe,PI/2)
 var right_up=await read_probe(viewport,probe,PI*1.5)
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
 if folder!="":
  DirAccess.make_dir_recursive_absolute(folder)
  left_up.save_png(folder.path_join("left-up.png"));right_up.save_png(folder.path_join("right-up.png"))
 print("FOOTSTEP GPU split=",split," bottoms ",foot_bottom(left_up,40,split),",",foot_bottom(right_up,40,split)," / ",foot_bottom(left_up,split,120),",",foot_bottom(right_up,split,120))
 check(foot_bottom(right_up,40,split)-foot_bottom(left_up,40,split)>=6,"GPU pixels: left boot visibly clears ground")
 check(foot_bottom(left_up,split,120)-foot_bottom(right_up,split,120)>=6,"GPU pixels: right boot visibly clears ground")
 check(left_up.get_region(Rect2i(0,0,160,100)).get_data()==right_up.get_region(Rect2i(0,0,160,100)).get_data(),"GPU pixels: lifting feet does not translate head or torso")
 viewport.queue_free();await frames()
func run():
 await rendered_feet()
 var leg=YinMonsterArt.joint_pose("bone","leg_right",PI/2,true,Vector3.ZERO)
 var hit_leg=YinMonsterArt.joint_pose("bone","leg_right",PI/2,true,Vector3.ZERO,0)
 var torso=YinMonsterArt.joint_pose("bone","body",PI/2,true,Vector3.ZERO)
 var hit_torso=YinMonsterArt.joint_pose("bone","body",PI/2,true,Vector3.ZERO,0)
 check((hit_leg.origin-leg.origin).is_equal_approx(hit_torso.origin-torso.origin),"hit recoil keeps the raised leg attached to the torso")
 for row in range(4):
  var left=YinFootstep.foot_offset(PI/2,0,row)
  var right=YinFootstep.foot_offset(PI/2,1,row)
  check(left.y< -4 and absf(right.y)<.01,"direction %d: left boot lifts while right is grounded"%row)
  left=YinFootstep.foot_offset(PI*1.5,0,row);right=YinFootstep.foot_offset(PI*1.5,1,row)
  check(right.y< -4 and absf(left.y)<.01,"direction %d: next half-cycle lifts the opposite boot"%row)
  check(YinFootstep.displacement(Vector2(.25,.5),PI/2,1,row,Vector2(0,-1))==Vector2.ZERO,"direction %d: feet do not translate upper body"%row)
  check(YinFootstep.displacement(Vector2(.25,1),PI/2,0,row,Vector2.ZERO)==Vector2.ZERO,"direction %d: no deformation when stopped"%row)
  check(YinFootstep.displacement(Vector2(.25,1),.4,1,row,Vector2.ZERO).distance_to(YinFootstep.displacement(Vector2(.25,1),.401,1,row,Vector2.ZERO))<.02,"direction %d: continuous foot trajectory"%row)
 for kind in YinMonsterArt.metadata():
  for part in ["leg_left","leg_right"]:
   var rest=YinMonsterArt.joint_pose(kind,part,0,false,Vector3.ZERO)
   var lift=YinMonsterArt.joint_pose(kind,part,PI/2 if part.ends_with("right") else PI*1.5,true,Vector3.ZERO)
   check(lift.origin.distance_to(rest.origin)<.001,kind+" "+part+" hip remains attached")
   var toe=Vector2(0,17)
   check((lift*toe).y<(rest*toe).y-3,kind+" "+part+" complete foot lifts visibly")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(6);game.close_modal()
 game.state.intro_seen=true
 # Find a genuinely unobstructed corridor; the old (260,380) fixture meets a tree.
 var corridor=Vector2.ZERO
 for y in range(300,580,24):
  for x in range(96,650,24):
   var at=Vector2(x,y)
   if game.world.clear_body_path(at,at+Vector2(130,0),Vector2(8,6)) and game.world.is_safe_position(at):
    corridor=at;break
  if corridor!=Vector2.ZERO:break
 check(corridor!=Vector2.ZERO,"fixture finds a clear walking corridor")
 game.player.position=corridor
 for enemy in get_nodes_in_group("enemies"):enemy.set_physics_process(false)
 var start: Vector2=game.player.position
 Input.action_press("move_right");await frames(20)
 check(game.player.position.x>start.x+20,"normal held input moves player")
 check(game.player.art_pose().get("gait_strength",0)>.9,"actual player renderer enables foot movement")
 var phase=game.player.animation_time
 await frames(5)
 check(game.player.animation_time>phase,"actual displacement advances walking phase")
 Input.action_release("move_right");await frames(15)
 phase=game.player.animation_time
 check(game.player.gait_blend<.01,"feet settle after releasing movement")
 await frames(10)
 check(game.player.animation_time==phase,"idle does not march in place")
 var wall=StaticBody2D.new();wall.position=game.player.position+Vector2(20,-4);wall.collision_layer=1
 var shape=CollisionShape2D.new();shape.shape=RectangleShape2D.new();shape.shape.size=Vector2(8,120);wall.add_child(shape);game.world.add_child(wall)
 await frames();Input.action_press("move_right");await frames(30)
 phase=game.player.animation_time;await frames(12)
 check(absf(game.player.animation_time-phase)<.001 and game.player.gait_blend<.01,"pushing into wall does not skate or step")
 Input.action_release("move_right");wall.queue_free();await frames()
 Input.action_press("move_left");await frames(12);phase=game.player.animation_time;game.player.hit_pause=.2
 await frames(5)
 check(game.player.animation_time==phase,"hit stop freezes feet with the body")
 game.player.hit_pause=0;game.player.attack_time=.2
 check(not game.player.art_pose().has("gait_phase"),"attack uses its authored pose without walking deformation")
 game.player.attack_time=0;game.player.dodge_time=.2
 check(not game.player.art_pose().has("gait_phase"),"dodge does not play a walking step")
 Input.action_release("move_left")
 var continent_before=game.state.continent_ready;game.state.continent_ready=true
 var enemy=YinEnemy.new();enemy.game=game;enemy.record=game.state.enemies[0].duplicate(true)
 enemy.record.kind="bone";enemy.record.severed=[];enemy.position=game.player.position+Vector2(100,0)
 game.world.actors.add_child(enemy);enemy.set_physics_process(false)
 var walking=enemy.art_pose();walking.motion={"gait":PI/2};walking.flip=false
 enemy.model.present("bone",walking,[],0,true,false,Color.WHITE)
 var leg_transform: Transform2D=enemy.model.modular.joints.leg_right.transform
 var death=JSON.parse_string(JSON.stringify(YinCorpse.snapshot(enemy)))
 game.state.continent_ready=continent_before
 check(YinCorpse.valid(death,"bone"),"walking corpse scale survives JSON validation")
 var record=enemy.record.duplicate(true);record.at=[enemy.position.x,enemy.position.y];record.dead=true;record.death_pose=death
 var corpse=YinCorpse.new();corpse.bind(record);game.world.actors.add_child(corpse)
 check(corpse.modular.joints.leg_right.transform.is_equal_approx(leg_transform),"death and reload preserve the bent leg without popping straight")
 var legacy=death.duplicate(true);legacy.erase("rig_scale")
 check(YinCorpse.valid(legacy,"bone"),"existing corpses without scale metadata remain valid")
 var bad=death.duplicate(true);bad.rig_scale.leg_right=[1,NAN]
 check(not YinCorpse.valid(bad,"bone"),"invalid saved leg scale is rejected")
 print("FOOTSTEP RESULT ",checks," checks ",failures," failures")
 game.queue_free();await frames();quit(1 if failures else 0)
