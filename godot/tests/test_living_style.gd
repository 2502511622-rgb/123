extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node2D
var folder: String
func check(ok: bool, message: String) -> void:
	checks += 1
	print("LIVING ", "PASS " if ok else "FAIL ", message)
	if not ok: failures += 1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT","1")
	folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
	call_deferred("run")
func frames(count: int = 4) -> void:
	for i in range(count): await physics_frame
func capture(name_value: String) -> void:
	game.player.get_node("Camera2D").reset_smoothing()
	game.player.get_node("Camera2D").force_update_scroll()
	await frames()
	if folder=="" or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))==OK,"actual scene capture "+name_value)
func path_in_grass(grass: YinLivingGrass) -> Vector2:
	for y in range(365,460,8):
		for x in range(400,550,8):
			var valid: bool = true
			for step in range(0,65,4): valid = valid and grass.grass_at(Vector2(x+step,y))
			if valid: return Vector2(x,y)
	return Vector2.ZERO
func run() -> void:
	var atlas: Dictionary = YinActorArt.atlas()
	check(atlas.hero_walk.size()==4 and atlas.hero_walk.all(func(row): return row.size()==8),"32 individually drawn walking frames")
	check(atlas.hero_attack.size()==4 and atlas.hero_attack.all(func(row): return row.size()==6),"24 individually drawn combat frames")
	check(atlas.npc.size()==4 and atlas.npc.all(func(row): return row.size()==6),"six NPC identities with 24 idle walk and talk poses")
	for direction in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
		var frames_seen: Array = []
		var attack_seen: Array = []
		for i in range(8): frames_seen.append(YinActorArt.hero_motion_pose(direction,(i+0.1)/16.0,true,0,0).source)
		for i in range(6): attack_seen.append(YinActorArt.hero_motion_pose(direction,0,false,0.22*(1.0-(i+0.1)/6.0),0).source)
		var unique_walk: Dictionary = {}
		var unique_attack: Dictionary = {}
		for item in frames_seen: unique_walk[item]=true
		for item in attack_seen: unique_attack[item]=true
		check(unique_walk.size()==8 and unique_attack.size()==6,"walk and combat selectors traverse every frame for "+str(direction))
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state.intro_seen=true
	game.state.factions.last_day=game.state.day
	game.state.weather="sun"
	game.state.minutes=930
	check(game.world.grass.baked and game.world.grass.blade_count>100,"farm builds actual instanced grass")
	check(not game.world.grass.grass_at(Vector2(336,272)) and not game.world.grass.grass_at(Vector2(656,400)),"grass avoids farm plots and river")
	check(game.world.environment.soil_material!=null,"farm soil uses matching material")
	game.state.plots[0].tilled=true
	game.state.plots[0].watered=true
	game.world.environment.refresh_soil()
	var plot_map: Texture2D=game.world.environment.soil_material.get_shader_parameter("plots")
	check(plot_map.get_image().get_pixel(0,0).r>0.9 and plot_map.get_image().get_pixel(0,0).g>0.9,"tilled and watered plot state reaches material")
	game.player.position=Vector2(416,272)
	await capture("style17-farm")
	game.travel("village")
	await frames(8)
	var grass: YinLivingGrass=game.world.grass
	check(grass.blade_count>1000 and grass.chunks.size()>10,"village grass grouped in spatial batches")
	check(grass.visible_chunks<grass.chunks.size(),"offscreen grass batches are culled")
	var start: Vector2=path_in_grass(grass)
	check(start!=Vector2.ZERO,"find actual traversable grass path")
	game.player.position=start
	grass.last_position=start
	await frames()
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	await frames(2)
	check(game.player.position.x>start.x+15 and not grass.trails.is_empty(),"real movement in grass leaves bending trail")
	var at: Vector2=grass.trails[-1].at if not grass.trails.is_empty() else start
	check(grass.sample_reaction(at)>0.5,"foot contact has a strong local reaction")
	check(grass.material_back.get_shader_parameter("trail_count")>0 and grass.material_front.get_shader_parameter("foreground"),"reaction uploaded to both rooted grass passes")
	check(grass.material_back.get_shader_parameter("world_size")==game.world.level_size,"per-blade custom coordinates match actual map dimensions")
	var age: float=grass.trails[-1].age if not grass.trails.is_empty() else 0
	var clock: float=grass.clock
	game.show_pause()
	await frames(10)
	check(grass.clock==clock and (grass.trails.is_empty() or grass.trails[-1].age==age),"pause freezes grass and bend recovery")
	game.close_modal()
	game.player.position=start+Vector2(96,0)
	await frames(90)
	check(grass.trails.size()<=12 and grass.sample_reaction(at)<0.01,"bent grass recovers; trail population bounded")
	game.player.position=Vector2(540,256)
	await capture("style17-village")
	check(game.world.environment.terrain_types.get_image().get_pixel(17,9).r>16.0/255.0,"actual connected road types uploaded for material mapping")
	var villagers: Array=get_nodes_in_group("villagers").filter(func(n): return n.get_parent()==game.world.actors)
	check(villagers.size()==6 and villagers.all(func(n): return YinActorArt.npc_pose(n.record.id,0,false).texture==YinActorArt.NPC),"all six living NPCs use new art")
	game.player.position=Vector2(540,610)
	await capture("style17-npc")
	game.state.weather="rain"
	game.state.minutes=1260
	await frames(20)
	await capture("style17-rain-night")
	game.state.weather="sun"
	game.state.minutes=930
	if folder!="" and DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute(folder.path_join("walk-frames"))
		game.player.position=start
		grass.last_position=start
		await frames(8)
		Input.action_press("move_right")
		for i in range(48):
			await frames(2)
			game.player.get_node("Camera2D").reset_smoothing()
			game.player.get_node("Camera2D").force_update_scroll()
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder.path_join("walk-frames/frame-%03d.png"%i))==OK,"walking grass frame "+str(i))
		Input.action_release("move_right")
		await frames()
		print("LIVING CAPTURE includes PNG readback; process_ms=",Performance.get_monitor(Performance.TIME_PROCESS)*1000," render_draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," visible_chunks=",grass.visible_chunks," total_chunks=",grass.chunks.size()," blades=",grass.blade_count)
	game.travel("island")
	game.player.position=Vector2(1480,360)
	await capture("style17-island")
	game.travel("temple")
	game.player.position=Vector2(1136,240)
	await capture("style17-temple")
	game.travel("hall")
	await frames()
	check(game.world.grass.baked and game.world.grass.blade_count==0,"interior does not create outdoor vegetation")
	await capture("style17-interior")
	check(FarmState.new().restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))),"visual upgrades preserve save round trip")
	game.queue_free()
	await frames()
	print("LIVING RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
