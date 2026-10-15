class_name FarmPlayer
extends CharacterBody2D
# Adapted from gadget-hq/2d-farming-game player_controller.gd (MIT).
# Copyright 2025 Tall Tales Games. See res://licenses/Farmworld-MIT.txt.

const SPEED: float = 92.0
var facing := Vector2.DOWN
var aim_direction := Vector2.RIGHT
var held_item: String = "tool0"
var snare_time: float = 0
var scorch_time: float = 0
var poison_time: float = 0
var status_tick: float = 0
var wind_impulse := Vector2.ZERO
var recoil_time: float = 0
var animation_time: float = 0.0
var frozen: bool = false
var burden: bool = false
var invincible: float = 0
var dodge_time: float = 0
var dodge_cooldown: float = 0
var dodge_direction := Vector2.DOWN
var attack_time: float = 0
var hit_feedback: float = 0
var ghosts: Array = []

var state_machine: YinPlayerStateMachine
var hitbox: YinHitbox
var health_receiver: YinHealthReceiver

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/hit_flash.gdshader")
	state_machine = YinPlayerStateMachine.new()
	state_machine.name = "ActionStateMachine"
	state_machine.bind(self)
	add_child(state_machine)
	hitbox = YinHitbox.new()
	hitbox.name = "Hitbox"
	hitbox.actor = self
	add_child(hitbox)
	health_receiver = YinHealthReceiver.new()
	health_receiver.name = "HealthReceiver"
	add_child(health_receiver)

func _physics_process(delta: float) -> void:
	if frozen:
		state_machine.update(0, Vector2.ZERO, true)
		velocity = Vector2.ZERO
		return
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector2 = state_machine.update(delta, input_direction, false)
	snare_time = maxf(0, snare_time - delta)
	scorch_time = maxf(0, scorch_time - delta)
	poison_time = maxf(0, poison_time - delta)
	status_tick -= delta
	if status_tick <= 0 and (scorch_time > 0 or poison_time > 0):
		status_tick = 1
		var game := get_tree().get_first_node_in_group("yintian_game")
		if game != null:
			game.take_damage(2 if poison_time > 0 else 3)
			if game.player != self: return
	recoil_time = maxf(0, recoil_time - delta)
	hit_feedback = maxf(0, hit_feedback - delta)
	for ghost in ghosts: ghost.age += delta
	ghosts = ghosts.filter(func(g): return g.age < 0.18)
	if dodge_time > 0: ghosts.append({"at": position, "age": 0.0})
	invincible = maxf(0, invincible - delta)
	dodge_cooldown = maxf(0, dodge_cooldown - delta)
	attack_time = maxf(0, attack_time - delta)
	dodge_time = maxf(0, dodge_time - delta)
	velocity = direction * SPEED * (0.62 if burden else 1.0)
	if snare_time > 0: velocity *= 0.45
	velocity += wind_impulse
	wind_impulse = wind_impulse.move_toward(Vector2.ZERO, delta * 180)
	if dodge_time > 0 and not frozen:
		velocity = dodge_direction * 250
	if direction != Vector2.ZERO:
		facing = Vector2(signf(direction.x), 0) if absf(direction.x) > absf(direction.y) else Vector2(0, signf(direction.y))
		animation_time += delta
	else:
		animation_time = 0
	collision_mask = 1 if dodge_time > 0 else 5
	collision_layer = 0 if dodge_time > 0 else 2
	get_node("Camera2D").offset = Vector2(2 if int(hit_feedback * 40) % 2 == 0 else -2, 0) if hit_feedback > 0 else Vector2.ZERO
	move_and_slide()
	position = position.round() if direction == Vector2.ZERO else position
	queue_redraw()

func _draw() -> void:
	var column: int = YinActorArt.hero_column(animation_time, velocity.length() > 2, attack_time, hit_feedback)
	var pose: Dictionary = YinActorArt.hero_pose(facing, column)
	for ghost in ghosts:
		YinActorArt.draw_pose(self, YinActorArt.hero_pose(facing, 1), Color(0.55, 0.85, 0.79, (1 - ghost.age / 0.18) * 0.3), ghost.at - position)
	draw_rect(Rect2(-10, -3, 20, 5), Color(0.18, 0.25, 0.20, 0.22))
	var tint := Color("ef9a82") if hit_feedback > 0 else (Color(1, 1, 1, 0.55 if int(invincible * 20) % 2 == 0 else 1.0) if invincible > 0 else Color.WHITE)
	var lean: float = dodge_direction.x * 0.12 if dodge_time > 0 else 0.0
	draw_set_transform(Vector2.ZERO, lean)
	YinActorArt.draw_pose(self, pose, tint)
	draw_set_transform(Vector2.ZERO)
	draw_held_item()
	if attack_time > 0 and held_item in YinBalance.MELEE:
		var sweep: float = 1 - attack_time / 0.22
		draw_arc(Vector2.ZERO, hitbox.radius, facing.angle() - 0.85, facing.angle() + 0.85, 12, Color("dcd7b0") if held_item != "whip" else Color("b99470"), 2)
		var tip := Vector2.from_angle(facing.angle() - 0.85 + sweep * 1.7) * (hitbox.radius - 2)
		draw_line(Vector2.ZERO, tip, Color("9f7452"), 3)
		draw_line(tip * 0.7, tip, Color("f0ddb0"), 3)
	if burden:
		draw_rect(Rect2(-37, -8, 18, 12), Color("6e5848"))
		draw_rect(Rect2(-34, -5, 12, 6), Color("a99a78"))

func dodge() -> void:
	if dodge_cooldown > 0 or frozen: return
	if not state_machine.begin("dodge", 0.18): return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	dodge_direction = movement.normalized() if movement != Vector2.ZERO else facing
	dodge_time = 0.18
	invincible = 0.35
	dodge_cooldown = 1.2

func draw_held_item() -> void:
	var direction: Vector2 = aim_direction if held_item in YinBalance.GUNS or held_item in YinBalance.MAGIC else facing
	var hand := direction * 8 + Vector2(0, -22)
	if attack_time > 0: hand += direction * (4 if attack_time < 0.11 else -3)
	if held_item.begins_with("tool"):
		var index: int = int(held_item.substr(4))
		var swing: float = sin((0.2 - attack_time) * 18) * 0.4 if attack_time > 0 else 0.0
		draw_set_transform(hand, direction.angle() + swing, Vector2.ONE)
		draw_texture_rect_region(preload("res://assets/tools.png"), Rect2(-6, -6, 16, 16), Rect2(index * 16, 0, 16, 16))
	else:
		var index: int = YinBalance.ICON_ORDER.find(held_item)
		if index < 0: return
		var recoil: float = recoil_time / 0.09 * 3
		draw_set_transform(hand - direction * recoil, direction.angle(), Vector2.ONE)
		draw_texture_rect(YinBalance.icon(held_item), Rect2(-6, -7, 24, 16), false)
		if recoil_time > 0:
			draw_rect(Rect2(18, -3, 5, 4), Color("f7df9c"))
			draw_rect(Rect2(21, -5, 3, 8), Color("db9c63"))
	draw_set_transform(Vector2.ZERO)
