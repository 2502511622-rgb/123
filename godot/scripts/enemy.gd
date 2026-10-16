class_name YinEnemy
extends CharacterBody2D
var motion:=YinMonsterMotion.new()
var model: YinMonsterRig
var body_shape: CollisionShape2D
var art_clock: float = 0
var art_facing := Vector2.DOWN
var art_strike: float = 0
var game: Node2D
var record: Dictionary
var stun: float = 0
var cooldown: float = 1
var windup: float = 0
var attack_center := Vector2.ZERO
var hit_flash: float = 0
var hit_stop: float = 0
var health_trail: float = -1
var trail_delay: float = 0
var knockback := Vector2.ZERO
var burst_remaining: int = 0
var burst_timer: float = 0
var route: PackedVector2Array = []
var repath: float = 0
var victim: Node2D
var bleed_time: float = 0
var bleed_tick: float = 0
var bleed_damage: int = 0
var passive_clock: float = 0
var myth_time: float = 0
var myth_regen: float = 0
var myth_phase: int = 0
var shield: int = 0
var burn_time: float = 0
var burn_tick: float = 0
var burn_power: int = 3
var chill_time: float = 0
var freeze_lock: float = 0
var freeze_immunity: float = 0
var panic_turn: float = 0
var panic_direction := Vector2.RIGHT
var charge_time: float = 0
var charge_direction: Vector2
var charge_hit: bool = false
var health_receiver: YinHealthReceiver
var hurtbox: YinHurtbox

func _ready() -> void:
	var flash_material := ShaderMaterial.new()
	flash_material.shader = preload("res://shaders/hit_flash.gdshader")
	material = flash_material
	material.set_shader_parameter("environment_blend",0.35)
	health_receiver = YinHealthReceiver.new()
	health_receiver.name = "HealthReceiver"
	health_receiver.bind_record(record)
	add_child(health_receiver)
	hurtbox = YinHurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.actor = self
	add_child(hurtbox)
	if record.get("faction", "") == "village": hurtbox.collision_layer = 0
	health_trail = float(record.hp)
	shield = 20 if record.kind == "opera_boss" else 0
	collision_layer=4
	collision_mask=7
	motion_mode=CharacterBody2D.MOTION_MODE_FLOATING
	body_shape=CollisionShape2D.new()
	body_shape.name="PhysicalVolume"
	body_shape.shape=YinBodyProfile.shape(record.kind)
	body_shape.rotation=PI/2
	body_shape.position=Vector2(0,-4)
	add_child(body_shape)
	model=YinMonsterRig.new()
	model.actor=self
	add_child(model)

