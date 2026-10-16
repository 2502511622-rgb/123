extends SceneTree
var game
var checks=0
var failures=0
func _initialize():OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func check(ok: bool,label_value: String):
 checks+=1;print("REGIONAL ","PASS " if ok else "FAIL ",label_value)
 if not ok:failures+=1
func frames(n: int=3):
 for i in range(n):await physics_frame
func capture(label_value: String):
 if DisplayServer.get_name()=="headless" or OS.get_environment("YINTIAN_CAPTURE_DIR")=="":return
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(folder.path_join(label_value+".png"))==OK,"capture "+label_value)
func place(at: Vector2):
 game.player.position=at;game.player.velocity=Vector2.ZERO
 game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
 await frames(3)
func probe_edges():
 var viewport=SubViewport.new();viewport.size=Vector2i(8,8);viewport.transparent_bg=true;viewport.world_2d=World2D.new()
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var pixels=Image.create(8,8,false,Image.FORMAT_RGBA8);pixels.fill_rect(Rect2i(1,1,6,6),Color.WHITE)
 var sprite=Sprite2D.new();sprite.centered=false;sprite.texture=ImageTexture.create_from_image(pixels);sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var shader=ShaderMaterial.new();shader.shader=preload("res://shaders/hit_flash.gdshader");sprite.material=shader;viewport.add_child(sprite)
 await process_frame;await RenderingServer.frame_post_draw
 var image=viewport.get_texture().get_image()
 check(image.get_pixel(1,3).r<0.8,"renderer suppresses bright matte at the actual sprite edge")
 check(image.get_pixel(3,3).r>0.95,"edge treatment preserves interior white hair and cloth")
 check(image.get_pixel(0,3).a==0,"edge treatment does not add an exterior outline")
 shader.set_shader_parameter("flash",1.0);await process_frame;await RenderingServer.frame_post_draw
 check(viewport.get_texture().get_image().get_pixel(1,3).r>0.95,"strong hit flash remains visible after edge cleanup")
 viewport.queue_free()
