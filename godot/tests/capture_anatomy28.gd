extends SceneTree
var game
func _initialize():OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func capture(name_value: String):
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
 DirAccess.make_dir_recursive_absolute(folder)
 game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(6);game.close_modal()
 for r in game.state.enemies:r.dead=true
 game.state.factions=YinFactions.initial();game.state.factions.last_day=game.state.day
 for enemy in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):enemy.queue_free()
 await frames()
 game.player.position=Vector2(4210,3090);game.player.invincible=1000;game.state.minutes=900;game.state.weather="sun"
 var actors=[]
 for i in range(5):
  var e=YinEnemy.new();e.game=game;e.record=game.state.spawn_record("brute","graveyard",Vector2.ZERO,1)
  e.record.at=[4030.0+i*90,3070.0];e.position=Vector2(e.record.at[0],e.record.at[1]);e.record.hp=100;e.record.max_hp=100;e.record.armor=0;e.record.severed=[]
  game.world.actors.add_child(e);e.add_to_group("enemies");e.set_physics_process(false)
  e.model.present("brute",e.art_pose(),[],0,false,false,Color.WHITE);actors.append(e)
 await frames(5);await capture("anatomy-before")
 for i in range(1,5):
  var enemy=actors[i];enemy.record.hp=[100,64,30,20,10][i];enemy.update_dismemberment()
 await frames(1);await capture("anatomy-hit")
 for frame in range(30):
  for i in range(5):
   actors[i].art_clock=frame*.03
   actors[i].model.present("brute",actors[i].art_pose(),actors[i].record.get("severed",[]),frame*.03,true,false,Color.WHITE)
  await frames(2)
  if frame%2==0:await capture("motion-%03d"%frame)
 await capture("anatomy-after")
 # Prove full named limbs by showing their actual live rigid bodies after landing.
 print("ANATOMY28 rigid limbs=",get_nodes_in_group("severed_limbs").size()," final missing=",actors[4].record.severed)
 game.queue_free();await frames();quit()
