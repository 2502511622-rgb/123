# Exploratory play session: stock save, real movement and combat inputs only.
# Route waypoints are navigation assistance; enemy AI, damage and inventory are untouched.
extends SceneTree
var game
var route: PackedVector2Array=[]
var route_timer=0
var road_done=false
var crossed=false
var last_goal=Vector2.INF
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func stop():
 for a in ["move_left","move_right","move_up","move_down"]:Input.action_release(a)
func move_to(goal: Vector2):
 route_timer-=1
 if route_timer<=0 or goal.distance_to(last_goal)>64 or route.is_empty():
  route=game.world.path_to(game.player.position,goal,Vector2(8,6));route_timer=90;last_goal=goal
 while not route.is_empty() and game.player.position.distance_to(route[0])<11:route.remove_at(0)
 stop()
 if route.is_empty():return
 var delta=route[0]-game.player.position
 if absf(delta.x)>5:Input.action_press("move_right" if delta.x>0 else "move_left")
 if absf(delta.y)>5:Input.action_press("move_down" if delta.y>0 else "move_up")
func key(code: int):
 for down in [true,false]:
  var event=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=down;root.push_input(event,true)
func aim(actor: Node2D):
 var e=InputEventMouseMotion.new();e.position=game.world.get_global_transform_with_canvas()*actor.position;root.push_input(e,true)
func capture(label: String):
 if DisplayServer.get_name()=="headless":return
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func find_button(node: Node,text: String) -> Button:
 if node is Button and text in node.text:return node
 for child in node.get_children():
  var found=find_button(child,text)
  if found!=null:return found
 return null
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(8)
 if game.modal!=null:key(KEY_ESCAPE)
 await frames()
 print("NEW PLAYER start at=",game.player.position," hp=",game.state.health," weapon=",game.player.held_item)
 var phase="outbound";var engaged=false;var returned=false
 for tick in range(12000):
  if game.state.health<=0 or game.modal!=null:
   print("NEW PLAYER stopped: hp=",game.state.health," modal=",game.modal!=null);break
  if not road_done and phase=="outbound" and game.player.position.x>2200:
   var target=YinWorldDistricts.PLACES.road_supplies.at+Vector2(0,36)
   if game.player.position.distance_to(target)>28:
    move_to(target);await frames(1);continue
   stop();key(KEY_E);await frames(4)
   var take=find_button(game.modal,"取行旅护甲") if game.modal!=null else null
   if take!=null and not take.disabled:
    var scroll=game.modal.get_node("ModalCard/Layout/Scroll");scroll.ensure_control_visible(take);await frames(2)
    for down in [true,false]:
     var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=take.get_global_rect().get_center();event.pressed=down;root.push_input(event,true);await frames(1)
   await capture("journey-road-choice")
   road_done=game.state.exploration_rewards.has("road_supplies")
   print("NEW PLAYER ROAD chosen=",road_done," hp=",game.state.health)
   if game.modal!=null:key(KEY_ESCAPE);await frames(2)
   route_timer=0;last_goal=Vector2.INF
   if not road_done:break
  if game.player.position.x>3296 and not crossed:
   crossed=true;print("NEW PLAYER crossed bridge with held movement inputs at tick=",tick);await capture("journey-crossing")
  var progress=YinAdventure.progress(game.state,"first_watch")
  if progress>=2:phase="return"
  if phase=="return":
   if game.player.position.distance_to(YinContinent.HOME)<65:
    stop();returned=true;key(KEY_O);await frames();await capture("journey-return-quest")
    var claim=find_button(game.modal,"复命 · 领取银剑")
    if claim!=null and not claim.disabled:
     var at=claim.get_global_rect().get_center()
     for down in [true,false]:
      var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=at;root.push_input(event,true);await frames(1)
     await frames();await capture("journey-reward")
    print("NEW PLAYER reward claimed=",game.state.quests.first_watch.claimed)
    break
   move_to(YinContinent.HOME)
  else:
   var nearest: Node2D=null;var distance_value=INF
   for e in get_nodes_in_group("enemies"):
    if e.is_queued_for_deletion() or e.record.dead or e.record.has("war_id") or e.record.zone!="graveyard":continue
    var d=game.player.position.distance_to(e.position)
    if d<distance_value:nearest=e;distance_value=d
   if nearest==null:break
   if distance_value<55:
    stop();aim(nearest)
    if not engaged:engaged=true;await capture("journey-first-contact")
    if nearest.windup>0 and game.player.dodge_cooldown<=0:key(KEY_SHIFT)
    elif tick%25==0:key(KEY_J)
   else:move_to(nearest.position)
  if tick%900==0:print("NEW PLAYER tick=",tick," at=",game.player.position," hp=",game.state.health," progress=",progress," phase=",phase)
  await frames(1)
 stop();await capture("journey-end")
 print("NEW PLAYER RESULT crossed=",crossed," kills=",YinAdventure.progress(game.state,"first_watch")," returned=",returned," hp=",game.state.health," at=",game.player.position)
 if game.state.quests.get("first_watch",{}).get("claimed",false):
  if game.modal!=null:key(KEY_ESCAPE);await frames(3)
  var target=YinWorldDistricts.PLACES.village_watch.at+Vector2(0,36)
  route_timer=0;last_goal=Vector2.INF
  for step in range(5000):
   if game.player.position.distance_to(target)<22:break
   if game.state.health<=0 or game.modal!=null:break
   move_to(target);await frames(1)
  stop();key(KEY_E);await frames(4);await capture("branch-discovery")
  var loot=find_button(game.modal,"领取探索遗物") if game.modal!=null else null
  if loot!=null and not loot.disabled:
   var point=loot.get_global_rect().get_center()
   for down in [true,false]:
    var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;root.push_input(event,true);await frames(1)
   await frames();await capture("branch-reward")
  print("NEW PLAYER BRANCH claimed=",game.state.exploration_rewards.has("village_watch")," actual gear=",game.state.equipment.back())
  var travel=find_button(game.modal,"循驿路返回义庄") if game.modal!=null else null
  if travel!=null:
   var point=travel.get_global_rect().get_center()
   for down in [true,false]:
    var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;root.push_input(event,true);await frames(1)
   await frames(5);await capture("branch-fast-return")
  print("NEW PLAYER FINAL road_choice=",road_done," hp=",game.state.health," home_distance=",game.player.position.distance_to(YinContinent.HOME)," branch_reward=",game.state.exploration_rewards.has("village_watch"))
 game.queue_free();await frames();quit()
