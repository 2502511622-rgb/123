extends SceneTree
var game: Node2D
var checks: int=0
var failures: int=0
var folder: String
func check(ok: bool,message: String) -> void:
	checks+=1
	print("PLAYTEST ","PASS " if ok else "FAIL ",message)
	if not ok:failures+=1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT","1")
	folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func key(code: int) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new()
		event.physical_keycode=code
		event.keycode=code
		event.pressed=down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
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
	check(control!=null,"visible action exists")
	if control==null:return
	var parent: Node=control.get_parent()
	while parent!=null:
		if parent is ScrollContainer:parent.ensure_control_visible(control)
		parent=parent.get_parent()
	await process_frame
	for down in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=control.get_global_rect().get_center()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		root.push_input(event,true)
		await frames(1)
func run() -> void:
	# Fixed fresh profile and safe clearing only isolate individual control cases.
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	game.close_modal()
	game.state.intro_seen=true
	game.state.factions.last_day=game.state.day
	game.player.position=Vector2(260,380)
	var start: Vector2=game.player.position
	Input.action_press("move_right")
	await frames(12)
	check(game.player.position.x>start.x+16,"walking responds promptly to held movement")
	Input.action_release("move_right")
	await frames(3)
	var stopped: Vector2=game.player.position
	await frames(5)
	check(game.player.position.distance_to(stopped)<0.1,"releasing movement stops without drifting or pixel snapping")
	await key(KEY_7)
	game.player.facing=Vector2.RIGHT
	game.action_cooldown=0
	await key(KEY_J)
	check(game.player.attack_time>0,"keyboard attack starts animation")
	var windup_at: Vector2=game.player.position
	Input.action_press("move_down")
	await frames(3)
	Input.action_release("move_down")
	check(game.player.position.y>windup_at.y+1,"player can reposition during sword swing")
	await key(KEY_SHIFT)
	check(game.player.dodge_time>0 and game.player.attack_time==0,"dodge cancels attack immediately")
	await frames(5)
	check(game.combat.pending.is_empty(),"cancelled windup cannot hit after dodge")
	await frames(35)
	game.action_cooldown=0
	await key(KEY_J)
	await frames(7)
	await key(KEY_J)
	check(game.combat.buffered_until>0,"early repeated attack is buffered")
	var saw_followup: bool=false
	for i in range(23):
		await frames(1)
		if game.combat.buffered_until==0 and game.action_cooldown>0.25:saw_followup=true
	check(saw_followup,"buffered attack follows without an extra key press")
	await frames(30)
	await key(KEY_J)
	await key(KEY_8)
	check(game.player.attack_time==0 and game.combat.pending.is_empty() and game.player.state_machine.current in ["idle","walk"],"number-key weapon swap cancels old swing consistently with wheel")
	await key(KEY_7)
	var wheel:=InputEventMouseButton.new()
	wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed=true
	wheel.position=Vector2(320,190)
	root.push_input(wheel,true)
	await frames(2)
	check(game.weapon_popup.visible and YinBalance.WEAPONS[game.state.current_gear().weapon].name in game.weapon_popup_label.text,"mouse wheel shows actual current weapon and ammunition status")
	await capture("polish-weapon")
	var gun: Dictionary=game.state.current_gear()
	gun.magazine=0
	game.action_cooldown=0
	await key(KEY_U)
	check(not game.combat.reload_job.is_empty(),"reload starts with actual key input")
	await key(KEY_SHIFT)
	await frames(2)
	check(game.combat.reload_job.is_empty() and gun.magazine==0,"dodging cancels reload without granting ammunition")

	await key(KEY_I)
	await frames(3)
	var inventory: YinInventoryPanel=game.modal.find_child("*",true,false) as YinInventoryPanel
	for panel in get_nodes_in_group("inventory_panels"):inventory=panel
	check(inventory!=null,"I opens inventory")
	if inventory!=null:
		var slot: YinInventorySlot=inventory.controls.filter(func(c):return c.model.slots()[c.index].id!="")[0]
		await click(slot)
		var item: String=slot.model.slots()[slot.index].id
		check(inventory.hint.visible and YinItemCatalog.spec(item).description in inventory.hint.text,"clicking an item exposes its description without a tooltip wait")
	await capture("polish-item")
	await key(KEY_ESCAPE)
	await key(KEY_O)
	check(game.modal!=null and find_button(game.modal,"领取主线")!=null,"task panel makes equipment and faction goals accessible")
	await capture("polish-goals")
	await key(KEY_ESCAPE)
	# Real map travel uses the existing route installer; inspect each map's navigation UI.
	for zone in ["farm","village","graveyard","forest","island","temple"]:
		game.travel(zone)
		await frames(3)
		await key(KEY_TAB)
		check(game.modal!=null and game.minimap.gates().size()==game.minimap.gate_labels().size(),"map exit labels match real routes "+zone)
		if zone=="farm" or zone=="island":await capture("polish-map-"+zone)
		await key(KEY_ESCAPE)
	game.travel("graveyard")
	await frames(4)
	for enemy in get_nodes_in_group("enemies"):enemy.stun=100
	var enemy: YinEnemy=game.nearest_enemy(Vector2(280,240),50)
	game.player.position=enemy.position+Vector2(0,32)
	game.player.facing=Vector2.UP
	game.combat.select_weapon("sword")
	game.player.facing=Vector2.UP
	game.action_cooldown=0
	var health_before: int=enemy.record.hp
	await key(KEY_J)
	check(enemy.record.hp==health_before,"windup has no premature damage")
	await frames(5)
	check(enemy.record.hp<health_before and game.player.hit_pause>0,"visible strike lands with impact freeze")
	await capture("polish-impact")
	await frames(20)
	# Source joint transforms change with gait and remain shared by severed fragments.
	var pose: Dictionary=enemy.art_pose()
	var first: Array=YinActorArt.posed_parts(enemy.record.kind,pose,0.0,true,false)
	var next_pose: Dictionary=pose.duplicate(true);next_pose.motion.gait+=1.5
	var next: Array=YinActorArt.posed_parts(enemy.record.kind,next_pose,0.15,true,false)
	check(first!=next,"monster joints have distinct movement poses")
	var legacy: Dictionary=game.state.snapshot()
	legacy.version=11
	legacy.erase("mainline_claimed")
	legacy.remains.append({"id":legacy.next_id,"kind":"water","name":"旧遗骸","integrity":100,"regret":"担水","fierceness":20,"yin":"水阴","at":[300.0,300.0],"zone":"cargo"})
	legacy.cargo=[legacy.next_id]
	legacy.next_id+=1
	var restored:=FarmState.new()
	check(restored.restore(legacy) and restored.cargo.is_empty() and restored.remains.back().zone=="farm","old cart saves recover bodies in accessible courtyard")
	var leisure:=FarmState.new()
	leisure.plots[0].crop="candle"
	leisure.plots[0].tilled=true
	leisure.next_day()
	check(leisure.plots[0].growth==1,"optional crops grow while player explores")
	leisure.equipment.append(YinBalance.make_gear(leisure.next_gear_id,"silver_sword",2,1))
	leisure.next_gear_id+=1
	var money_before: int=leisure.money
	leisure.claim_mainline()
	leisure.claim_mainline()
	check(leisure.money==money_before+80 and leisure.mainline_claimed==["gear"],"equipment milestone pays exactly once without farming")
	var balances:=FarmState.new()
	balances.factions.powers.temple={"troops":30,"supply":20}
	YinFactions.aid_weakest(balances)
	check(balances.factions.powers.temple.troops==42 and balances.money==60,"balancing assistance targets actual weakest faction")
	var before_repeat: int=balances.money
	YinFactions.aid_weakest(balances)
	check(balances.money==before_repeat,"daily support limit prevents repeated spending")
	for id in YinFactions.IDS:balances.factions.powers[id]={"troops":80,"supply":60}
	check(balances.mainline_stages()[2].done,"balanced peaceful world satisfies main goal")
	YinFactions.declare(balances,"temple","island")
	check(not balances.mainline_stages()[2].done,"active war prevents claiming peaceful balance")
	var persisted:=FarmState.new()
	check(persisted.restore(JSON.parse_string(JSON.stringify(leisure.snapshot()))) and persisted.mainline_claimed==leisure.mainline_claimed,"milestone claims survive JSON save roundtrip")
	game.travel("farm")
	game.state.weather="rain"
	game.player.position=Vector2(620,260)
	await frames(12)
	if folder!="" and DisplayServer.get_name()!="headless":
		for i in range(60):await process_frame
	await capture("polish-water")
	if folder!="" and DisplayServer.get_name()!="headless":
		game.player.position=Vector2(250,380)
		game.combat.select_weapon("sword")
		game.player.invincible=100
		var clips: String=folder.path_join("motion")
		DirAccess.make_dir_recursive_absolute(clips)
		Input.action_press("move_right")
		for i in range(48):
			if i in [6,30]:await key(KEY_J)
			if i==21:await key(KEY_SHIFT)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(clips.path_join("frame-%03d.png"%i))
		Input.action_release("move_right")

	print("Player polish: %d checks, %d failures"%[checks,failures])
	game.queue_free()
	await frames(2)
	quit(1 if failures else 0)
