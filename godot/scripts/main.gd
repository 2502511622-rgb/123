extends Node2D
const SaveStore = preload("res://scripts/save_store.gd")
const TOOL_NAMES = ["铁锹", "阴种", "浇灌", "收割", "斧头", "铁镐"]
const CROP_IDS = ["candle", "vine", "gourd", "rice"]
var state := FarmState.new()
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
var tool_buttons: Array[Button] = []
var health_bar: YinStatBar
var combat_label: Label
var energy_bar: YinStatBar
var modal: Control
var message_time: float = 8
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

func _ready() -> void:
	ThemeDB.fallback_font = preload("res://assets/mossfield-font.ttf")
	setup_inputs()
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
	clock.minute_changed.connect(func(_day, _hour, _minute): update_labels())
	refresh("存档损坏，新建义庄；原文件在首次保存前保留。" if not loaded else "槐阴村的风，带着纸灰的味道。")
	if not state.intro_seen:
		var box := open_modal("阴田录 · 师父遗书", "你刚刚出师，来到槐阴村接管破败义庄与荒田。\n\n田里长出人声，不要答应。\n驱使的东西，每夜都要点名。\n祠堂里的神，不是祖宗。\n\nWASD 移动，空格劳作，E 互动。\nJ 桃木剑 / Shift 闪避 / F 镇符 / G 符火。")
		box.add_child(button("收起遗书，走进义庄", func():
			state.intro_seen = true
			close_modal()
			persist()
		))
	audio_manager.start()
	ambience = audio_manager.player

func build_zone(zone_name: String, at: Vector2) -> void:
	if not YinSceneRouter.ROUTES.has(zone_name): return
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
	player.facing = state.saved_facing
	world.actors.add_child(player)
	player.health_receiver.bind_source(state, "health")
	world.player = player
	clock.bind(state)
	world.loot_requested.connect(spawn_loot)
	placement = YinPlacementController.new()
	placement.game = self
	world.add_child(placement)
	spawn_pickups()
	spawn_enemies()
	spawn_spirits()
	spawn_remains_visuals()

func travel(zone_name: String) -> void:
	close_modal()
	var origin: String = state.zone
	var at: Vector2 = {"graveyard": Vector2(182, 533), "hall": Vector2(480, 435), "shop": Vector2(480, 435)}.get(zone_name, Vector2(160, 218) if origin == "hall" else (Vector2(780, 260) if origin == "shop" else Vector2(810, 538)))
	build_zone(zone_name, at)
	var entry: String = {"hall": "FromHall", "shop": "FromShop", "graveyard": "FromGraveyard"}.get(origin, "Entry") if zone_name == "farm" else "Entry"
	player.position = router.spawn(entry, at)
	notify_action({"graveyard": "乱葬坡：留意攻击预兆，装车后从纸灯处返回。", "hall": "义庄：案台炼骸，仓箱存取，卧榻休息。靠近按 E。", "shop": "杂货铺：走近柜台按 E 购买阴种与灯油。", "farm": "回到院落。进入义庄，在案台处理载骸。"}.get(zone_name, ""))

func spawn_enemies() -> void:
	for e in state.enemies:
		if e.zone != state.zone or e.dead: continue
		var enemy: YinEnemy = preload("res://scenes/actors/enemy.tscn").instantiate()
		enemy.game = self
		enemy.record = e
		enemy.position = Vector2(e.at[0], e.at[1])
		enemy.add_to_group("enemies")
		world.actors.add_child(enemy)

func spawn_spirits() -> void:
	for actor in get_tree().get_nodes_in_group("companions"):
		actor.queue_free()
	for s in state.spirits:
		var actor := Node2D.new()
		actor.set_script(preload("res://scripts/spirit_actor.gd"))
		actor.set("game", self)
		actor.set("record", s)
		actor.position = player.position + Vector2(-30, 20)
		actor.add_to_group("companions")
		world.actors.add_child(actor)

