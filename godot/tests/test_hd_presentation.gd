extends SceneTree
var checks: int=0
var failures: int=0
var game: Node2D
func check(ok: bool,label_value: String):
	checks+=1;print("HD ","PASS " if ok else "FAIL ",label_value)
	if not ok:failures+=1
func _initialize():
	OS.set_environment("YINTIAN_SILENT","1");call_deferred("run")
func frames(n: int=3):
	for i in range(n):await physics_frame
func capture(name_value: String):
	var folder: String=OS.get_environment("YINTIAN_CAPTURE_DIR")
	if folder=="" or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(folder)
	game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))==OK,"capture "+name_value)
func run():
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/third_party/kenney/manifest.json"))
	for file in manifest.files:
		check(FileAccess.get_sha256("res://assets/third_party/kenney/"+file)==manifest.files[file].sha256,"unmodified credited CC0 source "+file)
	for weapon in YinBalance.MELEE:
		var light:=YinStrikeTimeline.resolve(weapon)
		var heavy:=YinStrikeTimeline.resolve(weapon,true)
		check(heavy.duration>light.duration and heavy.recovery>=heavy.duration and heavy.damage_scale>1,"data-driven distinct heavy timing "+weapon)
		var poses: Dictionary={}
		for i in range(100):poses[heavy.frame(heavy.duration*(i+0.1)/100)]=true
		check(poses.size()==6,"all six weighted authored attack poses remain reachable "+weapon)
	check(YinStrikeTimeline.pose_frame(0.49)==2 and YinStrikeTimeline.pose_frame(0.50)==3,"attack contact divides extension from follow-through")
	for direction in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
		check(YinActorArt.hero_pose(direction,0).texture==YinActorArt.HERO_ATTACK,"legacy gallery source remains available "+str(direction))
		var pose: Dictionary=YinActorArt.hero_motion_pose(direction,0,true,0,0)
		check(pose.texture==YinActorArt.PIXEL_WALK and pose.source.has_area() and pose.get("authored_frames",false),"current four-direction authored pixel walk source "+str(direction))
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(4)
	game.close_modal();game.state.intro_seen=true
	game.player.position=Vector2(300,350)
	game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
	await process_frame
	var target: Vector2=game.player.position+Vector2(41,-26)
	var screen: Vector2=game.world.get_global_transform_with_canvas()*target
	check(YinAimResolver.world_point(game.world,screen).distance_to(target)<0.01,"mouse conversion is inverse of actual camera canvas transform")
	check(YinAimResolver.direction(game.world,game.player,screen).distance_to(game.player.position.direction_to(target))<0.001,"aim direction survives camera offset")
	for zone in YinRegionStyle.STYLES:
		game.build_zone(zone,Vector2(300,350));await frames(4)
		for enemy in get_nodes_in_group("enemies"):enemy.stun=100
		var style: Dictionary=YinRegionStyle.profile(zone)
		var mat: ShaderMaterial=game.world.environment.terrain_material
		check(mat.get_shader_parameter("turf_tint")==Color(style.turf) and mat.get_shader_parameter("stone_tint")==Color(style.stone),zone+" uploads distinct regional terrain palette")
		check(YinRegionStyle.tree(zone,Vector2(50,50)) in YinWorldArt.REGIONS,zone+" vegetation uses current atlas")
		if zone=="temple":
			var walls: Array=get_nodes_in_group("diorama_walls").filter(func(node):return not node.is_queued_for_deletion())
			check(walls.size()>30 and walls.all(func(node):return node.get_parent()==game.world.actors),"raised courtyard walls share the actual actor depth-sort layer")
		if zone in ["farm","graveyard","forest","village","island","temple","sunken","theatre"]:
			var positions: Dictionary={"farm":Vector2(560,256),"graveyard":Vector2(360,340),"forest":Vector2(2304,440),"village":Vector2(540,350),"island":Vector2(224,1408),"temple":Vector2(656,800),"sunken":Vector2(700,650),"theatre":Vector2(1000,520)}
			game.player.position=positions[zone]
			game.state.minutes=1080 if zone in ["forest","temple","theatre"] else 840
			game.state.weather="rain" if zone=="sunken" else "sun"
			await capture("hd22-"+zone)
	game.build_zone("graveyard",Vector2(260,300));await frames(4)
	for enemy in get_nodes_in_group("enemies"):enemy.stun=100
	var foe: YinEnemy=game.nearest_enemy(game.player.position,1000)
	foe.position=game.player.position+Vector2(70,0)
	await process_frame;await process_frame
	check(game.quest_tracker.mouse_filter==Control.MOUSE_FILTER_IGNORE and game.quest_tracker.modulate.a<1,"combat dims objective and releases its mouse capture")
	game.player.state_machine.reset();game.action_cooldown=0
	var button:=InputEventMouseButton.new();button.button_index=MOUSE_BUTTON_LEFT;button.position=game.quest_tracker.get_global_rect().get_center();button.pressed=true
	root.push_input(button,true);await frames(1)
	check(game.modal==null and not game.combat.pending.is_empty(),"clicking through faded objective starts a world attack")
	button=InputEventMouseButton.new();button.button_index=MOUSE_BUTTON_LEFT;button.position=game.quest_tracker.get_global_rect().get_center();button.pressed=false;root.push_input(button,true)
	game.state=FarmState.new();game.state.intro_seen=true
	for i in range(2):
		var follower: Dictionary=game.state.make_spirit("water",0);game.state.spirits.append(follower);game.state.assign_spirit(follower.id,"follow")
	game.build_zone("farm",Vector2(300,350));await frames(8)
	var companions: Array=get_nodes_in_group("companions").filter(func(node):return not node.is_queued_for_deletion())
	check(companions.size()==2 and companions.all(func(node):return node.model is YinMonsterRig),"followers render through the same independently animated rig as enemies")
	check(game.world.navigation_cache.size()==1 and game.world.navigation_cache.has(Vector2i(7,5)),"followers reuse one world navigation cache instead of rebuilding grids per follower")
	game.show_equipment();await process_frame;await process_frame
	check(game.modal.get_node("ModalCard").get_global_rect().end.x<=640,"reworked equipment navigation stays inside viewport")
	await capture("hd22-equipment")
	print("HD RESULT ",checks," checks, ",failures," failures");quit(1 if failures else 0)
