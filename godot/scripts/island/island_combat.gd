class_name YinIslandCombat
extends RefCounted
static func visible(e, at: Vector2) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(e.position + Vector2(0, -4), at + Vector2(0, -4), 1)
	return e.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
static func damage(e) -> int:
	var result: int = int(e.record.damage)
	if "arm" in e.record.get("severed", []): result = maxi(1, roundi(result * 0.75))
	if e.record.kind == "itsumade": result += unrest(e) * 2
	return result
static func unrest(e) -> int:
	return mini(3, e.game.state.remains.filter(func(r): return r.zone == "island" and Vector2(r.at[0], r.at[1]).distance_to(e.position) < 300).size())
static func shot(e, direction: Vector2, tint: Color, payload: Dictionary = {}, speed: float = 180) -> void:
	if e.record.dead or "head" in e.record.get("severed", []): return
	e.game.world.projectiles.spawn(e.position + Vector2(0, -4), direction, false, damage(e), speed, 620, tint, payload)
static func attack(e) -> void:
	if e.record.dead or "head" in e.record.get("severed", []): return
	var active_world: Node2D = e.game.world
	var aim: Vector2 = e.position.direction_to(e.attack_center)
	match e.record.kind:
		"kappa":
			for angle in [-0.18, 0.0, 0.18]: shot(e, aim.rotated(angle), Color("7acbd1"), {"snare": 1.0}, 200)
		"chochin":
			shot(e, aim, Color("dc8a87"), {"drain": 6}, 300)
			e.game.world.spell_trace(e.position + Vector2(0, -18), e.attack_center + Vector2(0, -18), "curse")
		"ippon_datara":
			if e.victim.position.distance_to(e.attack_center) < 60 and visible(e, e.victim.position): e.hurt_victim(int(e.record.damage))
			if e.game.world != active_world: return
			e.game.world.shock_ring(e.attack_center, 60, Color("d7b888"))
		"jorogumo":
			for angle in [-0.28, 0.0, 0.28]: shot(e, aim.rotated(angle), Color("d3d9c7"), {"snare": 2.5}, 150)
		"sogenbi":
			for angle in [-0.48, -0.24, 0.0, 0.24, 0.48]: shot(e, aim.rotated(angle), Color("dc9365"), {"scorch": 4.0}, 155)
		"itsumade":
			var count: int = 5 + unrest(e) + (2 if e.record.hp < e.record.max_hp / 2 else 0)
			for i in range(count): shot(e, aim.rotated((i - (count - 1) / 2.0) * 0.16), Color("e3c96c"), {}, 225)
			for side in [-1, 1]: shot(e, aim.rotated(side * 0.75), Color("99b78b"), {"poison": 4.0}, 130)
		"daitengu":
			var count: int = 9 if e.record.hp < e.record.max_hp / 2 else 5
			for i in range(count): shot(e, aim.rotated((i - (count - 1) / 2.0) * 0.17), Color("a6d3c9"), {"push": 95.0}, 250)
			for side in [-1, 1]: shot(e, aim.rotated(side * PI / 2), Color("a6d3c9"), {"push": 95.0}, 200)
		"ryomen_sukuna":
			if e.myth_phase % 2 == 0:
				var direction: Vector2 = e.position.direction_to(e.victim.position)
				if e.position.distance_to(e.victim.position) < 105 and absf(aim.dot(direction)) > 0.45 and visible(e, e.victim.position): e.hurt_victim(int(e.record.damage))
				if e.game.world != active_world: return
				e.game.world.shock_ring(e.position, 100, Color("c38278"))
			else:
				for side in [0.0, PI]:
					for angle in [-0.22, 0.0, 0.22]: shot(e, aim.rotated(side + angle), Color("d5b58c"), {}, 260)
			e.myth_phase += 1
	if e.game.world != active_world: return
	e.game.world.effect(e.attack_center, Color("c7b98a"))
