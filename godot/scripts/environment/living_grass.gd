class_name YinLivingGrass
extends Node2D
const CHUNK: int = 128
const MAX_TRAILS: int = 12
var world: FarmWorld
var chunks: Array = []
var material_back := ShaderMaterial.new()
var material_front := ShaderMaterial.new()
var trails: Array = []
var last_position := Vector2.ZERO
var baked: bool = false
var blade_count: int = 0
var visible_chunks: int = 0
var clock: float = 0
func _ready() -> void:
	material_back.shader = preload("res://shaders/living_grass.gdshader")
	material_front.shader = material_back.shader
	material_front.set_shader_parameter("foreground", true)
	for mat in [material_back, material_front]: mat.set_shader_parameter("world_size", world.level_size)
	call_deferred("bake")
func grass_at(at: Vector2) -> bool:
	if at.x < 20 or at.y < 20 or at.x > world.level_size.x-20 or at.y > world.level_size.y-20: return false
	if world.state.zone in ["hall", "shop"]: return false
	if world.state.zone == "farm" and Rect2(296, 230, 306, 258).has_point(at): return false
	var tile: int = world.tile_farm.ground.get_cell_atlas_coords(Vector2i(at / 32)).x
	return (tile < 8 or tile in [14, 15]) and world.is_safe_position(at)
func bake() -> void:
	if not is_inside_tree() or world.state.zone in ["hall", "shop"]:
		baked = true
		return
	var random := RandomNumberGenerator.new()
	random.seed = world.state.zone.hash() + 17017
	var mesh := QuadMesh.new()
	mesh.size = Vector2(3, 14)
	for y in range(0, int(world.level_size.y), CHUNK):
		for x in range(0, int(world.level_size.x), CHUNK):
			var base := Vector2(x, y)
			var blades: Array = []
			for i in range(64):
				var at: Vector2 = base + Vector2(random.randf_range(0, CHUNK), random.randf_range(0, CHUNK))
				# Broad organic patches, with sparse bare soil between tufts.
				var coverage: float = sin(at.x * 0.037 + cos(at.y * 0.021)) + sin(at.y * 0.029 + at.x * 0.013)
				if coverage < -0.9 or not grass_at(at): continue
				blades.append({"at": at-base, "height": random.randf_range(0.45, 0.78), "seed": random.randf()})
			if blades.is_empty(): continue
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_2D
			multi.use_custom_data = true
			multi.mesh = mesh
			multi.instance_count = blades.size()
			for i in range(blades.size()):
				var blade: Dictionary = blades[i]
				multi.set_instance_transform_2d(i, Transform2D(0, Vector2(0.6 + blade.seed * 0.4, blade.height), 0, blade.at))
				multi.set_instance_custom_data(i, Color(blade.seed, (base.x+blade.at.x)/world.level_size.x, (base.y+blade.at.y)/world.level_size.y, 1))
			var back := MultiMeshInstance2D.new()
			back.multimesh = multi
			back.position = base
			back.material = material_back
			back.z_index = -1
			add_child(back)
			var front := MultiMeshInstance2D.new()
			front.multimesh = multi
			front.position = base
			front.material = material_front
			front.z_index = 1
			add_child(front)
			chunks.append({"back": back, "front": front, "bounds": Rect2(base, Vector2(CHUNK, CHUNK)).grow(24)})
			blade_count += blades.size()
	if is_instance_valid(world.player): last_position = world.player.position
	baked = true
func sample_reaction(at: Vector2) -> float:
	var value: float = 0
	for trail in trails:
		value = maxf(value, (1.0-smoothstep(2, 18, at.distance_to(trail.at))) * maxf(0, 1.0-trail.age/1.2))
	return value
func _process(delta: float) -> void:
	if not baked or not is_instance_valid(world.player) or world.environment == null: return
	var game := get_tree().get_first_node_in_group("yintian_game")
	if game != null and game.modal != null: return
	clock += delta
	for trail in trails: trail.age += delta
	trails = trails.filter(func(trail): return trail.age < 1.2)
	var at: Vector2 = world.player.position
	if last_position.distance_to(at) >= 4:
		# A teleport does not leave a stripe across the whole map.
		if last_position.distance_to(at) > 100: last_position = at
		var steps: int = mini(6, int(last_position.distance_to(at) / 4))
		for i in range(steps):
			var step: Vector2 = last_position.lerp(at, float(i+1) / maxi(1, steps))
			if grass_at(step): trails.append({"at": step, "age": 0.0})
		last_position = at
	while trails.size() > MAX_TRAILS: trails.pop_front()
	var actors := PackedVector2Array([at])
	var nearby: Array = []
	for actor in world.actors.get_children():
		if actor == world.player or not actor is CharacterBody2D or actor.is_queued_for_deletion(): continue
		if actor.position.distance_squared_to(at) < 320*320: nearby.append(actor)
	nearby.sort_custom(func(a, b): return a.position.distance_squared_to(at) < b.position.distance_squared_to(at))
	for i in range(mini(5, nearby.size())): actors.append(nearby[i].position)
	var actor_count: int = actors.size()
	while actors.size() < 6: actors.append(Vector2(-99999, -99999))
	var trail_data := PackedVector4Array()
	for trail in trails: trail_data.append(Vector4(trail.at.x, trail.at.y, pow(1.0-trail.age/1.2, 1.5), 0))
	while trail_data.size() < MAX_TRAILS: trail_data.append(Vector4.ZERO)
	for mat in [material_back, material_front]:
		mat.set_shader_parameter("clock_time", world.environment.time)
		mat.set_shader_parameter("wind", world.environment.wind)
		mat.set_shader_parameter("wetness", world.environment.wetness)
		mat.set_shader_parameter("player_at", at)
		mat.set_shader_parameter("actor_count", actor_count)
		mat.set_shader_parameter("actor_at", actors)
		mat.set_shader_parameter("trail_count", trails.size())
		mat.set_shader_parameter("trails", trail_data)
	var view: Rect2 = world.environment.visible_rect().grow(8)
	visible_chunks = 0
	for chunk in chunks:
		chunk.back.visible = chunk.bounds.intersects(view)
		chunk.front.visible = chunk.back.visible and chunk.bounds.has_point(at)
		if chunk.back.visible: visible_chunks += 1
