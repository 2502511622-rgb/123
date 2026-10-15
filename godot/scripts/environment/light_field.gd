class_name YinLightField
extends RefCounted
var viewport: SubViewport
var root: Node2D
var world: FarmWorld
var count: int = -1
var sources: Array = []
var blocked_rays: int = 0
func setup(owner_world: FarmWorld) -> void:
	world = owner_world
	viewport = SubViewport.new()
	viewport.name = "OccludedLightField"
	viewport.size = Vector2i(640, 360)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world.add_child(viewport)
	root = Node2D.new()
	viewport.add_child(root)
func rebuild() -> void:
	count = world.environment_revision
	blocked_rays = 0
	sources.clear()
	for child in root.get_children(): child.queue_free()
	for node in world.get_tree().get_nodes_in_group("art_lights"):
		if node.is_queued_for_deletion() or not world.is_ancestor_of(node): continue
		var at: Vector2 = node.global_position + Vector2(0, 6) if node is Marker2D else node.global_position - Vector2(0, 12)
		var polygon := Polygon2D.new()
		polygon.position = at
		polygon.polygon = visibility(at, 115, node.global_position - Vector2(0, 2))
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/light_field.gdshader")
		material.set_shader_parameter("radius", 115.0)
		material.set_shader_parameter("phase", at.x * 0.07)
		polygon.material = material
		root.add_child(polygon)
		sources.append({"node": node, "polygon": polygon})
func visibility(at: Vector2, radius: float, ignore_point: Vector2 = Vector2(INF, INF)) -> PackedVector2Array:
	var blockers: Array[Rect2] = []
	var angles: Array[float] = []
	for i in range(64): angles.append(TAU * i / 64)
	for obstacle in world.obstacles:
		if obstacle.has_point(at) or obstacle.has_point(ignore_point) or not obstacle.grow(radius).has_point(at): continue
		var tile: int = world.tile_farm.ground.get_cell_atlas_coords(Vector2i(obstacle.get_center() / 32)).x
		if tile in [11, 12, 13]: continue
		blockers.append(obstacle)
		for point in [obstacle.position, Vector2(obstacle.end.x, obstacle.position.y), obstacle.end, Vector2(obstacle.position.x, obstacle.end.y)]:
			var angle: float = at.angle_to_point(point)
			for bias in [-0.001, 0.0, 0.001]: angles.append(fposmod(angle + bias, TAU))
	angles.sort()
	var points := PackedVector2Array()
	for angle in angles:
		var direction := Vector2.from_angle(angle)
		var distance: float = radius
		for blocker in blockers: distance = minf(distance, hit_distance(at, direction, blocker, radius))
		if distance < radius: blocked_rays += 1
		var point: Vector2 = direction * maxf(1, distance - 0.5)
		if points.is_empty() or points[-1].distance_squared_to(point) > 0.000001: points.append(point)
	return points
static func hit_distance(at: Vector2, direction: Vector2, rect: Rect2, limit: float) -> float:
	var near: float = 0
	var far: float = limit
	for axis in range(2):
		if absf(direction[axis]) < 0.00001:
			if at[axis] < rect.position[axis] or at[axis] > rect.end[axis]: return limit
			continue
		var a: float = (rect.position[axis] - at[axis]) / direction[axis]
		var b: float = (rect.end[axis] - at[axis]) / direction[axis]
		near = maxf(near, minf(a, b))
		far = minf(far, maxf(a, b))
		if near > far: return limit
	return maxf(0, near) if far >= 0 else limit
func update(time: float) -> void:
	if count != world.environment_revision or sources.any(func(s): return not is_instance_valid(s.node) or s.node.is_queued_for_deletion()): rebuild()
	root.transform = world.get_global_transform_with_canvas()
	for source in sources:
		source.polygon.visible = Rect2(-130, -130, 900, 620).has_point(root.transform * source.polygon.position)
		if source.polygon.visible: source.polygon.material.set_shader_parameter("clock_time", time)
