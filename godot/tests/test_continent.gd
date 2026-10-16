extends SceneTree
var game: Node2D
var checks=0
var failures=0
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func check(ok: bool,detail: String):
 checks+=1;print("CONTINENT ","PASS " if ok else "FAIL ",detail)
 if not ok:failures+=1
func frames(n=3):
 for i in range(n):await physics_frame
func capture(name_value: String):
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
 if folder=="" or DisplayServer.get_name()=="headless":return
 DirAccess.make_dir_recursive_absolute(folder)
 game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))==OK,"capture "+name_value)
func findtext(n: Node,fragment: String) -> bool:
 if n is Button and fragment in n.text:return true
 for c in n.get_children():
  if findtext(c,fragment):return true
 return false
func run():
 var old=FarmState.new();old.prepare_enemies();old.intro_seen=true
 var old_snapshot=old.snapshot();old_snapshot.version=13;old_snapshot.erase("continent_ready")
 var restored=FarmState.new()
 check(restored.restore(old_snapshot),"version 13 save remains importable")
 var gear=restored.equipment.duplicate(true);var money=restored.money
 YinContinent.migrate(restored)
 check(restored.enemies.filter(func(e):return e.has("home_at")).all(func(e):return Vector2(e.home_at[0],e.home_at[1]).distance_to(Vector2(e.at[0],e.at[1]))<1),"boss home anchors migrate with their bodies")
 check(restored.continent_ready and restored.equipment==gear,"migration preserves existing equipment")
 check(restored.money>money and restored.seed_count("candle")==0,"retired farming stock refunded once")
 var snapshot=restored.snapshot();var again=FarmState.new()
 check(again.restore(snapshot),"global coordinates and world flag round trip")
 YinContinent.migrate(again)
 check(again.snapshot()==snapshot,"migration is idempotent")
 restored.next_day()
 check(restored.plots.all(func(p):return p.crop=="" and not p.tilled),"rest has no crop growth or farming jobs")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(5)
 check(game.world is YinContinentWorld and game.world.level_size==YinContinent.SIZE,"shipping game installs one 6400 by 4800 world")
 var escape=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.keycode=KEY_ESCAPE;escape.pressed=true;Input.parse_input_event(escape);Input.flush_buffered_events();await frames(2)
 escape=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.keycode=KEY_ESCAPE;escape.pressed=false;Input.parse_input_event(escape);Input.flush_buffered_events();await frames(2)
 check(game.modal==null and game.state.quests.has("first_watch"),"Esc intro starts the same first mission")
 check(not game.player.held_item.begins_with("tool") and game.world.front_plot()==-1,"new game has weapon and no farmland interaction")
 game.show_character("背包");await frames(2)
 check(not findtext(game.modal,"农具") and not findtext(game.modal,"阴种") and not findtext(game.modal,"智能"),"inventory exposes no farming controls")
 game.close_modal();game.show_shop();await frames(2)
 check(not findtext(game.modal,"种子"),"merchant has no seed trade")
 game.close_modal();await capture("world23-home")
 check(game.world.is_safe_position(Vector2(3024,1056)) and not game.world.is_safe_position(Vector2(3200,1400)),"banks block water while approach is walkable")
 var original=game.world.get_instance_id();var actor=game.player.get_instance_id()
 game.player.position=Vector2(3024,1056)
 Input.action_press("move_right");await frames(190);Input.action_release("move_right");await frames(3)
 check(game.player.position.x>3296,"actual input walks completely across northern bridge")
 check(game.state.zone=="island" and game.world.get_instance_id()==original and game.player.get_instance_id()==actor,"crossing changes territory without loading or replacing actors")
 await capture("world23-bridge")
 for id in YinContinent.CAPITALS:
  check(YinContinent.faction(YinContinent.CAPITALS[id])==id,"capital occupies matching territory "+id)
  check(not game.world.path_to(YinContinent.CAPITALS.village,YinContinent.CAPITALS[id]).is_empty(),"capital accessible across actual bridges "+id)
  game.player.position=YinContinent.CAPITALS[id]+Vector2(0,80);await frames(2);await capture("world23-"+id)
 game.show_character("地图");await frames(2);await capture("world23-map");game.close_modal()
 # Clear unrelated wilderness actors solely to isolate an actual army-vs-army encounter.
 for e in game.state.enemies:e.dead=true
 for foe in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):foe.queue_free()
 await frames(3)
 game.state.factions=YinFactions.initial();game.state.factions.last_day=game.state.day
 var war=YinFactions.declare(game.state,"island","temple")
 YinFactions.deploy(game.state,war);game.spawn_enemies();await frames(3)
 var soldiers=get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards")
 check(soldiers.size()==war.attackers+war.defenders,"every declared soldier exists as a physical actor")
 check(soldiers.all(func(e):return e.record.has("war_id") and e.body_shape!=null),"armies have persistent identities and collision bodies")
 var attackers=YinFactions.survivors(game.state,war,"attacker")
 check(Vector2(attackers[0].at[0],attackers[0].at[1]).distance_to(YinContinent.CAPITALS.island)<300,"attacking army musters in its own homeland")
 var march_origin=Vector2(attackers[0].at[0],attackers[0].at[1])
 await frames(90)
 check(Vector2(attackers[0].at[0],attackers[0].at[1]).distance_to(march_origin)>20,"army really advances before entering the battlefield fixture")
 var before=game.state.enemies.duplicate(true)
 game.state.minutes=1300
 YinFactions.simulate_offscreen(game.state,war);YinFactions.tick(game.state)
 check(game.state.enemies==before and war.status=="active","nightfall and offscreen tick cannot deduct health or decide victory")
 # Stage both already-created armies near a bridge, then let their real AI fight.
 for i in range(soldiers.size()):
  var foe=soldiers[i];var attacker=foe.record.war_side=="attacker"
  foe.position=Vector2(3160 if attacker else 3240,1000+(i%3)*32);foe.record.at=[foe.position.x,foe.position.y]
 game.player.position=YinContinent.HOME+Vector2(0,96);await frames(420)
 check(soldiers.any(func(e):return not is_instance_valid(e) or e.record.hp<e.record.max_hp),"armies exchange actual attacks while player is across the world")
 check(game.world.get_instance_id()==original,"distant war runs in the same persistent scene")
 var survivor_data=game.state.snapshot();check(FarmState.new().restore(survivor_data),"active real war and soldier positions can be saved")
 for i in range(1800):
  if game.state.factions.wars.is_empty():break
  await frames(1)
 check(game.state.factions.wars.is_empty() and not game.state.factions.history.is_empty(),"actual army deaths settle the battle without scheduled auto victory")
 # Exercise actual civilian AI attack, with an isolated hostile at a civilian's home.
 var npc=get_nodes_in_group("villagers")[0]
 var enemy_record=game.state.spawn_record("bone","village",Vector2(260,300)+Vector2(30,0),1)
 game.spawn_enemies();await frames(120)
 check(npc.attack_count>0 and enemy_record.hp<enemy_record.max_hp,"civilian independently attacks nearby hostile without player assistance")
 game.player.position=npc.position+Vector2(0,80);await capture("world23-militia")
 game.show_factions();await frames(2);await capture("world23-war");game.close_modal()
 print("CONTINENT RESULT ",checks," checks, ",failures," failures")
 root.remove_child(game);game.queue_free();await frames(3);quit(1 if failures else 0)
