extends CharacterBody2D
var game: Node2D
var record: Dictionary
var cooldown: float = 0
var time: float = 0
var guard_anchor: Vector2
var last_order: String = ""
var navigation := AStarGrid2D.new()
var route: PackedVector2Array = []
var repath: float = 0
const TEXTURE = preload("res://assets/spirits.png")
func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(14, 10)
	shape.shape = box
	shape.position.y = -4
	add_child(shape)
	guard_anchor = position
	navigation.region = Rect2i(Vector2i.ZERO, Vector2i(game.world.level_size / 16))
	navigation.cell_size = Vector2(16, 16)
	navigation.offset = Vector2(8, 8)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in range(navigation.region.size.y):
		for x in range(navigation.region.size.x):
			navigation.set_point_solid(Vector2i(x, y), not game.world.is_safe_position(Vector2(x * 16 + 8, y * 16 + 8)))
func visible(enemy: Node2D) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(global_position - Vector2(0, 8), enemy.global_position - Vector2(0, 8), 1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
func _physics_process(delta: float) -> void:
	if game.modal != null or is_queued_for_deletion(): return
	time += delta
	cooldown = maxf(0, cooldown - delta)
	if last_order != game.state.order:
		last_order = game.state.order
		guard_anchor = position
		repath = 0
	var target: Vector2 = game.player.position + Vector2(-24 - int(record.id) % 3 * 18, 22)
	if not game.world.is_safe_position(target): target = game.player.position
	if last_order == "guard": target = guard_anchor + Vector2.from_angle(int(time / 3) * PI / 2 + int(record.id)) * 36
	var enemy: YinEnemy = game.nearest_enemy(position, 260 if last_order != "focus" else 360)
	if enemy != null and (last_order == "guard" and enemy.position.distance_to(guard_anchor) < 220 or last_order != "guard" and position.distance_to(game.player.position) < 400):
		target = enemy.position
		if position.distance_to(enemy.position) < 44 and visible(enemy) and cooldown <= 0:
			enemy.receive_hit(9 + YinBalance.level(game.state.cultivation) * 2 + int(record.affinity / 25) + (5 if record.kind == "child" and record.branch == "shadow" else 0), "spirit")
			game.world.effect(enemy.position, Color("91aaa8"))
			cooldown = 1.1
			target = position
	repath -= delta
	if repath <= 0:
		repath = 0.4
		var start := Vector2i(position / 16)
		var end := Vector2i(target / 16)
		route = navigation.get_point_path(start, end, true) if navigation.is_in_boundsv(start) and navigation.is_in_boundsv(end) else PackedVector2Array()
		if route.size() > 0: route.remove_at(0)
	while route.size() > 0 and position.distance_to(route[0]) < 6: route.remove_at(0)
	velocity = position.direction_to(route[0]) * 105 if route.size() > 0 and position.distance_to(target) > 12 else Vector2.ZERO
	move_and_slide()
	queue_redraw()
func _draw() -> void:
	var row: int = {"water": 0, "bone": 1, "child": 2}.get(record.kind, 2)
	draw_rect(Rect2(-9, -2, 18, 4), Color(0.1, 0.15, 0.2, 0.25))
	draw_texture_rect_region(TEXTURE, Rect2(-16, -40 + roundf(sin(time * 2)), 32, 40), Rect2(0, row * 20, 16, 20), Color(1, 1, 1, 0.9))
