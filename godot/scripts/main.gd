extends Node2D
const SaveStore = preload("res://scripts/save_store.gd")
const TOOL_NAMES = ["铁锹", "阴种", "浇灌", "收割", "斧头", "铁镐"]
const CROP_IDS = ["candle", "vine", "gourd", "rice"]
var state := FarmState.new()
var frame_budget: YinFrameBudget
var save_requested: bool=false
var save_clock: float=0
var hud_clock: float=0
var seamless: bool = OS.get_environment("YINTIAN_LEGACY_MAPS") != "1"
var world: FarmWorld
var player: FarmPlayer
var tool: int = 0
var hud: Control
var stats_label: Label
var date_label: Label
var quest_label: Label
var context_label: Label
var seed_button: Button
var status_label: Label
var health_bar: YinStatBar
var combat_label: Label
var energy_bar: YinStatBar
var modal: Control
var message_time: float = 3
var autosave_time: float = 0
var action_cooldown: float = 0
var save_failed: bool = false
var whisper_day: int = 0
var atmosphere: Control
var ambience: AudioStreamPlayer
var router: YinSceneRouter
var clock: YinGameClock
var audio_manager: YinAudioManager
var bag_model: YinInventoryModel
var chest_model: YinInventoryModel
var placement: YinPlacementController
var save_component: YinSaveComponent
var combat: YinCombatController
var smart_button: Button
var shooting_mouse: bool = false
var minimap: YinMinimap
var character_tab: String = "背包"
var quest_tracker: Button
var npc_dialogue := YinNpcDialogue.new()
var dialogue_log: Dictionary = {}
var exploration_clock: float = 0
var weapon_popup: Panel
var weapon_popup_label: Label
var weapon_popup_time: float = 0
var popup_weapon: String = ""
var combat_icon: TextureRect
var area_banner: YinAreaBanner

func _ready() -> void:
	YinDisplaySettings.load_settings()
	add_to_group("yintian_game")
	ThemeDB.fallback_font = preload("res://assets/mossfield-font.ttf")
	setup_inputs()
	YinActorArt.prepare_parts()
	router = get_node("Systems/SceneRouter")
	router.bind(get_node("Levels"))
	clock = get_node("Systems/GameClock")
	audio_manager = get_node("Systems/AudioManager")
	combat = get_node("Systems/CombatController")
	combat.game = self
	save_component = get_node("Systems/SaveComponent")
	save_component.state = state
	save_component.capture_pose = func():
		state.player_position = player.position
		state.saved_facing = player.facing
	var loaded: bool = save_component.load_game()
	if seamless:YinContinent.migrate(state)
	build_zone(state.zone, state.player_position)
	var weather_layer := CanvasLayer.new()
	weather_layer.layer = 5
	add_child(weather_layer)
	atmosphere = Control.new()
	atmosphere.set_script(preload("res://scripts/atmosphere.gd"))
	atmosphere.set("state", state)
	atmosphere.set("game", self)
	weather_layer.add_child(atmosphere)
	build_hud()
	frame_budget=YinFrameBudget.new();frame_budget.game=self;add_child(frame_budget)
	clock.minute_changed.connect(func(_day, _hour, _minute): update_labels())
	refresh("存档损坏，新建义庄；原文件在首次保存前保留。" if not loaded else "槐阴村的风，带着纸灰的味道。")
	if not state.intro_seen:
		var box := open_modal("阴诡世界 · 师父遗书", "裂海将异乡传说缝进此世。你刚刚出师，来到青槐村，接管边境义庄。\n\n第一步：沿东路跨过界河桥，前往乱葬岗，击败两只异怪。\n返回义庄按O领取银剑，再按B比较换装。\n红圈出现先闪避，F镇符可打断。\n\n主线：探索装备、介入四方争端，维持势力平衡。\n各方领地由河流分隔，沿道路过桥可无缝抵达。\n田里长出人声，不要答应。\n驱使的东西，每夜都要点名。\n祠堂里的神，不是祖宗。\n\nWASD 移动，左键轻击，右键重击，E 互动。\n7 剑 / 8 手枪 / J 手持攻击 / U 装填。\nShift 闪避 / F 镇符 / G 符火。")
		box.add_child(button("先定制旅人外观",func(): state.intro_seen=true; YinFirstJourney.start(state); show_character("外观")))
		box.add_child(button("收起遗书，走进义庄", func():
			state.intro_seen = true
			YinFirstJourney.start(state)
			close_modal()
			persist()
		))
	audio_manager.start()
	ambience = audio_manager.player

func build_zone(zone_name: String, at: Vector2) -> void:
	if seamless:
		build_continent(at)
		return
	if not YinSceneRouter.ROUTES.has(zone_name): return
	if is_instance_valid(weapon_popup):
		weapon_popup.visible=false
		weapon_popup_time=0
	state.zone = zone_name
	save_component.state = state
	bag_model = YinInventoryModel.new(state, "bag")
	chest_model = YinInventoryModel.new(state, "chest")
	bag_model.sync()
	chest_model.sync()
	if is_instance_valid(atmosphere): atmosphere.set("state", state)
	state.prepare_enemies()
	world = router.install(zone_name, state)
	player = preload("res://scenes/actors/player.tscn").instantiate()
	player.position = at if world.is_safe_position(at) else Vector2(300, 350)
	player.appearance = state.appearance
	player.facing = state.saved_facing
	world.actors.add_child(player)
	player.health_receiver.bind_source(state, "health")
	world.player = player
	player.aim_direction = state.saved_facing
	player.held_item = state.current_gear().weapon if zone_name in ["graveyard", "forest", "sunken", "theatre", "village", "island", "temple"] else "tool%d" % tool
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_right = int(world.level_size.x)
	camera.limit_bottom = int(world.level_size.y)
	combat.pending.clear()
	combat.reload_job.clear()
	clock.bind(state)
	world.loot_requested.connect(spawn_loot)
	placement = YinPlacementController.new()
	placement.game = self
	world.add_child(placement)
	spawn_pickups()
	spawn_gear_pickups()
	spawn_enemies()
	spawn_villagers()
	spawn_spirits()
	spawn_remains_visuals()
	world.install_chests(self)

func build_continent(at: Vector2) -> void:
	state.prepare_enemies()
	bag_model=YinInventoryModel.new(state,"bag");chest_model=YinInventoryModel.new(state,"chest");bag_model.sync();chest_model.sync()
	for old in get_node("Levels").get_children():
		get_node("Levels").remove_child(old);old.queue_free()
	world=YinContinentWorld.new();world.state=state;get_node("Levels").add_child(world)
	player=preload("res://scenes/actors/player.tscn").instantiate()
	player.position=at if world.is_safe_position(at) else YinContinent.HOME+Vector2(0,96)
	player.appearance=state.appearance;player.facing=state.saved_facing;player.aim_direction=state.saved_facing
	player.held_item=state.current_gear().weapon
	world.actors.add_child(player);world.player=player
	player.health_receiver.bind_source(state,"health")
	var camera: Camera2D=player.get_node("Camera2D");camera.limit_right=6400;camera.limit_bottom=4800
	combat.pending.clear();combat.reload_job.clear();clock.bind(state)
	world.loot_requested.connect(spawn_loot)
	placement=YinPlacementController.new();placement.game=self;world.add_child(placement)
	spawn_enemies();spawn_villagers();spawn_spirits();spawn_pickups();spawn_gear_pickups();spawn_remains_visuals();world.install_chests(self)
func update_territory() -> void:
	var next: String=YinContinent.zone_at(player.position)
	if next==state.zone:return
	state.zone=next
	area_banner.reveal(next)
	# The same world, actors, projectiles and camera survive every border crossing.
	spawn_enemies()

func travel(zone_name: String) -> void:
	if seamless:
		notify_action("沿道路与界河桥步行前往领地，地图不再切换。")
		return
	close_modal()
	var origin: String = state.zone
	var at: Vector2 = {"temple": YinTemple.ENTRY, "island": Vector2(224, 1408), "village": Vector2(180, 800), "sunken": Vector2(180, 800), "theatre": Vector2(180, 800), "forest": Vector2(180, 1120), "graveyard": Vector2(810, 535) if origin == "forest" else Vector2(182, 533), "hall": Vector2(480, 435), "shop": Vector2(480, 435)}.get(zone_name, Vector2(160, 218) if origin == "hall" else (Vector2(780, 260) if origin == "shop" else Vector2(810, 538)))
	at=YinWorldLayout.arrival(origin,zone_name,at)
	build_zone(zone_name, at)
	if is_instance_valid(area_banner):area_banner.reveal(zone_name)
	if zone_name == "island" and not state.island_journal.visited:
		state.island_journal.visited = true
		state.add_log("裂海异闻：抵达岛国，异乡民俗在此世相接。")

	notify_action({"temple": "大佛寺：饿鬼逐食、幽魂虚化，先息修罗战意，再入夜叉护法殿。", "island": "岛国：苇岸、荒冢、风山与双面社。先平息以津真天，再循封印深入。", "forest": "后山铳林：远程弹幕与精英。B 穿戴装备，8 手枪 / 9 冲锋枪 / 0 步枪，U 装填。", "graveyard": "乱葬坡：留意攻击预兆，击败敌人获取装备，遗骸可就地处理。", "hall": "义庄：案台炼骸，仓箱存取，卧榻休息。靠近按 E。", "shop": "杂货铺：走近柜台按 E 购买阴种与灯油。", "farm": "回到院落。田园可供休憩，O 查看装备与势力主线。"}.get(zone_name, ""))

func spawn_enemies() -> void:
	var existing: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("faction_guards"):
		if enemy.get_parent() == world.actors and not enemy.is_queued_for_deletion(): existing.append(enemy.record.id)
	for e in state.enemies:
		if e.id in existing: continue
		if (not seamless and e.zone != state.zone) or e.dead: continue
		if e.zone == "island" and not YinIsland.available(state, e.kind): continue
		if e.zone == "temple" and not YinTemple.available(state, e.kind): continue
		var enemy: YinEnemy = preload("res://scenes/actors/enemy.tscn").instantiate()
		enemy.game = self
		enemy.record = e
		enemy.position = Vector2(e.at[0], e.at[1])
		if not world.is_safe_position(enemy.position,YinBodyProfile.spec(e.kind).half):
			var origin: Vector2 = enemy.position
			var located: bool = false
			for radius in range(16, 257, 16):
				for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
					var candidate: Vector2 = origin + direction * radius
					if world.is_safe_position(candidate,YinBodyProfile.spec(e.kind).half):
						enemy.position = candidate
						located = true
						break
				if located: break
			e.at = [enemy.position.x, enemy.position.y]
		enemy.add_to_group("faction_guards" if YinFactions.friendly(state,e) else "enemies")
		world.actors.add_child(enemy)

func spawn_spirits() -> void:
	var existing: Dictionary = {}
	for actor in get_tree().get_nodes_in_group("companions"):
		var found: Array = state.spirits.filter(func(s): return s.id == actor.record.id)
		if actor.get_parent() == world.actors and not actor.is_queued_for_deletion() and not found.is_empty() and ((found[0].active and found[0].hp>0) if seamless else state.spirit_present(found[0],state.zone)):
			actor.record = found[0]
			existing[actor.record.id] = actor
		else: actor.queue_free()
	for s in state.spirits:
		if seamless:
			if not s.active or s.hp<=0:continue
		elif not state.spirit_present(s,state.zone):continue
		if existing.has(s.id): continue
		var actor := CharacterBody2D.new()
		actor.set_script(preload("res://scripts/spirit_actor.gd"))
		actor.set("game", self)
		actor.set("record", s)
		actor.position = player.position + Vector2(-30-int(s.id)%4*12, 20)
		if s.get("assignment")=="village":
			var citizens: Array=state.villagers.filter(func(v):return int(v.id)==int(s.get("guard_villager",0)))
			actor.position=Vector2(citizens[0].at[0],citizens[0].at[1])+Vector2(-24,16) if not citizens.is_empty() else (YinContinent.CAPITALS.village if seamless else Vector2(560,400))
		actor.add_to_group("companions")
		world.actors.add_child(actor)

