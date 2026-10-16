class_name YinEnvironment
extends Node2D
var world: FarmWorld
var time: float = 0
var wind: float = 0.5
var wetness: float = 0
var rain: float = 0
var indoor: bool = false
var ground: YinEnvironmentLayer
var foreground: YinEnvironmentLayer
var light_field := YinLightField.new()
var terrain_types: ImageTexture
var ground_mask: ImageTexture
var reflections: Array[Sprite2D] = []
var reflected_prop_count: int = -1
var leaves: Array = []
var splashes: Array = []
var footsteps: Array = []
var random := RandomNumberGenerator.new()
var emit_clock: float = 0
var leaf_clock: float = 0
var last_step := Vector2.ZERO
var baked: bool = false
var soil_material: ShaderMaterial
var plot_flags := PackedByteArray()
var regional: YinRegionalClimate
var terrain_material: ShaderMaterial
func _ready() -> void:
	indoor = world.state.zone in ["hall", "shop"]
	if world is YinContinentWorld:
		regional=YinRegionalClimate.new();regional.environment=self
	random.seed = world.state.zone.hash() + 15015
	ground = YinEnvironmentLayer.new()
	ground.name = "WetGroundAndShadows"
	ground.environment = self
	ground.z_index = -1
	add_child(ground)
	foreground = YinEnvironmentLayer.new()
	foreground.name = "RainAndFallingLeaves"
	foreground.environment = self
	foreground.foreground = true
	foreground.z_index = 23
	add_child(foreground)
	if not indoor and world.state.weather == "rain":
		rain = 1
		wetness = 0.8
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = preload("res://shaders/terrain_weather.gdshader")
	terrain_material.set_shader_parameter("material_atlas", YinWorldArt.GROUND)
	terrain_material.set_shader_parameter("indoor", indoor)
	terrain_material.set_shader_parameter("continent",world is YinContinentWorld)
	YinRegionStyle.apply_terrain(terrain_material,world.state.zone)
	world.tile_farm.ground.material = terrain_material
	if world.state.zone == "farm" and not world is YinContinentWorld:
		soil_material = ShaderMaterial.new()
		soil_material.shader = preload("res://shaders/soil_material.gdshader")
		soil_material.set_shader_parameter("material_atlas",YinWorldArt.GROUND)
		world.tile_farm.soil.material = soil_material
		refresh_soil()
	light_field.setup(world)
	call_deferred("bake")
func bake() -> void:
	if not is_inside_tree(): return
	var size_cells := Vector2i(world.level_size / 32)
	var image := Image.create(size_cells.x, size_cells.y, false, Image.FORMAT_RGBA8)
	var types := Image.create(size_cells.x, size_cells.y, false, Image.FORMAT_RGBA8)
	for y in range(size_cells.y):
		for x in range(size_cells.x):
			var tile: int = world.tile_farm.ground.get_cell_atlas_coords(Vector2i(x, y)).x
			types.set_pixel(x, y, Color(maxi(0,tile)/255.0,0,0,1))
			var value: float = 1.0 if tile >= 16 or tile == 10 else (0.8 if tile in [11, 12, 13] else 0.04)
			image.set_pixel(x, y, Color(value, value, value))
	terrain_types = ImageTexture.create_from_image(types)
	terrain_material.set_shader_parameter("terrain_types", terrain_types)
	terrain_material.set_shader_parameter("map_size", world.level_size)
	ground_mask = ImageTexture.create_from_image(image)
	light_field.rebuild()
	refresh_reflections()
	baked = true
func refresh_soil() -> void:
	if soil_material == null: return
	var flags := PackedByteArray()
	for plot in world.state.plots: flags.append((2 if plot.tilled else 0)+(1 if plot.watered else 0))
	if flags == plot_flags: return
	plot_flags = flags
	var image := Image.create(8,6,false,Image.FORMAT_RGBA8)
	for i in range(flags.size()): image.set_pixel(i%8,i/8,Color(1 if flags[i]&2 else 0,1 if flags[i]&1 else 0,0,1))
	soil_material.set_shader_parameter("plots",ImageTexture.create_from_image(image))
