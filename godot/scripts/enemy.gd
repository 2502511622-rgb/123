class_name YinEnemy
extends CharacterBody2D
var game: Node2D
var record: Dictionary
var stun: float = 0
var cooldown: float = 1
var windup: float = 0
var attack_center := Vector2.ZERO
var hit_flash: float = 0
var knockback := Vector2.ZERO
var burst_remaining: int = 0
var burst_timer: float = 0
var health_receiver: YinHealthReceiver
var hurtbox: YinHurtbox
const TEXTURE = preload("res://assets/enemies.png")

func _ready() -> void:
	health_receiver = YinHealthReceiver.new()
	health_receiver.name = "HealthReceiver"
	health_receiver.bind_record(record)
	add_child(health_receiver)
	hurtbox = YinHurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.actor = self
	add_child(hurtbox)
	collision_layer = 4
	collision_mask = 7
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(14, 10)
	shape.shape = box
	shape.position.y = -4
	add_child(shape)

func _physics_process(delta: float) -> void:
	if game.modal != null or record.dead or is_queued_for_deletion(): return
	stun = maxf(0, stun - delta)
	hit_flash = maxf(0, hit_flash - delta)
	cooldown = maxf(0, cooldown - delta)
	var spec: Dictionary = YinBalance.MONSTERS[record.kind]
	var boss: bool = record.kind == "boss"
	var ranged: bool = spec.pattern in ["fan", "ring", "burst", "tide", "opera"]
	var distance: float = position.distance_to(game.player.position)
	if stun > 0:
		windup = 0
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, delta * 220)
	elif windup > 0:
		windup -= delta
		velocity = Vector2.ZERO
		if windup <= 0:
			if ranged:
				volley(spec.pattern)
			elif game.player.position.distance_to(attack_center) < (57 if boss else (42 if record.kind == "brute" else 29)):
				var ray := PhysicsRayQueryParameters2D.create(position + Vector2(0, -4), game.player.position + Vector2(0, -4), 1)
				if get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): game.take_damage(int(record.get("damage", spec.damage)))
			if boss: volley("boss")
			game.world.effect(attack_center, Color("b77862"))
			cooldown = 2.2 if ranged else (1.5 if boss else 1.2)
	elif burst_remaining > 0:
		velocity = Vector2.ZERO
		burst_timer -= delta
		if burst_timer <= 0:
			fire_bullet(position.direction_to(game.player.position), 240)
			burst_remaining -= 1
			burst_timer = 0.16
	elif distance < (520 if ranged else (360 if game.state.minutes >= 1080 else 180)):
		var direction: Vector2 = position.direction_to(game.player.position)
		velocity = direction * spec.speed
		if ranged:
			velocity = -direction * spec.speed if distance < 125 else (Vector2.ZERO if distance < 300 else velocity)
		if distance < (360 if ranged else (320 if boss else (38 if record.kind == "brute" else 26))) and cooldown <= 0:
			windup = 0.85 if ranged else (0.8 if boss else 0.5)
			attack_center = game.player.position
	else: velocity = Vector2.ZERO
	move_and_slide()
	record.at = [position.x, position.y]
	queue_redraw()
func fire_bullet(direction: Vector2, speed: float = 160) -> void:
	var spec: Dictionary = YinBalance.MONSTERS[record.kind]
	game.world.projectiles.spawn(position + Vector2(0, -4), direction, false, int(record.get("damage", spec.damage)), speed, 760, Color("c78882") if record.kind != "lantern" else Color("8bc5b1"))
func volley(pattern: String) -> void:
	var aim: Vector2 = position.direction_to(attack_center)
	match pattern:
		"fan":
			var count: int = 5 if record.get("elite", false) else 3
			for i in range(count): fire_bullet(aim.rotated((i - (count - 1) / 2.0) * 0.24), 185)
		"tide":
			for i in range(18): fire_bullet(Vector2.from_angle(TAU * i / 18 + float(record.hp) / record.max_hp), 100 if i % 2 == 0 else 180)
		"opera":
			for i in range(7): fire_bullet(aim.rotated((i - 3) * 0.14), 220)
			burst_remaining = 4 if record.hp < record.max_hp * 0.5 else 2
			burst_timer = 0.2
		"ring", "boss":
			var count: int = (16 if record.get("elite", false) else 12) if pattern == "ring" else 8
			for i in range(count): fire_bullet(Vector2.from_angle(TAU * i / count + 0.15), 135 if pattern == "ring" else 155)
			if pattern == "boss" and record.hp < record.max_hp * 0.5:
				for angle in [-0.18, 0.0, 0.18]: fire_bullet(aim.rotated(angle), 225)
		"burst":
			burst_remaining = 5 if record.get("elite", false) else 3
			burst_timer = 0