func spawn_remains_visuals(falling_id: int=-1) -> void:
	var existing: Dictionary={}
	for node in get_tree().get_nodes_in_group("remains"):
		if node is YinCorpse and not node.is_queued_for_deletion() and node.get_parent()==world.actors:
			existing[node.record.id]=node
		else:node.queue_free()
	var wanted: Dictionary={}
	for r in state.remains:
		if r.zone=="cargo" or (not seamless and r.zone!=state.zone):continue
		wanted[r.id]=true
		if existing.has(r.id):continue
		var corpse:=YinCorpse.new();corpse.bind(r,r.id==falling_id);world.actors.add_child(corpse)
	for id in existing:
		if not wanted.has(id):existing[id].queue_free()

func setup_inputs() -> void:
	var keys: Dictionary = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "use_tool": [KEY_SPACE], "interact": [KEY_E], "cycle_seed": [KEY_Q], "inventory": [KEY_I], "pause_game": [KEY_ESCAPE], "attack": [KEY_J], "dodge": [KEY_SHIFT], "seal": [KEY_F], "fire": [KEY_G], "rollcall": [KEY_R], "order": [KEY_C], "journal": [KEY_L], "wait_night": [KEY_T], "mute": [KEY_M], "reload": [KEY_U], "equipment": [KEY_B], "smart_farming": [KEY_Z], "instant_refine": [KEY_V], "quests": [KEY_O], "map": [KEY_TAB], "companions": [KEY_H], "mail": [KEY_K]}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func style(bg: String = "172e2cf2", border: String = "788064") -> StyleBoxFlat:
	return YinPixelTheme.box(bg, border)

func panel(at: Vector2, size_value: Vector2, parent: Node = null) -> Panel:
	var p := Panel.new()
	p.position = at
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	p.size = size_value
	p.add_theme_stylebox_override("panel", style())
	(parent if parent != null else hud).add_child(p)
	return p

func label(text: String, at: Vector2, parent: Node, font_size: int = 12) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("ded9bf"))
	parent.add_child(l)
	return l

