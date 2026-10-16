class_name FarmPlayer
extends CharacterBody2D
# Adapted from gadget-hq/2d-farming-game player_controller.gd (MIT).
# Copyright 2025 Tall Tales Games. See res://licenses/Farmworld-MIT.txt.

const SPEED: float = 112.0
var appearance: Dictionary = YinAppearance.initial()
var facing := Vector2.DOWN
var visual_facing:=Vector2.DOWN
var turn_target:=Vector2.DOWN
var turn_time: float=0
var turn_scale_x: float=1
var aim_direction := Vector2.RIGHT
var held_item: String = "tool0"
var road_check: float=0
var road_boost: float=1
var art_hand := Vector2(10,-23)
var snare_time: float = 0
var scorch_time: float = 0
var poison_time: float = 0
var status_tick: float = 0
var wind_impulse := Vector2.ZERO
var recoil_time: float = 0
var animation_time: float = 0.0
var visual_clock: float = 0
var hit_pause: float = 0
var swing_direction := Vector2.DOWN
var swing_sign: float = 1
var heavy_attack: bool = false
var attack_lunge := Vector2.ZERO
var impact_shake: float = 0
var gait_blend: float = 0
var body_offset := Vector2.ZERO
var weapon_angle: float = 0
var body_lean: float = 0
var attack_duration: float = 0.22
var last_attack_time: float = 0
var frozen: bool = false
var burden: bool = false
var invincible: float = 0
var dodge_time: float = 0
var dodge_cooldown: float = 0
var dodge_direction := Vector2.DOWN
var attack_time: float = 0
var hit_feedback: float = 0
var ghosts: Array = []

var weapon_layer: YinHeldWeapon
var state_machine: YinPlayerStateMachine
var hitbox: YinHitbox
var health_receiver: YinHealthReceiver

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/hit_flash.gdshader")
	YinAppearance.configure(material,appearance)
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
	weapon_layer=YinHeldWeapon.new()
	weapon_layer.name="HeldWeapon"
	weapon_layer.actor=self
	add_child(weapon_layer)

func _physics_process(delta: float) -> void:
	if frozen:
		state_machine.update(0, Vector2.ZERO, true)
		velocity = Vector2.ZERO
		return
	if hit_pause > 0:
		hit_pause = maxf(0, hit_pause-delta)
		velocity = Vector2.ZERO
		queue_redraw()
		return
	visual_clock += delta
	impact_shake = maxf(0,impact_shake-delta)
	if attack_time > last_attack_time + 0.005: attack_duration = maxf(0.16, attack_time)
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
	last_attack_time = attack_time
	dodge_time = maxf(0, dodge_time - delta)
	road_check-=delta
	if road_check<=0:
		road_check=.2;road_boost=YinExploration28.road_speed(get_tree().get_first_node_in_group("yintian_game"))
	var travel_speed: float=road_boost if attack_time<=0 and dodge_time<=0 else 1.0
	velocity = velocity.move_toward(direction * SPEED * travel_speed, delta * (1600.0 if direction == Vector2.ZERO else 1900.0))
	if snare_time > 0: velocity *= 0.45
	velocity += wind_impulse
	wind_impulse = wind_impulse.move_toward(Vector2.ZERO, delta * 180)
	if dodge_time > 0 and not frozen:
		velocity = dodge_direction * 250
	if attack_time>0:
		var progress: float=YinActionMotion.phase(attack_time,attack_duration)
		if progress>0.36 and progress<0.61:velocity+=swing_direction*(36.0 if heavy_attack else 14.0)
	if direction != Vector2.ZERO and attack_time <= 0:
		facing = Vector2(signf(direction.x), 0) if absf(direction.x) > absf(direction.y) else Vector2(0, signf(direction.y))
	if facing!=turn_target:
		turn_target=facing;turn_time=.10
	if attack_time>0 or dodge_time>0:
		visual_facing=facing;turn_time=0
	elif turn_time>0:
		turn_time=maxf(0,turn_time-delta)
		if turn_time<=.05:visual_facing=turn_target
	else:visual_facing=facing
	turn_scale_x=1.0-.13*sin(PI*(1-turn_time/.10)) if turn_time>0 else 1.0
	collision_mask = 1 if dodge_time > 0 else 5
	collision_layer = 0 if dodge_time > 0 else 2
	get_node("Camera2D").offset = Vector2(2 if int(hit_feedback * 40) % 2 == 0 else -2, 0) if hit_feedback > 0 else Vector2.ZERO
	if impact_shake>0:get_node("Camera2D").offset+=Vector2(sin(visual_clock*115),cos(visual_clock*91))*minf(3,impact_shake*24)
	material.set_shader_parameter("motion_clock", visual_clock)
	material.set_shader_parameter("motion_amount", 0.9 if direction.length() > 0 else 0.15)
	var previous_position: Vector2 = position
	move_and_slide()
	if direction.length()>0 and dodge_time<=0:
		var query=PhysicsShapeQueryParameters2D.new();var circle=CircleShape2D.new();circle.radius=13
		query.shape=circle;query.transform=Transform2D(0,global_position);query.collision_mask=8
		for result in get_world_2d().direct_space_state.intersect_shape(query,4):
			if result.collider is YinCorpse:result.collider.push_and_step(direction,delta)
	# Gait advances with distance travelled: walls and slow spells cannot skate.
	var travelled: float=position.distance_to(previous_position)
	animation_time += travelled / SPEED
	gait_blend=move_toward(gait_blend,minf(1,travelled/maxf(delta*SPEED,0.01)),delta*12)
	if velocity.length() < 2: animation_time = 0
	queue_redraw()
	weapon_layer.show_behind_parent=visual_facing.y< -0.5
	weapon_layer.material.set_shader_parameter("wetness",material.get_shader_parameter("wetness"))
	weapon_layer.queue_redraw()

