class_name FarmWorld
extends Node2D
signal loot_requested(item: String, count: int, at: Vector2)

const SIZE = Vector2(960, 640)
const FIELD = Vector2(320, 256)
const TILE = 32
const HOME = Vector2(160, 209)
const SHOP = Vector2(780, 238)
const SHIPPING = Vector2(248, 197)
const NPC = Vector2(778, 345)
const ALTAR = Vector2(214, 433)
const GATE = Vector2(846, 531)
const RETURN_GATE = Vector2(155, 547)
const TILE_TEXTURE = preload("res://assets/tiles.png")
const CROP_TEXTURE = preload("res://assets/crops.png")
var state: FarmState
var tile_farm: YinTileFarm
var player: FarmPlayer
var actors: Node2D
var trees: Array[Vector2] = []
var obstacles: Array[Rect2] = []
var time: float = 0.0
var redraw_timer: float = 0.0
var selected_plot: int = -1
var effects: Array = []
var feedback: Node2D

func _ready() -> void:
	tile_farm = YinTileFarm.new()
	tile_farm.name = "TerrainLayers"
	add_child(tile_farm)
	tile_farm.build(state.zone)
	tile_farm.refresh(state, 0)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	feedback = Node2D.new()
	feedback.z_index = 20
	add_child(feedback)
	add_child(actors)
	boundary(Rect2(-32, -32, 1024, 32))
	boundary(Rect2(-32, 640, 1024, 32))
	boundary(Rect2(-32, 0, 32, 640))
	boundary(Rect2(960, 0, 32, 640))
	if state.zone in ["hall", "shop"]:
		build_interior()
		return
	if state.zone == "graveyard":
		build_graveyard()
		return
	# River is solid except the wooden bridge.
	boundary(Rect2(640, 0, 64, 224))
	boundary(Rect2(640, 288, 64, 352))
	prop("cottage", Vector2(160, 200), Vector2(-80, -132), Rect2(-65, -95, 130, 89))
	prop("store", Vector2(784, 225), Vector2(-64, -116), Rect2(-54, -90, 108, 81))
	prop("chest", SHIPPING, Vector2(-20, -30), Rect2(-17, -22, 34, 22))
	prop("npc", NPC, Vector2(-16, -42), Rect2(-7, -12, 14, 12))
	for x in range(32, 960, 64):
		if x < 640 or x > 704:
			trees.append(Vector2(x, 57))
			trees.append(Vector2(x + 10, 626))
	for y in range(130, 600, 96):
		trees.append(Vector2(36, y))
		trees.append(Vector2(926, y + 25))
	for p in [Vector2(83, 295), Vector2(124, 325), Vector2(598, 138), Vector2(593, 493), Vector2(750, 490), Vector2(826, 529), Vector2(102, 526), Vector2(184, 565)]:
		trees.append(p)
	for p in trees:
		prop("tree", p, Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	for x in range(304, 592, 32):
		prop("fence", Vector2(x + 16, 242), Vector2(-16, -28), Rect2(-15, -11, 30, 11))
		prop("fence", Vector2(x + 16, 477), Vector2(-16, -28), Rect2(-15, -11, 30, 11))
	for y in range(260, 457, 32):
		if y != 324 and y != 356:
			prop("fence", Vector2(306, y + 16), Vector2(-16, -28), Rect2(-10, -24, 18, 28))
		prop("fence", Vector2(590, y + 16), Vector2(-16, -28), Rect2(-10, -24, 18, 28))
	for p in [Vector2(216, 468), Vector2(616, 571), Vector2(852, 405)]:
		prop("rock", p, Vector2(-20, -28), Rect2(-14, -15, 28, 15))
	add_sign(Vector2(108, 212), "义庄")
	add_sign(Vector2(727, 239), "槐阴村")
	add_sign(Vector2(223, 217), "出货箱")
	add_sign(Vector2(751, 358), "桥边阿婆")
	prop("altar", ALTAR, Vector2(-32, -64), Rect2(-24, -19, 48, 19))
	add_sign(ALTAR + Vector2(-25, 5), "虚构祭坛")
	prop("lantern", GATE, Vector2(-16, -48), Rect2(-5, -7, 10, 7))
	add_sign(GATE + Vector2(-23, 7), "乱葬坡 ↑")
	for at in [Vector2(212, 240), Vector2(318, 238), Vector2(600, 478)]:
		prop("lantern", at, Vector2(-16, -48), Rect2(-4, -4, 8, 4))
	for placed in state.placements:
		if placed.zone == state.zone: install_placement(placed)
	if state.hall_level >= 2:
		for x in [90, 123]:
			prop("chest", Vector2(x, 228), Vector2(-20, -28), Rect2(-16, -20, 32, 20))

func build_graveyard() -> void:
	for x in range(40, 945, 64):
		prop("tree", Vector2(x, 55), Vector2(-32, -88), Rect2(-8, -16, 16, 16))
		prop("tree", Vector2(x, 627), Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	for at in [Vector2(220, 180), Vector2(380, 340), Vector2(480, 200), Vector2(560, 440), Vector2(720, 310), Vector2(800, 150), Vector2(355, 485)]:
		prop("grave", at, Vector2(-16, -48), Rect2(-12, -16, 24, 16))
	prop("lantern", RETURN_GATE, Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(RETURN_GATE + Vector2(-34, 8), "返回义庄 ↓")
	add_sign(Vector2(410, 130), "乱葬坡 · 白天也不要久留")

func boundary(rect: Rect2) -> void:
	obstacles.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func prop(name_text: String, at: Vector2, offset: Vector2, collision_rect: Rect2) -> void:
	var body: StaticBody2D
	if name_text in ["tree", "rock"]:
		var key: String = "%s:%d:%d" % [state.zone, int(at.x), int(at.y)]
		if state.terrain.has(key) and state.terrain[key].hp == 0: return
		var resource := YinTerrainResource.new()
		resource.state = state
		resource.world = self
		resource.key = key
		resource.kind = name_text
		resource.required_tool = 4 if name_text == "tree" else 5
		resource.world_rect = Rect2(at + collision_rect.position, collision_rect.size)
		body = resource
	else: body = StaticBody2D.new()
	body.position = at
	actors.add_child(body)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/%s.png" % name_text)
	sprite.centered = false
	sprite.position = offset
	sprite.scale = Vector2(2, 2)
	body.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = collision_rect.size
	collision.position = collision_rect.get_center()
	collision.shape = shape
	body.add_child(collision)
	obstacles.append(Rect2(at + collision_rect.position, collision_rect.size))

func add_sign(at: Vector2, text: String) -> void:
	var label := Label.new()
	label.position = at
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("f8e2b3"))
	label.add_theme_color_override("font_shadow_color", Color("574e38"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

func is_safe_position(at: Vector2) -> bool:
	if state.zone in ["hall", "shop"] and not Rect2(200, 140, 560, 330).has_point(at): return false
	if at.x < 16 or at.x > 944 or at.y < 20 or at.y > 624:
		return false
	var body_rect := Rect2(at + Vector2(-7, -9), Vector2(14, 10))
	for obstacle in obstacles:
		if obstacle.intersects(body_rect):
			return false
	return true

func plot_at(at: Vector2) -> int:
	return tile_farm.plot_at(at)

func plot_center(index: int) -> Vector2:
	return tile_farm.plot_center(index)

func reachable(index: int) -> bool:
	return index >= 0 and index < state.plots.size() and player.position.distance_to(plot_center(index)) <= 49

func front_plot() -> int:
	return plot_at(player.position + Vector2(0, -6) + player.facing * 25)

func nearest_interaction() -> String:
	if state.zone in ["hall", "shop"]:
		if player.position.distance_to(Vector2(480, 461)) < 40: return "exit_interior"
		if player.position.distance_to(Vector2(480, 267)) < 45: return "workbench" if state.zone == "hall" else "counter"
		if state.zone == "hall" and player.position.distance_to(Vector2(306, 361)) < 45: return "storage"
		if state.zone == "hall" and player.position.distance_to(Vector2(666, 327)) < 45: return "bed"
		return ""
	if state.zone == "graveyard":
		return "return" if player.position.distance_to(RETURN_GATE) < 47 else ""
	for pair in [["home", HOME], ["shipping", SHIPPING], ["shop", SHOP], ["npc", NPC], ["altar", ALTAR], ["gate", GATE]]:
		if player.position.distance_to(pair[1]) < 45:
			return pair[0]
	return ""

func effect(at: Vector2, tint: Color) -> void:
	var burst := YinPixelBurst.new()
	burst.position = at
	burst.tint = tint
	feedback.add_child(burst)

func _process(delta: float) -> void:
	time += delta
	for e in effects:
		e.age += delta
	effects = effects.filter(func(e): return e.age < 0.5)
	redraw_timer += delta
	if redraw_timer >= 0.12:
		redraw_timer = 0
		if is_instance_valid(player):
			selected_plot = front_plot()
		tile_farm.refresh(state, time)
		queue_redraw()

func tile(id: int, at: Vector2) -> void:
	draw_texture_rect_region(TILE_TEXTURE, Rect2(at, Vector2(32, 32)), Rect2(id * 16, 0, 16, 16))

func _draw() -> void:
	if state == null:
		return
	if state.zone in ["hall", "shop"]:
		draw_rect(Rect2(0, 0, 960, 120), Color("293b3b"))
		draw_rect(Rect2(0, 480, 960, 160), Color("293b3b"))
		draw_rect(Rect2(0, 120, 176, 360), Color("293b3b"))
		draw_rect(Rect2(784, 120, 176, 360), Color("293b3b"))
		draw_rect(Rect2(192, 128, 576, 60), Color("56665d"))
		for x in range(196, 768, 32):
			draw_line(Vector2(x, 132), Vector2(x, 184), Color("6f7d6b"), 2)
		for y in range(192, 478, 16):
			draw_line(Vector2(192, y), Vector2(768, y), Color("a18b66"), 2)
			for x in range(192 + (16 if y % 32 == 0 else 0), 768, 64): draw_line(Vector2(x, y), Vector2(x, y + 16), Color("a18b66"), 1)
		draw_rect(Rect2(420, 278, 120, 74), Color("7e6a4f"))
		draw_rect(Rect2(424, 282, 112, 66), Color("a5946d"), false, 2)
		for x in range(432, 532, 12): draw_rect(Rect2(x, 288, 4, 54), Color("8b7959"))
		return
	if state.zone == "graveyard":
		draw_rect(Rect2(0, 0, 960, 640), Color(0.15, 0.21, 0.23, 0.24))
		for y in range(160, 576, 32): tile(10, Vector2(128, y))
		for x in range(128, 864, 32): tile(10, Vector2(x, 512))
		return
	# River banks and plank bridge.
	draw_rect(Rect2(636, 0, 4, 224), Color("c2b47c"))
	draw_rect(Rect2(704, 0, 4, 224), Color("c2b47c"))
	draw_rect(Rect2(636, 288, 4, 352), Color("c2b47c"))
	draw_rect(Rect2(704, 288, 4, 352), Color("c2b47c"))
	draw_rect(Rect2(628, 224, 88, 64), Color("97704b"))
	for y in range(226, 286, 6):
		draw_rect(Rect2(630, y, 84, 4), Color("c1a16b"))
	draw_rect(Rect2(628, 224, 88, 4), Color("71553b"))
	draw_rect(Rect2(628, 284, 88, 4), Color("71553b"))
	# Field tiles and crop sprites.
	for i in range(state.plots.size()):
		var p: Dictionary = state.plots[i]
		var at := plot_center(i) - Vector2(16, 16)
		if p.yin > 0:
			draw_rect(Rect2(at + Vector2(1, 1), Vector2(30, 30)), Color("52637b"), false, 1)
		if p.crop == "rice" and p.growth >= 2 and not p.sealed and int(time) % 3 == 0:
			draw_rect(Rect2(at + Vector2(5, 20), Vector2(20, 2)), Color("a38078"))
		if p.watered:
			draw_rect(Rect2(at + Vector2(26, 25), Vector2(2, 4)), Color("8fc6d1"))
		if i == selected_plot and reachable(i):
			draw_rect(Rect2(at + Vector2(1, 1), Vector2(30, 30)), Color("f5dfa1"), false, 2)
	# Choices alter the courtyard: extra mortuary roof, paper strips and footprints.
	if state.hall_level >= 2:
		draw_rect(Rect2(70, 204, 84, 24), Color("515e5c"))
		for x in range(73, 150, 7): draw_rect(Rect2(x, 206, 4, 18), Color("707973"))
	if state.ritual_count > 0:
		for x in range(165, 253, 16):
			draw_rect(Rect2(x, 418, 4, 14), Color("bdc2a3"))
	if state.pollution >= 10:
		for i in range(mini(10, int(state.pollution / 5))):
			draw_rect(Rect2(230 + i * 7, 268 - i * 5, 3, 6), Color("626e60"))
	if state.ending != "":
		draw_arc(ALTAR, 39, 0, TAU, 20, Color("7ea29a") if state.ending == "seal" else Color("b1a170"), 2)
	# Mushroom patches and wild flowers.
	for at in [Vector2(210, 316), Vector2(475, 523), Vector2(746, 425), Vector2(566, 172), Vector2(86, 444)]:
		draw_rect(Rect2(at + Vector2(3, 5), Vector2(4, 8)), Color("e4c99c"))
		draw_rect(Rect2(at, Vector2(10, 6)), Color("c77e5d"))
		draw_rect(Rect2(at + Vector2(2, 1), Vector2(2, 2)), Color("f1d7a3"))
	for e in effects:
		var color: Color = e.color
		color.a = 1 - e.age * 2
		for i in range(5):
			var offset: Vector2 = Vector2(cos(i * 1.25), sin(i * 1.25)) * float(e.age) * 32
			draw_rect(Rect2(e.at + offset - Vector2(1, 1), Vector2(3, 3)), color)

func draw_remains_mark(at: Vector2, integrity: int) -> void:
	draw_texture_rect(load("res://assets/remains.png"), Rect2(at - Vector2(24, 12), Vector2(48, 28)), false, Color.WHITE if integrity >= 60 else Color("967668"))

func build_interior() -> void:
	boundary(Rect2(176, 112, 608, 16))
	boundary(Rect2(176, 478, 608, 16))
	boundary(Rect2(176, 112, 16, 382))
	boundary(Rect2(768, 112, 16, 382))
	prop("workbench", Vector2(480, 247), Vector2(-40, -50), Rect2(-34, -24, 68, 24))
	prop("lantern", Vector2(480, 475), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(440, 474), "返回院落")
	add_sign(Vector2(440, 264), "案台 · E 经营" if state.zone == "hall" else "柜台 · E 交易")
	if state.zone == "hall":
		prop("chest", Vector2(306, 343), Vector2(-20, -30), Rect2(-17, -22, 34, 22))
		add_sign(Vector2(278, 360), "仓箱 · E 存取")
		prop("bed", Vector2(666, 305), Vector2(-40, -30), Rect2(-35, -18, 70, 18))
		add_sign(Vector2(638, 324), "卧榻 · E 休息")
		for x in [282, 340]: prop("grave", Vector2(x, 231), Vector2(-16, -48), Rect2(-12, -16, 24, 16))
	else:
		for x in [308, 370, 588, 650]: prop("chest", Vector2(x, 220), Vector2(-20, -30), Rect2(-17, -22, 34, 22))

func install_placement(record: Dictionary) -> void:
	var at := Vector2(record.at[0], record.at[1])
	prop("lantern" if record.kind == "paper_lamp" else "grave", at, Vector2(-16, -48), Rect2(-6, -10, 12, 10))

func damage_number(at: Vector2, amount: int, tint: Color) -> void:
	var text := Label.new()
	text.text = str(amount)
	text.position = at + Vector2(-8, -58)
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", tint)
	text.add_theme_color_override("font_shadow_color", Color("24383b"))
	text.add_theme_constant_override("shadow_offset_x", 1)
	text.add_theme_constant_override("shadow_offset_y", 1)
	feedback.add_child(text)
	var tween := text.create_tween().set_parallel(true)
	tween.tween_property(text, "position:y", text.position.y - 22, 0.55)
	tween.tween_property(text, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(text.queue_free)
func spell_trace(start: Vector2, end: Vector2, method: String) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([start, start.lerp(end, 0.5) + Vector2(0, -6), end])
	line.width = 3
	line.default_color = Color("e5a166") if method == "fire" else Color("8dd8c7")
	feedback.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.22)
	tween.tween_callback(line.queue_free)
	effect(end, line.default_color)