func button(text: String, action: Callable, size_value: Vector2 = Vector2(100, 27)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size_value
	b.add_theme_stylebox_override("normal", style("1f3732", "617359"))
	b.add_theme_stylebox_override("hover", style("2d493d", "bea56d"))
	b.add_theme_stylebox_override("pressed", style("3d5140", "c7af77"))
	b.add_theme_stylebox_override("focus", YinPixelTheme.focus())
	b.add_theme_color_override("font_color", Color("ded9bf"))
	b.add_theme_color_override("font_hover_color", Color("ded9bf"))
	b.add_theme_color_override("font_focus_color", Color("ded9bf"))
	b.add_theme_color_override("font_pressed_color", Color("e8dfbf"))
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(action)
	return b

func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.theme = YinPixelTheme.install()
	layer.add_child(hud)
	var info := panel(Vector2(10, 10), Vector2(170, 48))
	date_label = label("", Vector2(6, 3), info, 10)
	stats_label = label("", Vector2(6, 16), info, 9)
	health_bar = YinStatBar.new()
	health_bar.position = Vector2(6, 34)
	health_bar.size = Vector2(76, 7)
	health_bar.fill_color = Color("b87364")
	info.add_child(health_bar)
	energy_bar = YinStatBar.new()
	energy_bar.position = Vector2(90, 34)
	energy_bar.size = Vector2(76, 7)
	info.add_child(energy_bar)
	quest_label = label("", Vector2.ZERO, hud, 10)
	quest_label.visible = false
	quest_tracker = button("O 委托", show_quests, Vector2(194, 44))
	quest_tracker.position = Vector2(436, 106)
	quest_tracker.add_theme_font_size_override("font_size", 10)
	quest_tracker.clip_text=true
	hud.add_child(quest_tracker)
	seed_button = button("", cycle_seed)
	var crop_icon := AtlasTexture.new()
	crop_icon.atlas = preload("res://assets/crops.png")
	crop_icon.region = Rect2(80, 0, 16, 16)
	seed_button.icon = crop_icon
	seed_button.visible = false
	hud.add_child(seed_button)
	smart_button = button("", toggle_smart)
	smart_button.visible = false
	hud.add_child(smart_button)
	var bag := button("I 行囊", show_inventory, Vector2(66, 22))
	bag.position = Vector2(10, 62)
	bag.focus_mode = Control.FOCUS_NONE
	hud.add_child(bag)
	var combat_panel := panel(Vector2(10, 310), Vector2(190, 40))
	combat_label = label("", Vector2(6, 4), combat_panel, 10)
	combat_label.size = Vector2(138, 32)
	combat_icon=TextureRect.new()
	combat_icon.position=Vector2(6,5);combat_icon.size=Vector2(32,30)
	combat_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	combat_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	combat_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	combat_panel.add_child(combat_icon)
	weapon_popup = panel(Vector2(216, 231), Vector2(208, 43))
	weapon_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_popup_label = label("",Vector2(8,4),weapon_popup,10)
	weapon_popup_label.size=Vector2(192,35)
	weapon_popup_label.clip_text=true
	weapon_popup.visible = false
	var hint := panel(Vector2(210, 326), Vector2(420, 24))
	context_label = label("", Vector2(5, 3), hint, 9)
	context_label.size.x = 415
	context_label.clip_text = true
	var toast := panel(Vector2(208, 280), Vector2(300, 35))
	toast.name = "Toast"
	status_label = label("", Vector2(6, 3), toast, 10)
	status_label.size = Vector2(288, 29)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	minimap = YinMinimap.new()
	minimap.game = self
	minimap.position = Vector2(516, 6)
	minimap.size = Vector2(118, 91)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(minimap)
	area_banner=YinAreaBanner.new()
	area_banner.game=self
	hud.add_child(area_banner)
	area_banner.reveal(state.zone)

func _physics_process(delta: float) -> void:
	if modal != null: return
	action_cooldown = maxf(-delta, action_cooldown - delta)
	if player.held_item in YinBalance.GUNS and (Input.is_action_pressed("attack") or shooting_mouse): combat.shoot()

func _process(delta: float) -> void:
	save_clock=maxf(0,save_clock-delta)
	if save_requested and save_clock<=0:
		save_requested=false;persist();save_clock=0.75
	if modal == null:
		var previous_day: int = state.day
		clock.advance(delta, false)
		if state.day != previous_day:
			spawn_spirits()
			notify_action(("新求救信：青槐村今夜遭袭，K 阅读。" if state.raid_status == "warned" else "天亮了，仍留在原地。") + state.last_report)
		if seamless:update_territory()
		if YinFactions.tick(state):
			if seamless or state.factions.wars.any(func(w): return w.status == "active" and w.defender == state.zone): spawn_enemies()
			notify_action("势力战况有变，P 查看四方局势。")
		if state.update_raid():
			if seamless or state.zone == "village": spawn_enemies()
			notify_action("求救来信：青槐村遭袭！角色 → 书信查看，义庄东侧 E 前往村庄。")
		if not seamless and state.maybe_boss() and state.zone == "farm":
			spawn_new_boss()
			refresh("义庄门前响了三声。棺中客来了。J 攻击，F 压制，Shift 躲开预兆。")
		if not seamless and state.zone == "farm" and state.minutes >= 1080 and whisper_day != state.day and state.plots.any(func(p): return p.crop == "rice" and p.growth >= 2 and not p.sealed):
			whisper_day = state.day
			refresh("田里响起师父的声音：你回来啦？——不要答应，靠近返魂稻按 E 封声。")
		exploration_clock += delta
		if exploration_clock >= 0.25:
			exploration_clock = 0
			update_exploration()
		var threatened: bool=nearest_enemy(player.position,140)!=null
		quest_tracker.modulate.a=move_toward(quest_tracker.modulate.a,0.22 if threatened else 1.0,delta*3)
		quest_tracker.mouse_filter=Control.MOUSE_FILTER_IGNORE if threatened else Control.MOUSE_FILTER_STOP
		weapon_popup_time = maxf(0,weapon_popup_time-delta)
		weapon_popup.visible = weapon_popup_time > 0 and player.held_item==popup_weapon
		message_time -= delta
		hud.get_node("Toast").visible = message_time > 0 or save_failed
		autosave_time += delta
		if autosave_time > 15:
			autosave_time = 0
			persist()
	state.player_position = player.position
	state.saved_facing = player.facing
	player.burden = false
	hud_clock+=delta
	if hud_clock>=0.1:
		hud_clock=0;update_labels()
	audio_manager.set_night(state.minutes >= 1080)

func has_live_boss() -> bool:
	return state.enemies.any(func(e): return e.kind == "boss" and not e.dead)

func spawn_new_boss() -> void:
	for e in state.enemies:
		if e.kind != "boss" or e.dead: continue
		var enemy: YinEnemy = preload("res://scenes/actors/enemy.tscn").instantiate()
		enemy.record = e
		enemy.game = self
		enemy.position = Vector2(e.at[0], e.at[1])
		enemy.add_to_group("enemies")
		world.actors.add_child(enemy)

func update_labels() -> void:
	update_quest_tracker()
	date_label.text = "第 %02d 日  %02d:%02d  %s" % [state.day, (int(state.minutes) % 1440) / 60, int(state.minutes) % 60, "雨" if state.weather == "rain" else ("夜" if state.minutes >= 1080 else "昼")]
	if seamless and world.environment.regional!=null:date_label.text="第 %02d 日 %02d:%02d %s"%[state.day,(int(state.minutes)%1440)/60,int(state.minutes)%60,YinRegionalClimate.LABELS[world.environment.regional.event]]
	stats_label.text = "命%d · 气%d · %d文" % [state.health,state.energy,state.money]
	health_bar.value = state.health
	energy_bar.value = state.energy
	energy_bar.tooltip_text = "气力 %d/100" % state.energy
	health_bar.tooltip_text = "命息 %d/100" % state.health
	var gear: Dictionary = state.current_gear()
	var spec: Dictionary = YinBalance.WEAPONS[gear.weapon]
	var shown_name: String = TOOL_NAMES[int(player.held_item.substr(4))] if player.held_item.begins_with("tool") else spec.name
	combat_icon.visible=not player.held_item.begins_with("tool")
	if combat_icon.visible:combat_icon.texture=YinBalance.icon(gear.weapon)
	combat_label.position.x=44 if combat_icon.visible else 6
	combat_label.text = "%s  ·  %s\nF %d/2%s" % [shown_name, ("气力 %d" % state.energy if gear.weapon in YinBalance.MAGIC else "近战") if spec.ammo == "" else "%d / %d" % [gear.magazine, state.container_count("bag", spec.ammo)], state.skill_charges.seal, "    G %d/2" % state.skill_charges.fire if state.skill_ranks.fire > 0 else ""]
	if not combat.reload_job.is_empty(): combat_label.text += " · 装填 %.1fs" % combat.reload_job.remaining
	smart_button.text = "Z 智能劳作：" + ("开" if state.smart_farming else "手动")
	(seed_button.icon as AtlasTexture).region = Rect2(80, CROP_IDS.find(state.selected_crop) * 16, 16, 16)
	seed_button.text = "Q %s × %d" % [FarmState.CROPS[state.selected_crop].display_name, state.seed_count(state.selected_crop)]
	quest_label.text = state.mainline_summary()
	var kind: String = world.nearest_interaction()
	var hints: Dictionary = {"temple_gate": "E 沿山道前往大佛寺", "temple_return": "E 返回青槐村", "island_ferry": "E 乘船前往岛国 · 异乡缝合海岸", "island_return": "E 乘船返回青槐村", "treasure": "E 开启宝箱 · 清理附近守卫后领取","village_gate": "E 青槐村 · 村民与夜袭求救", "village_return": "E 返回义庄田园", "villager": "E 与村民交谈","sunken_gate": "E 沉水村 · 支线首领井中龙婆", "theatre_gate": "E 废戏台 · 支线首领无面伶王", "branch_return": "E 返回后山铳林","forest_gate": "E 进入后山铳林 · 更大地图、精英与远程弹幕", "forest_return": "E 返回乱葬坡", "home": "E 进入义庄：案台、卧榻与仓箱", "shipping": "E 货箱：出售背包里的灵物", "shop": "E 进入杂货铺", "npc": "E 桥边阿婆：村庄秘密与十日抉择", "altar": "E 祭坛：先看收益和代价，也可不祭祀", "gate": "E 进入乱葬坡 · 探索装备与遗骸", "return": "E 返回义庄，处理遗骸", "exit_interior": "E 返回院落", "workbench": "E 案台：炼骸、制符与役灵", "counter": "E 柜台：交易", "storage": "E 仓箱：存取、拆分与交换物品", "bed": "E 卧榻：休息至天亮"}

	for point in YinWorldLayout.points(state.zone):
		if point.id.begins_with("inspect_"):hints[point.id]="E 调查"+point.name
	if kind.begins_with("post28:"):hints[kind]="E 据点 · 领地与驿路"
	if kind.begins_with("echo27:"):hints[kind]="E 调查 · "+YinWorldDistricts.PLACES[kind.trim_prefix("echo27:")].name
	var remains_hint: Dictionary = nearest_remains()
	for body in get_tree().get_nodes_in_group("remains"):
		if body is YinCorpse:body.highlight(not remains_hint.is_empty() and body.record.id==remains_hint.id)
	context_label.text = "V 免费炼化 · E 处理 · " + remains_hint.name if not remains_hint.is_empty() else hints.get(kind, "")
	if seamless:
		context_label.text={"workbench":"E 义庄整备与休息","counter":"E 商队交易","storage":"E 仓箱","villager":"E 交谈与委托","treasure":"E 开启宝箱","altar":"E 祈愿祭坛"}.get(kind,context_label.text)
	context_label.get_parent().visible = context_label.text != ""
	if not seamless and state.zone == "farm" and state.smart_farming and kind == "":
		var index: int = world.front_plot()
		if world.reachable(index): context_label.text = "空格 " + suggested_action(index)
		context_label.get_parent().visible = world.reachable(index)

func queue_save() -> void:
	if not seamless:persist()
	else:save_requested=true

func persist() -> void:
	save_requested=false
	state.player_position = player.position
	state.saved_facing = player.facing
	save_failed = not save_component.save_game()
	if save_failed: status_label.text = "保存失败，请检查 user:// 是否可写。"

func refresh(message: String = "") -> void:
	if message != "":
		status_label.text = message
		message_time = 3
		hud.get_node("Toast").show()
	world.queue_redraw()
	update_labels()

func notify_action(message: String) -> void:
	refresh(message)
	queue_save()

func cycle_seed() -> void:
	state.selected_crop = CROP_IDS[(CROP_IDS.find(state.selected_crop) + 1) % 4]
	notify_action("选择 %s。按 2 播种。" % FarmState.CROPS[state.selected_crop].display_name)

func use_plot(index: int) -> void:
	if seamless:return
	if state.smart_farming and index >= 0:
		var suggested: int = smart_tool(index)
		if suggested < 0:
			refresh(suggested_action(index))
			return
		tool = suggested
	if tool >= 4:
		use_terrain()
		return
	if action_cooldown > 0: return
	action_cooldown = 0.2
	if not world.reachable(index):
		refresh("走近灵田再劳作。")
		return
	if not player.state_machine.begin("tool", 0.25): return
	player.held_item = "tool%d" % tool
	player.attack_time = 0.2
	notify_action(state.use_tool(index, tool))
	world.effect(world.plot_center(index), Color("91b4a8"))

func nearest_enemy(at: Vector2,max_distance: float) -> YinEnemy:
	var result: YinEnemy=null
	for actor in world.combat_index().nearby(at,max_distance,true):
		var distance: float=at.distance_to(actor.position)
		if distance<max_distance:result=actor;max_distance=distance
	return result

func attack(method: String) -> void:
	combat.trigger(method)

func take_damage(amount: int) -> void:
	if player.invincible > 0 or modal != null: return
	if state.zone == "farm": amount = maxi(1, amount - int(state.ward / 30))
	amount = YinBalance.damage(amount, 1, {}, YinBalance.armor_value(state.armor_gear()))
	player.health_receiver.apply(amount, "enemy")
	player.invincible = 0.6
	world.damage_number(player.position, amount, Color("e59a86"))
	player.hit_feedback = 0.2
	refresh("受伤，命息 -%d。Shift 闪避可避开攻击预兆。" % amount)
	if state.health <= 0:
		state.health = 60
		state.energy = 35
		state.money = maxi(0, state.money - 15)
		build_zone("farm", YinContinent.HOME+Vector2(0,96) if seamless else Vector2(160,218))
		notify_action("护命符将你送回义庄，损失 15 文。")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		shooting_mouse = false

func _unhandled_input(event: InputEvent) -> void:
	if modal != null:
		shooting_mouse = false
		if event.is_action_pressed("pause_game"): close_modal()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_P: show_factions()
		elif event.is_action_pressed("instant_refine"): instant_refine()
		elif event.physical_keycode in [KEY_7, KEY_8, KEY_9, KEY_0]:
			var kind: String = {KEY_7: "sword", KEY_8: "pistol", KEY_9: "smg", KEY_0: "rifle"}[event.physical_keycode]
			if combat.select_weapon(kind): player.held_item = kind
		elif event.is_action_pressed("reload"): combat.reload()
		elif event.is_action_pressed("equipment"): show_character("穿戴")
		elif event.is_action_pressed("quests"): show_quests()
		elif event.is_action_pressed("map"): show_character("地图")
		elif event.is_action_pressed("companions"): show_character("随从")
		elif event.is_action_pressed("mail"): show_character("书信")
		elif event.is_action_pressed("smart_farming") and not seamless: toggle_smart()
		elif event.is_action_pressed("cycle_seed") and not seamless: cycle_seed()
		elif event.is_action_pressed("inventory"): show_inventory()
		elif event.is_action_pressed("pause_game"):
			if placement.selected != "":
				placement.selected = ""
				refresh("已取消放置，物品仍在行囊。")
			else: show_pause()
		elif event.is_action_pressed("interact"): interact()
		elif event.is_action_pressed("use_tool"):
			if seamless:attack("sword")
			else:use_plot(world.front_plot())
		elif event.is_action_pressed("attack"): attack("sword")
		elif event.is_action_pressed("seal"): attack("seal")
		elif event.is_action_pressed("fire"): attack("fire")
		elif event.is_action_pressed("dodge"): player.dodge()
		elif event.is_action_pressed("rollcall"): notify_action(state.rollcall())
		elif event.is_action_pressed("order"):
			state.order = ["follow", "guard", "focus"] [(["follow", "guard", "focus"].find(state.order) + 1) % 3]
			notify_action("役灵指令：" + {"follow": "跟随", "guard": "驻守", "focus": "集火"}[state.order])
		elif event.is_action_pressed("journal"): show_journal()
		elif event.is_action_pressed("wait_night"):
			if state.zone != "farm": refresh("只能在义庄附近等候入夜。")
			else:
				var box := open_modal("等候黄昏", "时间将推进到 18:00。役灵未点名、未备灯油都将在睡觉时产生后果。")
				box.add_child(button("等到入夜", func():
					state.minutes = maxf(1080, state.minutes)
					close_modal()
					notify_action("纸灯亮了。别忘记点名。")
				))
		elif event.is_action_pressed("mute"): audio_manager.toggle()
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		combat.cancel_reload()
		combat.pending.clear()
		combat.buffered_until = 0
		player.attack_time = 0
		if player.state_machine.current != "dodge": player.state_machine.reset()
		var slot: String = state.cycle_weapon(1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1)
		player.held_item = state.current_gear().weapon
		show_weapon_popup()
		refresh("%s：%s" % [{"melee": "近战", "primary": "主武器", "secondary": "副武器"}[slot], YinBalance.gear_name(state.current_gear())])
		return
	if event is InputEventMouseMotion and player.attack_time <= 0:
		player.aim_direction = YinAimResolver.direction(world,player,event.position)
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT: shooting_mouse = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if player.held_item in YinBalance.MELEE:
			var aim: Vector2=YinAimResolver.direction(world,player,event.position)
			if aim!=Vector2.ZERO and player.attack_time<=0:player.facing=aim
			if not combat.heavy() and state.energy<14:refresh("重击需要14气力。")
		elif player.held_item in YinBalance.GUNS:combat.reload()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if placement.selected != "":
			if placement.place(world.get_global_mouse_position()): notify_action("放置完成。")
			else: refresh("距离太远、田地或障碍物占用，未消耗物品。")
		elif seamless or state.zone in ["graveyard", "forest", "sunken", "theatre", "village", "island", "temple"] or nearest_enemy(player.position, 65) != null or player.held_item in YinBalance.GUNS:
			var aim: Vector2 = YinAimResolver.direction(world,player,event.position)
			if aim != Vector2.ZERO and player.state_machine.current in ["idle", "walk"]:
				player.facing = aim
				player.aim_direction = aim
			shooting_mouse = state.current_gear().weapon not in YinBalance.MELEE
			attack("sword")
		else: use_plot(world.plot_at(world.get_global_mouse_position()))

func nearest_remains() -> Dictionary:
	for r in state.remains:
		if (seamless or r.zone == state.zone) and world.can_interact(Vector2(r.at[0],r.at[1]),46): return r
	return {}

func interact() -> void:
	var remains_data: Dictionary = nearest_remains()
	if not remains_data.is_empty():
		show_remains(remains_data, false)
		return
	var index: int = world.front_plot()
	if index >= 0 and world.reachable(index) and state.plots[index].crop in ["gourd", "rice"]:
		show_special_plot(index)
		return
	var interaction: String=world.nearest_interaction()
	if interaction.begins_with("post28:"):
		show_waypost28(interaction.trim_prefix("post28:"));return
	if interaction.begins_with("echo27:"):
		show_world_echo(interaction.trim_prefix("echo27:"));return
	if interaction.begins_with("inspect_"):
		show_landmark(interaction.trim_prefix("inspect_"))
		return
	for point in YinWorldLayout.points(state.zone):
		if point.id==interaction and point.to!="":
			travel(point.to)
			return
	match interaction:
		"treasure":
			var id: String = world.nearest_chest()
			notify_action(YinAdventure.open_chest(state, id, player.position))
		"villager": show_villager()
		"shipping": notify_action(state.sell())
		"npc": show_npc()
		"altar": show_ritual()
		"workbench": show_hall()
		"counter": show_shop()
		"storage": show_storage()
		"bed": show_hall()
		_: refresh("靠近义庄、村民、祭坛、出口或遗骸，再按 E。")

func advance_day() -> void:
	state.next_day()
	close_modal()
	build_zone("farm", YinContinent.HOME+Vector2(0,96) if seamless else Vector2(160,218))
	persist()
	if state.raid_status == "warned": notify_action("收到求救信：青槐村今夜遭袭，K 阅读。")

func open_modal(title_text: String, description: String) -> VBoxContainer:
	close_modal()
	player.frozen = true
	shooting_mouse = false
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(modal)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.035, 0.045, 0.075, 0.72)
	modal.add_child(dim)
	var card := panel(Vector2(88, 25), Vector2(464, 309), modal)
	card.name = "ModalCard"
	var accent := ColorRect.new()
	accent.position = Vector2(14, 37)
	accent.size = Vector2(436, 1)
	accent.color = Color("788064")
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(accent)
	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.position = Vector2(14, 10)
	layout.size = Vector2(436, 287)
	layout.add_theme_constant_override("separation", 8)
	card.add_child(layout)
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color("d9bf83"))
	layout.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(436, 209)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var column := VBoxContainer.new()
	column.name = "Content"
	column.custom_minimum_size.x = 420
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	var desc := Label.new()
	desc.text = description
	desc.custom_minimum_size.x = 418
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color("acb6a2"))
	column.add_child(desc)
	var back := button("合上 · Esc", close_modal)
	layout.add_child(back)
	back.grab_focus()
	return column

