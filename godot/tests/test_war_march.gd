extends SceneTree
var game
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(6);game.close_modal()
 for r in game.state.enemies:r.dead=true
 for e in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):e.queue_free()
 await frames()
 game.state.factions=YinFactions.initial();game.state.factions.last_day=game.state.day
 game.player.position=YinContinent.HOME;game.player.invincible=1000
 var war=YinFactions.declare(game.state,"island","temple");YinFactions.deploy(game.state,war);game.spawn_enemies();await frames()
 var crossed=false;var fought=false
 for i in range(110):
  await frames(60)
  for r in game.state.enemies:
   if r.get("war_id",0)!=war.id:continue
   var x=float(r.at[0]);var y=float(r.at[1])
   if (r.faction=="island" and x<3104) or (r.faction=="temple" and x>3296):crossed=true
   if r.hp<r.max_hp:fought=true
  if i%15==0:print("NATURAL MARCH ",i,"s crossed=",crossed," fought=",fought)
  if crossed and fought:break
 print("NATURAL WAR ","PASS" if crossed and fought else "FAIL"," from actual capital deployment to cross-river combat; crossed=",crossed," damage=",fought)
 game.queue_free();await frames();quit(0 if crossed and fought else 1)
