extends Node2D
const SaveStore = preload("res://scripts/save_store.gd")
const TOOL_NAMES = ["锄头", "种子", "水壶", "收获"]
const CROP_IDS = ["turnip", "carrot", "tomato"]
var state := FarmState.new()
var world: FarmWorld
var player: FarmPlayer
var tool: int = 0
var hud: Control
var stats_label: Label
var date_label: Label
var inventory_label: Label
var quest_label: Label
var context_label: Label
var seed_button: Button
var status_label: Label
var tool_buttons: Array[Button] = []
var energy_bar: ProgressBar
var modal: Control
var message_time: float = 8.0
var autosave_time: float = 0.0
var action_cooldown: float = 0.0
var load_ok: bool = true
var save_failed: bool = false

func _ready() -> void:
	ThemeDB.fallback_font = preload("res://assets/mossfield-font.ttf")
	setup_inputs()
	load_ok = SaveStore.load_game(state)
	world = FarmWorld.new()
	world.state = state
	add_child(world)
	player = FarmPlayer.new()
	player.position = state.player_position if world.is_safe_position(state.player_position) else Vector2(300, 350)
	player.facing = state.saved_facing
	world.actors.add_child(player)
	world.player = player
	var weather_layer := CanvasLayer.new()
	weather_layer.layer = 5
	add_child(weather_layer)
	var weather := Control.new()
	weather.set_script(preload("res://scripts/atmosphere.gd"))
	weather.set("state", state)
	weather_layer.add_child(weather)
	build_hud()
	refresh("欢迎来到青苔牧场！WASD 移动，走近田块按空格劳作。" if load_ok else "存档损坏：已开启新农场。原文件保留，首次操作后保存新进度。")

func setup_inputs() -> void:
	var keys: Dictionary = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "use_tool": [KEY_SPACE], "interact": [KEY_E], "cycle_seed": [KEY_Q], "inventory": [KEY_I], "pause_game": [KEY_ESCAPE]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func style(bg: String = "ead4a2", border: String = "856b48") -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(bg)
	s.border_color = Color(border)
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	s.shadow_color = Color(0.12, 0.16, 0.10, 0.18)
	s.shadow_size = 3
	return s

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
	l.add_theme_color_override("font_color", Color("514c35"))
	parent.add_child(l)
	return l

