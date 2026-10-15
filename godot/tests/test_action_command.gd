extends SceneTree
var game: Node2D
var checks: int=0
var failures: int=0
var folder: String
func check(ok: bool,message: String) -> void:
	checks+=1
	print("ACTION ","PASS " if ok else "FAIL ",message)
	if not ok:failures+=1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT","1")
	folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
	call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func mouse(button_value: int,at: Vector2) -> void:
	for down in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=button_value
		event.position=at
		event.pressed=down
		root.push_input(event,true)
		await frames(1)
func capture(name_value: String) -> void:
	if folder=="" or DisplayServer.get_name()=="headless":return
	game.player.get_node("Camera2D").reset_smoothing()
	game.player.get_node("Camera2D").force_update_scroll()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))==OK,"capture "+name_value)
func find_button(node: Node,fragment: String) -> Button:
	for child in node.get_children():
		if child is Button and fragment in child.text:return child
		var found: Button=find_button(child,fragment)
		if found!=null:return found
	return null
func click(control: Control) -> void:
	check(control!=null,"available UI action")
	if control==null:return
	var ancestor: Node=control.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:ancestor.ensure_control_visible(control)
		ancestor=ancestor.get_parent()
	await process_frame
	await mouse(MOUSE_BUTTON_LEFT,control.get_global_rect().get_center())
