extends Control
const SaveStore = preload("res://scripts/save_store.gd")
var state := FarmState.new()
var tool: int = 0
var status_label: Label
var stats_label: Label
var tool_buttons: Array[Button] = []
var plot_buttons: Array[Button] = []

func _ready() -> void:
	SaveStore.load_game(state)
	var bg := ColorRect.new()
	bg.color = Color("f6f5ee")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.position = Vector2(38, 24)
	root.size = Vector2(1024, 670)
	root.add_theme_constant_override("separation", 16)
	add_child(root)
	var title := Label.new()
	title.text = "青苔牧场   /   MOSSFIELD"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("35473c"))
	root.add_child(title)
	stats_label = Label.new()
	stats_label.add_theme_color_override("font_color", Color("496b50"))
	root.add_child(stats_label)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	root.add_child(body)
	var farm := VBoxContainer.new()
	body.add_child(farm)
	var landscape := Control.new()
	landscape.custom_minimum_size = Vector2(700, 120)
	landscape.draw.connect(func():
		landscape.draw_rect(Rect2(0, 0, 700, 120), Color("95b974"))
		landscape.draw_rect(Rect2(550, 0, 80, 120), Color("7aaeb3"))
		landscape.draw_rect(Rect2(70, 40, 110, 65), Color("f1deb8"))
		landscape.draw_colored_polygon(PackedVector2Array([Vector2(55, 40), Vector2(125, 0), Vector2(195, 40)]), Color("b66d52"))
		landscape.draw_rect(Rect2(110, 65, 25, 40), Color("725343"))
		for x in [260, 360, 455]:
			landscape.draw_rect(Rect2(x, 70, 10, 35), Color("795f43"))
			landscape.draw_circle(Vector2(x + 5, 52), 29, Color("5f8f57"))
	)
	farm.add_child(landscape)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	farm.add_child(grid)
	for i in range(24):
		var b := Button.new()
		b.custom_minimum_size = Vector2(111, 68)
		b.pressed.connect(func(): refresh(state.use_tool(i, tool)))
		plot_buttons.append(b)
		grid.add_child(b)
	var toolbar := HBoxContainer.new()
	farm.add_child(toolbar)
	for i in range(4):
		var b := make_button(["1 翻土", "2 播种", "3 浇水", "4 收获"][i], func():
			tool = i
			refresh()
		)
		b.custom_minimum_size.x = 170
		b.toggle_mode = true
		tool_buttons.append(b)
		toolbar.add_child(b)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 285
	side.add_theme_constant_override("separation", 18)
	body.add_child(side)
	var guide := Label.new()
	guide.text = "农场日记\n\n一小块土地，一点慢生活。\n\n翻土 → 播种 → 每天浇水\n浇水 3 天后即可收获。\n\n每次劳作消耗 5 点体力。\n回小屋休息可恢复体力。\n\n快捷键：1—4 切换工具"
	guide.add_theme_color_override("font_color", Color("496b50"))
	side.add_child(guide)
	side.add_child(make_button("购买种子 · 5 包 / 40 G", func(): refresh(state.buy_seeds())))
	side.add_child(make_button("出货 · 35 G / 个", func(): refresh(state.sell())))
	side.add_child(make_button("回小屋，结束今天", func():
		state.next_day()
		refresh("新的一天！记得给作物浇水。")
	))
	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Color("496b50"))
	root.add_child(status_label)
	refresh("欢迎来到青苔牧场，点击田块开始翻土。")

func make_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 42
	b.pressed.connect(action)
	return b

func refresh(message: String = "") -> void:
	stats_label.text = "春 · 第 %d 天     |     金币 %d G     |     体力 %d / 100     |     种子 %d     |     萝卜 %d" % [state.day, state.money, state.energy, state.seeds, state.harvest]
	for i in range(24):
		var p: Dictionary = state.plots[i]
		var b := plot_buttons[i]
		b.text = "草地" if not p.tilled else "已翻土"
		if p.crop:
			b.text = "成熟萝卜" if p.growth >= 3 else "幼苗 %d/3" % p.growth
			if p.watered:
				b.text += "\n已浇水"
		var style := StyleBoxFlat.new()
		style.bg_color = Color("adc486") if not p.tilled else Color("98714e")
		if p.watered:
			style.bg_color = Color("785d48")
		style.set_corner_radius_all(5)
		b.add_theme_stylebox_override("normal", style)
	for i in range(4):
		tool_buttons[i].set_pressed_no_signal(i == tool)
	if message != "":
		status_label.text = message
	if not SaveStore.save_game(state):
		status_label.text += "（存档失败）"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			tool = event.keycode - KEY_1
			refresh()