func refresh_reflections() -> void:
	for sprite in reflections:
		if is_instance_valid(sprite): sprite.queue_free()
	reflections.clear()
	reflected_prop_count = world.environment_revision
	if indoor: return
	for body in world.actors.get_children():
		if not body is StaticBody2D or body.is_queued_for_deletion(): continue
		for source in body.get_children():
			if not source is Sprite2D: continue
			if source.texture not in [YinArt.texture("cottage"), YinArt.texture("store"), YinArt.texture("lantern"), YinArt.texture("tree"), YinArt.texture("tree_autumn"), YinArt.texture("tree_pine")] and body.get_meta("biome_prop","") not in ["edo_shop","edo_house","street_lantern"]: continue
			var reflection := Sprite2D.new()
			reflection.texture = source.texture
			reflection.centered = false
			reflection.flip_v = true
			reflection.position = body.position + Vector2(source.position.x, 1)
			reflection.scale = source.scale * Vector2(1, 0.34)
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://shaders/wet_reflection.gdshader")
			mat.set_shader_parameter("ground_mask", ground_mask)
			mat.set_shader_parameter("map_size", world.level_size)
			mat.set_shader_parameter("origin", reflection.position)
			mat.set_shader_parameter("reflection_scale", reflection.scale)
			mat.set_shader_parameter("source_height", float(source.texture.get_height()))
			reflection.material = mat
			reflection.set_meta("source", weakref(body))
			ground.add_child(reflection)
			reflections.append(reflection)
func _process(delta: float) -> void:
	if not baked or not is_instance_valid(world.player): return
	var game = world.get_tree().get_first_node_in_group("yintian_game")
	if game != null and game.modal != null: return
	refresh_soil()
	time += delta
	if regional!=null:regional.update(delta)
	var rain_target=regional.rain_target if regional!=null else (1.0 if world.state.weather=="rain" and not indoor else 0.0)
	rain = move_toward(rain,rain_target,delta*1.2)
	wetness = move_toward(wetness, 1.0 if rain > 0.1 else 0.0, delta * (0.14 if rain > 0.1 else 0.025))
	wind = (0.65 + 0.35 * sin(time * 0.35) + 0.25 * sin(time * 0.91)) * (1.5 if rain > 0.2 else 1.0)
	if regional!=null:wind+=regional.dust*1.6+regional.snow*0.35
	terrain_material.set_shader_parameter("clock_time", time)
	terrain_material.set_shader_parameter("wetness", wetness)
	if regional!=null:
		terrain_material.set_shader_parameter("snow",regional.snow);terrain_material.set_shader_parameter("dust",regional.dust)
	if world.canopy_material!=null:
		world.canopy_material.set_shader_parameter("clock_time",time);world.canopy_material.set_shader_parameter("wind",wind);world.canopy_material.set_shader_parameter("wetness",wetness)
	if regional!=null:
		if world.biome_material!=null:
			world.biome_material.set_shader_parameter("snow",regional.snow);world.biome_material.set_shader_parameter("dust",regional.dust);world.biome_material.set_shader_parameter("wetness",wetness)
		if world.canopy_material!=null:world.canopy_material.set_shader_parameter("snow",regional.snow)
	light_field.update(time)
	if reflected_prop_count != world.environment_revision: refresh_reflections()
	var screen: Rect2 = visible_rect().grow(130)
	for actor in world.actors.get_children():
		if actor is CharacterBody2D and actor.material is ShaderMaterial and screen.has_point(actor.position): actor.material.set_shader_parameter("wetness", wetness)
	for reflection in reflections:
		var source: Object = reflection.get_meta("source").get_ref()
		reflection.visible = source != null and not source.is_queued_for_deletion() and wetness > 0.01 and screen.has_point(reflection.position)
		if reflection.visible:
			reflection.material.set_shader_parameter("wetness", wetness)
			reflection.material.set_shader_parameter("clock_time", time)
	if not indoor:
		emit_clock += delta
		if emit_clock > 0.06:
			emit_clock = 0
			for i in range(3):
				if random.randf() < rain: emit_splash()
		leaf_clock += delta
		if leaf_clock > 0.32:
			leaf_clock = 0
			emit_leaf()
		if wetness > 0.2 and last_step.distance_to(world.player.position) > 14:
			last_step = world.player.position
			if exposed(last_step):
				footsteps.append({"at": last_step, "age": 0.0})
	for splash in splashes: splash.age += delta
	for step in footsteps: step.age += delta
	splashes = splashes.filter(func(s): return s.age < 0.5)
	footsteps = footsteps.filter(func(s): return s.age < 0.7)
	for leaf in leaves:
		leaf.age += delta
		if leaf.height > 0:
			leaf.at += Vector2(13 + wind * 18 + sin(leaf.age * 3 + leaf.phase) * 12, 3) * delta
			leaf.height = maxf(0, leaf.height - delta * (10 + 4 * wind))
			leaf.angle += delta * 2
	leaves = leaves.filter(func(leaf): return leaf.age < 9)
	ground.queue_redraw()
	foreground.queue_redraw()