func _physics_process(delta: float) -> void:
	if record.dead:
		queue_free()
		return
	if game.modal != null or is_queued_for_deletion(): return
	motion.update(self,delta)
	if freeze_lock <= 0 and hit_stop <= 0: art_clock += delta*(0.62 if "leg" in record.get("severed",[]) else 1.0)
	if velocity.length() > 2: art_facing = velocity.normalized()
	material.set_shader_parameter("motion_clock", art_clock)
	material.set_shader_parameter("motion_amount", 0.0)
	art_strike = 0.18 if windup > 0 else maxf(0, art_strike - delta)
	hit_flash = maxf(0, hit_flash - delta)
	material.set_shader_parameter("flash", 1.0 if hit_flash > 0.065 else 0.0)
	trail_delay = maxf(0, trail_delay - delta)
	if trail_delay <= 0: health_trail = move_toward(health_trail, float(record.hp), delta * record.max_hp)
	queue_redraw()
	if hit_stop > 0:
		hit_stop -= delta
		return
	var active_world: Node2D = game.world
	victim = faction_target() if record.has("war_id") else game.closest_ally(position)
	if victim == null: return
	chill_time = maxf(0, chill_time - delta)
	freeze_lock = maxf(0, freeze_lock - delta)
	freeze_immunity = maxf(0, freeze_immunity - delta)
	if burn_time > 0:
		burn_time -= delta
		burn_tick -= delta
		if burn_tick <= 0:
			burn_tick = 1
			receive_hit(burn_power, "burn")
			if record.dead: return
	if freeze_lock > 0:
		velocity = Vector2.ZERO
		return
	passive_clock += delta
	if bleed_time > 0:
		bleed_time -= delta
		bleed_tick -= delta
		if bleed_tick <= 0:
			bleed_tick = 1
			receive_hit(bleed_damage, "bleed")
			if record.dead: return
	if passive_clock >= 1:
		if record.kind == "water" and record.hp < record.max_hp / 2: record.hp = mini(record.max_hp, record.hp + 1)
		if record.kind == "opera_boss" and passive_clock >= 10:
			shield = 20
			passive_clock = 0
		elif record.kind != "opera_boss": passive_clock = 0
	stun = maxf(0, stun - delta)
	cooldown = maxf(0, cooldown - delta)
	var spec: Dictionary = YinBalance.MONSTERS[record.kind].duplicate()
	spec.pattern = YinAbilities.meta(record.kind).pattern
	if "leg" in record.get("severed", []): spec.speed *= 0.62
	if chill_time > 0: spec.speed *= 0.45
	if "head" in record.get("severed", []):
		windup = 0
		burst_remaining = 0
		charge_time = 0
		panic_turn -= delta
		if panic_turn <= 0 or is_on_wall():
			panic_direction = Vector2.from_angle(float(record.id) + float(Time.get_ticks_msec()) * 0.007)
			panic_turn = 0.55
		velocity = panic_direction * spec.speed * 1.35
		step_body(delta)
		record.at = [position.x, position.y]
		return
	if record.has("war_id"):
		faction_tick(delta, spec)
		return
	if YinTempleCombat.tick(self, delta, spec): return
	if YinIslandCombat.tick(self, delta, spec): return
	var boss: bool = record.kind in YinAbilities.BOSSES
	var ranged: bool = spec.pattern in ["fan", "ring", "burst", "tide", "opera", "cold"]
	var distance: float = position.distance_to(victim.position)
	var sight_ray := PhysicsRayQueryParameters2D.create(position + Vector2(0, -4), victim.position + Vector2(0, -4), 1)
	var has_sight: bool = get_world_2d().direct_space_state.intersect_ray(sight_ray).is_empty()
	repath -= delta
	if charge_time > 0:
		charge_time -= delta
		velocity = charge_direction * (130 if "leg" in record.get("severed", []) else 210)
		if not charge_hit and position.distance_to(victim.position) < 32:
			hurt_victim(int(record.get("damage", spec.damage)))
			charge_hit = true
	elif stun > 0:
		windup = 0
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, delta * 220)
	elif windup > 0:
		windup -= delta
		velocity = Vector2.ZERO
		if windup <= 0:
			if spec.pattern == "charge":
				charge_time = 0.45
				charge_direction = position.direction_to(attack_center)
				charge_hit = false
			elif ranged:
				volley(spec.pattern)
			elif victim.position.distance_to(attack_center) < (57 if boss else (42 if record.kind == "brute" else 29)):
				var ray := PhysicsRayQueryParameters2D.create(position + Vector2(0, -4), victim.position + Vector2(0, -4), 1)
				if get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): hurt_victim(int(record.get("damage", spec.damage)))
			if record.kind == "boss": volley("boss")
			game.world.effect(attack_center, Color("b77862"))
			cooldown = (1.1 if boss and record.hp < record.max_hp / 2 else 2.2) if ranged else (1.5 if boss else 1.8)
			if record.kind == "gunner": cooldown *= 0.8
	elif burst_remaining > 0:
		velocity = Vector2.ZERO
		burst_timer -= delta
		if burst_timer <= 0:
			fire_bullet(position.direction_to(victim.position), 240)
			burst_remaining -= 1
			burst_timer = 0.16
	elif distance < (520 if ranged else (360 if game.state.minutes >= 1080 else 180)):
		var direction: Vector2 = position.direction_to(victim.position)
		velocity = direction * spec.speed * (1.35 if record.kind == "brute" and record.hp < record.max_hp / 2 else 1.0)
		if ranged:
			velocity = -direction * spec.speed if distance < 125 else (Vector2.ZERO if distance < 300 else velocity)
		if not has_sight or not game.world.clear_body_path(position,victim.position,YinBodyProfile.spec(record.kind).half):
			if repath <= 0:
				route = game.world.path_to(position, victim.position,YinBodyProfile.spec(record.kind).half)
				repath = 0.5
			while route.size() > 0 and position.distance_to(route[0]) < 8: route.remove_at(0)
			velocity = position.direction_to(route[0]) * spec.speed if route.size() > 0 else velocity
		if has_sight and distance < (360 if ranged else (320 if boss else (210 if record.kind == "brute" else (42 if record.kind == "bone" else 26)))) and cooldown <= 0:
			windup = 0.85 if ranged else (0.8 if boss else 0.5)
			attack_center = victim.position
	else: velocity = Vector2.ZERO
	if game.world != active_world or not is_inside_tree(): return
	step_body(delta)
	record.at = [position.x, position.y]
	queue_redraw()