static func tick(e, delta: float, spec: Dictionary) -> bool:
	if not YinIsland.ROWS.has(e.record.kind): return false
	var active_world: Node2D = e.game.world
	e.myth_time += delta
	e.myth_regen += delta
	if e.myth_regen >= 1:
		e.myth_regen = 0
		if e.record.kind == "kappa" and YinIsland.near_water(e.position) and not e.record.suppressed and "head" not in e.record.get("severed", []): e.record.hp = mini(e.record.max_hp, e.record.hp + 3)
	var home := Vector2(e.record.get("home_at", e.record.at)[0], e.record.get("home_at", e.record.at)[1])
	var distance: float = e.position.distance_to(e.victim.position)
	var is_boss: bool = e.record.kind in YinIsland.BOSSES
	e.repath -= delta
	if e.stun > 0:
		e.windup = 0
		e.velocity = e.knockback
		e.knockback = e.knockback.move_toward(Vector2.ZERO, delta * 220)
	elif is_boss and (distance > 560 or e.position.distance_to(home) > 440):
		e.windup = 0
		advance(e, home, spec.speed)
	elif e.windup > 0:
		e.velocity = Vector2.ZERO
		e.windup -= delta
		if e.windup <= 0:
			attack(e)
			e.cooldown = 1.5 if is_boss and e.record.hp < e.record.max_hp / 2 else 2.3
	elif distance < (520 if is_boss else 380):
		var melee: bool = e.record.kind == "ippon_datara" or (e.record.kind == "ryomen_sukuna" and e.myth_phase % 2 == 0)
		var reach: float = 85 if melee else (180 if e.record.kind == "chochin" else 340)
		var speed: float = spec.speed
		if e.record.kind == "ippon_datara": speed *= 1.5 if fmod(e.myth_time, 0.8) < 0.3 else 0.25
		if e.record.kind == "kappa" and YinIsland.near_water(e.position) and not e.record.suppressed: speed *= 1.35
		if distance > (65 if melee else 240): advance(e, e.victim.position, speed)
		elif not melee and distance < 110: advance(e, e.position - e.position.direction_to(e.victim.position) * 40, speed * 0.7)
		else: e.velocity = Vector2.ZERO
		if distance < reach and e.cooldown <= 0 and visible(e, e.victim.position):
			e.windup = 0.95 if melee else 0.8
			e.attack_center = e.victim.position
	else:
		e.velocity = Vector2.ZERO
	if e.game.world != active_world or not e.is_inside_tree(): return true
	e.move_and_slide()
	e.record.at = [e.position.x, e.position.y]
	e.queue_redraw()
	return true
static func advance(e, at: Vector2, speed: float) -> void:
	if e.position.distance_to(at) < 12:
		e.velocity = Vector2.ZERO
		return
	if visible(e, at):
		e.velocity = e.position.direction_to(at) * speed
	else:
		if e.repath <= 0:
			e.route = e.game.world.path_to(e.position, at)
			e.repath = 0.5
		while e.route.size() > 0 and e.position.distance_to(e.route[0]) < 8: e.route.remove_at(0)
		e.velocity = e.position.direction_to(e.route[0]) * speed if e.route.size() > 0 else Vector2.ZERO
static func draw_warning(e) -> void:
	if e.windup <= 0: return
	var center: Vector2 = e.attack_center - e.position
	if e.record.kind == "ippon_datara" or e.record.kind == "ryomen_sukuna" and e.myth_phase % 2 == 0:
		if e.record.kind == "ryomen_sukuna": center = Vector2.ZERO
		var radius: float = 100 if e.record.kind == "ryomen_sukuna" else 60
		e.draw_circle(center, radius, Color("c97f7133"))
		e.draw_arc(center, radius, -PI / 2, -PI / 2 + TAU * (1 - e.windup / 0.95), 32, Color("efc481"), 2)
	else:
		var direction: Vector2 = e.position.direction_to(e.attack_center)
		e.draw_line(Vector2(0, -20), direction * 130 + Vector2(0, -20), Color("e7c785"), 2)
		if e.record.kind in ["jorogumo", "daitengu", "itsumade"]:
			for angle in [-0.35, 0.35]: e.draw_line(Vector2(0, -20), direction.rotated(angle) * 110 + Vector2(0, -20), Color("e7c78588"), 1)
