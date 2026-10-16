extends SceneTree
var game
var checks=0
var failures=0
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func check(ok: bool,label: String):
 checks+=1;print("RESET28 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func frames(n=3):
 for i in range(n):await physics_frame
func run():
 for kind in YinMonsterArt.metadata():
  var meta=YinMonsterArt.metadata()[kind];var image=YinMonsterArt.texture(kind).get_image()
  check(meta.get("independent_anatomy",false),kind+" is sourced from six independent anatomical assets")
  var torso=image.get_region(YinMonsterArt.region(0));var arms=[]
  for part in [2,3,4,5]:
   var limb=image.get_region(YinMonsterArt.region(part));var bounds=limb.get_used_rect()
   check(bounds.size.x>=3 and bounds.size.y>=5 and bounds.size.x<40 and bounds.size.y<40,kind+" complete isolated limb "+str(part))
  check(torso.get_used_rect().size.x>=10 and torso.get_used_rect().size.y>=8,kind+" torso remains whole without a limb mask")
 var a=YinMonsterArt.walk_key(.31);var b=YinMonsterArt.walk_key(.311)
 check(a.distance_to(b)<.02,"walk interpolates smoothly between eight key positions")
 check(YinEnemyPack.movement_factor("bone",["leg_left","leg_right"])<.3,"loss of both legs causes slow crawling")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(8);game.close_modal()
 for actor in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):actor.set_physics_process(false)
 var source=YinMonsterArt.texture("brute").get_image().get_region(YinMonsterArt.region(0)).get_data()
 var rig=YinModularRig.new();game.world.actors.add_child(rig);rig.setup("brute");rig.present("brute",[],0,false,false,false,Color.WHITE)
 var origin=rig.joints.arm_left.global_transform
 var limb=rig.detach("arm_left",game.world.feedback,Vector2.RIGHT)
 rig.present("brute",["arm_left"],.12,true,true,false,Color.WHITE)
 check(limb is RigidBody2D and limb.source_region==YinMonsterArt.region(2),"cut creates a complete independently authored arm as a physical entity")
 check(limb.visual.global_position.distance_to(origin.origin)<.01,"arm starts at the actual shoulder transform")
 check(source==rig.joints.body.get_node("Sprite").texture.get_image().get_region(YinMonsterArt.region(0)).get_data(),"dismemberment never erases or repartitions the torso image")
 check(rig.stumps.arm_left.visible and rig.joints.arm_right.visible,"cut cap covers shoulder and opposite arm survives")
 var id="grave_swords";game.state.world_echoes[id]=true
 var before=game.state.equipment.size();var message=YinExploration28.claim(game.state,id)
 check(game.state.equipment.size()==before+1 and game.state.equipment.back().tier==2 and game.state.equipment.back().enchantment=="freeze","side route grants a real tier-two enchanted weapon")
 YinExploration28.claim(game.state,id)
 check(game.state.equipment.size()==before+1,"exploration reward cannot be duplicated")
 check(FarmState.new().restore(game.state.snapshot()),"new anatomy, exploration rewards and territory state round trip")
 var legacy=game.state.snapshot()
 for key in ["territories","exploration_rewards","visited_posts"]:legacy.erase(key)
 check(FarmState.new().restore(legacy),"existing v0.27 saves migrate to new world state")
 print("RESET28 RESULT ",checks," checks ",failures," failures")
 game.queue_free();await frames();quit(1 if failures else 0)
