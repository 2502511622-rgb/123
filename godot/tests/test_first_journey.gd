extends SceneTree
var game: Node2D
var checks: int=0
var failures: int=0
func check(ok: bool,label_value: String):
	checks+=1;print("FIRST ","PASS " if ok else "FAIL ",label_value)
	if not ok:failures+=1
func _initialize():
	OS.set_environment("YINTIAN_SILENT","1");call_deferred("run")
func frames(n: int=3):
	for i in range(n):await physics_frame
func find_button(node: Node,fragment: String) -> Button:
	for child in node.get_children():
		if child is Button and fragment in child.text:return child
		var found: Button=find_button(child,fragment)
		if found!=null:return found
	return null
func click(control: Button):
	check(control!=null,"available button")
	if control==null:return
	var parent: Node=control.get_parent()
	while parent!=null:
		if parent is ScrollContainer:parent.ensure_control_visible(control)
		parent=parent.get_parent()
	await process_frame
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=control.get_global_rect().get_center();event.pressed=pressed
		root.push_input(event,true);await frames(1)
func key(code: int):
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
		Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
func capture(name_value: String):
	var folder: String=OS.get_environment("YINTIAN_CAPTURE_DIR")
	if folder=="" or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(folder)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))==OK,"render "+name_value)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(4)
	await click(find_button(game.modal,"收起遗书"))
	check(game.state.quests.has("first_watch"),"intro starts a concrete commission")
	var before: Dictionary=game.state.quests.duplicate(true)
	YinFirstJourney.start(game.state)
	check(game.state.quests==before,"starting again preserves progress")
	check(game.world.path_to(game.player.position,YinFirstJourney.guide(game.state).at).size()>0,"tutorial exit has a complete route")
	await capture("first21-start")
	game.show_character("随从");await process_frame
	check(find_button(game.modal,"全员随行")==null and find_button(game.modal,"追踪初次守夜")!=null,"empty follower page provides one useful action")
	game.close_modal();game.travel("graveyard");await frames(4)
	var actors: Array=get_nodes_in_group("enemies")
	check(actors.size()==5 and actors.any(func(e):return e.record.kind=="archer"),"first-day cemetery contains melee and ranged encounters")
	for actor in actors:actor.stun=100
	game.player.invincible=100
	game.combat.select_weapon("sword")
	for index in range(2):
		var actor: YinEnemy=actors[index]
		var record: Dictionary=actor.record
		game.player.position=actor.position+Vector2(0,34)
		game.player.facing=Vector2.UP
		for swing in range(12):
			if record.dead:break
			game.player.position=actor.position+Vector2(0,34);game.player.facing=Vector2.UP
			game.action_cooldown=0;game.player.state_machine.reset()
			await key(KEY_J);await frames(22)
		check(record.dead,"real keyboard sword attacks kill tutorial guard "+str(index))
	check(YinAdventure.progress(game.state,"first_watch")==2,"actual deaths complete commission")
	check("返回" in YinFirstJourney.guide(game.state).hint,"completion changes objective to return route")
	var money: int=game.state.money
	check("返回" in YinAdventure.claim(game.state,"first_watch",0) and game.state.money==money,"cannot claim remotely from battlefield")
	var restored:=FarmState.new()
	check(restored.restore(game.state.snapshot()) and YinAdventure.progress(restored,"first_watch")==2,"partial journey persists through existing save format")
	game.travel("farm");await frames(4)
	game.show_quests();await process_frame;await process_frame
	check(not game.modal.get_node("ModalCard/Layout/Scroll").get_h_scroll_bar().visible,"opening instructions cannot create horizontal scrolling")
	await capture("first21-report")
	await click(find_button(game.modal,"复命 · 领取银剑"))
	check(game.state.quests.first_watch.claimed and game.state.money==money+35,"UI turn-in grants exact money")
	var reward: Array=game.state.equipment.filter(func(g):return g.weapon=="silver_sword" and g.tier==2)
	check(reward.size()==1 and "换上" in YinFirstJourney.guide(game.state).get("hint",""),"reward is unique tier-two silver sword with equip objective")
	var count: int=game.state.equipment.size()
	YinAdventure.claim(game.state,"first_watch",0)
	check(game.state.equipment.size()==count and game.state.money==money+35,"reward cannot be duplicated")
	game.show_equipment();await process_frame
	var choice: Button=find_button(game.modal,"对比桃木剑")
	check(choice!=null and "伤害+" in choice.text,"equipment compares reward with current melee")
	check(choice!=null and choice.get_global_rect().position.y<260,"new reward is visible on first equipment screen")
	await capture("first21-comparison")
	await click(choice)
	check(not reward.is_empty() and game.state.weapon_slots.melee==reward[0].id and YinFirstJourney.guide(game.state).is_empty(),"actual equip click completes the opening loop")
	await capture("first21-equipped")
	game.close_modal()
	game.state.equip(1)
	check(YinFirstJourney.guide(game.state).is_empty(),"later weapon swaps do not restart completed onboarding")
	var finished:=FarmState.new()
	check(finished.restore(game.state.snapshot()) and finished.quests.first_watch.get("equipped",false),"completed onboarding remains complete after save and reload")
	var old:=FarmState.new();old.intro_seen=true
	check(YinFirstJourney.guide(old).is_empty(),"existing players are not forced into tutorial")
	game.state=old;game.show_quests();await process_frame
	check(find_button(game.modal,"接取 · 初次守夜")!=null,"existing players may opt in")
	YinFirstJourney.start(old)
	YinAdventure.accept(old,"grave_patrol")
	check(YinFirstJourney.guide(old).is_empty(),"explicitly tracking another commission hides tutorial guidance")
	old.quests.first_watch.progress=2;old.zone="farm"
	while old.equipment.size()<20:old.grant_gear("sword")
	var old_money: int=old.money
	check("已满" in YinAdventure.claim(old,"first_watch",0) and not old.quests.first_watch.claimed and old.money==old_money,"full equipment rejects reward without losing commission")
	print("FIRST RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
