class_name YinTempleCombat
extends RefCounted
static func phantom(e) -> bool:
	return e.record.kind == "rakshasa" and not e.record.suppressed and fmod(e.myth_time, 6.0) < 1.2
static func passive(e) -> void:
	if e.record.suppressed: return
	match e.record.kind:
		"hungry_ghost":
			if e.burn_time > 0 or e.record.hp >= e.record.max_hp: return
			for remains in e.game.state.remains:
				if remains.zone != e.record.zone or e.position.distance_to(Vector2(remains.at[0], remains.at[1])) > 100: continue
				e.game.state.remains.erase(remains)
				e.game.state.cargo.erase(remains.id)
				e.record.hp = mini(e.record.max_hp, int(e.record.hp) + 18)
				e.game.spawn_remains_visuals()
				e.game.world.shock_ring(e.position, 22, Color("b1ab77"))
				break
		"yaksha":
			e.shield = mini(50, e.shield + 18)

static func melee(e, radius: float, poison: bool = false) -> void:
	if not is_instance_valid(e.victim) or e.position.distance_to(e.victim.position) > radius or not YinIslandCombat.visible(e, e.victim.position): return
	var before: int = e.game.state.health
	var old_world: Node2D = e.game.world
	e.hurt_victim(int(e.record.damage))
	if e.game.world != old_world: return
	if e.victim == e.game.player and e.game.state.health < before:
		if poison: e.game.player.poison_time = maxf(3, e.game.player.poison_time)
		if e.record.kind == "hungry_ghost":
			e.game.state.energy = maxi(0, e.game.state.energy - 8)
			e.record.hp = mini(e.record.max_hp, int(e.record.hp) + mini(8, before - e.game.state.health))

static func attack(e) -> void:
	if e.record.dead or "head" in e.record.get("severed", []): return
	var old_world: Node2D = e.game.world
	var aim: Vector2 = e.position.direction_to(e.attack_center)
	match e.record.kind:
		"hungry_ghost": melee(e, 48)
		"wraith": YinIslandCombat.shot(e, aim, Color("a0d0d8"), {"drain": 5}, 170)
		"rakshasa":
			melee(e, 58, true)
			if e.game.world != old_world: return
			e.game.world.shock_ring(e.position - aim * 34, 22, Color("b18cc6"))
		"kumbhanda":
			for angle in [-0.25, 0.0, 0.25]: YinIslandCombat.shot(e, aim.rotated(angle), Color("bba4d7"), {"snare": 2.2, "drain": 12}, 130)
		"asura":
			if e.myth_phase % 2 == 0:
				var direction: Vector2 = e.position.direction_to(e.victim.position)
				# Six blades leave six clear gaps; sidestepping a spoke avoids the strike.
				var aligned: bool = false
				for i in range(6):
					if aim.rotated(i * TAU / 6).dot(direction) > cos(0.22): aligned = true
				if aligned: melee(e, 112)
			else:
				for i in range(12): YinIslandCombat.shot(e, aim.rotated(i * TAU / 12), Color("df9567"), {"scorch": 3.0}, 170)
			e.myth_phase += 1
		"yaksha":
			if e.myth_phase % 2 == 0:
				e.charge_direction = aim
				e.charge_time = 0.65
				e.charge_hit = false
			else:
				for angle in [-0.22, 0.0, 0.22]: YinIslandCombat.shot(e, aim.rotated(angle), Color("f0d78a"), {"push": 80.0}, 300)
			e.myth_phase += 1
	if e.game.world != old_world: return
	e.game.world.effect(e.attack_center, Color("e3c98b"))

static func tick(e, delta: float, spec: Dictionary) -> bool:
	if not YinTemple.ROWS.has(e.record.kind): return false
	var old_world: Node2D = e.game.world
	e.myth_time += delta
	e.myth_regen += delta
	if e.myth_regen >= 6:
		e.myth_regen = 0
		passive(e)
	var distance: float = e.position.distance_to(e.victim.position)
	var boss: bool = e.record.kind in YinTemple.BOSSES
	var home := Vector2(e.record.get("home_at", e.record.at)[0], e.record.get("home_at", e.record.at)[1])
	e.repath -= delta
	if e.stun > 0:
		e.windup = 0
		e.charge_time = 0
		e.velocity = e.knockback
		e.knockback = e.knockback.move_toward(Vector2.ZERO, delta * 220)
	elif e.charge_time > 0:
		e.charge_time -= delta
		e.velocity = e.charge_direction * (140 if "leg" in e.record.get("severed", []) else 260)
		if not e.charge_hit and distance < 45:
			melee(e, 45)
			e.charge_hit = true
		if e.is_on_wall(): e.charge_time = 0
	elif boss and (distance > 580 or e.position.distance_to(home) > 430):
		e.windup = 0
		YinIslandCombat.advance(e, home, spec.speed)
	elif e.windup > 0:
		e.velocity = Vector2.ZERO
		e.windup -= delta
		if e.windup <= 0:
			attack(e)
			e.cooldown = 1.3 if boss and e.record.hp < e.record.max_hp / 2 else 2.1
	elif distance < (540 if boss else 380):
		var close: bool = e.record.kind in ["hungry_ghost", "rakshasa"] or (e.record.kind == "asura" and e.myth_phase % 2 == 0)
		var reach: float = (110 if e.record.kind == "asura" else 48) if close else 350
		var speed: float = spec.speed * (1.35 if e.record.kind == "asura" and e.record.hp < e.record.max_hp / 2 else 1.0)
		if distance > (reach * 0.8 if close else 230):
			var destination: Vector2 = e.victim.position
			if phantom(e): destination += e.position.direction_to(destination).orthogonal() * 64
			YinIslandCombat.advance(e, destination, speed)
		else: e.velocity = Vector2.ZERO
		if distance < reach and e.cooldown <= 0 and YinIslandCombat.visible(e, e.victim.position):
			e.windup = 1.0 if boss else 0.75
			e.attack_center = e.victim.position
	else: e.velocity = Vector2.ZERO
	if e.game.world != old_world or not e.is_inside_tree(): return true
	e.step_body(delta)
	e.record.at = [e.position.x, e.position.y]
	e.queue_redraw()
	return true

static func draw_warning(e) -> void:
	if phantom(e): e.draw_arc(Vector2(24, -22), 17, 0, TAU, 20, Color("bba1cc77"), 2)
	if e.windup <= 0: return
	var aim: Vector2 = e.position.direction_to(e.attack_center)
	var color := Color("e9cb87")
	if e.record.kind == "asura" and e.myth_phase % 2 == 0:
		for i in range(6):
			var direction: Vector2 = aim.rotated(i * TAU / 6)
			e.draw_line(direction * 22, direction * 112, Color("e3ac7e77"), 14)
			e.draw_line(direction * 22, direction * 112, color, 2)
	elif e.record.kind in ["hungry_ghost", "rakshasa"]:
		e.draw_arc(e.attack_center - e.position, 48, 0, TAU, 32, color, 2)
	else:
		var reach: float = 170 if e.record.kind == "yaksha" else 120
		e.draw_line(Vector2(0, -8), aim * reach + Vector2(0, -8), color, 3)
		e.draw_arc(Vector2(0, -12), 26, -PI / 2, -PI / 2 + TAU * (1 - e.windup), 24, color, 2)