func spawn_remains_visuals() -> void:
	for node in get_tree().get_nodes_in_group("remains"):
		node.queue_free()
	for r in state.remains:
		if r.zone != state.zone: continue
		var sprite := Sprite2D.new()
		sprite.texture = preload("res://assets/remains.png")
		sprite.position = Vector2(r.at[0], r.at[1])
		sprite.scale = Vector2(2, 2)
		sprite.modulate = Color("bdaf96") if r.integrity < 60 else Color.WHITE
		sprite.add_to_group("remains")
		world.actors.add_child(sprite)

func setup_inputs() -> void:
	var keys: Dictionary = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "use_tool": [KEY_SPACE], "interact": [KEY_E], "cycle_seed": [KEY_Q], "inventory": [KEY_I], "pause_game": [KEY_ESCAPE], "attack": [KEY_J], "dodge": [KEY_SHIFT], "seal": [KEY_F], "fire": [KEY_G], "rollcall": [KEY_R], "order": [KEY_C], "journal": [KEY_L], "wait_night": [KEY_T], "mute": [KEY_M]}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func style(bg: String = "e1d2ae", border: String = "514b40") -> StyleBoxFlat:
	return YinPixelTheme.box(bg, border)

func panel(at: Vector2, size_value: Vector2, parent: Node = null) -> Panel:
	var p := Panel.new()
	p.position = at
	p.size = size_value
	p.add_theme_stylebox_override("panel", style())
	(parent if parent != null else hud).add_child(p)
	return p

func label(text: String, at: Vector2, parent: Node, font_size: int = 12) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("424c42"))
	parent.add_child(l)
	return l

func button(text: String, action: Callable, size_value: Vector2 = Vector2(100, 27)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size_value
	b.add_theme_stylebox_override("normal", style("c6c4a0"))
	b.add_theme_stylebox_override("hover", style("e6d6ae", "8c9778"))
	b.add_theme_stylebox_override("pressed", style("829480", "586963"))
	b.add_theme_stylebox_override("focus", style("d3d4b6", "748a76"))
	b.add_theme_color_override("font_color", Color("3e4a42"))
	b.add_theme_color_override("font_hover_color", Color("3e4a42"))
	b.add_theme_color_override("font_focus_color", Color("3e4a42"))
	b.add_theme_color_override("font_pressed_color", Color("263932"))
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
	var title := panel(Vector2(10, 10), Vector2(148, 50))
	label("阴 田 录", Vector2(12, 2), title, 21)
	label("槐阴村 · 十日祭帖", Vector2(12, 31), title, 10)
	var date_panel := panel(Vector2(450, 10), Vector2(180, 52))
	date_label = label("", Vector2(9, 4), date_panel, 12)
	stats_label = label("", Vector2(9, 28), date_panel, 10)
	var energy_panel := panel(Vector2(10, 65), Vector2(148, 48))
	label("气力", Vector2(8, 25), energy_panel, 11)
	energy_bar = YinStatBar.new()
	energy_bar.position = Vector2(40, 29)
	energy_bar.size = Vector2(96, 10)
	energy_panel.add_child(energy_bar)
	label("命息", Vector2(8, 6), energy_panel, 11)
	health_bar = YinStatBar.new()
	health_bar.position = Vector2(40, 10)
	health_bar.size = Vector2(96, 9)
	health_bar.fill_color = Color("b87364")
	energy_panel.add_child(health_bar)
	var task_panel := panel(Vector2(10, 118), Vector2(148, 54))
	quest_label = label("", Vector2(8, 5), task_panel, 10)
	var toolbar := panel(Vector2(166, 305), Vector2(386, 45))
	var row := HBoxContainer.new()
	row.position = Vector2(5, 4)
	row.add_theme_constant_override("separation", 4)
	toolbar.add_child(row)
	for i in range(TOOL_NAMES.size()):
		var b := button("%d %s" % [i + 1, TOOL_NAMES[i]], func():
			tool = i
			refresh()
		, Vector2(59, 34))
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		var icon := AtlasTexture.new()
		icon.atlas = preload("res://assets/tools.png")
		icon.region = Rect2(i * 16, 0, 16, 16)
		b.icon = icon
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 16)
		b.add_theme_font_size_override("font_size", 10)
		b.text = str(i + 1)
		b.tooltip_text = TOOL_NAMES[i] + " · 空格使用"
		tool_buttons.append(b)
		row.add_child(b)
	seed_button = button("", cycle_seed, Vector2(148, 29))
	seed_button.position = Vector2(10, 318)
	seed_button.focus_mode = Control.FOCUS_NONE
	hud.add_child(seed_button)
	var bag := button("I 行囊", show_inventory, Vector2(74, 29))
	bag.position = Vector2(556, 318)
	bag.focus_mode = Control.FOCUS_NONE
	hud.add_child(bag)
	var hint := panel(Vector2(166, 280), Vector2(464, 23))
	context_label = label("", Vector2(7, 4), hint, 10)
	var toast := panel(Vector2(166, 10), Vector2(276, 52))
	toast.name = "Toast"
	status_label = label("", Vector2(8, 5), toast, 11)
	status_label.size = Vector2(260, 44)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var combat_panel := panel(Vector2(450, 68), Vector2(180, 38))
	combat_label = label("", Vector2(8, 4), combat_panel, 10)
	combat_label.size = Vector2(164, 32)