func close_modal() -> void:
	if seamless and not state.intro_seen:
		state.intro_seen=true;YinFirstJourney.start(state)
	if modal != null:
		modal.queue_free()
		modal = null
	if is_instance_valid(player):
		player.frozen = false
		if is_instance_valid(player.state_machine): player.state_machine.update(0, Vector2.ZERO, false)

func feedback(column: VBoxContainer, text: String) -> void:
	column.get_child(0).text = text
	notify_action(text)

func show_hall() -> void:
	var box := open_modal("义庄 · 停尸棚", "安置 %d/%d · 灯油 %d" % [state.spirits.size(), state.capacity(), state.oil])
	box.add_child(button("每夜点名：今天 %s" % ("已完成" if state.called_day == state.day else "未完成"), func(): feedback(box, state.rollcall())))
	box.add_child(button("休息到天亮", func():
		if has_live_boss():
			feedback(box, "夜袭未结束，不能安睡。先击败棺中客，或被护命符救回。")
			return
		advance_day()
		refresh(state.last_report)
	))
	box.add_child(button("役灵安排与供养状况", show_spirits))
	for r in state.remains:
		if r.zone == "farm": box.add_child(button("处理遗骸："+r.name,func():show_remains(r,true)))
	box.add_child(button("制作与扩建", show_crafting))

func show_crafting() -> void:
	var box := open_modal("制作与扩建", "选择配方后制作；材料不足时保留现有物品。")
	box.add_child(button("制作 12 轻弹 · 1 零件 + 1 骨料", func(): feedback(box, state.craft_ammo("light_ammo"))))
	box.add_child(button("制作 6 步枪弹 · 1 零件 + 1 骨料", func(): feedback(box, state.craft_ammo("rifle_ammo"))))
	for pair in ([] if seamless else [["oil", "烛穗 → 4 灯油"]]) + [ ["talisman", "1 阴灰或 12 文 → 3 张符"], ["ward", "修阵：1 骨料 + 1 灯油 → 镇守 +30"], ["hall", "扩建：3 骨料 + 80 文 → 3 安置位"], ["paper_lamp", "纸灯：2 槐木 + 1 灯油"], ["ward_stake", "阵桩：1 骨料 + 1 青石"]]:
		box.add_child(button(pair[1], func():
			var text: String = state.craft(pair[0])
			feedback(box, text)
		))

func show_spirits() -> void:
	if seamless:
		show_character("随从")
		return
	var box := open_modal("役灵册 · 名字必须由你来记", "安置 %d/%d；每日需要 %d 灯油，现有 %d。\n漏点名怨气 +20；缺供养 +25；错配工作 +8。怨气达 60 时失踪并增加污染。\nC 切换跟随 / 驻守 / 集火，主动追击敌人；驻守围绕当前位置巡逻。" % [state.spirits.size(), state.capacity(), state.spirits.size(), state.oil])
	for s in state.spirits:
		box.add_child(button("%s · 怨气 %d · 契合 %d · %s" % [s.name, s.risk, s.affinity, {"rest": "休息", "water": "浇灌", "dig": "开荒", "clean": "净秽", "guard": "守门"}[s.job]], func(): show_job(s)))
	if state.spirits.is_empty(): box.get_child(0).text += "\n尚无役灵：遗骸炼化或成熟童影葫芦破壳可获得。"

func show_job(s: Dictionary) -> void:
	var box := open_modal(s.name + " · 生前残念", "最佳工作：%s。匹配工作每天提升契合 10，降低怨气 3。\n当前怨气 %d，达到 60 会失踪。" % [{"water": "浇灌", "dig": "开荒", "clean": "净秽", "guard": "守夜"}.get(state.preferred_job(s), "休息"), s.risk])
	for pair in [["water", "浇灌：担水尸每天灌溉全部作物"], ["dig", "开荒：掘土骨每天翻 3 块地"], ["clean", "净秽：食秽童每天污染 -8"], ["guard", "守门：每天镇守 +3"], ["rest", "休息：仍需供养和点名"]]:
		box.add_child(button(pair[1], func():
			s.job = pair[0]
			feedback(box, s.name + "接下了差事。")
		))

func show_remains(r: Dictionary, at_hall: bool) -> void:
	var meta: Dictionary = YinAbilities.meta(r.kind)
	var box := open_modal(r.name, "完整度 %d · %s\n%s / %s" % [r.integrity, r.regret, meta.active, meta.passive])
	box.add_child(button("炼为役灵 · 无需耗材", func(): process_choice(box, r, "refine")))
	if at_hall:
		var empty_index: int = empty_plot()
		box.add_child(button("埋入第 %d 块空灵田 · 阴性 +1 / 污染增加" % [empty_index + 1], func(): process_choice(box, r, "bury", empty_index)))
	box.add_child(button("拆解骨料与阴灰 · 放弃完整役灵", func(): process_choice(box, r, "dismantle")))
	box.add_child(button("超度残念 · 声望 +1 / 污染 -8 / 12 文", func(): process_choice(box, r, "release")))

func empty_plot() -> int:
	for i in range(state.plots.size()):
		if state.plots[i].crop == "": return i
	return -1

func process_choice(box: VBoxContainer, r: Dictionary, method: String, index: int = -1) -> void:
	var message: String = state.process_remains(r.id, method, index)
	if state.find_remains(r.id).is_empty():
		close_modal()
		spawn_remains_visuals()
		spawn_spirits()
		notify_action(message)
	else: feedback(box, message)

func show_special_plot(index: int) -> void:
	var p: Dictionary = state.plots[index]
	if p.crop == "rice":
		var box := open_modal("返魂稻 · 声音不属于师父", "逐日生长，无需每日浇灌，也不再每日增加污染。\n可观察规律：未封声的成熟稻不能安全收获。\n使用镇符技能封声：12 体力 / 1 充能，无需耗材。")
		box.add_child(button("镇符封声 · 12 体力 / 1 充能", func(): feedback(box, state.seal_plot(index))))
	else:
		var box := open_modal("童影葫芦 · 里面有个小影子", "成长 %d/%d。选择陪伴方式改变成熟后的役灵。\n也可按 4 收割为材料；破壳需要空安置位。" % [p.growth, FarmState.CROPS.gourd.growth_days])
		for pair in [["eat", "净秽陪伴 → 食秽童"], ["light", "陪它守夜 → 提灯童"], ["shadow", "教它伏影 → 伏影童"]]:
			box.add_child(button(pair[1], func():
				p.branch = pair[0]
				feedback(box, "影子记住了你的陪伴，成长方向已改变。")
			))
		box.add_child(button("成熟后破壳，成为役灵", func():
			var message: String = state.release_gourd(index)
			feedback(box, message)
			spawn_spirits()
		))

func show_shop() -> void:
	var box := open_modal("槐阴村 · 阴物换粮", "持有 %d 文。补充弹药、装备与旅途物资。" % state.money)
	if not seamless:
		for id in CROP_IDS:
			var spec: CropSpec = FarmState.CROPS[id]
			box.add_child(button("%s种子 ×3 · %d 文 · %d 日成熟" % [spec.display_name, spec.seed_price * 3, spec.growth_days], func(): feedback(box, state.buy_seeds(id, 3))))
	box.add_child(button("购买 4 灯油 · 18 文", func():
		if state.money < 18: feedback(box, "铜钱不足。")
		elif not state.can_gain("oil", 4): feedback(box, "行囊已满。")
		else:
			state.money -= 18
			state.oil += 4
			feedback(box, "购得 4 灯油。")
	))

	box.add_child(button("轻弹 ×24 · 12 文", func(): purchase_ammo("light_ammo", 24, 12, box)))
	box.add_child(button("步枪弹 ×12 · 18 文", func(): purchase_ammo("rifle_ammo", 12, 18, box)))
	for pair in [["smg", 80], ["rifle", 140], ["whip", 60], ["silver_sword", 110], ["revolver", 100], ["gatling", 260], ["spellbook", 150], ["curse_doll", 130], ["armor", 50]]:
		box.add_child(button("%s · %d 文" % [YinBalance.WEAPONS[pair[0]].name, pair[1]], func():
			if state.money < pair[1]: feedback(box, "铜钱不足。")
			elif state.equipment.size() >= 20: feedback(box, "装备位已满。")
			else:
				state.money -= pair[1]
				state.grant_gear(pair[0])
				feedback(box, "购入装备，B 穿戴；新枪弹匣为空，U 装填。")
		))

func purchase_ammo(id: String, amount: int, cost: int, box: VBoxContainer) -> void:
	if state.money < cost: feedback(box, "铜钱不足。")
	elif not state.can_gain(id, amount): feedback(box, "行囊已满。")
	else:
		state.money -= cost
		state.supplies[id] += amount
		feedback(box, "购得 %s ×%d。" % [YinItemCatalog.spec(id).display_name, amount])

func show_ritual() -> void:
	var box := open_modal("祭坛 · 全部规则为虚构经营效果", "第六日开放，只能主持一次。先预览收益和已知代价。\n可不祭祀，依靠种植、超度和符器发展；第九夜仍需守住义庄。")
	for pair in [["earth", "地脉灵"], ["guest", "无名客"], ["mountain", "旧山神"]]:
		box.add_child(button("预览：" + pair[1], func():
			var preview := open_modal(pair[1] + " · 确认经营选择", state.ritual_preview(pair[0]))
			preview.add_child(button("按预览效果主持祭祀", func(): feedback(preview, state.ritual(pair[0]))))
		))

func show_npc() -> void:
	var box := open_modal("桥边阿婆", "")
	var data := YinDialogueData.new()
	data.speaker = "桥边阿婆"
	data.portrait = YinActorArt.npc_texture(2)
	data.lines.assign([state.story_line(), "这片田里的东西，镇住它，也在养着它。" if state.day >= 8 else "你师父每夜都要点名，有一夜，门外多答了一声。", state.talk()])
	var dialogue := YinDialoguePanel.new()
	dialogue.data = data
	box.add_child(dialogue)
	dialogue.finished.connect(func():
		dialogue.hide()
		if state.day >= 10 and state.boss_defeated:
			box.add_child(button("封镇：镇守 100、污染 -25（本章不可更改）", func(): feedback(box, state.choose_ending("seal"))))
			box.add_child(button("共处：契合 +20、怨气 -10（本章不可更改）", func(): feedback(box, state.choose_ending("coexist"))))
		else: close_modal()
	)

