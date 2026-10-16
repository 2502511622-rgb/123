extends SceneTree
var game: Node2D
var failures=0
var checks=0
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("INVASION ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func soldier(at: Vector2,side: String,war: int,frozen=false) -> YinEnemy:
 var r=game.state.spawn_record("bone","island",Vector2(200,200),1)
 r.at=[at.x,at.y];r.faction="island" if side=="defender" else "temple";r.war_id=war;r.war_side=side;r.hp=10000;r.max_hp=10000;r.damage=1
 var actor=YinEnemy.new();actor.game=game;actor.record=r;actor.position=at;game.world.actors.add_child(actor);actor.add_to_group("enemies");actor.set_physics_process(not frozen)
 return actor
func clear_armies():
 for e in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):e.queue_free()
 await frames()
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(8)
 if game.modal!=null:game.close_modal()
 game.player.position=Vector2(800,3552)
 await clear_armies()
 for i in range(4):
  var center: Vector2=YinContinent.BRIDGES[i].get_center()
  var axis=Vector2.RIGHT if i<2 else Vector2.DOWN
  var tangent=axis.orthogonal()
  # Both faces of each crossing: diagonal approach and physical collision enabled.
  for direction in [-1,1]:
   var start=center-axis*176*direction+tangent*144
   var goal=center+axis*240*direction-tangent*144
   var attacker=soldier(start,"attacker",990+i)
   soldier(goal,"defender",990+i,true)
   var route=game.world.path_to(start,goal,YinBodyProfile.spec("bone").half)
   check(not route.is_empty(),"bridge %d direction %d path exists"%[i,direction])
   await frames(60*32)
   check((attacker.position-center).dot(axis)*direction>96,"bridge %d direction %d REAL unit crosses, end=%s"%[i,direction,attacker.position])
   await clear_armies()
 # A formation may not turn a crossing into a permanent queue.
 var convoy=[]
 for i in range(6):convoy.append(soldier(Vector2(3008-(i/3)*32,976+(i%3)*32),"attacker",999))
 soldier(Vector2(3460,1136),"defender",999,true)
 await frames(60*40)
 check(convoy.all(func(e):return e.position.x>3296),"six soldiers pass north bridge with actor separation and physical volumes")
 check(convoy.any(func(e):return e.record.hp<e.record.max_hp) or get_nodes_in_group("enemies").any(func(e):return e.record.hp<e.record.max_hp),"crossing leads to actual damage, not position-only completion")
 print("INVASION RESULT ",checks," checks ",failures," failures")
 game.queue_free();await frames();quit(1 if failures else 0)
