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
var level_size := Vector2(960, 640)
var environment_revision: int = 0
var grass: YinLivingGrass
var environment: YinEnvironment
var projectiles: YinProjectiles
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
var biome_material: ShaderMaterial
var feedback: Node2D
var canopy_material: ShaderMaterial
func shared_canopy() -> ShaderMaterial:
	if canopy_material==null:
		canopy_material=ShaderMaterial.new();canopy_material.shader=preload("res://shaders/canopy.gdshader");canopy_material.set_shader_parameter("world_phase",true)
	return canopy_material
var actor_index: YinActorIndex
func combat_index() -> YinActorIndex:
	if actor_index==null:
		actor_index=YinActorIndex.new();actor_index.world=self;add_child(actor_index)
	return actor_index
func screen_bounds() -> Rect2:
	return get_global_transform_with_canvas().affine_inverse()*Rect2(Vector2.ZERO,get_viewport_rect().size)


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
	var scenery := YinScenery.new()
	scenery.name = "ArtScenery"
	scenery.world = self
	scenery.z_index = -1
	add_child(scenery)
	level_size = Vector2(1600, 1280) if state.zone == "temple" else Vector2(2240, 1600) if state.zone == "island" else Vector2(2880, 1920) if state.zone == "forest" else (Vector2(1280, 960) if state.zone in ["sunken", "theatre", "village"] else SIZE)
	environment = YinEnvironment.new()
	environment.name = "Environment"
	environment.world = self
	add_child(environment)
	call_deferred("install_interactions")
	grass = YinLivingGrass.new()
	grass.name = "LivingGrass"
	grass.world = self
	add_child(grass)
	projectiles = YinProjectiles.new()
	projectiles.name = "Projectiles"
	projectiles.game = get_tree().get_first_node_in_group("yintian_game")
	projectiles.world = self
	projectiles.z_index = 18
	add_child(projectiles)
	boundary(Rect2(-32, -32, level_size.x + 64, 32))
	boundary(Rect2(-32, level_size.y, level_size.x + 64, 32))
	boundary(Rect2(-32, 0, 32, level_size.y))
	boundary(Rect2(level_size.x, 0, 32, level_size.y))
	if state.zone == "temple":
		build_temple()
		return
	if state.zone == "island":
		build_island()
		return
	if state.zone == "village":
		build_village()
		return
	if state.zone in ["sunken", "theatre"]:
		build_branch()
		return
	if state.zone == "forest":
		build_forest()
		return
	if state.zone in ["hall", "shop"]:
		build_interior()
		return
	if state.zone == "graveyard":
		build_graveyard()
		return
	prop("lantern", Vector2(900, 350), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(852, 365), "青槐村 → E")
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
	add_sign(Vector2(245,505),"守夜路 ↑ 先镇符，再挥剑")
	add_sign(Vector2(390,425),"骨冢 → 红圈蓄力时闪避")
	add_sign(Vector2(650,330),"铳箭岗 ↑ 利用墓碑遮挡弹道")
	prop("lantern", Vector2(850, 550), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(816, 564), "后山铳林 ↑")

