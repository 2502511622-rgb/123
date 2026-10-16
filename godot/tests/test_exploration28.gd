extends SceneTree
var game
var checks=0
var failures=0
func _initialize():OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("EXPLORATION28 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(6);game.close_modal()
 for e in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):e.queue_free()
 await frames()
 game.player.position=Vector2(2640,3610);await frames(4)
 check(YinExploration28.road_speed(game)>1.4,"safe road grants free travel speed")
 var before=game.player.position;Input.action_press("move_right");await frames(60);Input.action_release("move_right")
 check(game.player.position.distance_to(before)>140,"normal movement input actually travels faster on the road")
 var record=game.state.spawn_record("bone","village",Vector2.ZERO,1);record.at=[game.player.position.x+80,game.player.position.y]
 var hostile=YinEnemy.new();hostile.game=game;hostile.record=record;hostile.position=Vector2(record.at[0],record.at[1]);game.world.actors.add_child(hostile);hostile.add_to_group("enemies");hostile.set_physics_process(false)
 check(YinExploration28.road_speed(game)==1.0,"enemy proximity cancels road boost")
 game.state.visited_posts.island=true
 game.show_world_echo("village_tea");var current=game.player.position;game.travel_post28("home")
 check(game.player.position==current and game.modal!=null,"combat blocks fast return without moving or dismissing the modal")
 hostile.record.dead=true;hostile.queue_free();await frames(2);game.close_modal()
 game.travel_post28("graveyard")
 check(game.player.position==current,"undiscovered destination remains locked")
 game.travel_post28("island")
 check(game.player.position.distance_to(YinTerritory28.post("island"))<80,"discovered safe post can be revisited")
 game.travel_post28("home")
 check(game.player.position.distance_to(YinContinent.HOME)<110,"safe return reaches actual home without scene replacement")
 var id=game.world.get_instance_id()
 for place in YinWorldDistricts.PLACES:
  game.state.world_echoes[place]=true
  var gear=game.state.equipment.size();var money=game.state.money
  YinExploration28.claim(game.state,place)
  check(game.state.equipment.size()>gear or game.state.money>money,"every side landmark provides a real reward "+place)
  var data=game.state.snapshot();YinExploration28.claim(game.state,place)
  check(game.state.snapshot()==data,"reward is single-use "+place)
 check(game.world.get_instance_id()==id,"travel and rewards preserve persistent world and armies")
 var restored=FarmState.new()
 check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))) and restored.exploration_rewards.size()==16,"all claimed rewards persist")
 print("EXPLORATION28 RESULT ",checks," checks ",failures," failures")
 game.queue_free();await frames();quit(1 if failures else 0)