func _draw() -> void:
	var pose: Dictionary = YinActorArt.hero_motion_pose(visual_facing, animation_time, velocity.length() > 2, attack_time, hit_feedback, attack_duration,int(appearance.body))
	var gait: float=animation_time*16.0*TAU/8.0
	body_offset=Vector2(sin(gait)*0.5,-absf(sin(gait))*1.1)*gait_blend
	if attack_time>0:body_offset=YinActionMotion.body_offset(swing_direction,YinActionMotion.phase(attack_time,attack_duration),heavy_attack)
	if attack_time<=0:
		pose.gait_phase=gait
		pose.gait_strength=0.0 # Authored walk frames now supply the leg motion.
	YinAppearance.pose_uniforms(material,pose)
	var direction_row: int=YinActorArt.direction_row(visual_facing)
	art_hand=[Vector2(8,-24),Vector2(9,-23),Vector2(-11,-23),Vector2(11,-23)][direction_row]
	if attack_time>0:
		var column: int=clampi(int((1.0-attack_time/maxf(attack_duration,0.01))*6),0,5)
		var hand_x: Array=[[7,-5,4,17,15,7],[8,3,8,20,17,8],[-10,-11,-13,-21,-19,-10],[10,11,13,21,19,10]][direction_row]
		var hand_y: Array=[-24,-27,-26,-25,-24,-23]
		art_hand=Vector2(hand_x[column],hand_y[column])
	if int(appearance.body)==1:art_hand.y+=1.5
	if pose.has("hand"):art_hand=pose.hand
	art_hand+=body_offset
	art_hand.x*=turn_scale_x
	if attack_time<=0:art_hand+=Vector2(sin(gait)*0.8,sin(gait)*0.6)*gait_blend
	for ghost in ghosts:
		YinActorArt.draw_pose(self, YinActorArt.hero_motion_pose(visual_facing, animation_time, true, 0, 0,0.22,int(appearance.body)), Color(0.55, 0.85, 0.79, (1 - ghost.age / 0.18) * 0.3), ghost.at - position)
	YinActorArt.contact_shadow(self,10,animation_time*16.0*TAU/8.0,velocity.length()/SPEED)
	var tint := Color("ef9a82") if hit_feedback > 0 else (Color(1, 1, 1, 0.55 if int(invincible * 20) % 2 == 0 else 1.0) if invincible > 0 else Color.WHITE)
	var lean: float = dodge_direction.x * 0.12 if dodge_time > 0 else velocity.x/SPEED*0.025
	if attack_time>0:lean=swing_direction.x*YinActionMotion.force(YinActionMotion.phase(attack_time,attack_duration))*(0.13 if heavy_attack else 0.07)
	body_lean=lean
	draw_set_transform(Vector2.ZERO, lean,Vector2(turn_scale_x,1))
	YinActorArt.draw_pose(self, pose, tint,body_offset)
	draw_set_transform(Vector2.ZERO)