func boundary(rect: Rect2) -> void:
	obstacles.append(rect)
	environment_revision += 1
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	if not self is YinContinentWorld and state.zone=="temple" and rect.position.x>=0 and rect.position.y>=0:YinWallFace.install(self,rect)
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
	body.set_meta("interaction_anchor",at)
	actors.add_child(body)
	var sprite: Sprite2D = YinWindSprite.new() if name_text.begins_with("tree") or name_text=="dead_pine" else Sprite2D.new()
	if sprite is YinWindSprite:
		sprite.world = self
		body.add_to_group("wind_trees")
	var biome: bool=YinBiomeArt.SIZES.has(name_text)
	if biome:body.set_meta("biome_prop",name_text)
	var detailed: bool=biome or YinWorldDetailArt.SIZES.has(name_text) or YinWorldArt.REGIONS.has(name_text) or name_text=="npc"
	sprite.texture = YinWorldDetailArt.texture(name_text) if YinWorldDetailArt.SIZES.has(name_text) else YinBiomeArt.texture(name_text) if biome else (YinArt.texture(name_text) if detailed or YinWorldArt.REGIONS.has(name_text) else load("res://assets/%s.png" % name_text))
	sprite.name = "ArtSprite"
	if name_text == "tree":
		sprite.texture = YinArt.texture(YinRegionStyle.tree(YinContinent.faction(at) if self is YinContinentWorld else state.zone,at))
	sprite.centered = false
	sprite.position = Vector2(-48, -124) if name_text == "tree" else (Vector2(-16, -48) if name_text == "npc" else offset)
	sprite.scale = Vector2.ONE if detailed else Vector2(2, 2)
	body.add_child(sprite)
	if biome and name_text!="dead_pine":sprite.material=shared_biome_surface()
	if name_text in ["lantern","street_lantern"]: body.add_to_group("art_lights")
	if name_text in ["cottage", "store","edo_shop","edo_house"]:
		var window_light := Marker2D.new()
		window_light.position = Vector2(-32, -44)
		window_light.add_to_group("art_lights")
		body.add_child(window_light)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = collision_rect.size
	collision.position = collision_rect.get_center()
	collision.shape = shape
	body.add_child(collision)
	obstacles.append(Rect2(at + collision_rect.position, collision_rect.size))
	environment_revision += 1
	get_node("ArtScenery").queue_redraw()