func receive_hit(damage: int, method: String = "sword") -> void:
	if record.dead: return
	var armor: int = int(record.get("armor", 0)) if method not in ["seal", "fire"] else 0
	var adjusted: int = YinBalance.damage(damage, 1, {}, armor)
	var dealt: int = health_receiver.apply(adjusted, method)
	game.world.damage_number(position, dealt, Color("edb779") if method == "fire" else Color("eee0b4"))
	game.world.effect(position + Vector2(0, -16), Color("d7cba6"))
	hit_flash = 0.15
	if method == "fire":
		record.integrity = maxi(0, record.integrity - 35)
		stun = 0.2
	elif method == "seal":
		record.suppressed = true
		stun = 3
		windup = 0
		burst_remaining = 0
	elif method == "bullet":
		pass
	else:
		windup = 0
		stun = maxf(stun, 0.18)
		knockback = game.player.position.direction_to(position) * 75
	if record.hp == 0:
		game.state.kill_enemy(record.id, position)
		game.world.effect(position, Color("97b5a1"))
		game.spawn_remains_visuals()
		game.spawn_pickups()
		game.spawn_gear_pickups()
		game.notify_action("鬼物倒下，遗骸留在原地。靠近按 E，亲自处理。")
		queue_free()

func _draw() -> void:
	if record.is_empty(): return
	draw_rect(Rect2(-12, -3, 24, 5), Color("253b3a66"))
	var row: int = {"water": 0, "bone": 1, "boss": 2, "archer": 3, "lantern": 4, "gunner": 5, "brute": 6, "well_boss": 0, "opera_boss": 5}.get(record.kind, 0)
	var scale_value: float = 3 if record.kind in ["boss", "well_boss", "opera_boss"] else 2
	var tint := Color("eab498") if hit_flash > 0 else (Color("8eafd0") if stun > 0.3 else Color.WHITE)
	draw_texture_rect_region(TEXTURE, Rect2(-8 * scale_value, -22 * scale_value, 16 * scale_value, 24 * scale_value), Rect2(0, row * 24, 16, 24), tint)
	if record.kind == "well_boss":
		draw_arc(Vector2(0, -18), 24, 0, TAU, 16, Color("85c9ce"), 3)
		draw_rect(Rect2(-20, -70, 40, 8), Color("366777"))
	if record.kind == "opera_boss":
		draw_rect(Rect2(-12, -62, 24, 16), Color("e7d6b9"))
		draw_rect(Rect2(-9, -56, 18, 4), Color("9d495c"))
		for side in [-1, 1]: draw_line(Vector2(side * 15, -38), Vector2(side * 31, -7), Color("c26f85"), 4)
	draw_rect(Rect2(-16, -50 * (1.4 if row == 2 else 1), 32, 3), Color("413e3e"))
	draw_rect(Rect2(-16, -50 * (1.4 if row == 2 else 1), 32 * float(record.hp) / record.max_hp, 3), Color("aa7164"))
	var caption: String = YinBalance.MONSTERS[record.kind].name + " Lv%d" % int(record.get("level", 1)) + (" · 精英" if record.get("elite", false) else "")
	draw_string(ThemeDB.fallback_font, Vector2(-24, -56 * (1.4 if row == 2 else 1)), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e6c485") if record.get("elite", false) else Color("c8c9ae"))
	if windup > 0 and YinBalance.MONSTERS[record.kind].pattern in ["fan", "ring", "burst", "tide", "opera"]:
		var direction: Vector2 = position.direction_to(attack_center)
		draw_line(Vector2(0, -14), direction * 120 - Vector2(0, 14), Color("e0a27b99"), 1)
		draw_arc(Vector2(0, -14), 26, 0, TAU * (1 - windup / 0.85), 24, Color("e6b17c"), 2)
	elif windup > 0:
		var local_center: Vector2 = attack_center - position
		draw_circle(local_center, 57 if row == 2 else (42 if record.kind == "brute" else 29), Color(0.7, 0.27, 0.20, 0.2))
		draw_arc(local_center, 57 if row == 2 else (42 if record.kind == "brute" else 29), -PI / 2, -PI / 2 + TAU * (1 - windup / (0.8 if row == 2 else 0.5)), 32, Color("f0bc7d"), 3)
		draw_rect(Rect2(local_center - Vector2(2, 2), Vector2(4, 4)), Color("f0bc7d"))
