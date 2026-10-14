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
const TEXTURE = preload("res://assets/enemies.png")

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(14, 10)
	shape.shape = box
	shape.position.y = -4
	add_child(shape)

func _physics_process(delta: float) -> void:
	if game.modal != null:
		return
	stun = maxf(0, stun - delta)
	hit_flash = maxf(0, hit_flash - delta)
	cooldown = maxf(0, cooldown - delta)
	var boss: bool = record.kind == "boss"
	var distance: float = position.distance_to(game.player.position)
	if windup > 0:
		windup -= delta
		if windup <= 0:
			if game.player.position.distance_to(attack_center) < (57 if boss else 29):
				game.take_damage(18 if boss else 9)
			game.world.effect(attack_center, Color("b77862"))
			cooldown = 1.5 if boss else 1.2
		velocity = Vector2.ZERO
	elif stun > 0:
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, delta * 220)
	elif distance < (360 if game.state.minutes >= 1080 else 180):
		velocity = position.direction_to(game.player.position) * (39 if boss else 29)
		if distance < (70 if boss else 26) and cooldown <= 0:
			windup = 0.8 if boss else 0.5
			attack_center = game.player.position
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	record.at = [position.x, position.y]
	queue_redraw()

func receive_hit(damage: int, method: String = "sword") -> void:
	if record.dead: return
	record.hp = maxi(0, record.hp - damage)
	hit_flash = 0.15
	if method == "fire":
		record.integrity = maxi(0, record.integrity - 35)
		stun = 0.2
	elif method == "seal":
		record.suppressed = true
		stun = 3
		windup = 0
	else:
		stun = maxf(stun, 0.18)
		knockback = game.player.position.direction_to(position) * 75
	if record.hp == 0:
		game.state.kill_enemy(record.id, position)
		game.world.effect(position, Color("97b5a1"))
		game.spawn_remains_visuals()
		game.notify_action("鬼物倒下，遗骸留在原地。靠近按 E，亲自处理。")
		queue_free()

func _draw() -> void:
	if record.is_empty(): return
	var row: int = {"water": 0, "bone": 1, "boss": 2}.get(record.kind, 0)
	var scale_value: float = 3 if row == 2 else 2
	var tint := Color("eab498") if hit_flash > 0 else (Color("8eafd0") if stun > 0.3 else Color.WHITE)
	draw_texture_rect_region(TEXTURE, Rect2(-8 * scale_value, -22 * scale_value, 16 * scale_value, 24 * scale_value), Rect2(0, row * 24, 16, 24), tint)
	draw_rect(Rect2(-16, -50 * (1.4 if row == 2 else 1), 32, 3), Color("413e3e"))
	draw_rect(Rect2(-16, -50 * (1.4 if row == 2 else 1), 32 * float(record.hp) / record.max_hp, 3), Color("aa7164"))
	if windup > 0:
		var local_center: Vector2 = attack_center - position
		draw_circle(local_center, 57 if row == 2 else 29, Color(0.7, 0.27, 0.20, 0.2))
		draw_arc(local_center, 57 if row == 2 else 29, 0, TAU, 24, Color("bb7761"), 2)