func add_sign(at: Vector2, text: String) -> void:
	var label := Label.new()
	label.position = at
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("d9cfad"))
	label.add_theme_color_override("font_shadow_color", Color("172d2d"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

func is_safe_position(at: Vector2,half_size: Vector2=Vector2(7,5)) -> bool:
	if not inside_level(at):return false
	var body_rect := Rect2(at+Vector2(0,-4)-half_size,half_size*2)
	for obstacle in obstacles:
		if obstacle.intersects(body_rect):
			return false
	return true

func inside_level(at: Vector2) -> bool:
	if state.zone in ["hall","shop"] and not Rect2(200,140,560,330).has_point(at):return false
	return at.x>=16 and at.x<=level_size.x-16 and at.y>=20 and at.y<=level_size.y-16

func plot_at(at: Vector2) -> int:
	return tile_farm.plot_at(at)

func plot_center(index: int) -> Vector2:
	return tile_farm.plot_center(index)

func reachable(index: int) -> bool:
	return index >= 0 and index < state.plots.size() and player.position.distance_to(plot_center(index)) <= 49

func front_plot() -> int:
	return plot_at(player.position + Vector2(0, -6) + player.facing * 25)

func can_interact(at: Vector2,reach: float=47) -> bool:
	if not is_instance_valid(player) or player.position.distance_to(at)>reach:return false
	var query:=PhysicsRayQueryParameters2D.create(player.position+Vector2(0,4),at,1)
	var hit: Dictionary=get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():return true
	# A gate lamp or chest is the target, not an intervening wall.
	var blocker: Object=hit.collider
	if blocker.has_meta("interaction_anchor") and Vector2(blocker.get_meta("interaction_anchor")).distance_to(at)<12:
		query.exclude=[blocker.get_rid()]
		return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
	return false
func nearest_interaction() -> String:
	var chest: String=nearest_chest()
	var selected: String="treasure" if chest!="" else ""
	var distance_value: float=player.position.distance_to(YinAdventure.CHESTS[chest].at) if chest!="" else INF
	for point in YinWorldLayout.points(state.zone):
		var distance_to: float=player.position.distance_to(point.at)
		if distance_to<distance_value and can_interact(point.at,point.range):
			selected=point.id;distance_value=distance_to
	if state.zone=="village":
		for villager in get_tree().get_nodes_in_group("villagers"):
			if not villager.is_queued_for_deletion() and player.position.distance_to(villager.position)<distance_value and can_interact(villager.position,56):
				selected="villager";distance_value=player.position.distance_to(villager.position)
	return selected
func install_interactions() -> void:
	if not is_inside_tree():return
	var composition:=YinRegionComposition.new()
	composition.world=self
	add_child(composition)
	var trail:=YinTrailGuide.new()
	trail.world=self
	feedback.add_child(trail)
	for point in YinWorldLayout.points(state.zone):
		var beacon:=YinInteractionBeacon.new()
		beacon.world=self;beacon.point=point;beacon.position=point.at
		feedback.add_child(beacon)
	if state.zone=="forest":
		for id in YinAdventure.LANDMARKS:
			var kind: String={"well":"well","camp":"brazier","temple":"shrine"}[id]
			var at: Vector2=YinAdventure.LANDMARKS[id].at
			var size_value: Vector2=Vector2(YinWorldArt.SIZES[kind])
			prop(kind,at,Vector2(-size_value.x*0.5,-size_value.y+2),Rect2(-17,-15,34,15))

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
	draw_texture_rect_region(YinArt.terrain(state.zone), Rect2(at, Vector2(32, 32)), Rect2(id * 32, 0, 32, 32))

func _draw() -> void:
	if state == null:
		return
	if state.zone == "village": return
	if state.zone == "temple":
		draw_temple()
		return
	if state.zone == "island":
		draw_island()
		return
	if state.zone in ["hall", "shop"]:
		draw_rect(Rect2(0, 0, 960, 120), Color("293b3b"))
		draw_rect(Rect2(0, 480, 960, 160), Color("293b3b"))
		draw_rect(Rect2(0, 120, 176, 360), Color("293b3b"))
		draw_rect(Rect2(784, 120, 176, 360), Color("293b3b"))
		draw_texture_rect(YinWorldArt.surface(3),Rect2(192,128,576,60),true,Color("6f756c"))
		draw_line(Vector2(192,188),Vector2(768,188),Color("4c4838"),2)
		return
	if state.zone == "forest":
		draw_texture_rect(YinWorldArt.surface(3),Rect2(948,544,88,96),true)
		draw_texture_rect(YinWorldArt.surface(3),Rect2(948,1360,88,96),true)
		return
	if state.zone == "graveyard":
		draw_rect(Rect2(0, 0, 960, 640), Color(0.15, 0.21, 0.23, 0.24))

		return
	# River banks and plank bridge.
	draw_rect(Rect2(636, 0, 4, 224), Color("647c61"))
	draw_rect(Rect2(704, 0, 4, 224), Color("647c61"))
	draw_rect(Rect2(636, 288, 4, 352), Color("647c61"))
	draw_rect(Rect2(704, 288, 4, 352), Color("647c61"))
	draw_texture_rect(YinWorldArt.surface(3),Rect2(628,224,88,64),true)
	draw_rect(Rect2(628, 224, 88, 4), Color("405548"))
	draw_rect(Rect2(628, 284, 88, 4), Color("405548"))
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
	var fx:=YinCombatVfx.new()
	fx.position=start
	fx.target=end-start
	fx.direction=start.direction_to(end)
	fx.kind=method
	feedback.add_child(fx)
	var game:=get_tree().get_first_node_in_group("yintian_game")
	if game!=null:game.audio_manager.play_cue(method)

func build_forest() -> void:
	add_sign(Vector2(1700, 220), "沉水村 → E")
	add_sign(Vector2(1700, 1020), "废戏台 → E")
	for gate in [Vector2(1760, 250), Vector2(1760, 1050)]:
		prop("lantern", gate, Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	boundary(Rect2(960, 0, 64, 544))
	boundary(Rect2(960, 640, 64, 720))
	boundary(Rect2(960, 1456, 64, 464))
	for x in range(40, 2860, 64):
		prop("tree", Vector2(x, 55), Vector2(-32, -88), Rect2(-8, -16, 16, 16))
		prop("tree", Vector2(x, 1898), Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	for y in range(160, 1840, 112):
		prop("tree", Vector2(40, y), Vector2(-32, -88), Rect2(-8, -16, 16, 16))
		prop("tree", Vector2(2840, y), Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	for at in [Vector2(350, 320), Vector2(620, 680), Vector2(780, 950), Vector2(1120, 370), Vector2(1380, 660), Vector2(1720, 1090)]:
		for offset in [Vector2.ZERO, Vector2(34, -18), Vector2(-30, 18)]: prop("tree", at + offset, Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	for at in [Vector2(700, 180), Vector2(1400, 880), Vector2(1520, 440), Vector2(300, 400)]:
		prop("grave", at, Vector2(-16, -48), Rect2(-12, -16, 24, 16))
	prop("lantern", Vector2(155, 1140), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(125, 1152), "返回乱葬坡 ↓")
	add_sign(Vector2(160, 1070), "后山铳林 · T2–T5 · 远程弹幕与精英")
	# Open trails connect the old eastern exits to three new encounter landmarks.
	add_sign(Vector2(1710, 590), "向东探索 → 宝箱与遗址")
	add_sign(Vector2(608, 720), "猎人旧箱 · 支路")
	add_sign(Vector2(320, 1060), "沿主路向北过桥 → 东侧分岔")
	add_sign(Vector2(1900, 570), "东行 · 断碑营地 / 枯井 / 山门")
	for center in [Vector2(2304, 384), Vector2(2432, 1024), Vector2(2304, 1632)]:
		for offset in [Vector2(-112, -80), Vector2(112, -80), Vector2(-112, 80), Vector2(112, 80)]:
			prop("grave", center + offset, Vector2(-16, -48), Rect2(-12, -16, 24, 16))
		prop("lantern", center + Vector2(-72, 40), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(2220, 400), "断碑营地 · 纸铳兵")
	add_sign(Vector2(2350, 1040), "枯井 · 游魂盘踞")
	add_sign(Vector2(2220, 1650), "山门遗址 · 精英山魈")
	for at in [Vector2(2050, 640), Vector2(2700, 700), Vector2(2100, 1280), Vector2(2680, 1480)]:
		prop("tree", at, Vector2(-32, -88), Rect2(-8, -16, 16, 16))
		prop("rock", at + Vector2(48, 35), Vector2(-20, -28), Rect2(-14, -15, 28, 15))
	for placed in state.placements:
		if placed.zone == "forest": install_placement(placed)

func build_branch() -> void:
	prop("lantern", Vector2(155, 820), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(120, 835), "返回后山 ↓ E")
	add_sign(Vector2(200, 760), "沉水村 · 井中龙婆" if state.zone == "sunken" else "废戏台 · 无面伶王")
	for x in range(40, 1260, 80):
		prop("tree", Vector2(x, 65), Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	for at in [Vector2(440, 220), Vector2(700, 640), Vector2(850, 180)]:
		prop("cottage" if state.zone == "sunken" else "store", at, Vector2(-64, -116), Rect2(-54, -90, 108, 81))
	if state.zone == "sunken":
		boundary(Rect2(580, 160, 48, 220))
		boundary(Rect2(580, 480, 48, 260))
	else:
		for at in [Vector2(940, 240), Vector2(1140, 240)]:
			prop("grave", at, Vector2(-16, -48), Rect2(-12, -16, 24, 16))

func build_village() -> void:
	for at in [Vector2(416, 254), Vector2(716, 254), Vector2(1050, 570), Vector2(110, 480)]:
		prop("tree", at, Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	add_sign(Vector2(1000, 135), "山道 · 大佛寺 ↑ E")
	prop("lantern", Vector2(1152, 160), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(1080, 790), "东码头 · 岛国 → E")
	prop("lantern", Vector2(1200, 820), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	prop("lantern", Vector2(155, 820), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(110, 842), "义庄田园 ↓ E")
	add_sign(Vector2(280, 820), "青槐村 · 村民与求救书信")
	for x in [260, 560, 860]:
		prop("cottage", Vector2(x, 220), Vector2(-80, -132), Rect2(-65, -95, 130, 89))
		prop("store", Vector2(x, 540), Vector2(-64, -116), Rect2(-54, -90, 108, 81))
	for x in range(40, 1250, 80):
		prop("tree", Vector2(x, 75), Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	for y in [300, 620]:
		for x in [180, 470, 770, 1060]: prop("lantern", Vector2(x, y + 70), Vector2(-16, -48), Rect2(-4, -6, 8, 6))

var navigation_cache: Dictionary={}
var navigation_revision: int=-1
var combat_navigation: AStarGrid2D
var navigation_obstacles: int = -1
func clear_body_path(start: Vector2,end: Vector2,half_size: Vector2) -> bool:
	var query:=PhysicsShapeQueryParameters2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=half_size*2
	query.shape=shape
	query.transform=Transform2D(0,start+Vector2(0,-4))
	query.motion=end-start
	query.collision_mask=1
	query.margin=0.1
	var fraction: PackedFloat32Array=get_world_2d().direct_space_state.cast_motion(query)
	return fraction.size()==2 and fraction[0]>0.999

func path_to(start: Vector2,end: Vector2,half_size: Vector2=Vector2(7,5)) -> PackedVector2Array:
	var step: int=32 if self is YinContinentWorld else 16
	var offset: Vector2=Vector2.ONE*step*0.5
	if navigation_revision!=environment_revision:
		navigation_cache.clear();navigation_revision=environment_revision
	var key:=Vector2i(half_size.ceil())
	if not navigation_cache.has(key):
		var grid:=AStarGrid2D.new()
		grid.region=Rect2i(Vector2i.ZERO,Vector2i(level_size/step))
		grid.cell_size=Vector2(step,step);grid.offset=offset
		grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		grid.update()
		for y in range(grid.region.size.y):
			for x in range(grid.region.size.x):
				if not inside_level(Vector2(x*step+offset.x,y*step+offset.y)):grid.set_point_solid(Vector2i(x,y))
				if self is YinContinentWorld:
					var terrain=tile_farm.ground.get_cell_atlas_coords(Vector2i(x,y)).x
					grid.set_point_weight_scale(Vector2i(x,y),1.0 if terrain==10 or terrain>=16 else 1.5)
		# Rasterize each expanded obstacle locally rather than scan every obstacle per cell.
		# A 32px navigation edge must not skip thin lanterns/posts between
		# two free grid centres. Reserve cells by their footprint on the continent.
		var grid_margin:=Vector2.ONE*(step*0.5) if self is YinContinentWorld else Vector2.ZERO
		var clearance: Vector2=half_size+grid_margin
		for obstacle in obstacles:
			var bounds:=Rect2(obstacle.position-clearance+Vector2(0,4),obstacle.size+clearance*2)
			var low:=Vector2i(((bounds.position-offset)/step).floor()).max(Vector2i.ZERO)
			var high:=Vector2i(((bounds.end-offset)/step).ceil()).min(grid.region.size-Vector2i.ONE)
			for y in range(low.y,high.y+1):
				for x in range(low.x,high.x+1):
					var body:=Rect2(Vector2(x*step+offset.x,y*step+offset.y-4)-clearance,clearance*2)
					if obstacle.intersects(body):grid.set_point_solid(Vector2i(x,y))
		navigation_cache[key]=grid
	combat_navigation=navigation_cache[key]
	navigation_obstacles=obstacles.size()
	var from_cell: Vector2i=nearest_nav_cell(combat_navigation,Vector2i(start/step))
	var to_cell: Vector2i=nearest_nav_cell(combat_navigation,Vector2i(end/step))
	if from_cell.x<0 or to_cell.x<0:return PackedVector2Array()
	var points: PackedVector2Array=combat_navigation.get_point_path(from_cell,to_cell,false)
	# A repath starts inside a grid cell, not at its centre. Returning that
	# centre makes slow units reverse every refresh before reaching the next cell.
	if points.size()>1 and clear_body_path(start,points[1],half_size):points.remove_at(0)
	return points
func nearest_nav_cell(grid: AStarGrid2D,cell: Vector2i) -> Vector2i:
	for radius in range(5):
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				var candidate:=cell+Vector2i(x,y)
				if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):return candidate
	return Vector2i(-1,-1)

func impact(at: Vector2, direction: Vector2, method: String) -> void:
	var fx:=YinCombatVfx.new()
	fx.position=at
	fx.direction=direction
	fx.kind=method
	feedback.add_child(fx)
	var game:=get_tree().get_first_node_in_group("yintian_game")
	if game!=null:game.audio_manager.play_cue(method)

func nearest_chest() -> String:
	for id in YinAdventure.CHESTS:
		var spec: Dictionary = YinAdventure.CHESTS[id]
		if spec.zone == state.zone and id not in state.opened_chests and is_instance_valid(player) and can_interact(spec.at,46): return id
	return ""
func install_chests(game: Node2D) -> void:
	for id in YinAdventure.CHESTS:
		if YinAdventure.CHESTS[id].zone != state.zone: continue
		var chest := YinTreasureChest.new()
		chest.chest_id = id
		chest.game = game
		chest.position = YinAdventure.CHESTS[id].at
		actors.add_child(chest)

func build_island() -> void:
	boundary(Rect2(0, 0, 2240, 64))
	boundary(Rect2(0, 1536, 2240, 64))
	boundary(Rect2(0, 0, 64, 1600))
	boundary(Rect2(2176, 0, 64, 1600))
	boundary(Rect2(960, 64, 64, 640))
	boundary(Rect2(960, 832, 64, 384))
	boundary(Rect2(960, 1312, 64, 224))
	boundary(Rect2(352, 832, 192, 128))
	prop("lantern", Vector2(180, 1440), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(110, 1460), "渡船 · 返回青槐村 E")
	for at in [Vector2(320, 1280), Vector2(800, 1040), Vector2(304, 448), Vector2(1280, 384), Vector2(1376, 1040), Vector2(2080, 1216), Vector2(1856, 240)]:
		prop("tree", at, Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	for at in [Vector2(624, 288), Vector2(784, 288), Vector2(624, 432), Vector2(784, 432)]:
		prop("grave", at, Vector2(-16, -48), Rect2(-12, -16, 24, 16))
	for at in [Vector2(1200, 496), Vector2(1440, 432), Vector2(1680, 480), Vector2(1616, 1056)]:
		prop("rock", at, Vector2(-20, -28), Rect2(-14, -15, 28, 15))
	add_sign(Vector2(288, 1344), "岛国 · 异乡地貌在裂海中缝合")
	add_sign(Vector2(560, 1024), "苇岸 · 河童依水，封皿可制")
	add_sign(Vector2(560, 496), "荒冢 ↑ 以津真天 · 先超度亡骸")
	add_sign(Vector2(1040, 768), "渡桥向北 → 风山")
	add_sign(Vector2(1440, 512), "风山 ↑ 大天狗 · 镇符破风障")
	add_sign(Vector2(1664, 1376), "双面社 ↑ 两面宿傩 · 剑弓交替")
func draw_island() -> void:
	for y_range in [Vector2i(704, 832), Vector2i(1216, 1312)]:
		draw_texture_rect(YinWorldArt.surface(3),Rect2(948,y_range.x,88,y_range.y-y_range.x),true)
	for at in [Vector2(700, 288), Vector2(1568, 256), Vector2(1824, 1120)]:
		draw_texture(YinArt.texture("torii"),at-Vector2(64,122))
	for kind in ["daitengu", "ryomen_sukuna"]:
		if not YinIsland.available(state, kind):
			var at: Vector2 = YinIsland.ARENAS[kind]
			draw_arc(at, 90, 0, TAU, 32, Color("80a7b2"), 3)
			draw_string(ThemeDB.fallback_font, at + Vector2(-60, 0), "前一祭场尚未平息", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ced7be"))
func shock_ring(at: Vector2, radius: float, tint: Color) -> void:
	var ring := Line2D.new()
	for i in range(33): ring.add_point(at + Vector2.from_angle(TAU * i / 32) * radius)
	ring.width = 2
	ring.default_color = tint
	feedback.add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.4)
	tween.tween_callback(ring.queue_free)
func artifact_sweep(at: Vector2, facing: Vector2, reach: float, level_value: int) -> void:
	for layer in range(3):
		var slash := Line2D.new()
		slash.add_to_group("ipetam_slashes")
		slash.width = 3 if layer == 0 else 1
		slash.default_color = Color("da6c79") if layer != 1 else Color("9dd7ce")
		for i in range(17):
			var angle: float = facing.angle() - 0.85 + float(i) / 16 * 1.7
			slash.add_point(at + Vector2.from_angle(angle) * (reach - layer * 9))
		feedback.add_child(slash)
		var tween := slash.create_tween()
		tween.tween_property(slash, "modulate:a", 0.0, 0.24 + level_value * 0.005)
		tween.tween_callback(slash.queue_free)

func build_temple() -> void:
	# Open courtyards linked by gates, with optional side loops around the pagodas.
	for rect in [Rect2(64, 64, 1472, 32), Rect2(64, 64, 32, 1024), Rect2(64, 1216, 1472, 32), Rect2(1504, 64, 32, 1152), Rect2(96, 736, 480, 32), Rect2(736, 736, 304, 32), Rect2(1216, 736, 288, 32), Rect2(992, 96, 32, 224), Rect2(992, 448, 32, 288)]: boundary(rect)
	prop("lantern", YinTemple.EXIT + Vector2(32, 0), Vector2(-16, -48), Rect2(-4, -6, 8, 6))
	add_sign(Vector2(112, 1184), "青槐村山道 ↓ E")
	add_sign(Vector2(288, 1088), "大佛寺 · 施食庭 ↑ 塔林 / 修罗道场")
	add_sign(Vector2(1024, 1120), "梦障院 ↑ 护法殿 · 镇符可破梦障")
	add_sign(Vector2(512, 800), "修罗道场 ↑ 六臂战阵，看清预兆再进退")
	add_sign(Vector2(1056, 496), "护法殿 ↑ 先息修罗，再问守藏夜叉")
	for at in [Vector2(288, 608), Vector2(480, 448), Vector2(1184, 640), Vector2(1408, 736)]:
		prop("rock", at, Vector2(-20, -28), Rect2(-14, -15, 28, 15))
	for at in [Vector2(352, 992), Vector2(832, 1056), Vector2(1376, 1120)]: prop("tree", at, Vector2(-32, -88), Rect2(-8, -16, 16, 16))
	# Actual statue and stupa footprints match the drawing below.
	boundary(Rect2(1144, 128, 208, 72))
	for at in [Vector2(256, 352), Vector2(448, 352), Vector2(256, 544), Vector2(512, 672)]: boundary(Rect2(at - Vector2(20, 12), Vector2(40, 24)))

func draw_temple() -> void:
	for at in [Vector2(704, 512), Vector2(1248, 288)]:
		var points := PackedVector2Array()
		var uv := PackedVector2Array()
		for i in range(48):
			var direction := Vector2.from_angle(TAU*i/48.0)
			points.append(at+direction*108)
			uv.append(Vector2(0.5,0.5)+direction*0.5)
		draw_colored_polygon(points,Color("c0b997"),uv,YinWorldArt.surface(1))
		draw_arc(at, 104, 0, TAU, 48, Color("a3976d"), 2)
		for i in range(8): draw_line(at + Vector2.from_angle(i * TAU / 8) * 35, at + Vector2.from_angle(i * TAU / 8) * 100, Color("8b8469"), 1)
	for at in [Vector2(256, 352), Vector2(448, 352), Vector2(256, 544), Vector2(512, 672)]:
		draw_texture(YinArt.texture("stupa"), at - Vector2(24, 84))
	draw_texture(YinArt.texture("buddha"), Vector2(1144, 0))
	if not YinTemple.available(state, "yaksha"):
		draw_arc(YinTemple.ARENAS.yaksha, 90, 0, TAU, 40, Color("dabf73"), 3)
		draw_string(ThemeDB.fallback_font, YinTemple.ARENAS.yaksha + Vector2(-64, 0), "先平息阿修罗战意", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ead4a1"))

func prajna_sweep(at: Vector2, facing: Vector2, reach: float, actor_level: int) -> void:
	for layer in range(4):
		var slash := Line2D.new()
		slash.add_to_group("prajna_slashes")
		slash.width = 3 if layer == 0 else 2
		slash.default_color = [Color("f0dc92"), Color("e7a26e"), Color("9bd9e6"), Color("cbb2ef")][layer]
		for i in range(25):
			var angle: float = facing.angle() - 1.0 + float(i) / 24 * 2.0
			slash.add_point(at + Vector2.from_angle(angle) * (reach - layer * 6))
		feedback.add_child(slash)
		var tween := slash.create_tween()
		tween.tween_property(slash, "modulate:a", 0.0, 0.28 + actor_level * 0.003)
		tween.tween_callback(slash.queue_free)
	shock_ring(at, 16 + actor_level, Color("e9cf83"))

func shared_biome_surface() -> ShaderMaterial:
	if biome_material==null:
		biome_material=ShaderMaterial.new();biome_material.shader=preload("res://shaders/biome_surface.gdshader")
	return biome_material