func fire_bullet(direction: Vector2, speed: float = 160) -> void:
	if "head" in record.get("severed", []) or record.dead: return
	var spec: Dictionary = YinBalance.MONSTERS[record.kind]
	game.world.projectiles.spawn(position + Vector2(0, -4), direction, false, roundi(int(record.get("damage", spec.damage)) * (0.75 if "arm" in record.get("severed", []) else 1.0)) + (2 if record.kind == "archer" else 0), speed, 760, Color("c78882") if record.kind != "lantern" else Color("8bc5b1"))
func volley(pattern: String) -> void:
	if "head" in record.get("severed", []) or record.dead: return
	var aim: Vector2 = position.direction_to(attack_center)
	match pattern:
		"cold":
			for angle in [-0.18, 0.0, 0.18]: fire_bullet(aim.rotated(angle), 155)
		"fan":
			var count: int = 5 if record.get("elite", false) else 3
			for i in range(count): fire_bullet(aim.rotated((i - (count - 1) / 2.0) * 0.24), 185)
		"tide":
			record.hp = mini(record.max_hp, record.hp + 4)
			for i in range(18): fire_bullet(Vector2.from_angle(TAU * i / 18 + float(record.hp) / record.max_hp), 100 if i % 2 == 0 else 180)
		"opera":
			for i in range(7): fire_bullet(aim.rotated((i - 3) * 0.14), 220)
			burst_remaining = 4 if record.hp < record.max_hp * 0.5 else 2
			burst_timer = 0.2
		"ring", "boss":
			if pattern == "ring": record.hp = mini(record.max_hp, record.hp + 3)
			var count: int = (16 if record.get("elite", false) else 12) if pattern == "ring" else (16 if record.hp < record.max_hp / 2 else 12)
			for i in range(count): fire_bullet(Vector2.from_angle(TAU * i / count + 0.15), 135 if pattern == "ring" else 155)
			if pattern == "boss" and record.hp < record.max_hp * 0.5:
				for angle in [-0.18, 0.0, 0.18]: fire_bullet(aim.rotated(angle), 225)
		"burst":
			burst_remaining = 5 if record.get("elite", false) else 3
			burst_timer = 0

