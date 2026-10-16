extends SceneTree
var game
var checks=0
var failures=0
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func check(ok: bool,label_value: String):
 checks+=1;print("MODULAR ","PASS " if ok else "FAIL ",label_value)
 if not ok:failures+=1
func frames(n: int=3):
 for i in range(n):await physics_frame
func capture(label_value: String):
 if DisplayServer.get_name()=="headless" or OS.get_environment("YINTIAN_CAPTURE_DIR")=="":return
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
 await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(folder.path_join(label_value+".png"))==OK,"capture "+label_value)
func run():
 for pack in YinEnemyPack.IDS:
  var folder="res://assets/enemy_packs/"+pack+"/"
  var manifest=JSON.parse_string(FileAccess.get_file_as_string(folder+"manifest.json"))
  var atlas=load(folder+"atlas.png").get_image()
  var allowed: Dictionary={}
  for hex in YinEnemyPack.PALETTE:allowed[Color(hex).to_rgba32()]=true
  var palette_ok=true
  for y in range(atlas.get_height()):
   for x in range(atlas.get_width()):
    var c=atlas.get_pixel(x,y)
    if c.a>0 and not allowed.has(c.to_rgba32()):palette_ok=false
  check(palette_ok and atlas.get_pixel(0,0).a==0,pack+" exact shared palette and transparent background")
  check(manifest.cell_size==[64.0,64.0] and manifest.parts.size()==6 and manifest.stumps.size()==4,pack+" unified 64px cells and four independent whole limbs")
  check(manifest.animations.idle.frames==4 and manifest.animations.walk.frames==8 and manifest.animations.hit.frames==3,pack+" complete idle / walk / hit sequences")
  var residual=load(folder+"residual.png").get_image()
  check(residual.get_pixel(27,58).a==0 and residual.get_pixel(37,58).a==0,pack+" residual has no baked feet")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(5);game.close_modal()
 game.state.minutes=900;game.state.weather="sun";game.player.invincible=1000
 for e in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):e.set_physics_process(false)
 game.player.position=Vector2(4150,3070)
 game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
 await frames(2)
 var actors: Array=[]
 for i in range(5):
  var kind: String=["water","bone","daitengu","hungry_ghost","rakshasa"][i]
  var e=YinEnemy.new();e.game=game;e.record=game.state.spawn_record(kind,"graveyard",Vector2.ZERO,1,false)
  e.record.max_hp=100;e.record.hp=100;e.record.armor=0;e.record.at=[4020+i*70,3010];e.position=Vector2(e.record.at[0],e.record.at[1])
  game.world.actors.add_child(e);e.add_to_group("enemies");e.set_physics_process(false)
  e.model.present(kind,e.art_pose(),[],0.2,true,false,Color.WHITE);actors.append(e)
  check(e.model.modular!=null and e.model.modular.joints.arm_left.get_node("Sprite") is Sprite2D,kind+" live enemy uses actual child sprites")
  check(e.model.modular.pack==YinEnemyPack.IDS[i],kind+" selects its independent pack")
 await capture("five-enemy-packs")
 var distant: YinEnemy=actors[4];var local_position=distant.position
 distant.position=Vector2(5500,4000);distant.modular_hit_feedback(Vector2.RIGHT)
 check(is_equal_approx(Engine.time_scale,1),"offscreen faction combat cannot slow down the player")
 distant.position=local_position
 var enemy: YinEnemy=actors[1];var rig: YinModularRig=enemy.model.modular
 enemy.art_facing=Vector2.LEFT;enemy.art_clock=0.28;enemy.velocity=Vector2.LEFT*30;enemy.art_strike=0.1
 enemy.model.present(enemy.record.kind,enemy.art_pose(),[],enemy.art_clock,true,true,Color.WHITE)
 var joint_transform=rig.joints.arm_left.global_transform
 enemy.record.hp=64;enemy.update_dismemberment()
 var limbs=get_nodes_in_group("severed_limbs")
 check(enemy.record.severed==["arm_left"] and limbs.size()==1,"one arm threshold does not remove its opposite arm")
 var limb: YinSeveredLimb=limbs[0]
 check(limb is RigidBody2D and limb.get_parent()==game.world.feedback and limb.collision_mask&1!=0,"detached limb has independent rigid body and terrain collision")
 check(limb.visual.global_position.distance_to(joint_transform.origin)<0.01 and (limb.visual.global_transform.x-joint_transform.x).length()<0.01,"mirrored animated joint and detached sprite share the exact transform")
 check(not rig.joints.arm_left.visible and rig.joints.arm_right.visible and rig.stumps.arm_left.visible and not rig.stumps.arm_right.visible,"only severed child is removed and its own stump is enabled")
 await frames(2)
 check(rig.joints.arm_left.get_node_or_null("Sprite")==null,"severed limb child Sprite is actually freed")
 var limb_id=limb.get_instance_id();var at=limb.position
 check(game.world.screen_bounds().grow(100).has_point(enemy.position),"hit-feedback fixture is inside the real camera view")
 enemy.modular_hit_feedback(Vector2.RIGHT)
 check(rig.animation is AnimationPlayer and rig.animation.is_playing(),"AnimationPlayer runs the authored three hit poses")
 check(Engine.time_scale<1 and not get_nodes_in_group("blood_bursts").is_empty(),"impact triggers time dilation and one-shot blood burst")
 rig.animation.advance(0.06)
 check(rig.hit_frame==1,"hit animation advances through the second hit frame")
 rig.animation.advance(0.2)
 await frames(45)
 check(is_equal_approx(Engine.time_scale,1),"real-time hit clock always restores normal speed")
 check(limb.position.distance_to(at)>2 and limb.height>=0 and limb.bounce_count>0,"rigid limb moves and lands with a vertical bounce")
 var wall=StaticBody2D.new();var barrier=CollisionShape2D.new();var rectangle=RectangleShape2D.new();rectangle.size=Vector2(8,100)
 barrier.shape=rectangle;wall.position=limb.position+Vector2(20,0);wall.add_child(barrier);game.world.feedback.add_child(wall)
 limb.contact_monitor=true;limb.max_contacts_reported=4;limb.sleeping=false;limb.linear_damp=0;limb.linear_velocity=Vector2.RIGHT*180
 var contacts: Array=[];limb.body_entered.connect(func(other):contacts.append(other))
 await frames(20)
 check(wall in contacts and limb.position.x<wall.position.x,"detached RigidBody actually collides with a physical wall")
 wall.queue_free()
 check(not get_nodes_in_group("blood_drops").is_empty() or not get_nodes_in_group("blood_stains").is_empty(),"stump slowly emits separate drops that reach the ground")
 enemy.record.hp=1;enemy.update_dismemberment()
 check(YinEnemyPack.LIMBS.all(func(p):return p in enemy.record.severed) and "head" in enemy.record.severed,"all four limbs and head sever independently")
 await capture("severed-and-blood")
 var enemy_id=enemy.get_instance_id();enemy.receive_hit(100000,"sword")
 var record: Dictionary=game.state.remains.back();var bodies=get_nodes_in_group("remains").filter(func(n):return n.record.id==record.id)
 check(bodies.size()==1 and bodies[0] is StaticBody2D,"death creates one static corpse entity")
 var corpse: YinCorpse=bodies[0]
 check(corpse.modular!=null and corpse.modular.joints.body.visible and not corpse.modular.joints.arm_left.visible,"corpse retains residual torso without resurrecting limbs")
 check(corpse.modular.stumps.arm_left.visible and corpse.modular.stumps.leg_right.visible,"corpse retains shoulder and thigh stump layers")
 await frames(40)
 check(not is_instance_id_valid(enemy_id) and is_instance_id_valid(limb_id),"enemy CharacterBody is destroyed while detached rigid limb survives")
 check(corpse.footprint.shape is CapsuleShape2D and not corpse.is_physics_processing(),"settled corpse has a physical volume and no movement AI")
 var before=corpse.position
 corpse.push_and_step(Vector2.RIGHT,0.1)
 check(corpse.position.x>before.x and corpse.step_time>0,"static corpse responds to scripted pushing and stepping")
 check(Vector2(record.at[0],record.at[1]).is_equal_approx(corpse.position),"pushed corpse coordinates are written back to the save record")
 game.player.position=corpse.position+corpse.footprint.position-Vector2(12,0)
 var before_walk=corpse.position
 var player_start=game.player.position
 Input.action_press("move_right");await frames(12);Input.action_release("move_right")
 check(corpse.position.x>before_walk.x and game.player.position.x>player_start.x+5,"real player movement pushes and steps across corpse volume")
 var snapshot=JSON.parse_string(JSON.stringify(game.state.snapshot()))
 var restored=FarmState.new()
 var good=restored.restore(snapshot)
 check(good and restored.remains.back().severed.size()==5,"four-limb corpse state round trips through actual JSON numbers")
 if not good:quit(1);return
 var clone=YinCorpse.new();clone.bind(restored.remains.back());game.world.actors.add_child(clone)
 check(clone.modular!=null and clone.modular.stumps.leg_right.visible and clone.age==0.45,"loaded corpse restores residual sprite and stump layers")
 clone.queue_free()
 var bad=snapshot.duplicate(true);bad.remains.back().death_pose.rig_pose.body=[NAN,0,0]
 check(not FarmState.new().restore(bad),"non-finite saved joint transforms are rejected")
 await capture("physical-corpses")
 var permanent=record.duplicate(true);permanent.id+=99999;permanent.corpse_lifetime=0
 var body=YinCorpse.new();body.bind(permanent);game.world.actors.add_child(body)
 check(body.lifetime==0,"zero lifetime keeps corpse permanently")
 body.queue_free()
 corpse.fade_out();await frames(135)
 check(not is_instance_valid(corpse) and game.state.find_remains(record.id).is_empty(),"fade removes both physical corpse and save record")
 var settings=YinDisplaySettings.panel();root.add_child(settings)
 settings.get_node("CorpseLifetimeChoice").select(1)
 var apply_button=settings.get_children().filter(func(n):return n is Button and n.text=="应用分辨率")[0]
 apply_button.pressed.emit()
 check(YinDisplaySettings.corpse_lifetime==60,"actual settings control selects timed corpse retention")
 YinDisplaySettings.corpse_lifetime=0;YinDisplaySettings.load_settings()
 check(YinDisplaySettings.corpse_lifetime==60,"retention preference persists through settings reload")
 var timed_record=game.state.leave_remains(actors[0].record,actors[0].position)
 var timed_body=YinCorpse.new();timed_body.bind(timed_record);game.world.actors.add_child(timed_body)
 var timed_limb=YinSeveredLimb.new();timed_limb.source_texture=YinEnemyPack.texture("drowned");timed_limb.source_region=YinEnemyPack.region(2);timed_limb.draw_size=Vector2.ONE*64
 game.world.feedback.add_child(timed_limb)
 check(timed_body.lifetime==60 and timed_limb.lifetime==60,"new torso and detached rigid limb share selected lifetime")
 timed_body.queue_free();timed_limb.queue_free();settings.queue_free()
 YinDisplaySettings.corpse_lifetime=0;YinDisplaySettings.apply(0,false)
 print("MODULAR RESULT ",checks," checks, ",failures," failures")
 root.remove_child(game);game.queue_free();await frames(3);quit(1 if failures else 0)