func show_inventory() -> void:
	show_character("背包")

func show_storage() -> void:
	show_inventory_grid(true)

func show_inventory_grid(with_storage: bool) -> void:
	bag_model.sync()
	chest_model.sync()
	var box := open_modal("义庄仓箱" if with_storage else "行囊", "命息 %d · 铜钱 %d · 修为 %d
探索装备并参与四方纷争；站到遗骸上按 V 顷刻炼化。" % [state.health, state.money, state.cultivation])
	if with_storage:
		var card: Panel = modal.get_node("ModalCard")
		card.position = Vector2(12, 12)
		card.size = Vector2(616, 336)
		var layout: VBoxContainer = card.get_node("Layout")
		layout.size = Vector2(588, 312)
		var scroll: ScrollContainer = layout.get_node("Scroll")
		scroll.custom_minimum_size = Vector2(588, 238)
		box.custom_minimum_size.x = 572
		box.get_child(0).custom_minimum_size.x = 570
		box.get_child(0).text = "命息 %d · 铜钱 %d · B 查看装备" % [state.health, state.money]
	var view := YinInventoryPanel.new()
	view.bag = bag_model
	view.chest = chest_model
	view.show_chest = with_storage
	view.use_item.connect(func(id):
		close_modal()
		placement.selected = id
		refresh("绿色可放，红色被占用。左键放置，Esc 取消。")
	)
	view.drop_item.connect(func(id):
		if state.container_count("bag", id) < 1: return
		state.set_container_count("bag", id, state.container_count("bag", id) - 1)
		close_modal()
		spawn_loot(id, 1, player.position + player.facing * 44)
		notify_action("物品已放在地上，靠近可以拾回。")
	)
	view.mutated.connect(func(): notify_action("物品已存放，进度已保存。"))
	box.add_child(view)

func show_journal() -> void:
	open_modal("阴田手札 · 十日祭帖", "\n\n".join(state.journal))

func show_factions() -> void:
	var box := open_modal("四方势力 · P", YinFactions.report(state))
	for war in state.factions.wars:
		for side in ["defender","attacker"]:
			var choice:=button("支援%s · %s"%["守方" if side=="defender" else "攻方",YinFactions.NAMES[war[side]]],func():
				var message: String=YinFactions.choose_side(state,int(war.id),side)
				for actor in get_tree().get_nodes_in_group("enemies")+get_tree().get_nodes_in_group("faction_guards"):
					if actor.record.has("war_id"):
						actor.remove_from_group("enemies");actor.remove_from_group("faction_guards")
						actor.add_to_group("faction_guards" if YinFactions.friendly(state,actor.record) else "enemies")
						actor.hurtbox.collision_layer=0 if YinFactions.friendly(state,actor.record) else 16
				persist();show_factions();refresh(message)
			)
			choice.disabled=war.get("player_side","")!="" and war.player_side!=side
			box.add_child(choice)

	box.add_child(button("援助当前最弱势力 · 30 文",func():
		var result: String=YinFactions.aid_weakest(state)
		persist()
		show_factions()
		refresh(result)
	))
	box.add_child(button("资助青槐村 · 30 文 · 每日一次", func():
		var message: String = YinFactions.sponsor(state)
		persist()
		show_factions()
		notify_action(message)
	))

func show_pause() -> void:
	var box := open_modal("暂停", "进度自动保存 · 世界已暂停")
	box.add_child(button("操作帮助", func(): open_modal("操作", "WASD 移动 · E 互动 · 空格/左键攻击\nJ / 左键轻击 · 右键近战重击 · 滚轮换武器 · U 装填\nShift 闪避 · F 镇符 · G 符火 · V 免费炼化\nI 行囊 · B 装备 · H 随从 · Tab 地图\nR 点名 · C 指令 · K 书信 · L 手札\nP 势力 · O 委托 · T 黄昏 · M 环境音")))
	box.add_child(button("四方势力 · P", show_factions))
	box.add_child(button("委托 · O", show_quests))
	box.add_child(button("地图 · Tab", func(): show_character("地图")))
	box.add_child(button("书信 · K", func(): show_character("书信")))
	box.add_child(button("画面与分辨率设置", func(): show_character("设置")))
	box.add_child(button("存档并返回标题", func():
		persist()
		if not save_failed: get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
	))
	box.add_child(button("保存义庄进度", func():
		persist()
		feedback(box, "进度已保存。" if not save_failed else "保存失败。")
	))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player):
		persist()
		get_tree().quit()

func _exit_tree() -> void:
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null

func use_terrain() -> void:
	if action_cooldown > 0 or state.energy < 4: return
	var target: YinTerrainResource = null
	var distance: float = 52
	for node in get_tree().get_nodes_in_group("terrain_resources"):
		if not node.is_inside_tree() or node.is_queued_for_deletion() or node.world != world or node.required_tool != tool: continue
		var next: float = player.position.distance_to(node.position)
		if next < distance and player.facing.dot(player.position.direction_to(node.position)) > 0.2:
			target = node
			distance = next
	if target == null:
		refresh("面朝近处的树使用斧头，面朝岩石使用铁镐。")
		return
	var ray := PhysicsRayQueryParameters2D.create(player.position + Vector2(0, -4), target.position + Vector2(0, -4), 1)
	var blocked: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(ray)
	if not blocked.is_empty() and blocked.collider != target: return
	if not player.state_machine.begin("tool", 0.25): return
	player.attack_time = 0.18
	player.held_item = "tool%d" % tool
	action_cooldown = 0.3
	if target.strike(tool):
		state.energy -= 4
		notify_action("工具击中了槐木。" if tool == 4 else "工具击中了青石。")

func spawn_loot(item: String, count: int, at: Vector2) -> void:
	var target: Vector2 = Vector2(clampf(at.x, 20, world.level_size.x - 20), clampf(at.y, 20, world.level_size.y - 20))
	if not world.is_safe_position(target):
		target = player.position
		for offset in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var alternative: Vector2 = player.position + offset * 44
			if world.is_safe_position(alternative):
				target = alternative
				break
	var record: Dictionary = {"id": state.next_id, "item": item, "count": count, "zone": state.zone, "at": [target.x, target.y]}
	state.next_id += 1
	state.drops.append(record)
	spawn_pickups()

func spawn_pickups() -> void:
	for old in get_tree().get_nodes_in_group("loose_items"): old.queue_free()
	for record in state.drops:
		if not seamless and record.zone != state.zone: continue
		var pickup := YinItemPickup.new()
		pickup.game = self
		pickup.record = record
		pickup.position = Vector2(record.at[0], record.at[1])
		pickup.add_to_group("loose_items")
		world.actors.add_child(pickup)

func smart_tool(index: int) -> int:
	if index < 0 or index >= state.plots.size(): return -1
	var plot: Dictionary = state.plots[index]
	if not plot.tilled: return 0
	if plot.crop == "": return 1
	if plot.growth >= FarmState.CROPS[plot.crop].growth_days: return 3
	if not plot.watered: return 2
	return -1
func suggested_action(index: int) -> String:
	var kind: int = smart_tool(index)
	if kind == 1: return "播种 " + FarmState.CROPS[state.selected_crop].display_name
	if kind == 3 and state.plots[index].crop == "rice" and not state.plots[index].sealed: return "先按 E 封声，再收割"
	return ["翻土", "播种", "浇灌", "收割"][kind] if kind >= 0 else "今日已浇灌，等待生长"
func toggle_smart() -> void:
	state.smart_farming = not state.smart_farming
	notify_action("智能劳作已开启：空格依次翻土、播种、浇灌与收获。" if state.smart_farming else "手动工具：I 角色背包中选择。")
func spawn_gear_pickups() -> void:
	for old in get_tree().get_nodes_in_group("gear_pickups"): old.queue_free()
	for record in state.gear_drops:
		if not seamless and record.zone != state.zone: continue
		var pickup := YinGearPickup.new()
		pickup.game = self
		pickup.record = record
		pickup.position = Vector2(record.at[0], record.at[1])
		pickup.add_to_group("gear_pickups")
		world.actors.add_child(pickup)
func show_equipment() -> void:
	show_character("穿戴")

func equipment_content(box: VBoxContainer) -> void:
	var slots:=HBoxContainer.new()
	slots.add_theme_constant_override("separation",6)
	box.add_child(slots)
	for slot in ["melee","primary","secondary"]:
		var worn: Array=state.equipment.filter(func(gear):return gear.id==state.weapon_slots[slot])
		var text: String={"melee":"近战","primary":"主武器","secondary":"副武器"}[slot]+"\n"+(YinBalance.WEAPONS[worn[0].weapon].name if not worn.is_empty() else "空位")
		var slot_button:=button(text,func():
			if worn.is_empty():return
			state.equip(worn[0].id);player.held_item=state.current_gear().weapon
			persist();show_equipment()
		,Vector2(160,35))
		slot_button.disabled=worn.is_empty()
		if not worn.is_empty():
			slot_button.icon=YinBalance.icon(worn[0].weapon);slot_button.expand_icon=true
			slot_button.add_theme_constant_override("icon_max_width",22)
		slots.add_child(slot_button)
	var displayed: Array = state.equipment.duplicate()
	var opening_reward: bool=not YinFirstJourney.guide(state).is_empty() and state.quests.has("first_watch") and state.quests.first_watch.claimed
	displayed.sort_custom(func(a,b):
		var rank_a: int=3 if opening_reward and a.weapon=="silver_sword" and a.id!=state.weapon_slots.melee else (2 if a.id==state.equipped_gear else (1 if a.id==state.equipped_armor else 0))
		var rank_b: int=3 if opening_reward and b.weapon=="silver_sword" and b.id!=state.weapon_slots.melee else (2 if b.id==state.equipped_gear else (1 if b.id==state.equipped_armor else 0))
		return rank_a>rank_b if rank_a!=rank_b else int(a.id)<int(b.id)
	)
	for gear in displayed:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		box.add_child(row)
		var spec: Dictionary = YinBalance.WEAPONS[gear.weapon]
		var info: String = "护甲 %d" % YinBalance.armor_value(gear)
		if gear.weapon != "armor":
			info = "伤害 %d · " % YinBalance.damage(spec.damage, YinBalance.level(state.cultivation), gear)
			info += "弹匣 %d/%d" % [gear.magazine, spec.magazine] if spec.ammo != "" else ("气力 %d" % spec.energy if gear.weapon in YinBalance.MAGIC else "距离 %d" % spec.range)
		if gear.weapon!="armor":info+=" · 间隔%.2fs"%float(spec.interval)
		var equip_button := button("%s  %s\n%s" % [YinBalance.gear_name(gear), "已装备" if gear.id in state.weapon_slots.values() or gear.id == state.equipped_armor else "点击装备", info + ("\n" + YinAbilities.affix_text(gear, YinBalance.level(state.cultivation)) if gear.weapon != "armor" else "")], func():
			state.equip(gear.id)
			player.held_item = state.current_gear().weapon
			persist()
			show_equipment()
			refresh("已装备："+YinBalance.gear_name(gear))
		)
		equip_button.add_theme_color_override("font_color", YinBalance.COLORS[int(gear.quality)].lightened(0.12))
		equip_button.add_theme_font_size_override("font_size", 11)
		equip_button.add_theme_stylebox_override("normal", style("223a33", YinBalance.COLORS[int(gear.quality)].darkened(0.35).to_html(false)))
		equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		equip_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		equip_button.icon = YinBalance.icon(gear.weapon)
		equip_button.expand_icon=true
		equip_button.add_theme_constant_override("icon_max_width",44)
		equip_button.tooltip_text = YinWeaponLore.describe(gear.weapon) + "\n获取时自带词条，无需加工\n" + YinAbilities.affix_text(gear, YinBalance.level(state.cultivation))
		var comparison: Array=state.equipment.filter(func(other):return other.id in state.weapon_slots.values() and ((gear.weapon in YinBalance.MELEE and other.weapon in YinBalance.MELEE) or (gear.weapon in YinBalance.GUNS and other.weapon in YinBalance.GUNS) or (gear.weapon in YinBalance.MAGIC and other.weapon in YinBalance.MAGIC)))
		if gear.weapon!="armor" and not comparison.is_empty() and comparison[0].id!=gear.id:
			var old: Dictionary=comparison[0]
			var delta_damage: int=YinBalance.damage(spec.damage,YinBalance.level(state.cultivation),gear)-YinBalance.damage(YinBalance.WEAPONS[old.weapon].damage,YinBalance.level(state.cultivation),old)
			equip_button.text+="\n对比"+YinBalance.WEAPONS[old.weapon].name+"：伤害%+d"%delta_damage
		else:equip_button.text+="\n"+YinWeaponLore.describe(gear.weapon)
		row.add_child(equip_button)
		equip_button.custom_minimum_size.y = 58
		if gear.id not in [state.equipped_gear, state.equipped_armor] and gear.id not in state.weapon_slots.values() and not (opening_reward and gear.weapon=="silver_sword"):
			row.add_child(button("拆解", func():
				var result: String = state.salvage(gear.id)
				show_equipment()
				refresh(result)
				persist()
			))