func _process(delta: float) -> void:
	action_cooldown = maxf(0, action_cooldown - delta)
	if modal == null:
		clock.advance(delta, false)
		if state.maybe_boss() and state.zone == "farm":
			spawn_new_boss()
			refresh("义庄门前响了三声。棺中客来了。J 攻击，F 压制，Shift 躲开预兆。")
		if state.zone == "farm" and state.minutes >= 1080 and whisper_day != state.day and state.plots.any(func(p): return p.crop == "rice" and p.growth >= 2 and not p.sealed):
			whisper_day = state.day
			refresh("田里响起师父的声音：你回来啦？——不要答应，靠近返魂稻按 E 封声。")
		if state.minutes >= 1440 and not has_live_boss():
			advance_day()
			refresh("天将亮，自动归庄。" + state.last_report)
		message_time -= delta
		hud.get_node("Toast").visible = message_time > 0 or save_failed
		autosave_time += delta
		if autosave_time > 15:
			autosave_time = 0
			persist()
	state.player_position = player.position
	state.saved_facing = player.facing
	player.burden = not state.cargo.is_empty()
	update_labels()
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
	date_label.text = "第 %02d 日  %02d:%02d  %s" % [state.day, int(state.minutes) / 60, int(state.minutes) % 60, "雨" if state.weather == "rain" else ("夜" if state.minutes >= 1080 else "昼")]
	stats_label.text = "%d 文  油 %d  符 %d" % [state.money, state.oil, state.talismans]
	health_bar.value = state.health
	energy_bar.value = state.energy
	energy_bar.tooltip_text = "气力 %d/100" % state.energy
	health_bar.tooltip_text = "命息 %d/100" % state.health
	combat_label.text = "J 桃木剑  F 镇符  G 符火\nShift " + ("闪避就绪" if player.dodge_cooldown <= 0 else "恢复 %.1fs" % player.dodge_cooldown)
	seed_button.text = "Q %s × %d" % [FarmState.CROPS[state.selected_crop].display_name, state.seed_count(state.selected_crop)]
	quest_label.text = "役灵 %d/%d  污染 %d\n镇守 %d  载骸 %d/2\n%s" % [state.spirits.size(), state.capacity(), state.pollution, state.ward, state.cargo.size(), "手札 L · 第一章已完成" if state.ending != "" else ("棺中客已倒下 · 十日赴约" if state.boss_defeated else ("夜袭进行中 · 不可安睡" if has_live_boss() else "每夜 R 点名 · C 役灵指令"))]
	var kind: String = world.nearest_interaction()
	var hints: Dictionary = {"home": "E 进入义庄：案台、卧榻与仓箱", "shipping": "E 货箱：出售背包里的灵物", "shop": "E 进入杂货铺", "npc": "E 桥边阿婆：村庄秘密与十日抉择", "altar": "E 祭坛：先看收益和代价，也可不祭祀", "gate": "E 进入乱葬坡 · 携骸时移速下降", "return": "E 返回义庄，处理遗骸", "exit_interior": "E 返回院落", "workbench": "E 案台：炼骸、制符与役灵", "counter": "E 柜台：交易", "storage": "E 仓箱：存取、拆分与交换物品", "bed": "E 卧榻：休息至天亮"}
	var general: String = "J 剑 / F 镇符 / G 符火 / Shift 闪避 / E 遗骸" if state.zone == "graveyard" else ("靠近案台、仓箱、卧榻按 E · 门口返回院落" if state.zone == "hall" else ("靠近柜台按 E 交易 · 门口返回院落" if state.zone == "shop" else "WASD 移动 · 空格劳作 · E 互动 · T 待到入夜"))
	var remains_hint: Dictionary = nearest_remains()
	context_label.text = "E 装载遗骸 · " + remains_hint.name if not remains_hint.is_empty() else hints.get(kind, general)

