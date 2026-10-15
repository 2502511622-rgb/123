extends SceneTree
var game: Node2D
var checks: int=0
var failures: int=0
func check(ok: bool,label_value: String) -> void:
	checks+=1
	print("MODEL ","PASS " if ok else "FAIL ",label_value)
	if not ok:failures+=1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT","1")
	call_deferred("run")
func frames(n: int=3) -> void:
	for i in range(n):await physics_frame
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state=FarmState.new()
	game.state.intro_seen=true
	game.travel("graveyard")
	await frames()
	var sample: Dictionary=get_nodes_in_group("enemies")[0].record.duplicate(true)
	for enemy in get_nodes_in_group("enemies"):enemy.queue_free()
	await frames()
	game.player.position=Vector2(760,560)
	for kind in YinBalance.MONSTERS:
		var actor:=YinEnemy.new()
		actor.game=game
		actor.record=sample.duplicate(true);actor.record.kind=kind;actor.record.severed=[]
		actor.position=Vector2(440,540)
		actor.art_facing=Vector2.RIGHT
		game.world.actors.add_child(actor)
		actor.set_physics_process(false)
		await frames(1)
		check(actor.collision_mask==7 and actor.body_shape.shape is CapsuleShape2D,kind+" solid physical volume includes all actors")
		actor.model.present(kind,actor.art_pose(),[],0,true,false,Color.WHITE)
		check(actor.model.joints.size()>=(2 if kind in ["sogenbi","chochin"] else 4),kind+" independent articulated nodes")
		var transforms: Dictionary={}
		for joint in actor.model.joints:transforms[joint]=actor.model.joints[joint].transform
		var animated_pose: Dictionary=actor.art_pose()
		animated_pose.motion={"gait":PI/2,"action":0.7}
		actor.model.present(kind,animated_pose,[],0.3,true,true,Color.WHITE)
		var moved: bool=false
		var aligned: bool=true
		for part in YinActorArt.posed_parts(kind,animated_pose,0.3,true,true):
			var joint: YinRigJoint=actor.model.joints[part.pose.joint]
			moved=moved or joint.transform!=transforms[part.pose.joint]
			aligned=aligned and (joint.transform*joint.pose.destination.get_center()).distance_to(YinActorArt.part_center(part.pose))<0.01
		check(moved,kind+" real joint transforms animate")
		check(aligned,kind+" mirrored joint and detached source positions agree")

		var first: float=actor.motion.travel
		actor.motion.update(actor,0.1);actor.position.x+=12;actor.motion.update(actor,0.1)
		check(actor.motion.state=="move" and actor.motion.travel>first,kind+" gait follows actual displacement")
		actor.windup=0.3;actor.motion.update(actor,0.01)
		check(actor.motion.state=="anticipation",kind+" attack anticipation")
		actor.windup=0;actor.motion.update(actor,0.01)
		check(actor.motion.state=="strike",kind+" attack release")
		actor.motion.update(actor,0.2)
		check(actor.motion.state=="recover",kind+" attack recovery")
		actor.hit_stop=0.2
		var clock: float=actor.motion.time
		actor.motion.update(actor,0.1)
		check(actor.motion.time==clock,kind+" contact pause freezes articulated clock")
		actor.hit_stop=0
		actor.model.present(kind,actor.art_pose(),["head","leg"],0.3,true,false,Color.WHITE)
		for joint in actor.model.joints:
			if joint=="head" or joint=="leg":check(not actor.model.joints[joint].visible,kind+" amputated "+joint+" hidden on same rig")
		game.player.position=actor.position+Vector2(40,0)
		await frames(2)
		check(actor.test_move(actor.global_transform,Vector2(65,0)),kind+" blocks on player volume")
		game.player.position=Vector2(760,560)
		var other:=YinEnemy.new();other.game=game;other.record=actor.record.duplicate(true);other.position=actor.position+Vector2(40,0)
		game.world.actors.add_child(other);other.set_physics_process(false)
		await frames(2)
		check(actor.test_move(actor.global_transform,Vector2(65,0)),kind+" blocks on another monster volume")
		other.queue_free();await frames(2)
		# Add an isolated physical wall and exercise the real physics query.
		var wall:=StaticBody2D.new();var shape:=CollisionShape2D.new();var rectangle:=RectangleShape2D.new()
		rectangle.size=Vector2(8,100);shape.shape=rectangle;wall.position=actor.position+Vector2(40,0);wall.add_child(shape);game.world.add_child(wall)
		await frames(2)
		check(actor.test_move(actor.global_transform,Vector2(65,0)),kind+" physical wall blocks movement")
		wall.queue_free();actor.queue_free();await frames(1)
	for zone in ["farm","graveyard","forest","village","island","temple","sunken","theatre","hall","shop"]:
		game.build_zone(zone,Vector2(300,350))
		await frames(4)
		for actor in get_nodes_in_group("enemies"):actor.set_physics_process(false)
		var origin:=Vector2.ZERO
		for point in YinWorldLayout.points(zone):
			var approach: Vector2=point.at+Vector2(0,25)
			if not game.world.is_safe_position(approach):approach=point.at+Vector2(25,0)
			if not game.world.is_safe_position(approach):approach=point.at+Vector2(-25,0)
			for direction in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
				var candidate: Vector2=point.at+direction*32
				game.player.position=candidate
				if game.world.is_safe_position(candidate) and game.world.can_interact(point.at,point.range):
					approach=candidate;break
			game.player.position=approach
			await frames(1)
			check(game.world.can_interact(point.at,point.range),zone+" approachable interaction "+point.id)
			if point.to!="":
				if origin==Vector2.ZERO:origin=approach
				check(game.world.path_to(origin,approach).size()>0,zone+" complete path to "+point.id)
		if origin!=Vector2.ZERO:
			game.world.path_to(origin,origin,Vector2(17,9))
			check(game.world.navigation_cache.has(Vector2i(17,9)),zone+" large body navigation has independent clearance")
			var matches: bool=true
			for half in [Vector2(7,5),Vector2(17,9)]:
				game.world.path_to(origin,origin,half)
				var grid: AStarGrid2D=game.world.navigation_cache[Vector2i(half)]
				for y in range(0,grid.region.size.y,7):
					for x in range(0,grid.region.size.x,7):
						matches=matches and grid.is_point_solid(Vector2i(x,y))==not game.world.is_safe_position(Vector2(x*16+8,y*16+8),half)
			check(matches,zone+" optimized navigation agrees with physical obstacle clearance")

	await villager_selection()
	await landmark_actions()
	await gallery()
	print("MODEL RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)

func gallery() -> void:
	var folder: String=OS.get_environment("YINTIAN_CAPTURE_DIR")
	if folder=="" or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(folder)
	var view:=SubViewport.new();view.size=Vector2i(1280,800);view.transparent_bg=false
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var rigs: Array=[]
	for i in range(YinBalance.MONSTERS.size()):
		var rig:=YinMonsterRig.new();rig.position=Vector2(106+i%6*210,174+i/6*195);rig.scale=Vector2(2,2)
		view.add_child(rig);rigs.append(rig)
	for frame in range(18):
		for i in range(rigs.size()):
			var kind: String=YinBalance.MONSTERS.keys()[i]
			var pose: Dictionary=YinActorArt.enemy_pose(kind,Vector2.LEFT if i%2 else Vector2.RIGHT,frame/30.0,true,frame>10,kind in YinAbilities.BOSSES)
			pose.motion={"gait":frame*0.4,"action":sin(frame*0.3)*0.4}
			rigs[i].present(kind,pose,[],frame/30.0,true,frame>10,Color.WHITE)
		await process_frame
		await RenderingServer.frame_post_draw
		if frame in [0,6,12,17]:check(view.get_texture().get_image().save_png(folder.path_join("models20-"+str(frame)+".png"))==OK,"real articulated model render "+str(frame))
	view.queue_free()
	game.travel("forest");await frames(4)
	game.player.position=YinAdventure.LANDMARKS.camp.at+Vector2(0,70)
	game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join("map20-camp.png"))==OK,"actual redesigned forest landmark")
	game.player.position=YinAdventure.LANDMARKS.camp.at+Vector2(0,30)
	game.interact()
	check(game.modal!=null,"E interaction dispatch opens the nearest landmark menu")
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join("map20-camp-menu.png"))==OK,"actual landmark action menu")
	game.close_modal()