func button(text: String, action: Callable, size_value: Vector2 = Vector2(100, 27)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size_value
	b.add_theme_stylebox_override("normal", style("e6c996"))
	b.add_theme_stylebox_override("hover", style("f3dfb2", "a7824b"))
	b.add_theme_stylebox_override("pressed", style("a5b47b", "6b7d50"))
	b.add_theme_stylebox_override("focus", style("efdda9", "627950"))
	b.add_theme_color_override("font_color", Color("4c4b35"))
	b.add_theme_color_override("font_hover_color", Color("4c4b35"))
	b.add_theme_color_override("font_pressed_color", Color("384a32"))
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(action)
	return b

func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	var title := panel(Vector2(10, 10), Vector2(158, 55))
	label("青苔牧场", Vector2(10, 3), title, 18)
	label("M O S S F I E L D", Vector2(11, 30), title, 9)
	var date_panel := panel(Vector2(432, 10), Vector2(198, 52))
	date_label = label("", Vector2(10, 3), date_panel, 13)
	stats_label = label("", Vector2(10, 27), date_panel, 11)
	var energy_panel := panel(Vector2(10, 134), Vector2(158, 32))
	label("体力", Vector2(8, 6), energy_panel, 11)
	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(40, 10)
	energy_bar.size = Vector2(98, 12)
	energy_bar.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color("b6a17b")
	energy_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("829f5d")
	energy_bar.add_theme_stylebox_override("fill", fill)
	energy_panel.add_child(energy_bar)
	var task_panel := panel(Vector2(10, 71), Vector2(158, 57))
	label("小禾的委托", Vector2(10, 4), task_panel, 12)
	quest_label = label("", Vector2(10, 24), task_panel, 10)
	var toolbar := panel(Vector2(184, 307), Vector2(272, 43))
	var row := HBoxContainer.new()
	row.position = Vector2(5, 4)
	row.add_theme_constant_override("separation", 4)
	toolbar.add_child(row)
	for i in range(4):
		var b := button("%d %s" % [i + 1, TOOL_NAMES[i]], func():
			tool = i
			refresh()
		, Vector2(62, 34))
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		tool_buttons.append(b)
		row.add_child(b)
	seed_button = button("", cycle_seed, Vector2(164, 29))
	seed_button.position = Vector2(10, 318)
	seed_button.focus_mode = Control.FOCUS_NONE
	hud.add_child(seed_button)
	var bag := button("I 背包", show_inventory, Vector2(72, 29))
	bag.position = Vector2(558, 318)
	bag.focus_mode = Control.FOCUS_NONE
	hud.add_child(bag)
	var hint := panel(Vector2(158, 283), Vector2(324, 22))
	context_label = label("", Vector2(8, 4), hint, 10)
	var toast := panel(Vector2(176, 10), Vector2(248, 52))
	toast.name = "Toast"
	status_label = label("", Vector2(8, 5), toast, 11)
	status_label.size = Vector2(232, 44)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _process(delta: float) -> void:
	action_cooldown = maxf(0, action_cooldown - delta)
	if modal == null:
		state.tick(delta)
		if state.minutes >= 1320:
			advance_day()
			refresh("夜深了，自动回小屋休息。新的一天开始！")
		message_time -= delta
		hud.get_node("Toast").visible = message_time > 0 or save_failed
		autosave_time += delta
		if autosave_time > 15:
			autosave_time = 0
			persist()
	state.player_position = player.position
	state.saved_facing = player.facing
	update_labels()

func update_labels() -> void:
	var hour: int = int(state.minutes) / 60
	var minute: int = int(state.minutes) % 60
	date_label.text = "春 %02d 日  %02d:%02d  %s" % [state.day, hour, minute, "雨" if state.weather == "rain" else "晴"]
	stats_label.text = "%d G  /  体力 %d  /  自动存档" % [state.money, state.energy]
	energy_bar.value = state.energy
	seed_button.text = "Q %s种子 × %d" % [FarmState.CROPS[state.selected_crop].display_name, state.seed_count(state.selected_crop)]
	quest_label.text = "已完成 · 奖励已领取" if state.quest_claimed else "收获 %d / 3 颗 · 奖励 100 G" % mini(3, state.total_harvest)
	var kind: String = world.nearest_interaction()
	var hints: Dictionary = {"home": "E 回小屋休息，进入下一天", "shipping": "E 出货：出售背包里的全部作物", "shop": "E 逛杂货铺，购买三种作物种子", "npc": "E 和小禾聊天 / 领取委托奖励"}
	context_label.text = hints[kind] if hints.has(kind) else "WASD 移动 · 空格 / 点击近处田块 · 1–4 工具"

func persist() -> void:
	state.player_position = player.position
	state.saved_facing = player.facing
	save_failed = not SaveStore.save_game(state)
	if save_failed:
		status_label.text = "保存失败，请检查 user:// 目录是否可写。"

func refresh(message: String = "") -> void:
	for i in range(4):
		tool_buttons[i].set_pressed_no_signal(i == tool)
	if message != "":
		status_label.text = message
		message_time = 6
		hud.get_node("Toast").show()
	world.queue_redraw()
	update_labels()

func notify_action(message: String) -> void:
	refresh(message)
	persist()

func cycle_seed() -> void:
	state.selected_crop = CROP_IDS[(CROP_IDS.find(state.selected_crop) + 1) % CROP_IDS.size()]
	refresh("已选择 %s种子，按 2 或点击种子工具播种。" % FarmState.CROPS[state.selected_crop].display_name)
	persist()

func use_plot(index: int) -> void:
	if action_cooldown > 0:
		return
	action_cooldown = 0.18
	if not world.reachable(index):
		refresh("太远了，走到田块旁边再劳作。")
		return
	var previous_energy: int = state.energy
	var previous_harvest: int = state.total_harvest
	var message: String = state.use_tool(index, tool)
	if state.energy != previous_energy or state.total_harvest != previous_harvest:
		world.effect(world.plot_center(index), Color("91c7d6") if tool == 2 else Color("edcf84"))
	notify_action(message)

func _unhandled_input(event: InputEvent) -> void:
	if modal != null:
		if event.is_action_pressed("pause_game"):
			close_modal()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
			tool = event.physical_keycode - KEY_1
			refresh()
		elif event.is_action_pressed("cycle_seed"):
			cycle_seed()
		elif event.is_action_pressed("inventory"):
			show_inventory()
		elif event.is_action_pressed("pause_game"):
			show_pause()
		elif event.is_action_pressed("interact"):
			interact()
		elif event.is_action_pressed("use_tool"):
			use_plot(world.front_plot())
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		use_plot(world.plot_at(world.get_global_mouse_position()))

func interact() -> void:
	match world.nearest_interaction():
		"home":
			var box := open_modal("回小屋休息", "睡觉会推进到下一天，恢复体力。\n今天浇过水的作物会生长，未浇水的不会生长。")
			box.add_child(button("好好睡一觉", func():
				close_modal()
				advance_day()
				notify_action("早安！新的一天开始了，给作物浇水吧。")
			))
			add_close(box)
		"shop":
			show_shop()
		"shipping":
			notify_action(state.sell())
		"npc":
			notify_action(state.talk())
		_:
			refresh("靠近小屋、出货箱、杂货铺或小禾，按 E 互动。")

func advance_day() -> void:
	state.next_day()
	player.position = Vector2(160, 217)
	player.facing = Vector2.DOWN
	persist()

func open_modal(title_text: String, description: String) -> VBoxContainer:
	if modal != null:
		close_modal()
	player.frozen = true
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(modal)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.12, 0.17, 0.14, 0.66)
	modal.add_child(dim)
	var card := panel(Vector2(133, 60), Vector2(374, 244), modal)
	var column := VBoxContainer.new()
	column.position = Vector2(16, 12)
	column.size = Vector2(342, 215)
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", Color("4c4b35"))
	column.add_child(heading)
	var desc := Label.new()
	desc.text = description
	desc.custom_minimum_size.x = 340
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color("706044"))
	column.add_child(desc)
	return column