func receive_hit(damage: int, method: String = "sword", source_gear_id: int = 0) -> void:
	if record.dead: return
	var armor: int = int(record.get("armor", 0)) if method not in ["seal", "fire", "bleed", "burn", "lightning", "curse"] else 0
	var adjusted: int = YinBalance.damage(damage, 1, {}, armor)
	if method in ["sword", "bullet", "tool"] and not record.suppressed:
		if record.kind == "wraith": adjusted = maxi(1, roundi(adjusted * 0.3))
		elif YinTempleCombat.phantom(self): adjusted = maxi(1, roundi(adjusted * 0.5))
	if method == "seal" and record.kind == "yaksha": shield = 0
	if record.kind == "boss" and method not in ["seal", "fire", "bleed", "burn", "lightning", "curse"]: adjusted = maxi(1, roundi(adjusted * 0.75))
	if record.kind == "chochin" and method in ["fire", "burn"]: adjusted = roundi(adjusted * 1.6)
	if record.kind == "sogenbi" and method in ["fire", "burn"]: adjusted = maxi(1, roundi(adjusted * 0.25))
	if record.kind == "daitengu" and windup > 0 and method == "bullet": adjusted = maxi(1, roundi(adjusted * 0.45))
	if shield > 0:
		var absorbed: int = mini(shield, adjusted)
		shield -= absorbed
		adjusted -= absorbed
	var dealt: int = health_receiver.apply(adjusted, method)
	if method == "sword": game.state.artifact_hit(source_gear_id, dealt)
	game.world.damage_number(position, dealt, Color("edb779") if method == "fire" else Color("eee0b4"))
	if dealt > 0:
		trail_delay = 0.3
		hit_flash = 0.13
		material.set_shader_parameter("flash", 1.0)
		if method not in ["bleed", "burn", "seal"]:
			hit_stop = 0.035 if record.kind in YinAbilities.BOSSES else 0.045
			if method == "sword": game.player.hit_pause = 0.045
			game.world.impact(position + Vector2(0, -20), game.player.position.direction_to(position), "heavy" if method=="sword" and game.player.heavy_attack else method)
			if method in ["sword", "bullet"]: update_dismemberment()

	if method == "fire":
		record.integrity = maxi(0, record.integrity - 35)
		stun = 0.2
	elif method == "seal":
		record.suppressed = true
		stun = 0.65 if record.kind in YinAbilities.BOSSES else 3
		windup = 0
		burst_remaining = 0
	elif method == "bullet":
		knockback = game.player.position.direction_to(position) * (18 if record.kind in YinAbilities.BOSSES else 42/float(YinBodyProfile.spec(record.kind).mass))
		stun = maxf(stun, 0.045)
	elif method in ["bleed", "burn", "curse", "lightning"] or record.kind in YinAbilities.BOSSES:
		pass
	else:
		windup = 0
		stun = maxf(stun, 0.18)
		knockback = (victim.position if is_instance_valid(victim) else game.player.position).direction_to(position) * 75
	if record.hp == 0:
		var first_before: int=YinAdventure.progress(game.state,YinFirstJourney.ID)
		game.state.kill_enemy(record.id, position, source_gear_id if method == "sword" else 0)
		var first_after: int=YinAdventure.progress(game.state,YinFirstJourney.ID)
		if first_after>first_before:game.notify_action("守夜完成：沿西南灯门回义庄，按O领取银剑。" if first_after==2 else "初次守夜 1/2 · 清理另一只异怪即可复命。")
		game.world.effect(position, Color("97b5a1"))
		game.spawn_remains_visuals()
		game.spawn_pickups()
		game.spawn_gear_pickups()
		if record.kind in YinTemple.BOSSES:
			game.spawn_enemies()
			game.refresh("佛寺战意已平息，返回村庄复命，或循山路进入护法殿。")
		if record.kind in YinIsland.BOSSES:
			game.spawn_enemies()
			game.refresh("岛国封印已松动，前往下一处祭场，或回村复命。")
		game.persist()
		queue_free()