func run():
 var events: Dictionary={}
 for day in range(1,31):
  events[YinRegionalClimate.forecast(Vector2(1504,864),day,900,"sun")]=true
 check(events.has("sandstorm") and events.has("clear"),"desert storms are probabilistic, not permanent")
 check(YinRegionalClimate.forecast(Vector2(4896,960),1,900,"rain")=="snow","island converts the wet weather front into heavy snow")
 var nights: Dictionary={}
 for day in range(1,31):nights[YinRegionalClimate.forecast(Vector2(4896,3552),day,1260,"sun")]=true
 check(nights.has("bloodmoon") and nights.has("clear"),"mountain blood moons occur on some nights")
 check(YinRegionalClimate.forecast(Vector2(1504,3552),1,900,"rain")=="rain","village retains ordinary rain")
 if DisplayServer.get_name()!="headless":await probe_edges()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(5);game.close_modal()
 game.state.minutes=1035;game.state.weather="sun";game.player.invincible=1000
 for e in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):e.set_physics_process(false)
 var env: YinEnvironment=game.world.environment;var climate=env.regional
 check(climate!=null and env.baked,"continuous map installs local climate controller")
 for id in YinBiomeArt.SIZES:
  check(YinBiomeArt.texture(id).get_size()==Vector2(YinBiomeArt.SIZES[id]),id+" imports at normalized pixel dimensions")
 var biome=game.world.actors.get_children().filter(func(n):return n.has_meta("biome_prop"))
 check(biome.any(func(n):return n.get_meta("biome_prop")=="desert_hall") and biome.any(func(n):return n.get_meta("biome_prop")=="desert_buddha"),"desert has ruined temple hall and eroded Buddha")
 check(biome.filter(func(n):return n.get_meta("biome_prop")=="edo_shop").size()==4 and biome.filter(func(n):return n.get_meta("biome_prop")=="edo_house").size()==4,"Edo town has two actual rows of ruined shopfronts")
 check(biome.any(func(n):return n.get_meta("biome_prop")=="mountain_crag") and biome.any(func(n):return n.get_meta("biome_prop")=="burial_cairn"),"graveyard uses crags and irregular burial cairns")
 check(not game.world.grass.grass_at(Vector2(1400,900)),"desert contains no lush village grass")
 check(not game.world.grass.grass_at(Vector2(4896,960)),"Edo main street stays clear of floating grass blades")
 await place(Vector2(1504,864));climate.forced_event="clear";await frames(10)
 check(float(game.atmosphere.lighting.get_shader_parameter("warmth"))>0.8,"sunset mixes warm directional light with scene lighting")
 await capture("desert-temple-sunset")
 climate.forced_event="sandstorm";await frames(115)
 check(climate.dust>0.8 and env.wind>1 and env.rain<0.05,"sandstorm adds gusts without rain")
 check(float(game.player.material.get_shader_parameter("dust_cover"))>0.8,"player clothes receive local sand accumulation")
 var start=game.player.position;Input.action_press("move_right");await frames(24);Input.action_release("move_right")
 check(game.player.position.distance_to(start)>10 and climate.footprints.any(func(s):return s.type=="sand"),"real movement leaves sand tracks and ground dust")
 await capture("desert-sandstorm")
 await place(Vector2(4896,960));climate.forced_event="snow";await frames(115)
 check(climate.snow>0.8 and climate.dust<0.1,"regional transition replaces sandstorm with snowfall")
 check(float(env.terrain_material.get_shader_parameter("snow"))>0.8,"snow affects the ground material")
 check(float(game.player.material.get_shader_parameter("snow_cover"))>0.8,"snow settles on character clothing")
 Input.action_press("move_down");await frames(25);Input.action_release("move_down")
 check(climate.footprints.any(func(s):return s.type=="snow"),"snow walking leaves compressed dark tracks")
 await capture("edo-snow-street")
 # Every monster uses the shared impact feedback, including floating and boss enemies.
 for kind in YinBalance.MONSTERS:
  var e=YinEnemy.new();e.game=game;e.record=game.state.spawn_record(kind,"graveyard",Vector2.ZERO,1,false)
  e.position=game.player.position+Vector2(36,0);e.record.at=[e.position.x,e.position.y]
  e.record.hp=10000;e.record.max_hp=10000;e.record.suppressed=true
  game.world.actors.add_child(e);e.set_physics_process(false);e.shield=0
  e.receive_hit(1,"bullet")
  check(e.hit_flash>0 and e.model.modular!=null and e.model.modular.animation.is_playing(),kind+" receives flash, hit animation and impact feedback")
  e.queue_free()
 await frames(8)
 climate.forced_event="rain";game.state.minutes=900;await place(YinContinent.HOME+Vector2(0,96));await frames(115)
 check(env.rain>0.8 and env.wetness>0.2,"rain darkens the ground after a weather change")
 var npc=get_nodes_in_group("villagers")[0];npc.set_physics_process(false)
 npc.position=game.player.position+Vector2(30,0);npc.home=npc.position;npc.shelter_clock=0
 var npc_start=npc.position
 for i in range(40):npc.weather_shelter(1.0/60.0);await physics_frame
 check(npc.brain_state=="weather_shelter" and is_finite(npc.shelter_target.x),"NPC finds a real building awning in rain")
 check(npc.position.distance_to(npc_start)>2,"NPC actually moves toward shelter")
 climate.interact();npc.position+=Vector2(20,0);climate.interact()
 check(climate.footprints.any(func(s):return s.type=="wet"),"NPC movement produces wet ground interactions too")
 await capture("village-rain-interactions")
 await place(Vector2(4600,3400));game.state.minutes=1260;climate.forced_event="bloodmoon";await frames(115)
 check(climate.blood>0.8 and float(game.atmosphere.lighting.get_shader_parameter("bloodmoon"))>0.8,"blood moon actually changes scene illumination")
 await capture("mountain-bloodmoon")
 game.show_pause();var time=env.time;var dust=climate.dust;await frames(10)
 check(env.time==time and climate.dust==dust,"modal pause freezes regional weather and interactions")
 game.close_modal()
 check(climate.footprints.size()<=120 and climate.breaths.size()<=24,"weather interaction populations stay bounded")
 check(Engine.physics_ticks_per_second==60,"regional effects preserve 60 Hz physics")
 print("REGIONAL RESULT ",checks," checks, ",failures," failures")
 root.remove_child(game);game.queue_free();await frames(3);quit(1 if failures else 0)
