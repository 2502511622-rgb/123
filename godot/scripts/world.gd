class_name FarmWorld
extends Node2D

const SIZE = Vector2(960, 640)
const FIELD = Vector2(320, 256)
const TILE = 32
const HOME = Vector2(160, 209)
const SHOP = Vector2(780, 238)
const SHIPPING = Vector2(248, 197)
const NPC = Vector2(778, 345)
const TILE_TEXTURE = preload("res://assets/tiles.png")
const CROP_TEXTURE = preload("res://assets/crops.png")
var state: FarmState
var player: FarmPlayer
var actors: Node2D
var trees: Array[Vector2] = []
var obstacles: Array[Rect2] = []
var time: float = 0.0
var redraw_timer: float = 0.0
var selected_plot: int = -1
var effects: Array = []

func _ready() -> void:
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	boundary(Rect2(-32, -32, 1024, 32))
	boundary(Rect2(-32, 640, 1024, 32))
	boundary(Rect2(-32, 0, 32, 640))
	boundary(Rect2(960, 0, 32, 640))
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
	add_sign(Vector2(108, 212), "小屋")
	add_sign(Vector2(727, 239), "杂货铺")
	add_sign(Vector2(223, 217), "出货箱")
	add_sign(Vector2(751, 358), "小禾")
	for i in range(3):
		var chicken := Node2D.new()
		chicken.set_script(preload("res://scripts/chicken.gd"))
		chicken.position = Vector2(168 + i * 30, 370 + i * 20)
		chicken.set("phase", i * 2.0)
		actors.add_child(chicken)

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
	var body := StaticBody2D.new()
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
	if at.x < 16 or at.x > 944 or at.y < 20 or at.y > 624:
		return false
	var body_rect := Rect2(at + Vector2(-7, -9), Vector2(14, 10))
	for obstacle in obstacles:
		if obstacle.intersects(body_rect):
			return false
	return true

func plot_at(at: Vector2) -> int:
	var local_pos: Vector2 = at - FIELD
	if local_pos.x < 0 or local_pos.y < 0 or local_pos.x >= FarmState.WIDTH * TILE or local_pos.y >= FarmState.HEIGHT * TILE:
		return -1
	return int(local_pos.y / TILE) * FarmState.WIDTH + int(local_pos.x / TILE)

func plot_center(index: int) -> Vector2:
	return FIELD + Vector2(index % FarmState.WIDTH, int(index / FarmState.WIDTH)) * TILE + Vector2(16, 16)

func reachable(index: int) -> bool:
	return index >= 0 and index < state.plots.size() and player.position.distance_to(plot_center(index)) <= 49

func front_plot() -> int:
	return plot_at(player.position + Vector2(0, -6) + player.facing * 25)

func nearest_interaction() -> String:
	for pair in [["home", HOME], ["shipping", SHIPPING], ["shop", SHOP], ["npc", NPC]]:
		if player.position.distance_to(pair[1]) < 45:
			return pair[0]
	return ""

func effect(at: Vector2, tint: Color) -> void:
	effects.append({"at": at, "color": tint, "age": 0.0})

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
		queue_redraw()

func tile(id: int, at: Vector2) -> void:
	draw_texture_rect_region(TILE_TEXTURE, Rect2(at, Vector2(32, 32)), Rect2(id * 16, 0, 16, 16))

func _draw() -> void:
	if state == null:
		return
	for y in range(20):
		for x in range(30):
			var at := Vector2(x * TILE, y * TILE)
			var id: int = (x * 7 + y * 11) % 8
			if y == 7 or y == 8 or (x == 8 and y >= 6 and y <= 17) or (x >= 22 and x <= 25 and y >= 6 and y <= 11):
				id = 10
			if x == 20 or x == 21:
				id = 11 + int(time * 2) % 3
			if (x * 13 + y * 7) % 31 == 0 and id < 8:
				id = 14
			tile(id, at)
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
		tile(9 if p.watered else (8 if p.tilled else 15), at)
		if p.crop != "":
			var row: int = ["turnip", "carrot", "tomato"].find(p.crop)
			var stage: int = 5 if p.growth >= FarmState.CROPS[p.crop].growth_days else mini(4, p.growth + 1)
			draw_texture_rect_region(CROP_TEXTURE, Rect2(at + Vector2(0, -4), Vector2(32, 32)), Rect2(stage * 16, row * 16, 16, 16))
		if p.watered:
			draw_rect(Rect2(at + Vector2(26, 25), Vector2(2, 4)), Color("8fc6d1"))
		if i == selected_plot and reachable(i):
			draw_rect(Rect2(at + Vector2(1, 1), Vector2(30, 30)), Color("f5dfa1"), false, 2)
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
