extends SceneTree
var game
var checks=0
var failures=0
func _initialize():OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func check(ok: bool,detail: String):
 checks+=1;print("PERF ","PASS " if ok else "FAIL ",detail)
 if not ok:failures+=1
func frames(n=3):
 for i in range(n):await physics_frame
func capture(label: String):
 if DisplayServer.get_name()=="headless" or OS.get_environment("YINTIAN_CAPTURE_DIR")=="":return
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
 await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(folder.path_join(label+".png"))==OK,"capture "+label)
func corpse(id: int) -> YinCorpse:
 for node in get_nodes_in_group("remains"):
  if node is YinCorpse and not node.is_queued_for_deletion() and node.record.id==id:return node
 return null
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(5);game.close_modal()
 check(Engine.physics_ticks_per_second==60 and Engine.max_fps==60,"shipping runtime uses 60 Hz physics and 60 FPS target")
 game.world.path_to(game.player.position,game.player.position)
 check(game.world.combat_navigation.region.size==Vector2i(200,150),"continuous-world navigation has one quarter the previous grid cells")
 check(game.world.grass.active_chunks.size()<60 and game.world.grass.active_chunks.size()<game.world.grass.chunks.size(),"grass updates only local active chunks")
 var trees=get_nodes_in_group("wind_trees")
 check(trees.size()>10 and trees.all(func(t):return t.get_node("ArtSprite").material==game.world.shared_canopy()),"all tree types share one wind material")
 var distant=get_nodes_in_group("enemies").filter(func(e):return e.position.distance_to(game.player.position)>1400)
 check(not distant.is_empty() and distant.all(func(e):return not e.visible),"offscreen enemy models are not redrawn")
 game.player.position=Vector2(4100,3050);await frames(4)
 for node in get_nodes_in_group("enemies"):node.stun=100
 game.player.invincible=1000
 var enemy=game.nearest_enemy(game.player.position,1000)
 check(enemy!=null,"real enemy available for death transition")
 enemy.position=game.player.position+Vector2(40,0);enemy.record.severed=["head","leg"];enemy.record.integrity=100
 enemy.art_facing=Vector2.LEFT
 var before=game.state.remains.size()
 enemy.receive_hit(100000,"sword")
 check(game.state.remains.size()==before+1,"actual player kill leaves a body record")
 var record: Dictionary=game.state.remains.back();var body=corpse(record.id)
 check(body!=null and body.age<0.45,"body begins an animated fall instead of a generic pile")
 check(body!=null and body.parts.all(func(p):return p.part not in ["head","leg"]),"missing limbs remain missing on the corpse")
 check(YinCorpse.valid(record.death_pose,record.kind),"death pose stores finite bounded anatomy and frame metadata")
 await capture("corpse24-fall")
 var first_id=body.get_instance_id()
 var enemy2=game.get_tree().get_nodes_in_group("enemies").filter(func(e):return not e.record.dead and not e.is_queued_for_deletion())[0]
 enemy2.position=game.player.position+Vector2(-45,12);enemy2.record.integrity=100;enemy2.receive_hit(100000,"sword")
 await frames(35)
 check(corpse(record.id).get_instance_id()==first_id,"subsequent deaths preserve existing corpse nodes")
 check(not body.is_processing() and body.age>=0.45,"settled corpses finish falling and have no per-frame process callback")
 check(body is StaticBody2D and body.footprint.shape is CapsuleShape2D and body.get_node_or_null("Hurtbox")==null and not body.is_physics_processing(),"static corpse retains collision but no enemy AI or hurtbox")
 var saved: Dictionary=JSON.parse_string(JSON.stringify(game.state.snapshot()));var restored=FarmState.new()
 check(restored.restore(saved) and restored.remains.back().has("death_pose"),"corpse pose and severed state survive saving")
 var rebuilt=YinCorpse.new();rebuilt.bind(restored.find_remains(record.id));game.world.actors.add_child(rebuilt)
 check(rebuilt.parts.size()==body.parts.size() and rebuilt.age==0.45,"loaded body is already settled with the same limb count")
 rebuilt.queue_free()
 var legacy=record.duplicate(true);legacy.erase("death_pose");legacy.erase("severed")
 var old_body=YinCorpse.new();old_body.bind(legacy)
 check(not old_body.parts.is_empty(),"old save bodies reconstruct from their monster type")
 old_body.free()
 var malformed=saved.duplicate(true);malformed.remains[0].death_pose.source=[NAN,0,20,20]
 check(not FarmState.new().restore(malformed),"invalid corpse geometry is rejected safely")
 await capture("corpse24-settled")
 game.frame_budget.apply_tier(2)
 check(game.frame_budget.tier==2 and game.world.environment.terrain_material.get_shader_parameter("quality")==0,"low-budget mode reduces visual effects without changing simulation")
 check(Engine.physics_ticks_per_second==60,"visual adaptation preserves 60 Hz gameplay")
 game.frame_budget.apply_tier(0)
 check(game.world.grass.chunks.all(func(c):return c.back.multimesh.visible_instance_count==-1),"full art density can be restored")
 # Refine through real input; corpses in an adjacent logical region remain accessible.
 var active=game.state.remains.back();active.integrity=100;game.player.position=Vector2(active.at[0],active.at[1]);game.state.zone="village"
 game.instant_refine();await frames(3)
 check(game.state.find_remains(active.id).is_empty() and corpse(active.id)==null,"refining removes exactly its body across logical territory boundaries")
 await frames(60)
 var disk=FarmState.new()
 check(load("res://scripts/save_store.gd").load_game(disk) and disk.find_remains(active.id).is_empty() and not disk.remains.is_empty(),"coalesced combat save persists processed and remaining bodies to disk")
 print("PERF RESULT ",checks," checks, ",failures," failures")
 root.remove_child(game);game.queue_free();await frames(3);quit(1 if failures else 0)
