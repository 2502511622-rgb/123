extends SceneTree
var game
var checks=0
var failures=0
func _initialize():OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("TERRITORY28 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func capture(label: String):
 if DisplayServer.get_name()=="headless" or OS.get_environment("YINTIAN_CAPTURE_DIR")=="":return
 game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
 await process_frame;await RenderingServer.frame_post_draw
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(6);game.close_modal()
 for e in game.state.enemies:e.dead=true
 for e in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):e.queue_free()
 await frames()
 game.state.factions=YinFactions.initial();game.state.factions.last_day=game.state.day
 var war=YinFactions.declare(game.state,"village","temple");YinFactions.deploy(game.state,war);game.spawn_enemies();await frames()
 var attackers=YinFactions.survivors(game.state,war,"attacker")
 # Isolate the post-battle phase. Defeat alone must never flip ownership.
 for r in YinFactions.survivors(game.state,war,"defender"):r.dead=true
 YinFactions.tick(game.state)
 check(war.status=="active" and YinTerritory28.owner(game.state,"temple")=="temple","army victory away from capital does not grant remote ownership")
 var post=YinTerritory28.post("temple")
 var soldiers=[]
 for actor in get_nodes_in_group("faction_guards"):
  if actor.record.get("war_id",0)==war.id:soldiers.append(actor)
 for i in range(soldiers.size()):
  soldiers[i].position=post+Vector2(-100-i*24,50+i*18);soldiers[i].record.at=[soldiers[i].position.x,soldiers[i].position.y]
 var origins=soldiers.map(func(e):return e.position)
 game.player.position=post+Vector2(0,120);await capture("occupation-approach")
 await frames(120)
 check(soldiers.any(func(e):return e.position.distance_to(origins[soldiers.find(e)])>15),"surviving soldiers physically advance toward the flag")
 await capture("occupation-progress")
 for i in range(1200):
  if YinTerritory28.owner(game.state,"temple")=="village":break
  await frames(1)
 check(YinTerritory28.owner(game.state,"temple")=="village" and game.state.factions.wars.is_empty(),"actual presence and hold time capture capital and conclude war")
 var guards=YinTerritory28.guards(game.state,"temple")
 check(guards.size()>0 and guards.size()<=3 and guards.all(func(e):return not e.has("war_id") and e.faction=="village"),"actual surviving expedition members become persistent garrison")
 check(guards.all(func(e):return e.id in attackers.map(func(a):return a.id)),"garrison is not replaced by teleported new soldiers")
 var restored=FarmState.new()
 check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))),"occupation, guards and war conclusion round trip")
 restored.next_day()
 check(not YinTerritory28.guards(restored,"temple").is_empty(),"garrison survives day change")
 game.player.position=post+Vector2(0,80);await frames();await capture("occupation-garrison")
 game.show_waypost28("temple");await frames();await capture("occupation-post");game.close_modal()
 game.show_character("地图");await frames();await capture("occupation-map");game.close_modal()
 game.show_factions();await frames();await capture("occupation-report");game.close_modal()
 var intrusion=game.state.spawn_record("bone","temple",Vector2.ZERO,1)
 intrusion.at=[post.x+70,post.y+60];intrusion.faction="island";intrusion.hp=200;intrusion.max_hp=200;intrusion.armor=0
 var intruder=YinEnemy.new();intruder.game=game;intruder.record=intrusion;intruder.position=Vector2(intrusion.at[0],intrusion.at[1]);game.world.actors.add_child(intruder);intruder.add_to_group("enemies")
 await frames(240)
 check(intrusion.hp<200,"stationed guards independently attack an intruder without player attacks")
 await capture("garrison-defends")
 intrusion.dead=true;intruder.queue_free();await frames(3)
 var positions=guards.map(func(e):return e.at.duplicate())
 var result=YinTerritory28.restore_homeland(game.state,"temple")
 check(YinTerritory28.owner(game.state,"temple")=="temple" and guards.all(func(e):return e.garrison_region=="village"),"player mediation restores homeland and orders allied guards to walk home")
 check(guards.map(func(e):return e.at)==positions,"mediation never teleports returning garrison")
 await frames(8);await capture("occupation-restored")
 print("TERRITORY28 RESULT ",checks," checks ",failures," failures")
 game.queue_free();await frames();quit(1 if failures else 0)
