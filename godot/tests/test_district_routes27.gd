extends SceneTree
var game
var failures=0
var checks=0
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("ROUTES27 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func clear_route(start: Vector2,path: PackedVector2Array,half: Vector2) -> bool:
 if path.is_empty():return false
 var at=start
 for next in path:
  if not game.world.clear_body_path(at,next,half):return false
  at=next
 return true
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(6);game.close_modal()
 var half=Vector2(8,6)
 for id in YinWorldDistricts.PLACES:
  var p=YinWorldDistricts.PLACES[id]
  var start: Vector2=YinContinent.CAPITALS[p.region]
  var path=game.world.path_to(start,p.at+Vector2(0,36),half)
  check(not path.is_empty(),"capital has a connected route to "+id)
  check(clear_route(start,path,half),"each route EDGE clears actual terrain, not just its endpoints "+id)
 var start=Vector2(1488,3504)
 var path=game.world.path_to(start,Vector2(1392,3504),half)
 check(clear_route(start,path,half) and path.size()>3,"thin lantern between grid centres cannot produce a false straight path")
 var snapshot=game.state.snapshot();snapshot.erase("world_echoes")
 check(FarmState.new().restore(snapshot),"existing v14 save gains an empty discovery journal")
 for bad in [{"not_a_place":true},{"temple_bell":"yes"}]:
  var damaged=game.state.snapshot();damaged.world_echoes=bad
  check(not FarmState.new().restore(damaged),"invalid discovery journal rejected")
 print("ROUTES27 RESULT ",checks," checks ",failures," failures")
 game.queue_free();await frames();quit(1 if failures else 0)