func choose_tool(index: int) -> void:
	if seamless:return
	combat.cancel_reload()
	tool = clampi(index, 0, TOOL_NAMES.size() - 1)
	state.smart_farming = false
	player.held_item = "tool%d" % tool
	close_modal()
	refresh("手持：" + TOOL_NAMES[tool])

func instant_refine() -> void:
	for remains in state.remains:
		if (seamless or remains.zone == state.zone) and player.position.distance_to(Vector2(remains.at[0], remains.at[1])) <= 28:
			var message: String = state.process_remains(remains.id, "refine")
			spawn_remains_visuals()
			spawn_spirits()
			world.effect(player.position, Color("91d6bb"))
			notify_action(message)
			return
	refresh("站到遗骸上按 V 炼化；无需耗材，完整度需达到 60。")

func show_character(tab: String = "背包") -> void:
	character_tab = tab
	bag_model.sync()
	var level_value: int = YinBalance.level(state.cultivation)
	var box := open_modal({"背包": "行囊", "穿戴": "装备", "技能": "修行", "随从": "随从", "地图": "地图", "书信": "书信", "设置": "设置"}.get(tab, tab), "命息 %d / 气力 %d · 铜钱 %d · 役灵 %d/%d" % [state.health, state.energy, state.money, state.spirits.size(), state.capacity()])
	var card: Panel = modal.get_node("ModalCard")
	card.position = Vector2(44, 10)
	card.size = Vector2(552, 340)
	var layout: VBoxContainer = card.get_node("Layout")
	layout.size = Vector2(524, 318)
	var scroll: ScrollContainer = layout.get_node("Scroll")
	scroll.custom_minimum_size = Vector2(524, 246)
	box.custom_minimum_size.x = 508
	var tabs := HBoxContainer.new()
	tabs.name = "Navigation"
	tabs.add_theme_constant_override("separation", 6)
	layout.add_child(tabs)
	layout.move_child(tabs, 1)
	for name_value in ["背包", "穿戴", "技能", "随从"]:
		var tab_button := button({"背包": "行囊", "穿戴": "装备", "技能": "修行", "随从": "随从"}[name_value], func(): show_character(name_value), Vector2(122, 26))
		tab_button.name = "Tab" + name_value
		tab_button.toggle_mode = true
		tab_button.set_pressed_no_signal(tab == name_value)
		tabs.add_child(tab_button)
	scroll.custom_minimum_size.y = 214
	box.get_child(0).add_theme_font_override("font",YinAppearance.name_font())
	box.get_child(0).text = "%s · %d 文 · Lv%d · 随从 %d/%d" % [state.appearance.name,state.money,level_value,state.spirits.size(),state.capacity()]
	box.get_child(0).add_theme_font_size_override("font_size", 10)
	match tab:
		"背包":
			box.get_child(0).visible = false
			var columns := VBoxContainer.new()
			columns.add_theme_constant_override("separation", 8)
			box.add_child(columns)
			var shortcuts := HBoxContainer.new()
			columns.add_child(shortcuts)
			if not seamless:
				shortcuts.add_child(button("农具 · " + TOOL_NAMES[tool], show_tools, Vector2(155, 24)))
				shortcuts.add_child(button("智能 " + ("开" if state.smart_farming else "关"), func(): toggle_smart(); show_character("背包"), Vector2(110, 24)))
				shortcuts.add_child(button("阴种 · " + FarmState.CROPS[state.selected_crop].display_name, func(): cycle_seed(); show_character("背包"), Vector2(210, 24)))
			var view := YinInventoryPanel.new()
			view.bag = bag_model
			view.chest = chest_model
			view.show_chest = false
			view.use_item.connect(func(id): close_modal(); placement.selected = id; refresh("选择位置，左键放置。"))
			view.drop_item.connect(func(id):
				if state.container_count("bag", id) < 1: return
				state.set_container_count("bag", id, state.container_count("bag", id) - 1)
				close_modal()
				spawn_loot(id, 1, player.position + player.facing * 44)
				notify_action("物品已放在地上。")
			)
			view.mutated.connect(func(): persist())
			columns.add_child(view)
		"穿戴":
			var worn := Label.new()
			worn.text = "护甲：%s · 护甲值 %d" % ["未穿戴" if state.armor_gear().is_empty() else YinBalance.gear_name(state.armor_gear()), YinBalance.armor_value(state.armor_gear())]
			worn.add_theme_font_size_override("font_size", 11)
			worn.add_theme_color_override("font_color", Color("ded9bf"))
			box.add_child(worn)
			equipment_content(box)
			box.add_child(button("外观定制",func(): show_character("外观"),Vector2(120,24)))
		"外观":
			var panel := YinAppearancePanel.new()
			panel.name = "AppearancePanel"
			panel.game = self
			panel.applied.connect(func():
				box.get_child(0).text="%s · %d 文 · Lv%d · 随从 %d/%d"%[state.appearance.name,state.money,YinBalance.level(state.cultivation),state.spirits.size(),state.capacity()]
				refresh("外观已保存。")
			)
			box.add_child(panel)
		"技能": skill_tree_content(box)
		"随从": companion_content(box)
		"书信": mail_content(box)
		"地图":
			var atlas := YinMinimap.new()
			atlas.game = self
			atlas.custom_minimum_size = Vector2(410, 160)
			box.add_child(atlas)
			var route_label := Label.new()
			route_label.text = "义庄 → 乱葬坡 → 后山铳林\n后山东北 → 沉水村【井中龙婆】\n后山东南 → 废戏台【无面伶王】\n后山向东 → 断碑营地 / 枯井 / 山门遗址\n村东码头 → 岛国【荒冢 / 风山 / 双面社】\n村北山道 → 大佛寺【修罗道场 / 护法殿】\n黄点出口 · 红点敌人 · 蓝点役灵 · 白点自己"
			if seamless:route_label.text="西北大佛寺 · 东北岛国 · 西南青槐村 · 东南乱葬岗\n蓝色界河 · 棕色桥梁 · 彩点军队 · 白点旅人\n沿桥跨境，无需出口传送；战场与军队位置实时显示。"
			route_label.add_theme_font_size_override("font_size", 11)
			route_label.add_theme_color_override("font_color", Color("ded9bf"))
			box.add_child(route_label)
		"设置": box.add_child(YinDisplaySettings.panel())

func spawn_villagers() -> void:
	if not seamless and state.zone != "village": return
	for record in state.villagers:
		var actor := YinVillager.new()
		actor.game = self
		actor.record = record
		actor.position = Vector2(record.at[0], record.at[1])
		world.actors.add_child(actor)
func closest_ally(at: Vector2) -> Node2D:
	var result: Node2D = player if state.health > 0 else null
	var best: float = at.distance_to(player.position) if result != null else INF
	for group in ["companions", "villagers"]:
		for actor in get_tree().get_nodes_in_group(group):
			if actor.is_queued_for_deletion() or actor.get_parent() != world.actors or actor.record.hp <= 0: continue
			var distance: float = at.distance_to(actor.position)
			if distance >= best: continue
			var ray := PhysicsRayQueryParameters2D.create(at + Vector2(0, -4), actor.position + Vector2(0, -4), 1)
			if player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				best = distance
				result = actor
	return result
func paragraph(box: VBoxContainer, text: String, font_size: int = 11) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size.x = 492
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color("c0c8ad"))
	box.add_child(result)
	return result
func skill_tree_content(box: VBoxContainer) -> void:
	paragraph(box, "技能点 %d · 每项最多三阶" % state.skill_points())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	for id in ["seal", "fire", "breath", "command"]:
		var spec: Dictionary = YinAbilities.SKILLS[id]
		var rank_value: int = int(state.skill_ranks[id])
		var details: String = "未学习" if rank_value == 0 else "%d 阶" % rank_value
		if id in ["seal", "fire"]:
			details += " · 充能 %d/2 · %.1f 秒回复一次" % [state.skill_charges[id], state.skill_recharge(id)]
		var card := VBoxContainer.new()
		card.custom_minimum_size.x = 244
		grid.add_child(card)
		var title := Label.new()
		title.text = "%s · %s" % [spec.name, "未学" if rank_value == 0 else "%d 阶" % rank_value]
		title.add_theme_color_override("font_color", Color("ded9bf"))
		card.add_child(title)
		var learn := button("学习 / 升阶 " + spec.name, func():
			var message: String = state.learn_skill(id)
			persist()
			show_character("技能")
			refresh(message)
		)
		learn.name = "Learn_" + id
		learn.disabled = rank_value >= 3 or state.skill_points() <= 0 or YinBalance.level(state.cultivation) < spec.level or (spec.parent != "" and state.skill_ranks[spec.parent] == 0)
		learn.tooltip_text = spec.description + "\n" + details
		card.add_child(learn)
func companion_content(box: VBoxContainer) -> void:
	paragraph(box, "随从 %d · 随行 %d · 驻村 %d · 出战数量不限" % [state.spirits.size(),state.spirits.filter(func(s):return s.active and s.get("assignment")=="follow").size(),state.village_guards().size()])
	if state.spirits.is_empty():
		paragraph(box,"暂无随从。去乱葬坡击败异怪，站到遗骸旁按V免费炼化。",12)
		box.add_child(button("追踪初次守夜",func():YinFirstJourney.start(state);persist();show_quests()))
		return
	var actions:=HBoxContainer.new()
	box.add_child(actions)
	for command in [["全员随行","follow"],["智能驻村","village"],["全部休整","rest"]]:
		actions.add_child(button(command[0],func():
			for follower in state.spirits:
				var citizen_id: int=0
				if command[1]=="village":
					var citizens: Array=state.villagers.duplicate()
					citizens.sort_custom(func(a,b):
						var load_a: int=state.village_guards().filter(func(g):return int(g.get("guard_villager",0))==int(a.id)).size()
						var load_b: int=state.village_guards().filter(func(g):return int(g.get("guard_villager",0))==int(b.id)).size()
						return int(a.hp)+load_a*28<int(b.hp)+load_b*28
					)
					citizen_id=int(citizens[0].id)
				state.assign_spirit(follower.id,command[1],citizen_id)
			spawn_spirits();persist();show_character("随从")
		,Vector2(126,26)))
	if state.spirits.is_empty(): paragraph(box, "站到遗骸上 V 炼化，无需耗材。")
	for spirit in state.spirits:
		box.add_child(button("管理 · %s  Lv%d  %d/%d  %s" % [spirit.name, spirit.level, spirit.hp, spirit.max_hp, "倒下" if spirit.hp == 0 else (("驻村守卫" if spirit.get("assignment")=="village" else "随行出战") if spirit.active else "休整")], func(): show_companion(spirit)))