func visible_rect() -> Rect2:
	var transform: Transform2D = world.get_global_transform_with_canvas()
	return transform.affine_inverse()*Rect2(Vector2.ZERO,world.get_viewport_rect().size)
func exposed(at: Vector2) -> bool:
	return world.is_safe_position(at)
func emit_splash() -> void:
	if splashes.size() >= 90: return
	var screen: Rect2 = visible_rect()
	var at := screen.position + Vector2(random.randf_range(0, 640), random.randf_range(0, 360))
	if not exposed(at): return
	splashes.append({"at": at, "age": 0.0, "water": is_water(at)})
func emit_leaf() -> void:
	if leaves.size() >= 54: return
	var screen: Rect2 = visible_rect().grow(90)
	var trees: Array = world.get_tree().get_nodes_in_group("wind_trees").filter(func(t): return not t.is_queued_for_deletion() and t.get_parent() == world.actors and screen.has_point(t.position))
	if trees.is_empty(): return
	var tree: Node2D = trees[random.randi_range(0, trees.size() - 1)]
	leaves.append({"at": tree.position + Vector2(random.randf_range(-25, 20), random.randf_range(-5, 8)), "height": random.randf_range(65, 110), "age": 0.0, "angle": random.randf_range(0, TAU), "phase": random.randf() * TAU, "color": [Color("aab57b"), Color("b8a16a"), Color("7f9b6e")][random.randi_range(0, 2)]})
func is_water(at: Vector2) -> bool:
	var tile: int = world.tile_farm.ground.get_cell_atlas_coords(Vector2i(at / 32)).x
	return tile in [11, 12, 13]
