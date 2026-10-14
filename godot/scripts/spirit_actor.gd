extends CharacterBody2D
var game: Node2D
var record: Dictionary
var cooldown: float = 0
var burst_remaining: int = 0
var burst_timer: float = 0
var burst_direction: Vector2
var burst_damage: int = 0
var skill_cooldown: float = 2
var passive_time: float = 0
var invincible: float = 0
var stun: float = 0
var shield: int = 0
var shield_clock: float = 0
var charge_duration: float = 0
var charge_direction: Vector2
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
	var hurtbox := YinAllyHurtbox.new()
	hurtbox.actor = self
	add_child(hurtbox)
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
	if record.hp <= 0 or not record.active:
		queue_free()
		return
	if burst_remaining > 0:
		burst_timer -= delta
		if burst_timer <= 0 and stun <= 0:
			game.world.projectiles.spawn(position, burst_direction, true, burst_damage, 210, 260, Color("8cc6b8"))
			burst_remaining -= 1
			burst_timer = 0.18
	invincible = maxf(0, invincible - delta)
	stun = maxf(0, stun - delta)
	skill_cooldown = maxf(0, skill_cooldown - delta)
	shield_clock += delta
	if shield_clock >= 10:
		shield_clock = 0
		if YinAbilities.meta(record.source_kind).get("trait") == "shield": shield = 8
	passive_time += delta
	if passive_time >= 2:
		passive_time = 0
		if YinAbilities.meta(record.source_kind).get("trait") == "regen": record.hp = mini(record.max_hp, record.hp + 1)
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
		if skill_cooldown <= 0 and position.distance_to(enemy.position) < 220 and visible(enemy):
			use_inherited_skill(enemy)
		if position.distance_to(enemy.position) < 44 and visible(enemy) and cooldown <= 0:
			enemy.receive_hit(attack_damage(), "spirit")
			game.world.effect(enemy.position, Color("91aaa8"))
			cooldown = 1.6
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
	if charge_duration > 0:
		charge_duration -= delta
		velocity = charge_direction * 160
	if stun > 0: velocity = Vector2.ZERO
	move_and_slide()
	queue_redraw()
func _draw() -> void:
	var row: int = {"water": 0, "bone": 1, "child": 2}.get(record.kind, 1)
	draw_rect(Rect2(-9, -2, 18, 4), Color(0.1, 0.15, 0.2, 0.25))
	if record.kind in ["water", "bone", "child"]:
		draw_texture_rect_region(TEXTURE, Rect2(-16, -40 + roundf(sin(time * 2)), 32, 40), Rect2(0, row * 20, 16, 20), Color(1, 1, 1, 0.9))
	else:
		var source_row: int = {"archer": 3, "lantern": 4, "gunner": 5, "brute": 6, "boss": 2, "well_boss": 0, "opera_boss": 5}.get(record.source_kind, 1)
		draw_texture_rect_region(preload("res://assets/enemies.png"), Rect2(-16, -44, 32, 48), Rect2(0, source_row * 24, 16, 24), Color("9ecdc7"))

	var fraction: float = float(record.hp) / record.max_hp
	draw_rect(Rect2(-16, -46, 32, 4), Color("263938"))
	draw_rect(Rect2(-16, -46, 32 * fraction, 4), Color("7eafb0"))
	draw_string(ThemeDB.fallback_font, Vector2(-15, -49), "Lv%d" % record.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("dfd1a8"))
func receive_hit(damage: int) -> void:
	if record.hp <= 0 or invincible > 0: return
	var passive_type: String = YinAbilities.meta(record.source_kind).get("trait")
	if passive_type in ["armor", "boss_armor", "shield"]: damage = maxi(1, roundi(damage * 0.8))
	if shield > 0:
		var blocked: int = mini(shield, damage)
		shield -= blocked
		damage -= blocked
	record.hp = maxi(0, record.hp - damage)
	invincible = 0.4
	stun = 0.15
	game.world.damage_number(position, damage, Color("da968a"))
	if record.hp == 0:
		record.active = false
		game.notify_action(record.name + "倒下，已召回。角色 → 随从中疗养。")
		queue_free()
func use_inherited_skill(enemy: YinEnemy) -> void:
	var meta: Dictionary = YinAbilities.meta(record.source_kind)
	var damage: int = attack_damage()
	var direction: Vector2 = position.direction_to(enemy.position)
	match meta.pattern:
		"cold", "fan":
			for angle in [-0.12, 0.0, 0.12]: game.world.projectiles.spawn(position, direction.rotated(angle), true, maxi(1, int(damage * 0.6)), 180, 240, Color("8cc6b8"))
		"burst":
			burst_remaining = 3
			burst_timer = 0
			burst_direction = direction
			burst_damage = maxi(1, int(damage * 0.6))
		"opera":
			for angle in [-0.12, 0.0, 0.12]: game.world.projectiles.spawn(position, direction.rotated(angle), true, maxi(1, int(damage * 0.6)), 180, 240, Color("a9b8d6"))
			burst_remaining = 2
			burst_timer = 0.18
			burst_direction = direction
			burst_damage = maxi(1, int(damage * 0.6))
		"ring", "tide", "boss":
			for i in range(6): game.world.projectiles.spawn(position, Vector2.from_angle(TAU * i / 6), true, maxi(1, int(damage * 0.65)), (90 if i % 2 == 0 else 150) if meta.pattern == "tide" else 140, 180, Color("a9b8d6"))
			if meta.get("trait") in ["siphon", "tide"]: record.hp = mini(record.max_hp, record.hp + 2)
		"charge":
			charge_direction = direction
			charge_duration = 0.3
		"slam":
			if position.distance_to(enemy.position) > 60: return
			enemy.receive_hit(damage + 2, "spirit")
	game.world.effect(position, Color("83bca4"))
	skill_cooldown = 6.4 if meta.get("trait") == "reload" else 8.0

func attack_damage() -> int:
	var result: int = YinAbilities.spirit_damage(record)
	var passive_type: String = YinAbilities.meta(record.source_kind).get("trait")
	if passive_type == "pierce": result += 1
	if passive_type == "rage" and record.hp < record.max_hp / 2: result = roundi(result * 1.25)
	return result