func show_companion(spirit: Dictionary) -> void:
	var meta: Dictionary = YinAbilities.meta(spirit.source_kind)
	var box := open_modal(spirit.name + " · Lv%d" % spirit.level, "生命 %d/%d · 经验 %d/%d\n%s / %s" % [spirit.hp, spirit.max_hp, spirit.xp, spirit.level * 40, meta.active, meta.passive])
	var duty_label: Label=paragraph(box,"当前指令："+{"follow":"随行战斗","village":"驻守青槐村","rest":"义庄休整"}.get(spirit.get("assignment","rest"),"休整"),10)
	duty_label.custom_minimum_size.x=418
	box.add_child(button("派往青槐村 · 优先保护受伤村民",func():
		var citizens: Array=state.villagers.duplicate()
		citizens.sort_custom(func(a,b):return a.hp<b.hp)
		var message: String=state.assign_spirit(spirit.id,"village",int(citizens[0].id))
		spawn_spirits();persist();show_companion(spirit);refresh(message)
	))
	box.add_child(button("归队随行",func():
		var message: String=state.assign_spirit(spirit.id,"follow")
		spawn_spirits();persist();show_companion(spirit);refresh(message)
	))
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(button("召回" if spirit.active else "出战", func():
		var message: String = state.deploy_spirit(spirit.id, not spirit.active)
		spawn_spirits()
		persist()
		show_companion(spirit)
		refresh(message)
	, Vector2(96, 27)))
	row.add_child(button("训练升级", func():
		var message: String = state.train_spirit(spirit.id)
		persist()
		show_companion(spirit)
		refresh(message)
	, Vector2(96, 27)))
	row.add_child(button("疗养", func():
		var message: String = state.heal_spirit(spirit.id)
		persist()
		show_companion(spirit)
		refresh(message)
	, Vector2(96, 27)))
	row.add_child(button("解散", func():
		var confirm := open_modal("解除役灵契约", "确认解散 %s？解散后将离开队伍。" % spirit.name)
		confirm.add_child(button("确认解散", func():
			var message: String = state.dismiss_spirit(spirit.id)
			spawn_spirits()
			persist()
			show_character("随从")
			refresh(message)
		))
	, Vector2(96, 27)))
	(row.get_child(0) as Button).disabled=not spirit.active and spirit.hp<=0
	(row.get_child(0) as Button).tooltip_text="倒下的随从需要先疗养。" if spirit.hp<=0 else "随行数量不限，召回后留在义庄。"
	(row.get_child(1) as Button).disabled=state.bones<2 or spirit.level>=10
	(row.get_child(1) as Button).tooltip_text="训练消耗2骨料，十级封顶。"
	(row.get_child(2) as Button).disabled=spirit.hp>=spirit.max_hp or state.oil<3
	(row.get_child(2) as Button).tooltip_text="疗养消耗3灯油，恢复全部生命。"
	box.add_child(button("安排工作", func(): show_job(spirit)))
	box.add_child(button("返回随从", func(): show_character("随从")))
func mail_content(box: VBoxContainer) -> void:
	paragraph(box, "青槐村完好度 %d/100 · 每 3 日发送求救信\n当日 18:00 袭击，次日 06:00 前消灭来犯者。\n义庄东侧纸灯 E 前往；未救援会造成村庄损坏与村民受伤。" % state.village_integrity)
	if state.letters.is_empty(): paragraph(box, "暂无求救来信。可先前往村庄与六位村民交谈。")
	for letter in state.letters:
		letter.read = true
		paragraph(box, "第 %d 日 · 柳伯的求救信\n村口纸灯被吹灭了，今夜恐有邪祟。愿道长来护住村里的人。\n状态：%s" % [letter.day, {"warned": "已预警，18:00 袭击", "active": "袭击中，请及时救援", "success": "已救援，村民致谢", "failed": "救援失败，村民养伤"}[letter.status]])
func show_villager() -> void:
	var candidates: Array=get_tree().get_nodes_in_group("villagers").filter(func(actor):return not actor.is_queued_for_deletion() and world.can_interact(actor.position,56))
	candidates.sort_custom(func(a,b):return a.position.distance_squared_to(player.position)<b.position.distance_squared_to(player.position))
	for actor in candidates:
		var record: Dictionary = actor.record
		var box := open_modal(record.name, "生命 %d/100 · 村庄完好度 %d\n%s" % [record.hp, state.village_integrity, "今晚求道长护村。" if state.raid_status in ["warned", "active"] else "村民已组织自卫；四方军队会沿界河桥进军。"])
		box.add_child(button("四方局势与援村", show_factions))
		box.add_child(button("派随从保护这位村民",func():show_villager_guard(record)))
		box.add_child(button("聊一聊", func(): show_chat(record)))
		box.add_child(button("委托", func(): show_npc_quests(record)))
		box.add_child(button("阅读村庄来信", func(): show_character("书信")))
		if record.id == 3: box.add_child(button("铁匠交易：武器与弹药", show_shop))
		box.add_child(button("救治村民 · 10 文 · 恢复 40 生命", func():
			if record.hp >= 100: feedback(box, "这位村民已康复。")
			elif state.money < 10: feedback(box, "需要 10 文。")
			else:
				state.money -= 10
				record.hp = mini(100, record.hp + 40)
				persist()
				feedback(box, "药汤让村民恢复了气力。")
		))
		return


func show_tools() -> void:
	var box := open_modal("农具", "选择后直接手持，关闭智能劳作。")
	var tools := GridContainer.new()
	tools.columns = 3
	box.add_child(tools)
	for i in range(TOOL_NAMES.size()):
		var choice := button(TOOL_NAMES[i], func(): choose_tool(i), Vector2(130, 44))
		choice.name = "Tool%d" % i
		var icon := AtlasTexture.new()
		icon.atlas = preload("res://assets/tools.png")
		icon.region = Rect2(i * 16, 0, 16, 16)
		choice.icon = icon
		tools.add_child(choice)

func update_exploration() -> void:
	if state.zone == "temple" and not state.temple_journal.visited:
		state.temple_journal.visited = true
		state.add_log("佛寺异闻：沿青槐村北山道抵达大佛寺。")
	if state.zone == "island" and not state.island_journal.visited:
		state.island_journal.visited = true
		notify_action("发现岛国：异乡地貌在裂海中缝合。可回村向砚青复命。")
	if state.zone != "forest": return
	for id in YinAdventure.LANDMARKS:
		var spec: Dictionary = YinAdventure.LANDMARKS[id]
		if not state.visited_landmarks.has(id) and player.position.distance_to(YinContinent.to_world("forest",spec.at) if seamless else spec.at) < 110:
			state.visited_landmarks[id] = true
			notify_action("发现地标：" + spec.name)
func update_quest_tracker() -> void:
	if not is_instance_valid(quest_tracker): return
	var first: Dictionary=YinFirstJourney.guide(state)
	if not first.is_empty():
		quest_tracker.text="O "+first.title+"\n"+first.hint
		quest_tracker.tooltip_text=YinAdventure.QUESTS.first_watch.description
		return
	var id: String = state.tracked_quest
	if id == "" or not state.quests.has(id):
		quest_tracker.custom_minimum_size = Vector2(194, 40)
		quest_tracker.size = Vector2(194, 40)
		quest_tracker.position = Vector2(436, 104)
		var remaining: Array=state.mainline_stages().filter(func(stage):return stage.id not in state.mainline_claimed)
		quest_tracker.text = "O 主线已完成 · 自由探索" if remaining.is_empty() else "O 主线 · %s%s\n%s"%[remaining[0].name," · 可领取" if remaining[0].done else "",{"gear":"探索精英与宝箱 · 获取二阶武器","journey":"探索后山 / 岛国 / 大佛寺","balance":"P 查看实力 · 援助弱方与止战"}[remaining[0].id]]
		quest_tracker.tooltip_text = state.mainline_summary()
		return
	quest_tracker.custom_minimum_size = Vector2(194, 40)
	quest_tracker.position = Vector2(436, 104)
	var spec: Dictionary = YinAdventure.QUESTS[id]
	var count: int = YinAdventure.progress(state, id)
	quest_tracker.text = "O %s  %d/%d\n%s" % [spec.name, count, spec.target, "返回村庄复命" if count >= spec.target else {"hunt": "前往乱葬坡", "delivery": "收集物资后交给委托人", "survey": "探索后山三处遗址", "temple_visit": "从村北山道前往大佛寺", "temple_hunt": "调查佛寺四类异怪", "temple_boss": "大佛寺平息护法战意", "temple_relic": "向阿祁领取般若剑", "island_visit": "从村东码头乘船", "island_hunt": "岛国调查五类妖怪", "island_boss": "岛国祭场平息首领", "island_relic": "向阿祁缔结神器契约"}[spec.kind]]
	quest_tracker.tooltip_text = spec.description
func show_quests() -> void:
	var box := open_modal("委托", "O 打开任务栏 · 一次追踪一项")
	box.get_child(0).text = "主线：获取装备，平衡四方势力。田园经营可自由选择。"
	if not state.quests.has(YinFirstJourney.ID):
		box.add_child(button("接取 · 初次守夜（推荐从这里开始）",func():YinFirstJourney.start(state);persist();show_quests()))
	else:
		var first: Dictionary=YinFirstJourney.guide(state)
		if not first.is_empty():
			var instruction: Label=paragraph(box,first.title+"\n"+first.hint,12)
			instruction.custom_minimum_size.x=410
		if not state.quests.first_watch.claimed:
			var claim:=button("复命 · 领取银剑与35文",func():
				var result: String=YinAdventure.claim(state,YinFirstJourney.ID,0)
				persist();show_quests();refresh(result)
			)
			claim.disabled=state.zone!="farm" or YinAdventure.progress(state,YinFirstJourney.ID)<2
			box.add_child(claim)
	var overview: Label=paragraph(box,state.mainline_summary(),11)
	overview.custom_minimum_size.x=418
	box.add_child(button("领取主线阶段奖励",func():
		var result: String = state.claim_mainline()
		show_quests()
		refresh(result)
		persist()
	))
	box.add_child(button("查看四方实力与调停",show_factions))
	for id in state.quests:
		var spec: Dictionary = YinAdventure.QUESTS[id]
		var completed: bool = state.quests[id].claimed
		var summary := Label.new()
		summary.text = "%s · %s\n%s" % [spec.name, "已领取奖励" if completed else "%d/%d" % [YinAdventure.progress(state, id), spec.target], spec.description]
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary.custom_minimum_size.x = 410
		summary.add_theme_color_override("font_color", Color("ded9bf"))
		summary.add_theme_font_size_override("font_size", 11)
		box.add_child(summary)
		if not completed:
			box.add_child(button("正在追踪" if state.tracked_quest == id else "追踪 · " + spec.name, func():
				state.tracked_quest = id
				persist()
				show_quests()
			))