func grass_geometry() -> void:
	if DisplayServer.get_name()=="headless":return
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(64,64)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var multi:=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_2D
	multi.use_custom_data=true
	var mesh:=QuadMesh.new()
	mesh.size=Vector2(3,14)
	multi.mesh=mesh
	multi.instance_count=1
	multi.set_instance_transform_2d(0,Transform2D(0,Vector2(32,40)))
	multi.set_instance_custom_data(0,Color(0.5,0.5,0.625,1))
	var blade:=MultiMeshInstance2D.new()
	blade.multimesh=multi
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://shaders/living_grass.gdshader")
	mat.set_shader_parameter("world_size",Vector2(64,64))
	mat.set_shader_parameter("wind",0.0)
	blade.material=mat
	viewport.add_child(blade)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var pixels: Image=viewport.get_texture().get_image()
	var above: int=0
	var below: int=0
	for y in range(64):
		for x in range(64):
			if pixels.get_pixel(x,y).a>0.05:
				if y<40:above+=1
				else:below+=1
	check(above>0 and below==0,"rendered grass grows upward from rooted base, never upside down")
	viewport.queue_free()
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	game.close_modal()
	game.state.intro_seen=true
	game.state.factions.last_day=game.state.day
	game.travel("graveyard")
	await frames(4)
	for actor in get_nodes_in_group("enemies"):actor.set_physics_process(false)
	var enemy: YinEnemy=game.nearest_enemy(Vector2(280,240),50)
	enemy.record.hp=2000;enemy.record.max_hp=2000
	game.player.position=enemy.position+Vector2(0,34)
	game.player.invincible=100
	game.combat.select_weapon("sword")
	# Isolate cancellation from independently timed bleed/enchantment damage.
	game.state.current_gear().affixes=[]
	game.state.current_gear().enchantment=""
	game.player.get_node("Camera2D").reset_smoothing()
	game.player.get_node("Camera2D").force_update_scroll()
	await process_frame
	var at: Vector2=game.world.get_global_transform_with_canvas()*enemy.position
	var energy: int=game.state.energy
	await mouse(MOUSE_BUTTON_RIGHT,at)
	check(game.player.heavy_attack and game.player.attack_duration>0.6 and game.combat.pending.get("heavy",false),"actual right mouse starts distinct heavy windup")
	check(game.state.energy==energy-14,"heavy consumes exactly fourteen energy")
	await frames(10)
	check(enemy.record.hp==2000 and game.player.state_machine.current=="attack","heavy cannot damage early or end its action during windup")
	await capture("action-heavy-windup")
	var contact_pause: bool=false
	for i in range(16):
		await frames(1)
		if enemy.record.hp<2000:
			contact_pause=game.player.hit_pause>0
			break
	check(enemy.record.hp<2000 and enemy.stun>=0.10 and contact_pause,"heavy release applies damage stagger and weighty contact freeze")
	check(not get_nodes_in_group("combat_vfx").is_empty(),"impact creates layered animated VFX")
	enemy.set_physics_process(true)
	enemy.stun=100
	await capture("action-heavy-impact")
	await frames(40)
	game.action_cooldown=0
	game.player.dodge_cooldown=0
	var before: int=enemy.record.hp
	await mouse(MOUSE_BUTTON_RIGHT,at)
	game.player.dodge()
	await frames(25)
	check(enemy.record.hp==before and game.combat.pending.is_empty(),"dodge cancel prevents delayed heavy damage")
	game.player.state_machine.reset();game.player.dodge_time=0;game.action_cooldown=0
	game.state.energy=13
	check(not game.combat.heavy() and game.state.energy==13,"insufficient energy rejects heavy without partial spending")
	for kind in YinWeaponArt.atlas():
		check(YinWeaponArt.icon(kind).atlas==YinWeaponArt.SHEET and YinWeaponArt.icon(kind).region.has_area(),"real weapon sprite source "+kind)
	game.show_equipment()
	await process_frame
	await process_frame
	var equipped: Button=find_button(game.modal,"已装备")
	check(equipped!=null and equipped.size.y<=90 and game.modal.get_node("ModalCard").get_global_rect().end.x<=640,"high-resolution weapon art cannot expand equipment cards beyond viewport")
	await capture("action-equipment")
	game.close_modal()
	check(game.player.weapon_layer.material.get_shader_parameter("avatar_enabled")==false,"held weapon has independent material and cannot inherit avatar hair or coat colors")
	game.player.facing=Vector2.UP
	await frames(2)
	check(game.player.weapon_layer.show_behind_parent and game.player.weapon_layer.z_index==0,"north-facing weapon sits behind its actor without escaping world depth sorting")
	game.player.facing=Vector2.DOWN
	# Unlimited deployment and persistent village assignments are independent of roster capacity.
	game.state.spirits=[]
	for i in range(7):game.state.spirits.append(game.state.make_spirit("water",0))
	for spirit in game.state.spirits:game.state.deploy_spirit(spirit.id,true)
	check(game.state.deployment_used()==7,"seven owned followers deploy together without point cap")
	var restored:=FarmState.new()
	# Increase capacity through existing progression solely to construct a legal large-roster save.
	game.state.cultivation=1600
	game.state.skill_ranks.command=3
	check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))),"unlimited deployed roster survives actual save validation")
	game.travel("village")
	await frames(4)
	check(get_nodes_in_group("companions").filter(func(c):return not c.is_queued_for_deletion() and c.get_parent()==game.world.actors).size()==7,"all seven appear as live companion actors")
	game.state.villagers[1].hp=25
	game.show_character("随从")
	await frames(3)
	await click(find_button(game.modal,"智能驻村"))
	check(game.state.village_guards().size()==7 and game.state.spirits[0].guard_villager==int(game.state.villagers[1].id),"smart command assigns healthy followers to vulnerable villagers")
	await capture("action-companion-command")
	game.close_modal()
	game.travel("island")
	await frames(3)
	check(get_nodes_in_group("companions").filter(func(c):return not c.is_queued_for_deletion() and c.get_parent()==game.world.actors).is_empty(),"village guards remain stationed when player travels")
	game.state.assign_spirit(game.state.spirits[0].id,"follow")
	game.spawn_spirits()
	await frames(3)
	check(get_nodes_in_group("companions").filter(func(c):return not c.is_queued_for_deletion() and c.get_parent()==game.world.actors).size()==1,"recall from village produces only the selected follower")
	await capture("action-new-monsters")
	var defense:=FarmState.new()
	defense.zone="farm";defense.raid_status="warned";defense.raid_day=1;defense.minutes=1080
	for i in range(4):
		var guard: Dictionary=defense.make_spirit("boss",0)
		defense.spirits.append(guard)
		defense.assign_spirit(guard.id,"village",1)
	defense.update_raid()
	var total: int=0
	for record in defense.enemies:total+=int(record.hp)
	defense.minutes+=40
	defense.update_raid()
	var after: int=0
	for record in defense.enemies:after+=int(record.hp)
	check(after<total,"stationed followers fight a village raid while player is elsewhere")
	var repeat: Array=defense.enemies.duplicate(true)
	defense.update_raid()
	check(defense.enemies==repeat,"same-time guard updates cannot multiply damage")
	var conflict:=FarmState.new()
	conflict.factions.last_day=1;conflict.zone="farm";conflict.minutes=720
	var war: Dictionary=YinFactions.declare(conflict,"island","temple")
	YinFactions.deploy(conflict,war)
	var armies: Array=conflict.enemies.duplicate(true)
	conflict.minutes=780
	YinFactions.tick(conflict)
	check(conflict.enemies!=armies,"offscreen opposing armies exchange actual damage before settlement")
	check("支援" in YinFactions.choose_side(conflict,int(war.id),"defender"),"player can choose a side in a live conflict")
	var friendly: Dictionary=YinFactions.survivors(conflict,war,"defender")[0]
	check(YinFactions.friendly(conflict,friendly),"chosen army becomes friendly")
	check("不能" in YinFactions.choose_side(conflict,int(war.id),"attacker"),"cannot repeatedly switch sides to exploit immunity")
	check(restored.restore(JSON.parse_string(JSON.stringify(conflict.snapshot()))),"ongoing attrition and alliance survive save roundtrip")
	game.close_modal()
	game.state=conflict
	game.build_zone("temple",Vector2(180,1080))
	await frames(4)
	game.show_factions()
	await capture("action-war-panel")
	game.close_modal()
	var soft: AudioStreamWAV=YinAudioManager.synth_cue("sword")
	var heavy: AudioStreamWAV=YinAudioManager.synth_cue("heavy")
	var audio_energy: float=0
	var peak: float=0
	for offset in range(0,heavy.data.size(),2):
		var value: float=float(heavy.data.decode_s16(offset))/32767.0
		audio_energy+=value*value
		peak=maxf(peak,absf(value))
	check(heavy.data.size()>soft.data.size() and audio_energy>1 and peak<=0.801,"light and heavy impact audio produce distinct non-clipping PCM streams")
	var legacy: Dictionary=FarmState.new().snapshot()
	var older:=FarmState.new()
	var wounded: Dictionary=older.make_spirit("water",0)
	wounded.hp=21;wounded.max_hp=42
	wounded.erase("assignment");wounded.erase("guard_villager")
	legacy.version=12;legacy.erase("defense_minute")
	legacy.spirits=[wounded];legacy.next_id=older.next_id
	check(restored.restore(legacy) and restored.spirits[0].hp==24 and restored.spirits[0].max_hp==48 and restored.spirits[0].assignment=="follow","version twelve followers migrate with proportional health and safe default orders")
	await grass_geometry()
	if folder!="" and DisplayServer.get_name()!="headless":
		game.travel("graveyard")
		for record in game.state.enemies:record.dead=true
		for actor in get_nodes_in_group("enemies")+get_nodes_in_group("faction_guards"):actor.queue_free()
		await frames(3)
		for i in range(6):
			game.state.spawn_record(["water","bone","brute","kappa","jorogumo","hungry_ghost"][i],"graveyard",Vector2(350+i%3*76,270+i/3*64),1)
		game.spawn_enemies()
		for actor in get_nodes_in_group("enemies"):actor.set_physics_process(false)
		game.player.position=Vector2(425,365)
		game.player.held_item="silver_sword"
		await capture("action-monsters-native")

	if folder!="" and DisplayServer.get_name()!="headless":
		game.travel("farm")
		game.player.position=Vector2(250,380)
		game.state.weather="sun"
		game.combat.select_weapon("sword")
		game.action_cooldown=0
		var clips: String=folder.path_join("motion")
		DirAccess.make_dir_recursive_absolute(clips)
		Input.action_press("move_right")
		for i in range(60):
			if i==10:game.combat.heavy()
			if i==42:game.player.dodge()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(clips.path_join("frame-%03d.png"%i))
		Input.action_release("move_right")
	print("Action and command: %d checks, %d failures"%[checks,failures])
	game.queue_free()
	await frames(2)
	quit(1 if failures else 0)