func persist() -> void:
	state.player_position = player.position
	state.saved_facing = player.facing
	save_failed = not save_component.save_game()
	if save_failed: status_label.text = "保存失败，请检查 user:// 是否可写。"

func refresh(message: String = "") -> void:
	for i in range(TOOL_NAMES.size()): tool_buttons[i].set_pressed_no_signal(i == tool)
	if message != "":
		status_label.text = message
		message_time = 7
		hud.get_node("Toast").show()
	world.queue_redraw()
	update_labels()

func notify_action(message: String) -> void:
	refresh(message)
	persist()

func cycle_seed() -> void:
	state.selected_crop = CROP_IDS[(CROP_IDS.find(state.selected_crop) + 1) % 4]
	notify_action("选择 %s。按 2 播种。" % FarmState.CROPS[state.selected_crop].display_name)

func use_plot(index: int) -> void:
	if tool >= 4:
		use_terrain()
		return
	if action_cooldown > 0: return
	action_cooldown = 0.2
	if not world.reachable(index):
		refresh("走近灵田再劳作。")
		return
	if not player.state_machine.begin("tool", 0.25): return
	notify_action(state.use_tool(index, tool))
	world.effect(world.plot_center(index), Color("91b4a8"))

func nearest_enemy(at: Vector2, max_distance: float) -> YinEnemy:
	var found: YinEnemy = null
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or node.is_queued_for_deletion() or node.record.dead or node.get_parent() != world.actors: continue
		var distance: float = at.distance_to(node.position)
		if distance < max_distance:
			found = node
			max_distance = distance
	return found

func attack(method: String) -> void:
	combat.trigger(method)

func take_damage(amount: int) -> void:
	if player.invincible > 0 or modal != null: return
	if state.zone == "farm": amount = maxi(1, amount - int(state.ward / 30))
	player.health_receiver.apply(amount, "enemy")
	player.invincible = 0.6
	world.damage_number(player.position, amount, Color("e59a86"))
	player.hit_feedback = 0.2
	refresh("受伤，命息 -%d。Shift 闪避可避开攻击预兆。" % amount)
	if state.health <= 0:
		for id in state.cargo:
			var r: Dictionary = state.find_remains(id)
			if not r.is_empty():
				r.zone = state.zone
				r.at = [player.position.x, player.position.y]
		state.cargo.clear()
		state.health = 60
		state.energy = 35
		state.money = maxi(0, state.money - 15)
		build_zone("farm", Vector2(160, 218))
		notify_action("护命符将你送回义庄，遗骸掉在昏倒处，损失 15 文。")