func show_npc_quests(record: Dictionary) -> void:
	var box := open_modal(record.name + " · 委托", "复命时领取报酬；奖励由委托规则决定。")
	var offered: bool = false
	for id in YinAdventure.QUESTS:
		var spec: Dictionary = YinAdventure.QUESTS[id]
		if spec.npc != int(record.id) or not YinAdventure.available(state, id): continue
		offered = true
		var detail := Label.new()
		detail.text = "%s\n%s\n报酬：%d 文 + %s" % [spec.name, spec.description, spec.money, YinBalance.WEAPONS[spec.weapon].name if spec.weapon != "" else "异闻进展"]
		detail.custom_minimum_size.x = 410
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_color_override("font_color", Color("ded9bf"))
		detail.add_theme_font_size_override("font_size", 11)
		box.add_child(detail)
		if not state.quests.has(id):
			box.add_child(button("接取 · " + spec.name, func():
				var message: String = YinAdventure.accept(state, id)
				persist()
				show_npc_quests(record)
				refresh(message)
			))
		elif not state.quests[id].claimed:
			box.add_child(button("复命 · %d/%d" % [YinAdventure.progress(state, id), spec.target], func():
				var message: String = YinAdventure.claim(state, id, int(record.id))
				persist()
				show_npc_quests(record)
				refresh(message)
			))
		else:
			detail.text += "\n已完成并领取。"
	if not offered: box.get_child(0).text = "暂时没有委托，去问问其他村民。"
func show_chat(record: Dictionary) -> void:
	var box := open_modal(record.name + " · 交谈", "离线交谈 · 可输入问题，也可选择话题")
	var layout: VBoxContainer = modal.get_node("ModalCard/Layout")
	var chat_scroll: ScrollContainer = layout.get_node("Scroll")
	chat_scroll.get_v_scroll_bar().changed.connect(func():
		if is_instance_valid(chat_scroll):chat_scroll.set_deferred("scroll_vertical",int(chat_scroll.get_v_scroll_bar().max_value))
	)
	chat_scroll.custom_minimum_size.y = 142
	var topics := HBoxContainer.new()
	layout.add_child(topics)
	layout.move_child(topics, 1)
	var composer := HBoxContainer.new()
	composer.add_theme_constant_override("separation", 6)
	layout.add_child(composer)
	layout.move_child(composer, layout.get_child_count() - 2)
	var transcript := Label.new()
	transcript.custom_minimum_size = Vector2(410, 62)
	transcript.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transcript.add_theme_font_size_override("font_size", 11)
	transcript.add_theme_color_override("font_color", Color("ded9bf"))
	box.add_child(transcript)
	var input := LineEdit.new()
	input.name = "NpcChatInput"
	input.placeholder_text = "想问什么？例如：附近宝箱在哪里"
	input.max_length = 240
	input.custom_minimum_size = Vector2(330, 28)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	composer.add_child(input)
	if not dialogue_log.has(record.id): dialogue_log[record.id] = []
	if dialogue_log[record.id].is_empty(): dialogue_log[record.id].append(record.name + "：" + npc_dialogue.reply(state, record, "你好"))
	transcript.text = "\n\n".join(dialogue_log[record.id])
	var send := func():
		var text: String = input.text.strip_edges()
		if text == "": return
		dialogue_log[record.id].append("你：" + text)
		dialogue_log[record.id].append(record.name + "：" + npc_dialogue.reply(state, record, text))
		while dialogue_log[record.id].size() > 6: dialogue_log[record.id].pop_front()
		transcript.text = "\n\n".join(dialogue_log[record.id])
		input.clear()
		call_deferred("scroll_chat_to_end", chat_scroll)
		input.grab_focus()
	for topic in ["委托", "近况", "武器", "探索"]:
		topics.add_child(button(topic, func(): input.text = topic; send.call(), Vector2(96, 24)))
	input.text_submitted.connect(func(_value): send.call())
	composer.add_child(button("发送", send, Vector2(78, 28)))
	input.grab_focus()

func scroll_chat_to_end(scroll: ScrollContainer) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll): scroll.set_deferred("scroll_vertical", int(scroll.get_v_scroll_bar().max_value))

func show_weapon_popup() -> void:
	var gear: Dictionary=state.current_gear()
	var spec: Dictionary=YinBalance.WEAPONS[gear.weapon]
	popup_weapon=gear.weapon
	weapon_popup_time=2.4
	weapon_popup.visible=true
	weapon_popup_label.text="%s · %s\n%s"%[YinBalance.gear_name(gear),("三元素" if gear.get("enchantment","")=="all" else YinBalance.ELEMENT_NAMES.get(gear.get("enchantment",""),"无附魔")),"弹药 %d/%d · U 装填"%[gear.magazine,spec.magazine] if spec.ammo!="" else ("气力 %d · 远程施术"%state.energy if gear.weapon in YinBalance.MAGIC else "近战 · J / 左键挥击")]

func show_villager_guard(citizen: Dictionary) -> void:
	var box:=open_modal("守卫安排 · "+citizen.name,"选择随从前往守卫。驻村角色留在青槐村，离开地图后仍参与抵御入侵。")
	for spirit in state.spirits:
		var choice:=button("%s · Lv%d · %d/%d"%[spirit.name,spirit.level,spirit.hp,spirit.max_hp],func():
			var message: String=state.assign_spirit(spirit.id,"village",int(citizen.id))
			spawn_spirits();persist();show_villager_guard(citizen);refresh(message)
		)
		choice.disabled=spirit.hp<=0 or (spirit.get("assignment")=="village" and int(spirit.get("guard_villager",0))==int(citizen.id))
		box.add_child(choice)
	if state.spirits.is_empty():box.get_child(0).text="暂无随从。遗骸旁按V可免费炼化，随后在这里安排守卫。"

func show_landmark(id: String) -> void:
	if not YinAdventure.LANDMARKS.has(id):return
	state.visited_landmarks[id]=true
	var descriptions: Dictionary={"camp":"旧军营仍有可供整备的火盆。东侧军械箱藏着遗留武器。","well":"井壁刻着通往村庄的水脉记号。附近密匣由残留守卫看护。","temple":"残碑指向佛寺旧道。探索记录可回青槐村向砚青复命。"}
	var box:=open_modal(YinAdventure.LANDMARKS[id].name,descriptions[id])
	box.add_child(button("查看探索委托",show_quests))
	var actions: Dictionary={"camp":"营地整备 · 10文 / 20分钟", "well":"井水净身 · 5气力 / 10分钟", "temple":"役灵祈安 · 20文 / 20分钟"}
	box.add_child(button(actions[id],func():
		var message: String=use_landmark(id)
		if message.begins_with("完成"):
			close_modal();refresh(message)
		else:feedback(box,message)
	))
	persist()

func use_landmark(id: String) -> String:
	if not YinAdventure.LANDMARKS.has(id) or state.zone!="forest":return "此处无法使用。"
	var at: Vector2=(YinContinent.to_world("forest",YinAdventure.LANDMARKS[id].at) if seamless else YinAdventure.LANDMARKS[id].at)+Vector2(0,40)
	if not world.can_interact(at,45):return "请靠近地标。"
	if nearest_enemy(player.position,150)!=null:return "附近仍有敌人，先确保安全。"
	match id:
		"camp":
			if state.money<10:return "整备需要10文。"
			state.money-=10;state.health=mini(100,state.health+20);state.energy=mini(100,state.energy+10)
			state.tick(5)
		"well":
			if player.poison_time<=0 and player.scorch_time<=0 and player.snare_time<=0:return "目前无需净身。"
			if state.energy<5:return "净身需要5点气力。"
			state.energy-=5;player.poison_time=0;player.scorch_time=0;player.snare_time=0
			state.tick(2.5)
		"temple":
			var wounded: Array=state.spirits.filter(func(spirit):return spirit.hp>0 and spirit.hp<spirit.max_hp)
			if wounded.is_empty():return "役灵暂无需要疗养的伤势。"
			if state.money<20:return "祈安需要20文。"
			state.money-=20
			for spirit in wounded:spirit.hp=mini(spirit.max_hp,spirit.hp+maxi(1,roundi(spirit.max_hp*0.2)))
			state.tick(5)
	persist()
	return {"camp":"完成营地整备：生命+20、气力+10。","well":"完成井水净身：中毒、灼烧与束缚已清除。","temple":"完成役灵祈安：存活役灵恢复20%生命。"}[id]

func show_world_echo(id: String) -> void:
	if not YinWorldDistricts.PLACES.has(id):return
	var place: Dictionary=YinWorldDistricts.PLACES[id]
	var box=open_modal(place.name,place.text)
	if not state.world_echoes.has(id):
		state.world_echoes[id]=true
		state.add_log("旅途见闻："+place.name)
	if not state.exploration_rewards.has(id):
		var reward=button("领取探索遗物 · "+YinExploration28.reward_text(id),func():
			if nearest_enemy(player.position,170)!=null:feedback(box,"先清理周围的敌人，再开启遗物。");return
			var result=YinExploration28.claim(state,id);persist();show_world_echo(id);refresh(result)
		)
		reward.disabled=nearest_enemy(player.position,170)!=null;box.add_child(reward)
		if reward.disabled:paragraph(box,"附近仍有守卫，清理后可领取探索遗物。",11)
	else:box.add_child(button("遗物已领取 · B查看装备",func():show_character("穿戴")))
	box.add_child(button("循驿路返回义庄",func():travel_post28("home")))
	box.add_child(button("继续探索 · Esc",close_modal))
	persist()

func show_waypost28(region: String) -> void:
	if region not in YinFactions.IDS:return
	state.visited_posts[region]=true
	var owner=YinTerritory28.owner(state,region)
	var box=open_modal(YinFactions.NAMES[region]+" · 驿路据点","当前由"+YinFactions.NAMES[owner]+"控制 · 驻守%d人 / 在途%d人。\n战胜守军后，远征军必须进入并守住旗帜才能占领，幸存者会留下驻守。"%[YinTerritory28.present_guards(state,region),YinTerritory28.guards(state,region).size()-YinTerritory28.present_guards(state,region)])
	box.add_child(button("返回义庄",func():travel_post28("home")))
	for id in YinFactions.IDS:
		if id==region or not state.visited_posts.has(id):continue
		box.add_child(button("沿已发现驿路前往"+YinFactions.NAMES[id],func():travel_post28(id)))
	if owner!=region:
		var allies=YinTerritory28.guards(state,region).all(func(e):return e.get("player_allied",false))
		var action="调停归还" if owner=="village" or allies else "清除占领军后归还"
		box.add_child(button(action+YinFactions.NAMES[region],func():
			if nearest_enemy(player.position,180)!=null:feedback(box,"先解除据点周围的威胁，再调停归还。");return
			var result=YinTerritory28.restore_homeland(state,region);persist();show_waypost28(region);refresh(result)
		))
	box.add_child(button("查看领地与驻军",show_factions));persist()
func travel_post28(id: String) -> void:
	if nearest_enemy(player.position,250)!=null:
		if modal!=null:feedback(modal.get_node("ModalCard/Layout"),"附近有敌人，先脱离战斗再启程。")
		return
	if id!="home" and not state.visited_posts.has(id):return
	var at: Vector2=YinContinent.HOME+Vector2(0,96) if id=="home" else YinTerritory28.post(id)+Vector2(0,56)
	if nearest_enemy(at,250)!=null:refresh("目的地正在交战，驿路暂时关闭。");return
	close_modal();player.position=at;player.velocity=Vector2.ZERO;player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll();update_territory();persist();refresh("沿已打通的驿路抵达。")
