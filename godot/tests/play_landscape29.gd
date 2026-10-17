# Local player exploration from the coastal approach. Initial placement is a fixture;
# after that all movement, collisions, enemy AI, damage and loot use normal inputs.
extends SceneTree
var game
var goal_index=0
var route=PackedVector2Array()
var folder: String
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");OS.set_environment("YINTIAN_SILENT","1");folder=OS.get_environment("YINTIAN_CAPTURE_DIR");call_deferred("run")
func frames(n=2):
 for i in range(n):await physics_frame
func stop():
 for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)
func screenshot(name_value):
 if folder=="" or DisplayServer.get_name()=="headless":return
 DirAccess.make_dir_recursive_absolute(folder);await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(8);game.close_modal();game.state.intro_seen=true
 game.player.position=Vector2(5152,1776)
 var health=game.state.health
 var goals=[Vector2(5376,1952),Vector2(5408,2164),Vector2(5408,2104),YinAdventure.chest_at("island_ruin",true)]
 for tick in range(1800):
  var goal: Vector2=goals[goal_index]
  if game.player.position.distance_to(goal)<20:
   print("WILDPLAY reached=",goal_index," at=",game.player.position," hp=",game.state.health)
   goal_index+=1;route.clear()
   if goal_index==goals.size():break
   goal=goals[goal_index]
  if tick%24==0 or route.is_empty():route=game.world.path_to(game.player.position,goal,Vector2(8,6))
  while not route.is_empty() and game.player.position.distance_to(route[0])<9:route.remove_at(0)
  # AStar returns grid centres; the final sub-cell approach still uses normal input.
  if game.player.position.distance_to(goal)<80 and game.world.clear_body_path(game.player.position,goal,Vector2(8,6)):route=PackedVector2Array([goal])
  if tick%240==0:print("WILDPLAY tick=",tick," goal=",goal_index," at=",game.player.position," next=",route[0] if not route.is_empty() else Vector2.INF)
  stop()
  if not route.is_empty():
   var delta=route[0]-game.player.position
   if absf(delta.x)>4:Input.action_press("move_right" if delta.x>0 else "move_left")
   if absf(delta.y)>4:Input.action_press("move_down" if delta.y>0 else "move_up")
  await frames(1)
  if goal_index in [1,2] and tick%12==0:await screenshot("walk-%04d"%tick)
  if game.state.health<=0:break
 stop();await frames(10)
 if goal_index==goals.size():
  for down in [true,false]:
   var key=InputEventKey.new();key.physical_keycode=KEY_E;key.keycode=KEY_E;key.pressed=down;root.push_input(key,true);await frames(1)
 await screenshot("coast-reward")
 print("WILDPLAY result reached=",goal_index,"/4 hp=",game.state.health," initial_hp=",health," cache=", "island_ruin" in game.state.opened_chests)
 var okay=goal_index==4 and "island_ruin" in game.state.opened_chests
 game.queue_free();await frames();quit(0 if okay else 1)