func _unhandled_input(event: InputEvent) -> void:
	if modal != null:
		if event.is_action_pressed("pause_game"): close_modal()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
			tool = event.physical_keycode - KEY_1
			refresh()
		elif event.is_action_pressed("cycle_seed"): cycle_seed()
		elif event.is_action_pressed("inventory"): show_inventory()
		elif event.is_action_pressed("pause_game"):
			if placement.selected != "":
				placement.selected = ""
				refresh("已取消放置，物品仍在行囊。")
			else: show_pause()
		elif event.is_action_pressed("interact"): interact()
		elif event.is_action_pressed("use_tool"): use_plot(world.front_plot())
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
		tool = posmod(tool + (1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1), TOOL_NAMES.size())
		refresh()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if placement.selected != "":
			if placement.place(world.get_global_mouse_position()): notify_action("放置完成。")
			else: refresh("距离太远、田地或障碍物占用，未消耗物品。")
		elif state.zone == "graveyard" or nearest_enemy(player.position, 65) != null:
			var aim: Vector2 = player.position.direction_to(world.get_global_mouse_position())
			if aim != Vector2.ZERO and player.state_machine.current in ["idle", "walk"]: player.facing = aim
			attack("sword")
		else: use_plot(world.plot_at(world.get_global_mouse_position()))

func nearest_remains() -> Dictionary:
	for r in state.remains:
		if r.zone == state.zone and player.position.distance_to(Vector2(r.at[0], r.at[1])) < 46: return r
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
	match world.nearest_interaction():
		"home": travel("hall")
		"shop": travel("shop")
		"shipping": notify_action(state.sell())
		"npc": show_npc()
		"altar": show_ritual()
		"gate": travel("graveyard")
		"return": travel("farm")
		"exit_interior": travel("farm")
		"workbench": show_hall()
		"counter": show_shop()
		"storage": show_storage()
		"bed": show_hall()
		_: refresh("靠近义庄、村民、祭坛、出口或遗骸，再按 E。")

func advance_day() -> void:
	state.next_day()
	close_modal()
	build_zone("farm", Vector2(160, 218))
	persist()

func open_modal(title_text: String, description: String) -> VBoxContainer:
	close_modal()
	player.frozen = true
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(modal)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.13, 0.15, 0.75)
	modal.add_child(dim)
	var card := panel(Vector2(88, 25), Vector2(464, 309), modal)
	card.name = "ModalCard"
	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.position = Vector2(14, 10)
	layout.size = Vector2(436, 287)
	layout.add_theme_constant_override("separation", 8)
	card.add_child(layout)
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color("3d4b42"))
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
	desc.add_theme_color_override("font_color", Color("59604b"))
	column.add_child(desc)
	var back := button("合上 · Esc", close_modal)
	layout.add_child(back)
	back.grab_focus()
	return column

func close_modal() -> void:
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
	var box := open_modal("义庄 · 停尸棚", "安置 %d/%d · 骨料 %d · 阴灰 %d · 灯油 %d\n睡觉前先点名！役灵每位每日消耗 1 灯油。" % [state.spirits.size(), state.capacity(), state.bones, state.ash, state.oil])
	box.add_child(button("每夜点名：今天 %s" % ("已完成" if state.called_day == state.day else "未完成"), func(): feedback(box, state.rollcall())))
	box.add_child(button("休息到天亮", func():
		if has_live_boss():
			feedback(box, "夜袭未结束，不能安睡。先击败棺中客，或被护命符救回。")
			return
		advance_day()
		refresh(state.last_report)
	))
	box.add_child(button("役灵安排与供养状况", show_spirits))
	for id in state.cargo:
		var r: Dictionary = state.find_remains(id)
		box.add_child(button("处理运输车：" + r.name, func(): show_remains(r, true)))
	for pair in [["oil", "烛穗 → 4 灯油"], ["talisman", "1 阴灰或 12 文 → 3 张符"], ["ward", "修阵：1 骨料 + 1 灯油 → 镇守 +30"], ["hall", "扩建：3 骨料 + 80 文 → 3 安置位"], ["paper_lamp", "纸灯：2 槐木 + 1 灯油"], ["ward_stake", "阵桩：1 骨料 + 1 青石"]]:
		box.add_child(button(pair[1], func():
			var text: String = state.craft(pair[0])
			feedback(box, text)
		))

