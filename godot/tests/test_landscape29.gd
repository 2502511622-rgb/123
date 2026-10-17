extends SceneTree
var game
var checks=0
var failures=0
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");OS.set_environment("YINTIAN_SILENT","1");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("LAND29 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func capture(label: String):
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
 if folder=="" or DisplayServer.get_name()=="headless":return
 DirAccess.make_dir_recursive_absolute(folder)
 game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(10);game.close_modal()
 game.state.intro_seen=true
 # Isolate scenery checks from scheduled wars; warfare has separate regressions.
 game.state.factions.last_day=game.state.day;game.state.factions.wars.clear()
 for enemy in get_nodes_in_group("enemies"):enemy.set_physics_process(false)
 var env=game.world.environment;var field=env.landscape29
 check(field!=null and field.texture!=null,"continuous road and relief field is baked")
 print("LAND29 field bake_ms=",field.bake_ms," lowplants=",env.wilderness29.low_count," props=",env.wilderness29.props.size())
 check(field.sample(Vector2(1000,3552))<0,"actual main route retains paved interior")
 check(field.sample(Vector2(1000,3552)+Vector2(0,112))>18,"road shoulders fade to open ground")
 var materials=load("res://assets/landscape29/materials.png").get_image();var variants={}
 for y in range(3):
  for x in range(4):variants[hash(materials.get_region(Rect2i(x*256,y*256,256,256)).get_data())]=true
 check(variants.size()==12,"four stone, four forest and four grave cells contain distinct artwork")
 var distinct={}
 for id in ["fern","clover","mushroom","shrub","tall_grass","dry_grass","stump","branch","stele","mound","coffin","tomb","bones","wreath","chain","tablet","ruin_left","ruin_right","pillar","statue","barrel","planks","shells","salt_grass"]:
  var image=YinWilderness29.art_texture(id).get_image()
  check(image.get_used_rect().has_area() and image.get_format()==Image.FORMAT_RGBA8,id+" is a separate transparent usable sprite")
  distinct[hash(image.get_data())]=true
 check(distinct.size()==24,"24 props have distinct source pixels")
 check(env.wilderness29.species.size()>=5 and env.wilderness29.low_count>300,"multiple low vegetation species are clustered with open space")
 var graves=0
 for prop in env.wilderness29.props:
  if prop.art=="mound":graves+=1
 check(graves==3,"exactly three authored focal grave mounds")
 for at in YinLandscape29.GRAVES:
  check(field.sample(at,1)>.4 and field.sample(at+Vector2(73,32),1)< -.3,"grave rises beside a genuinely recessed pit "+str(at))
 for id in ["forest_west","grave_cache","island_ruin"]:
  var goal=YinAdventure.chest_at(id,true)
  var start=YinContinent.CAPITALS[YinContinent.faction(goal)]
  var path=game.world.path_to(start,goal,Vector2(8,6));var clear=not path.is_empty();var previous: Vector2=start
  for at in path:
   clear=clear and game.world.clear_body_path(previous,at,Vector2(8,6));previous=at
  check(clear,"actual traversable branch reaches reward "+id)
 check(not game.world.grass.grass_at(Vector2(5552,2144)),"coast uses salt-grass clusters rather than scattered meadow blades")
 check(get_nodes_in_group("shore_crabs29").size()==3,"three coastal crabs occupy asymmetric positions")
 game.player.position=YinAdventure.chest_at("island_ruin",true);await frames()
 var before=game.state.equipment.size();game.interact();await frames()
 check("island_ruin" in game.state.opened_chests and game.state.equipment.size()==before+1,"normal E interaction awards the real coastal cache")
 game.interact();await frames()
 check(game.state.equipment.size()==before+1,"coastal cache cannot duplicate rewards")
 check(FarmState.new().restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))),"coastal reward persists in existing save schema")
 var left=env.wilderness29.props.filter(func(p):return p.art=="ruin_left")[0]
 var right=env.wilderness29.props.filter(func(p):return p.art=="ruin_right")[0]
 for arch in [left,right]:check(game.world.clear_body_path(arch.position+Vector2(0,25),arch.position-Vector2(0,35),Vector2(8,6)),"actual player capsule can pass through "+arch.art)
 game.player.position=left.position+Vector2(0,-35);await frames(25)
 check(left.sprite.modulate.a<.7,"arch softens when it occludes player")
 game.player.position=left.position+Vector2(0,45);await frames(25)
 check(left.sprite.modulate.a>.9,"arch returns opaque in front of player")
 for item in [["forest",Vector2(5100,4216),720],["grave-day",Vector2(4808,3392),840],["grave-moon",Vector2(4808,3392),1140],["coast",Vector2(5552,2160),900]]:
  if OS.get_environment("YINTIAN_SCENE29")!="" and OS.get_environment("YINTIAN_SCENE29")!=item[0]:continue
  game.player.position=item[1];game.state.minutes=item[2]
  env.regional.forced_event="bloodmoon" if item[0]=="grave-moon" else "clear"
  game.state.weather="sun";await frames(100)
  await capture(item[0])
  if DisplayServer.get_name()!="headless" and OS.get_environment("YINTIAN_CAPTURE_DIR")!="":
   game.hud.hide();await capture(item[0]+"-world");game.hud.show()
 game.queue_free();await frames()
 print("LAND29 RESULT ",checks," checks ",failures," failures");quit(1 if failures else 0)