func add_close(column: VBoxContainer) -> void:
	var b := button("返回农场 · Esc", close_modal)
	column.add_child(b)
	b.grab_focus()

func close_modal() -> void:
	if modal != null:
		modal.queue_free()
		modal = null
	player.frozen = false

func show_shop() -> void:
	var column := open_modal("桥边杂货铺", "持有 %d G。浇水天数决定成熟时间。" % state.money)
	for id in CROP_IDS:
		var spec: CropSpec = FarmState.CROPS[id]
		column.add_child(button("%s种子 × 5 · %d G · %d 天成熟" % [spec.display_name, spec.seed_price * 5, spec.growth_days], func():
			var feedback: String = state.buy_seeds(id)
			notify_action(feedback)
			column.get_child(1).text = "%s\n持有 %d G" % [feedback, state.money]
		))
	add_close(column)

func show_inventory() -> void:
	var text: String = "金币 %d G · 体力 %d/100\n\n" % [state.money, state.energy]
	for id in CROP_IDS:
		var spec: CropSpec = FarmState.CROPS[id]
		text += "%s：种子 %d 包 / 作物 %d 颗 / 出货 %d G\n" % [spec.display_name, state.seed_count(id), state.crop_count(id), spec.sell_price]
	text += "\n走到出货箱旁按 E，即可出售全部作物。"
	var column := open_modal("随身背包", text)
	add_close(column)

func show_pause() -> void:
	var column := open_modal("休息片刻", "时间已暂停。进度保存在你的电脑 user:// 中。\nWASD / 方向键移动，空格劳作，E 互动。\n1–4 切换工具，Q 换种子，I 打开背包。")
	column.add_child(button("保存进度", func():
		persist()
		var feedback: String = "进度已保存。" if not save_failed else "保存失败，请检查目录权限。"
		refresh(feedback)
		column.get_child(1).text = feedback
	))
	add_close(column)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player):
		persist()
		get_tree().quit()