func _draw() -> void:
	if record.is_empty(): return
	if record.has("faction"):
		draw_circle(Vector2(0, 1), 13, YinFactions.COLORS[record.faction])
		draw_string(ThemeDB.fallback_font, Vector2(-18, -72), YinFactions.NAMES[record.faction], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, YinFactions.COLORS[record.faction])
	YinActorArt.contact_shadow(self,15 if record.kind in YinAbilities.BOSSES else 10,float(motion.descriptor(record.kind).gait),clampf(velocity.length()/45.0,0,1))
	if position.distance_to(game.player.position)<145:
		draw_arc(Vector2(0,-3),float(YinBodyProfile.spec(record.kind).size.x)*0.5+3,0,TAU,24,Color(0.88,0.56,0.41,0.75 if windup>0 else 0.3),1.2)
	var boss: bool = record.kind in YinAbilities.BOSSES
	var tint := Color.WHITE if hit_flash > 0.065 else (Color("d79279") if hit_flash > 0 else (Color("8eafd0") if stun > 0.3 or chill_time > 0 else Color("e1e5ce")))
	if record.kind == "wraith": tint.a = 0.55 if not record.suppressed else 1.0
	if YinTempleCombat.phantom(self): tint = Color("c8a3e0aa")
	var missing: Array = record.get("severed", [])
	var pose: Dictionary = art_pose()
	model.present(record.kind,pose,missing,art_clock,velocity.length()>2 and freeze_lock<=0,art_strike>0,tint)
	draw_set_transform(Vector2.ZERO)
	var art_height: float = -pose.destination.position.y + 7
	var reveal: bool = record.hp < record.max_hp or record.kind in YinAbilities.BOSSES or record.get("elite", false) or position.distance_to(game.player.position) < 160
	if reveal:
		draw_rect(Rect2(-16, -art_height, 32, 3), Color("413e3e"))
		draw_rect(Rect2(-16, -art_height, 32 * health_trail / record.max_hp, 3), Color("e6bb83"))
		draw_rect(Rect2(-16, -art_height, 32 * float(record.hp) / record.max_hp, 3), Color("aa7164"))
	if windup>0:draw_string(ThemeDB.fallback_font,Vector2(19,-art_height-5),"蓄力",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffd793"))
	if shield > 0: draw_arc(Vector2(0, -25), 25, 0, TAU, 20, Color("96c0db"), 2)
	if burn_time > 0: draw_circle(Vector2(8, -24), 3, Color("f4a261"))
	if chill_time > 0: draw_arc(Vector2(0, -20), 18, 0, TAU, 12, Color("91d8ee"), 1)
	if bleed_time > 0: draw_rect(Rect2(-3, -56, 6, 6), Color("b54e5c"))
	var caption: String = YinBalance.MONSTERS[record.kind].name + " Lv%d" % int(record.get("level", 1)) + (" · 精英" if record.get("elite", false) else "")
	if record.get("faction", "") == "village": caption = "护村役卫 Lv%d" % int(record.get("level", 1))
	if reveal:
		draw_string(ThemeDB.fallback_font, Vector2(-24, -art_height - 5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e6c485") if record.get("elite", false) else Color("c8c9ae"))
	if YinTemple.ROWS.has(record.kind):
		YinTempleCombat.draw_warning(self)
	elif YinIsland.ROWS.has(record.kind):
		YinIslandCombat.draw_warning(self)
	elif windup > 0 and YinAbilities.meta(record.kind).pattern in ["fan", "ring", "burst", "tide", "opera", "cold"]:
		var direction: Vector2 = position.direction_to(attack_center)
		draw_line(Vector2(0, -14), direction * 120 - Vector2(0, 14), Color("e0a27b99"), 1)
		draw_arc(Vector2(0, -14), 26, 0, TAU * (1 - windup / 0.85), 24, Color("e6b17c"), 2)
	elif windup > 0:
		var local_center: Vector2 = attack_center - position
		draw_circle(local_center, 57 if boss else (42 if record.kind == "brute" else 29), Color(0.8, 0.24, 0.16, 0.28))
		draw_arc(local_center, 57 if boss else (42 if record.kind == "brute" else 29), -PI / 2, -PI / 2 + TAU * (1 - windup / (0.8 if boss else 0.5)), 32, Color("f0bc7d"), 3)
		draw_rect(Rect2(local_center - Vector2(2, 2), Vector2(4, 4)), Color("f0bc7d"))

func hurt_victim(damage: int) -> void:
	if not is_instance_valid(victim) or "head" in record.get("severed", []) or record.dead: return
	if "arm" in record.get("severed", []): damage = maxi(1, roundi(damage * 0.75))
	if record.kind == "brute" and record.hp < record.max_hp / 2: damage = roundi(damage * 1.2)
	if victim == game.player: game.take_damage(damage)
	else: victim.receive_hit(damage)
func apply_bleed(duration: float, damage: int) -> void:
	bleed_time = maxf(bleed_time, duration)
	bleed_damage = maxi(bleed_damage, damage)

func update_dismemberment() -> void:
	if not record.has("severed"): record.severed = []
	var ratio: float = float(record.hp) / record.max_hp
	for part in YinIsland.anatomy(record.kind):
		if part in record.severed or ratio > {"arm": 0.60, "leg": 0.30, "head": 0.15}[part]: continue
		record.severed.append(part)
		if part == "head":
			windup = 0
			burst_remaining = 0
			charge_time = 0
		var pose: Dictionary = art_pose()
		for piece in YinActorArt.posed_parts(record.kind,pose,art_clock,velocity.length()>2 and freeze_lock<=0,art_strike>0):
			if piece.part != part: continue
			var cut: Dictionary = piece.pose
			var fragment := YinSeveredLimb.new()
			fragment.part = part
			fragment.source_atlas = cut.origin_texture
			fragment.origin_region = cut.origin_region
			fragment.joint = cut.joint
			fragment.source_texture = cut.texture
			fragment.source_region = cut.source
			fragment.draw_size = cut.destination.size
			fragment.flip_h = cut.flip
			var center: Vector2 = YinActorArt.part_center(cut)
			fragment.rotation = float(cut.get("rotation",0))*(-1.0 if cut.flip else 1.0)
			fragment.position = position + center
			fragment.height = 0
			fragment.velocity = game.player.position.direction_to(position).rotated(-0.6 if part == "arm" else 0.6) * 85
			game.world.feedback.add_child(fragment)
			game.world.effect(fragment.position, Color("a57465"))

	queue_redraw()

func art_pose() -> Dictionary:
	var pose: Dictionary = YinActorArt.enemy_pose(record.kind,art_facing,art_clock,velocity.length()>2,art_strike>0,record.kind in YinAbilities.BOSSES)
	if hit_flash>0: pose.destination.position.x+=sin(hit_flash*80)*1.5
	pose.motion=motion.descriptor(record.kind)
	return pose

func apply_element(element: String, power: int = 3, harmonious: bool = false) -> void:
	if record.dead: return
	match element:
		"burn":
			if not harmonious:
				chill_time = 0
				freeze_lock = 0
			burn_time = 4
			burn_power = maxi(burn_power, power)
		"freeze":
			if burn_time > 0 and not harmonious:
				burn_time = 0
				game.world.effect(position + Vector2(0, -20), Color("dce5e7"))
			chill_time = 3
			if freeze_immunity <= 0:
				freeze_lock = 0.10 if record.kind in YinAbilities.BOSSES else 0.4
				freeze_immunity = 4
		"lightning":
			var neighbors: Array = []
			for other in get_tree().get_nodes_in_group("enemies"):
				if other == self or other.is_queued_for_deletion() or other.record.dead or other.get_parent() != game.world.actors or position.distance_to(other.position) > 140: continue
				var ray := PhysicsRayQueryParameters2D.create(position + Vector2(0, -4), other.position + Vector2(0, -4), 1)
				if get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): neighbors.append(other)
			neighbors.sort_custom(func(a, b): return position.distance_squared_to(a.position) < position.distance_squared_to(b.position))
			for i in range(mini(2, neighbors.size())):
				game.world.spell_trace(position + Vector2(0, -20), neighbors[i].position + Vector2(0, -20), "lightning")
				neighbors[i].receive_hit(power * 2, "lightning")
	queue_redraw()

# Expedition units seek the opposing army; village militia never target the player.
func faction_target() -> Node2D:
	var target: Node2D = null
	var best: float = INF
	for group in ["enemies", "faction_guards"]:
		for actor in get_tree().get_nodes_in_group(group):
			if actor == self or actor.is_queued_for_deletion() or actor.get_parent() != game.world.actors or actor.record.dead: continue
			if actor.record.get("war_id", 0) != record.war_id or actor.record.get("faction", "") == record.faction: continue
			var distance: float = position.distance_to(actor.position)
			if distance < best:
				best = distance
				target = actor
	if target == null and not YinFactions.friendly(game.state,record): return game.closest_ally(position)
	return target

func faction_tick(delta: float, spec: Dictionary) -> void:
	var distance: float = position.distance_to(victim.position)
	var ray := PhysicsRayQueryParameters2D.create(position + Vector2(0, -4), victim.position + Vector2(0, -4), 1)
	var sight: bool = get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
	velocity = Vector2.ZERO
	if stun > 0:
		windup = 0
	elif windup > 0:
		windup -= delta
		if windup <= 0:
			if sight and victim.position.distance_to(attack_center) < 45:
				if victim is YinEnemy:
					victim.receive_faction_hit(int(record.damage))
				else: hurt_victim(int(record.damage))
			cooldown = 1.2
	elif distance < 38 and sight and cooldown <= 0:
		windup = 0.5
		attack_center = victim.position
	else:
		if sight: velocity = position.direction_to(victim.position) * float(spec.speed)
		else:
			repath -= delta
			if repath <= 0:
				route = game.world.path_to(position, victim.position,YinBodyProfile.spec(record.kind).half)
				repath = 0.5
			while not route.is_empty() and position.distance_to(route[0]) < 8: route.remove_at(0)
			if not route.is_empty(): velocity = position.direction_to(route[0]) * float(spec.speed)
	if is_inside_tree() and get_parent() == game.world.actors:
		step_body(delta)
		record.at = [position.x, position.y]

func receive_faction_hit(damage: int) -> void:
	if record.dead: return
	health_receiver.apply(maxi(1, damage - int(record.get("armor", 0))), "war")
	hit_flash = 0.13
	game.world.impact(position+Vector2(0,-20),Vector2.RIGHT,"sword")
	game.world.damage_number(position, damage, Color("e5c792"))
	if record.hp <= 0:
		record.dead = true
		queue_free()

func step_body(_delta: float) -> void:
	var body: Dictionary=YinBodyProfile.spec(record.kind)
	if velocity.length()>1 and stun<=0:
		var separation:=Vector2.ZERO
		for other in get_tree().get_nodes_in_group("enemies")+get_tree().get_nodes_in_group("faction_guards"):
			if other==self or other.is_queued_for_deletion() or other.get_parent()!=get_parent():continue
			var away: Vector2=position-other.position
			var minimum: float=(body.size.x+YinBodyProfile.spec(other.record.kind).size.x)*0.55
			if away.length_squared()<minimum*minimum:
				if away.length_squared()<0.01:away=Vector2.from_angle(float(record.id)*2.399)
				separation+=away.normalized()*(1-clampf(away.length()/minimum,0,1))
		velocity+=separation*16/body.mass
	move_and_slide()
	if get_slide_collision_count()>0 and velocity.length()>1:repath=0