func draw_ground(canvas: Node2D) -> void:
	if indoor or not baked: return
	if regional!=null:regional.draw_ground(canvas)
	var screen: Rect2 = visible_rect().grow(100)
	# Directional canopy shadows share the same wind clock as the actual foliage.
	var sun: float = clampf((world.state.minutes - 360) / 720.0, 0, 1)
	for tree in world.get_tree().get_nodes_in_group("wind_trees"):
		if tree.is_queued_for_deletion() or tree.get_parent() != world.actors or not screen.has_point(tree.position): continue
		canvas.draw_set_transform(tree.position + Vector2(10 - sun * 32 + sin(time + tree.position.x) * wind, 5), -0.15 + sun * 0.3, Vector2(1.0, 0.43))
		canvas.draw_texture(tree.get_node("ArtSprite").texture, Vector2(-48, -42), Color(0.08, 0.17, 0.17, 0.20 * (1.0 - rain * 0.5)))
		canvas.draw_set_transform(Vector2.ZERO)
	# A shallow projected footprint gives buildings height without altering collisions.
	for body in world.actors.get_children():
		if not body is StaticBody2D or body.is_queued_for_deletion() or not screen.has_point(body.position): continue
		var sprite: Sprite2D = body.get_node_or_null("ArtSprite")
		if sprite == null or sprite.texture not in [YinArt.texture("cottage"), YinArt.texture("store")]: continue
		var width: float = sprite.texture.get_width() * 0.45
		var offset := Vector2(16-sun*38, 18 + sin(sun*PI)*14)
		var at: Vector2 = body.position
		canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-width,-5),at+Vector2(width,-5),at+Vector2(width,0)+offset,at+Vector2(-width,0)+offset]),Color(0.08,0.16,0.16,0.12*(1.0-rain*0.6)))
	if wetness > 0.02:
		var cell_start := Vector2i(screen.position / 32)
		for y in range(cell_start.y, cell_start.y + 18):
			for x in range(cell_start.x, cell_start.x + 28):
				var tile: int = world.tile_farm.ground.get_cell_atlas_coords(Vector2i(x, y)).x
				if (tile < 16 and tile!=10) or (x * 13 + y * 7) % 3 != 0: continue
				var at := Vector2(x * 32 + 7, y * 32 + 18)
				if not exposed(at): continue
				canvas.draw_set_transform(at, 0, Vector2(1, 0.28))
				canvas.draw_circle(Vector2.ZERO, 9 + (x + y) % 4, Color(0.10, 0.21, 0.24, wetness * 0.30))
				canvas.draw_arc(Vector2.ZERO, 10, PI * 0.1, PI, 14, Color(0.60, 0.72, 0.69, wetness * 0.25), 1)
				canvas.draw_set_transform(Vector2.ZERO)
	for splash in splashes:
		canvas.draw_set_transform(splash.at, 0, Vector2(1, 0.38))
		var alpha: float = (1.0 - splash.age * 2) * rain * (0.5 if splash.water else 0.28)
		canvas.draw_arc(Vector2.ZERO, 1 + splash.age * 14, 0, TAU, 16, Color(0.65, 0.80, 0.81, alpha), 1)
		canvas.draw_set_transform(Vector2.ZERO)
	for step in footsteps:
		canvas.draw_set_transform(step.at, 0, Vector2(1, 0.35))
		canvas.draw_arc(Vector2.ZERO, 2 + step.age * 12, 0, TAU, 16, Color(0.61, 0.75, 0.75, (0.7 - step.age) * wetness * 0.35), 1)
		canvas.draw_set_transform(Vector2.ZERO)
	for leaf in leaves:
		if leaf.height > 0: continue
		var tint: Color = leaf.color
		tint.a = minf(1, 9 - leaf.age) * 0.6
		canvas.draw_set_transform(leaf.at, leaf.angle, Vector2.ONE)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-2, 0), Vector2(0, -1), Vector2(3, 0), Vector2(0, 1)]), tint)
		canvas.draw_set_transform(Vector2.ZERO)
func draw_front(canvas: Node2D) -> void:
	if indoor or not baked: return
	if regional!=null:regional.draw_front(canvas)
	var screen: Rect2 = visible_rect()
	if rain > 0.01:
		for i in range(125):
			var speed: float = 145 + (i % 4) * 42
			var x: float = screen.position.x + fposmod(i * 97 - time * (28 + wind * 20) + screen.position.x * 0.2, 680) - 20
			var y: float = screen.position.y + fposmod(i * 53 + time * speed, 400) - 20
			var at := Vector2(x, y)
			var tint := Color(0.67, 0.79, 0.82, rain * (0.11 + (i % 3) * 0.04))
			canvas.draw_line(at, at + Vector2(-2 - wind * 2, 5 + i % 6), tint, 1)
		for body in world.actors.get_children():
			if not body is StaticBody2D or body.is_queued_for_deletion() or not screen.grow(100).has_point(body.position): continue
			for source in body.get_children():
				if not source is Sprite2D:continue
				if source.texture not in [YinArt.texture("cottage"), YinArt.texture("store")] and body.get_meta("biome_prop","") not in ["edo_shop","edo_house"]:continue
				for i in range(7):
					var at: Vector2 = body.position + source.position + Vector2(12 + i * 19, 66 if source.texture == YinArt.texture("cottage") else 57)
					var fall: float = fposmod(time * 38 + i * 11, 16)
					canvas.draw_line(at + Vector2(0, fall), at + Vector2(-1, fall + 4), Color(0.68, 0.79, 0.75, rain * 0.3), 1)
	for leaf in leaves:
		if leaf.height <= 0: continue
		var at: Vector2 = leaf.at - Vector2(0, leaf.height)
		var tint: Color = leaf.color
		tint.a = minf(1, 9 - leaf.age) * 0.85
		canvas.draw_set_transform(at, leaf.angle, Vector2(1, 0.55 + absf(sin(leaf.age * 4)) * 0.45))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-3, 0), Vector2(0, -1), Vector2(3, 0), Vector2(0, 2)]), tint)
		canvas.draw_line(Vector2(-2, 0), Vector2(2, 0), tint.darkened(0.25), 1)
		canvas.draw_set_transform(Vector2.ZERO)