func dodge() -> void:
	if dodge_cooldown > 0 or frozen: return
	if not state_machine.begin("dodge", 0.18): return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	dodge_direction = movement.normalized() if movement != Vector2.ZERO else facing
	attack_time = 0
	hit_pause = 0
	dodge_time = 0.18
	invincible = 0.35
	dodge_cooldown = 0.65

func draw_held_item(canvas: CanvasItem = null) -> void:
	if canvas==null:canvas=self
	var direction: Vector2 = aim_direction if held_item in YinBalance.GUNS or held_item in YinBalance.MAGIC else facing
	var hand: Vector2 = direction*8+Vector2(0,-23) if held_item in YinBalance.GUNS or held_item in YinBalance.MAGIC else art_hand
	if held_item in YinBalance.GUNS or held_item in YinBalance.MAGIC:hand+=body_offset
	hand=hand.rotated(body_lean)
	if held_item.begins_with("tool"):
		var index: int = int(held_item.substr(4))
		var swing: float = sin((0.2 - attack_time) * 18) * 0.4 if attack_time > 0 else 0.0
		canvas.draw_set_transform(hand, direction.angle() + swing, Vector2.ONE)
		canvas.draw_texture_rect_region(preload("res://assets/tools.png"), Rect2(-6, -6, 16, 16), Rect2(index * 16, 0, 16, 16))
	elif held_item in YinBalance.MELEE:
		var progress: float = clampf(1.0-attack_time/maxf(attack_duration,0.01),0,1)
		var active: float = smoothstep(0.36,0.61,progress)
		var angle_value: float = swing_direction.angle() + swing_sign*YinActionMotion.swing(progress) if attack_time>0 else direction.angle()+0.8
		var reach: float = maxf(31.0,hitbox.radius-8.0)
		var glow: Color = Color("ead9ad") if held_item!="ipetam" else Color("c98078")
		if held_item=="prajna": glow=Color("a5d8db")
		if attack_time>0 and progress>0.36 and progress<0.76:
			for trail in range(5):
				var lag: float=float(trail)*0.1*swing_sign
				canvas.draw_arc(hand,reach,angle_value-lag-swing_sign*0.28,angle_value-lag+0.01,12,Color(glow,0.23-float(trail)*0.035),2.0)
		weapon_angle=angle_value
		canvas.draw_set_transform(hand,angle_value)
		if held_item=="whip":
			# Grip stays attached; articulated lash follows the same swing clock.
			YinWeaponArt.draw(canvas,held_item,25)
			if attack_time>0:
				var points:=PackedVector2Array()
				for i in range(18):
					var fraction: float=float(i)/17.0
					points.append(Vector2(fraction*reach,sin(fraction*5.0-progress*7.0)*5.0*fraction*(1-active)))
				canvas.draw_polyline(points,Color("b69a72"),1.5)
		else:YinWeaponArt.draw(canvas,held_item,reach+8)
		# The painted sleeve and exposed hand follow the grip and the torso drive.
		canvas.draw_set_transform(Vector2.ZERO)
		canvas.draw_circle(hand,1.4,YinAppearance.COLORS.skin[int(appearance.skin)])

	else:
		var recoil: float = recoil_time / 0.09 * 3
		canvas.draw_set_transform(hand - direction * recoil, direction.angle())
		if held_item in YinBalance.GUNS:
			var barrel: float=40.0 if held_item in ["rifle","gatling"] else 27.0
			YinWeaponArt.draw(canvas,held_item,barrel+9)
			if recoil_time>0:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(barrel,-5),Vector2(barrel+9,0),Vector2(barrel,5)]),Color("f6d49a"))
		else:
			YinWeaponArt.draw(canvas,held_item,22)
			if attack_time>0:canvas.draw_arc(Vector2(7,0),14,visual_clock*5,visual_clock*5+4.0,20,Color("a8d5da"),2)

	canvas.draw_set_transform(Vector2.ZERO)
