extends SceneTree
var checks=0
var failures=0
var game
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("MONSTER27 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 var hashes={}
 check(YinMonsterArt.metadata().size()==YinBalance.MONSTERS.size(),"every enemy kind has an independent authored atlas")
 for kind in YinMonsterArt.metadata():
  var image=YinMonsterArt.texture(kind).get_image()
  var hash_value=hash(image.get_data());check(not hashes.has(hash_value),"unique appearance "+kind);hashes[hash_value]=true
  var signatures={}
  for frame in range(4):
   var combined=Image.create(96,96,false,Image.FORMAT_RGBA8);var overlap=false;var count=0
   for part in range(6):
    var cut=image.get_region(YinMonsterArt.region(frame*6+part))
    for y in range(96):
     for x in range(96):
      var pixel=cut.get_pixel(x,y)
      if pixel.a==0:continue
      if combined.get_pixel(x,y).a>0:overlap=true
      combined.set_pixel(x,y,pixel);count+=1
   check(not overlap and count>150,"no duplicate pixels or opaque rectangular background "+kind+" frame "+str(frame))
   signatures[hash(combined.get_data())]=true
  check(signatures.size()==4,"four genuinely different source poses "+kind)
 check(YinEnemyPack.anatomical("ippon_datara").count("leg_left")==0 and YinEnemyPack.anatomical("wraith").is_empty(),"lore-specific one-legged and spectral anatomy")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(6);game.close_modal()
 for e in get_nodes_in_group("enemies"):e.set_physics_process(false)
 game.player.position=Vector2(4896,1056);game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll();await frames()
 var e=YinEnemy.new();e.game=game;e.record=game.state.spawn_record("bone","island",Vector2.ZERO,1);e.record.at=[4896,1120];e.position=Vector2(4896,1120);e.record.max_hp=100;e.record.hp=100;e.record.armor=0
 game.world.actors.add_child(e);e.add_to_group("enemies");e.set_physics_process(false)
 e.art_clock=.26;e.velocity=Vector2.LEFT*29;e.model.present("bone",e.art_pose(),[],e.art_clock,true,false,Color.WHITE)
 var joint=e.model.modular.joints.arm_left.global_transform
 e.record.hp=64;e.update_dismemberment()
 var limbs=get_nodes_in_group("severed_limbs")
 check(limbs.size()==1 and limbs[0] is RigidBody2D,"real independent physical limb entity")
 check(limbs[0].visual.global_position.distance_to(joint.origin)<.01,"current authored action and detached limb align exactly")
 check(e.model.modular.stumps.arm_left.visible and not e.model.modular.joints.arm_left.visible,"removed child and enabled cut overlay")
 e.modular_hit_feedback(Vector2.RIGHT)
 check(e.model.modular.animation.is_playing() and Engine.time_scale<1,"preserved AnimationPlayer recoil and hit stop")
 await frames(3)
 check(e.model.modular.joints.arm_left.get_node_or_null("Sprite")==null,"severed child sprite actually destroyed")
 e.record.hp=0;e.record.death_pose=YinCorpse.snapshot(e)
 var remains=game.state.leave_remains(e.record,e.position);e.record.dead=true;game.spawn_remains_visuals(remains.id);e.queue_free();await frames()
 var corpses=get_nodes_in_group("corpses")
 check(corpses.any(func(c):return c is StaticBody2D and c.modular!=null and not c.modular.joints.arm_left.visible),"new static corpse preserves missing limb and new artwork")
 check(FarmState.new().restore(game.state.snapshot()),"new death snapshot is valid and survives save")
 game.queue_free();await frames()
 print("MONSTER27 RESULT ",checks," checks ",failures," failures");quit(1 if failures else 0)