func show_spirits() -> void:
	var box := open_modal("役灵册 · 名字必须由你来记", "安置 %d/%d；每日需要 %d 灯油，现有 %d。\n漏点名怨气 +20；缺供养 +25；错配工作 +8。怨气达 60 时失踪并增加污染。\nC 切换跟随 / 驻守 / 集火，战斗时靠近目标自动协助。" % [state.spirits.size(), state.capacity(), state.spirits.size(), state.oil])
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
	var box := open_modal(r.name, "完整度 %d / 残念：%s\n凶性 %d / 阴性：%s\n遗骸的四种用途互斥。火焚完整度低于 60 时不能收役。" % [r.integrity, r.regret, r.fierceness, r.yin])
	if not at_hall:
		box.add_child(button("装车带回（最多 2 具，减速；装满会引来追踪者）", func():
			var message: String = state.pickup(r.id)
			if state.cargo.has(r.id):
				if state.cargo.size() == 2: spawn_tracker()
				spawn_remains_visuals()
				close_modal()
				notify_action(message)
			else: feedback(box, message)
		))
	else:
		box.add_child(button("炼为役灵 · 2 灯油 · 完整度 ≥60", func(): process_choice(box, r, "refine")))
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

func spawn_tracker() -> void:
	var e: Dictionary = {"id": state.next_id, "kind": "water", "zone": state.zone, "at": [player.position.x + 110, player.position.y - 70], "hp": 36, "max_hp": 36, "integrity": 80, "suppressed": false, "dead": false}
	e.at[0] = clampf(e.at[0], 40, 920)
	e.at[1] = clampf(e.at[1], 70, 590)
	state.next_id += 1
	state.enemies.append(e)
	var actor: YinEnemy = preload("res://scenes/actors/enemy.tscn").instantiate()
	actor.game = self
	actor.record = e
	actor.position = Vector2(e.at[0], e.at[1])
	actor.add_to_group("enemies")
	world.actors.add_child(actor)

func show_special_plot(index: int) -> void:
	var p: Dictionary = state.plots[index]
	if p.crop == "rice":
		var box := open_modal("返魂稻 · 声音不属于师父", "生长到第 2 阶段后，每晚污染 +4。\n可观察规律：未封声的成熟稻不能安全收获。\n以 1 张符封声后停止污染，收益保留。")
		box.add_child(button("贴符封声 · 1 张镇符", func(): feedback(box, state.seal_plot(index))))
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
	var box := open_modal("槐阴村 · 阴物换粮", "持有 %d 文。烛穗还可在义庄炼灯油。" % state.money)
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
	data.portrait = preload("res://assets/npc.png")
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
	show_inventory_grid(false)

func show_storage() -> void:
	show_inventory_grid(true)

func show_inventory_grid(with_storage: bool) -> void:
	bag_model.sync()
	chest_model.sync()
	var box := open_modal("义庄仓箱" if with_storage else "行囊", "命息 %d · 铜钱 %d · 修为 %d
载骸 %d/2；遗骸仍需在义庄案台处理。" % [state.health, state.money, state.cultivation, state.cargo.size()])
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

func show_pause() -> void:
	var box := open_modal("纸灯下的片刻", "时间、敌人和角色已暂停。\nWASD 移动，J 桃木剑，F 镇符，G 符火，Shift 闪避。\n1–6 农具，Q 换阴种，E 互动，R 点名，C 役灵指令。\nT 待到黄昏，L 手札，I 行囊，M 开关环境音。")
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
	action_cooldown = 0.3
	if target.strike(tool):
		state.energy -= 4
		notify_action("工具击中了槐木。" if tool == 4 else "工具击中了青石。")

func spawn_loot(item: String, count: int, at: Vector2) -> void:
	var target: Vector2 = Vector2(clampf(at.x, 20, 940), clampf(at.y, 20, 620))
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
		if record.zone != state.zone: continue
		var pickup := YinItemPickup.new()
		pickup.game = self
		pickup.record = record
		pickup.position = Vector2(record.at[0], record.at[1])
		pickup.add_to_group("loose_items")
		world.actors.add_child(pickup)
