extends SceneTree
var game: Node2D
var checks: int = 0
var failures: int = 0
var folder: String
func check(ok: bool,message: String) -> void:
	checks+=1
	print("JRPG ","PASS " if ok else "FAIL ",message)
	if not ok:failures+=1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT","1")
	folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
	call_deferred("run")
func frames(count: int = 4) -> void:
	for i in range(count):await physics_frame
func capture(name_value: String) -> void:
	game.player.get_node("Camera2D").reset_smoothing()
	game.player.get_node("Camera2D").force_update_scroll()
	await frames()
	if folder=="" or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))==OK,"capture "+name_value)
func click(control: Control) -> void:
	for down in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=control.get_global_rect().get_center()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		root.push_input(event,true)
	await frames()
func benchmark(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await frames(4)
	var start: int=Time.get_ticks_usec()
	for i in range(24):await process_frame
	print("JRPG BENCH ",label," average_frame_ms=",float(Time.get_ticks_usec()-start)/24000.0)
func run() -> void:
	check(YinAppearance.validate(YinAppearance.initial()),"default appearance valid")
	for key in YinAppearance.LABELS:
		var bad: Dictionary=YinAppearance.initial()
		bad[key]=YinAppearance.LABELS[key].size()
		check(not YinAppearance.validate(bad),"reject invalid appearance "+key)
	var bad_name: Dictionary=YinAppearance.initial()
	bad_name.name="\n"
	check(not YinAppearance.validate(bad_name),"reject empty and control-character names")
	for body in range(2):
		for direction in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
			var idle: Dictionary=YinActorArt.hero_motion_pose(direction,0,false,0,0,0.22,body)
			var attack: Dictionary=YinActorArt.hero_motion_pose(direction,0,false,0.12,0,0.22,body)
			var expected=YinActorArt.PIXEL_COMBAT if body==0 else YinActorArt.HERO_ATTACK
			check(idle.texture==expected and attack.texture==expected and Rect2(Vector2.ZERO,idle.texture.get_size()).encloses(idle.source),"JRPG neutral standing and combat source "+str(body)+str(direction))
	var legacy: Dictionary=FarmState.new().snapshot()
	legacy.version=10
	legacy.erase("appearance")
	var migrated:=FarmState.new()
	check(migrated.restore(legacy) and migrated.appearance==YinAppearance.initial(),"version ten save gains safe default appearance")
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state.intro_seen=true
	game.state.factions.last_day=game.state.day
	game.state.weather="sun"
	game.state.minutes=900
	game.travel("village")
	await frames()
	game.player.position=Vector2(540,256)
	await capture("jrpg-village")
	await benchmark("grass-on")
	game.world.grass.visible=false
	await benchmark("grass-hidden")
	game.world.grass.visible=true
	var original: Dictionary=game.state.appearance.duplicate(true)
	game.show_character("外观")
	await frames()
	var panel: YinAppearancePanel=game.modal.find_child("AppearancePanel",true,false)
	check(panel!=null and panel.controls.size()==8,"appearance panel exposes body and seven color selections")
	panel.controls.body.select(1)
	panel.controls.body.item_selected.emit(1)
	panel.controls.coat.select(2)
	panel.controls.coat.item_selected.emit(2)
	panel.controls.hair.select(3)
	panel.controls.hair.item_selected.emit(3)
	panel.controls.scarf.select(5)
	panel.controls.scarf.item_selected.emit(5)
	var name_input: LineEdit=panel.find_child("Name",true,false)
	name_input.text=""
	name_input.text_changed.emit("")
	await click(panel.find_child("Apply",true,false))
	check(game.state.appearance==original and panel.find_child("Apply",true,false).text=="请填写姓名","empty name gives feedback and preserves saved appearance")
	name_input.text="青岚"
	name_input.text_changed.emit("青岚")
	check(game.state.appearance==original and panel.draft.body==1,"preview edits are draft until saved")
	await capture("jrpg-appearance")
	var weapon: int=game.state.equipped_gear
	await click(panel.find_child("Apply",true,false))
	check(game.state.appearance.body==1 and game.state.appearance.coat==2 and game.player.appearance==game.state.appearance,"actual UI click applies customized appearance")
	check(game.player.material.get_shader_parameter("avatar_coat")==YinAppearance.COLORS.coat[2] and game.player.material.get_shader_parameter("avatar_hair")==YinAppearance.COLORS.hair[3],"selected colors reach live player shader")
	var saved:=FarmState.new()
	check(load("res://scripts/save_store.gd").load_game(saved) and saved.appearance==game.state.appearance and saved.equipped_gear==weapon,"customization persists without changing gear")
	game.close_modal()
	await capture("jrpg-customized")
	game.travel("farm")
	await frames()
	check(game.player.appearance==saved.appearance,"appearance follows scene travel")
	game.state.island_journal.defeated=["itsumade"]
	game.travel("island")
	await frames()
	for kind in ["kappa","ippon_datara","daitengu"]:
		var enemy: YinEnemy=get_nodes_in_group("enemies").filter(func(e):return e.record.kind==kind and e.get_parent()==game.world.actors)[0]
		enemy.set_physics_process(false)
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP]:
			enemy.art_facing=direction
			enemy.art_clock=0.37
			enemy.art_strike=0.18
			enemy.velocity=direction*35
			enemy.hit_flash=0.09
			enemy.record.severed=[]
			enemy.record.hp=roundi(enemy.record.max_hp*0.12)
			var expected: Array=YinActorArt.posed_parts(kind,enemy.art_pose(),enemy.art_clock,true,true).filter(func(piece):return piece.part in YinIsland.anatomy(kind))
			enemy.update_dismemberment()
			var fragments: Array=game.world.feedback.get_children().filter(func(node):return node is YinSeveredLimb)
			var aligned: bool=fragments.size()==expected.size()
			for part in expected:
				var matches: Array=fragments.filter(func(fragment):return fragment.part==part.part and fragment.joint==part.pose.joint and fragment.source_region==part.pose.source)
				if matches.size()!=1:aligned=false;continue
				var fragment: YinSeveredLimb=matches[0]
				aligned=aligned and fragment.source_texture==part.pose.texture and fragment.draw_size.is_equal_approx(part.pose.destination.size) and fragment.position.is_equal_approx(enemy.position+YinActorArt.part_center(part.pose)) and is_equal_approx(fragment.rotation,float(part.pose.rotation)*(-1.0 if part.pose.flip else 1.0))
			check(aligned,kind+" detached fragments match moving attacking pose, flip, pivot and scale "+str(direction))
			for fragment in fragments:fragment.free()
			enemy.record.severed=[]
			enemy.record.hp=enemy.record.max_hp
	var limping: YinEnemy=get_nodes_in_group("enemies").filter(func(e):return e.record.kind=="kappa" and e.get_parent()==game.world.actors)[0]
	limping.art_strike=0
	limping.hit_flash=0
	limping.set_physics_process(true)
	limping.record.severed=["leg"]
	var clock_before: float=limping.art_clock
	await frames(10)
	var injured_gait: float=limping.art_clock-clock_before
	limping.record.severed=[]
	clock_before=limping.art_clock
	await frames(10)
	check(limping.art_clock-clock_before>injured_gait*1.3,"injured gait advances more slowly over the same physics interval")
	limping.set_physics_process(false)
	var tengu: YinEnemy=get_nodes_in_group("enemies").filter(func(e):return e.record.kind=="daitengu")[0]
	game.player.position=Vector2(1480,360)
	tengu.position=Vector2(1568,350)
	tengu.art_facing=Vector2.LEFT
	tengu.hit_flash=0
	tengu.art_strike=0.18
	tengu.velocity=Vector2.LEFT*35
	tengu.queue_redraw()
	await capture("jrpg-tengu-attack")
	tengu.record.hp=roundi(tengu.record.max_hp*0.12)
	tengu.update_dismemberment()
	await frames(16)
	await capture("jrpg-tengu-severed")
	check(FarmState.new().restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))),"JRPG art, appearance and severed state round trip")
	game.queue_free()
	await frames()
	print("JRPG RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
