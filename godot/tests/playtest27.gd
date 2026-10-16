extends SceneTree
var game: Node2D
var failures=0
var checks=0
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("PLAY27 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func capture(label: String):
 if DisplayServer.get_name()=="headless":return
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
 DirAccess.make_dir_recursive_absolute(folder)
 game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func key(action: String,n: int):
 Input.action_press(action);await frames(n);Input.action_release(action);await frames(2)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(8)
 if game.modal!=null:game.close_modal()
 for e in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):e.queue_free()
 await frames()
 var start=game.player.position
 await key("move_right",60)
 check(game.player.position.distance_to(start)>50,"actual held movement input moves player without teleport")
 await capture("01-home-walk")
 for id in YinWorldDistricts.PLACES:
  var p=YinWorldDistricts.PLACES[id]
  game.player.position=p.at+Vector2(0,36);await frames(5)
  check(game.world.nearest_interaction()=="echo27:"+id,"walkable approach and interaction priority "+id)
  var interact_event=InputEventKey.new();interact_event.physical_keycode=KEY_E;interact_event.keycode=KEY_E;interact_event.pressed=true;Input.parse_input_event(interact_event);Input.flush_buffered_events();await frames()
  check(game.modal!=null and game.state.world_echoes.has(id),"E interaction opens environmental story "+id)
  if id in ["temple_bell","island_market","grave_cairn","village_well"]:await capture("02-"+id+"-story")
  game.close_modal();await frames()
  if id in ["temple_bell","island_market","grave_cairn","village_well"]:await capture("03-"+id+"-district")
  var at=game.player.position
  await key("move_right",25)
  check(game.player.position.distance_to(at)>12,"walk from landmark instead of invisible collision "+id)
 for kind in YinMonsterArt.metadata():
  check(YinMonsterArt.texture(kind)!=null,"independent art loaded "+kind)
  var rig=YinModularRig.new();game.world.actors.add_child(rig);rig.setup(kind)
  for frame in range(4):
   rig.present(kind,[],frame*.1,frame!=0,frame==3,false,Color.WHITE)
   check(rig.joints.body.get_node("Sprite").region_rect.size==Vector2(96,96),"authored frame "+kind+" "+str(frame))
  rig.queue_free()
 game.player.position=Vector2(4896,1056);await frames(4)
 var species=["kappa","jorogumo","chochin","daitengu","ippon_datara"]
 for i in range(species.size()):
  var record=game.state.spawn_record(species[i],"island",Vector2(200,200),1)
  record.at=[4776.0+i*56,1152.0]
 game.spawn_enemies();await frames(30);await capture("04-island-monsters")
 # Exercise real light and heavy action bindings while surrounded by live enemies.
 var hit=InputEventKey.new();hit.physical_keycode=KEY_J;hit.keycode=KEY_J;hit.pressed=true;Input.parse_input_event(hit);Input.flush_buffered_events();await frames(45)
 var heavy=InputEventMouseButton.new();heavy.button_index=MOUSE_BUTTON_RIGHT;heavy.position=Vector2(390,220);heavy.pressed=true;root.push_input(heavy,true);await frames(2)
 check(game.player.heavy_attack,"actual right mouse event starts heavy attack")
 await frames(20)
 await capture("05-combat")
 var snap=game.state.snapshot()
 check(FarmState.new().restore(snap),"world stories and new monster/death state save round trip")
 print("PLAY27 RESULT ",checks," checks ",failures," failures")
 game.queue_free();await frames();quit(1 if failures else 0)
