class_name FarmPlayer
extends CharacterBody2D
# Adapted from gadget-hq/2d-farming-game player_controller.gd (MIT).
# Copyright 2025 Tall Tales Games. See res://licenses/Farmworld-MIT.txt.

const SPEED: float = 92.0
var facing := Vector2.DOWN
var animation_time: float = 0.0
var frozen: bool = false
var burden: bool = false
var invincible: float = 0
var dodge_time: float = 0
var dodge_cooldown: float = 0
var dodge_direction := Vector2.DOWN
var attack_time: float = 0
var texture: Texture2D = preload("res://assets/farmer.png")

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(14, 10)
	shape.shape = box
	shape.position = Vector2(0, -4)
	add_child(shape)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2.ZERO
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 960
	camera.limit_bottom = 640
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8
	add_child(camera)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO if frozen else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	invincible = maxf(0, invincible - delta)
	dodge_cooldown = maxf(0, dodge_cooldown - delta)
	attack_time = maxf(0, attack_time - delta)
	dodge_time = maxf(0, dodge_time - delta)
	velocity = direction * SPEED * (0.62 if burden else 1.0)
	if dodge_time > 0 and not frozen:
		velocity = dodge_direction * 250
	if direction != Vector2.ZERO:
		facing = Vector2(signf(direction.x), 0) if absf(direction.x) > absf(direction.y) else Vector2(0, signf(direction.y))
		animation_time += delta
	else:
		animation_time = 0
	move_and_slide()
	position = position.round() if direction == Vector2.ZERO else position
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-10, -3, 20, 5), Color(0.18, 0.25, 0.20, 0.22))
	var row: int = 0
	if facing == Vector2.UP:
		row = 1
	elif facing == Vector2.LEFT:
		row = 2
	elif facing == Vector2.RIGHT:
		row = 3
	var frame: int = int(animation_time * 9) % 4
	draw_texture_rect_region(texture, Rect2(-16, -40, 32, 40), Rect2(frame * 16, row * 20, 16, 20), Color(1, 1, 1, 0.55) if invincible > 0 else Color.WHITE)
	if attack_time > 0:
		draw_arc(Vector2.ZERO, 32, facing.angle() - 0.7, facing.angle() + 0.7, 10, Color("c8c89a"), 3)
	if burden:
		draw_rect(Rect2(-37, -8, 18, 12), Color("6e5848"))
		draw_rect(Rect2(-34, -5, 12, 6), Color("a99a78"))

func dodge() -> void:
	if dodge_cooldown > 0 or frozen: return
	dodge_direction = facing
	dodge_time = 0.18
	invincible = 0.35
	dodge_cooldown = 1.2