func landmark_actions() -> void:
	game.build_zone("forest",Vector2(2304,414));await frames(4)
	for actor in get_nodes_in_group("enemies"):actor.queue_free()
	await frames(2)
	game.player.position=YinAdventure.LANDMARKS.camp.at+Vector2(0,30)
	game.state.health=40;game.state.energy=40;game.state.money=100
	check(game.world.nearest_interaction()=="inspect_camp","nearby chest cannot steal closer camp interaction")
	var before: float=game.state.minutes
	check(game.use_landmark("camp").begins_with("完成") and game.state.health==60 and game.state.money==90 and is_equal_approx(game.state.minutes,before+20),"camp consumes money and time and restores player")
	game.state.money=0
	check(not game.use_landmark("camp").begins_with("完成") and game.state.health==60,"insufficient camp money cannot grant free restoration")
	game.player.position=YinAdventure.LANDMARKS.well.at+Vector2(0,30)
	game.player.poison_time=4;game.player.scorch_time=3;game.player.snare_time=2
	var energy: int=game.state.energy
	check(game.use_landmark("well").begins_with("完成") and game.player.poison_time==0 and game.player.scorch_time==0 and game.player.snare_time==0 and game.state.energy==energy-5,"well removes actual combat statuses with energy cost")
	check(not game.use_landmark("well").begins_with("完成") and game.state.energy==energy-5,"clean player cannot waste purification cost")
	game.player.position=YinAdventure.LANDMARKS.temple.at+Vector2(0,30)
	game.state.money=50
	var spirit: Dictionary=game.state.make_spirit("water",0);spirit.hp=1;game.state.spirits=[spirit]
	check(game.use_landmark("temple").begins_with("完成") and spirit.hp>1 and game.state.money==30,"ruined shrine restores real follower health")
	var wall:=StaticBody2D.new();var collision:=CollisionShape2D.new();var rectangle:=RectangleShape2D.new()
	rectangle.size=Vector2(60,4);collision.shape=rectangle;wall.add_child(collision);wall.position=game.player.position+Vector2(0,-12);game.world.add_child(wall)
	await frames(2)
	check(not game.world.can_interact(game.player.position+Vector2(0,-30),45),"interaction ray rejects an intervening wall")
	wall.queue_free()

func villager_selection() -> void:
	game.build_zone("village",Vector2(180,800));await frames(4)
	var citizens: Array=get_nodes_in_group("villagers").filter(func(actor):return not actor.is_queued_for_deletion())
	citizens[0].position=Vector2(212,800);citizens[1].position=Vector2(204,800)
	for actor in citizens:actor.set_physics_process(false)
	game.interact()
	check(game.modal!=null and game.modal.get_node("ModalCard/Layout").get_child(0).text==citizens[1].record.name,"E opens closest visible NPC rather than first spawned NPC")
	game.close_modal()
	var wall:=StaticBody2D.new();var shape:=CollisionShape2D.new();var rectangle:=RectangleShape2D.new()
	rectangle.size=Vector2(4,80);shape.shape=rectangle;wall.add_child(shape);wall.position=Vector2(192,800);game.world.add_child(wall)
	await frames(2)
	game.show_villager()
	check(game.modal==null,"NPC dialogue dispatch also rejects a wall")
	wall.queue_free()
