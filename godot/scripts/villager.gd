class_name YinVillager
extends CharacterBody2D
var game: Node2D
var record: Dictionary
var time: float = 0
var invincible: float = 0
var home: Vector2
var walking: bool = false
var walk_clock: float = 0
var brain_state: String = "work"
var attack_cooldown: float=0
var attack_flash: float=0
var combat_target: YinEnemy
var attack_count: int=0
var weather_route: PackedVector2Array=[]
var shelter_target:=Vector2(INF,INF)
var shelter_clock: float=0
var combat_route: PackedVector2Array=[]
var combat_repath: float=0
var route_target: int=0
func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/hit_flash.gdshader")
	home = position
	collision_layer = 0
	collision_mask = 1
	var body:=CollisionShape2D.new();var box:=RectangleShape2D.new();box.size=Vector2(14,10);body.shape=box;body.position=Vector2(0,-4);add_child(body)
	var hurtbox := YinAllyHurtbox.new()
	hurtbox.actor = self
	add_child(hurtbox)
	add_to_group("villagers")
func _physics_process(delta: float) -> void:
	if game.modal != null: return
	time += delta
	invincible = maxf(0, invincible - delta)
	material.set_shader_parameter("motion_clock",time)
	attack_cooldown=maxf(0,attack_cooldown-delta);attack_flash=maxf(0,attack_flash-delta)
	combat_repath=maxf(0,combat_repath-delta)
	if game.state.continent_ready and defend(delta):
		queue_redraw()
		return
	if game.state.continent_ready and weather_shelter(delta):
		queue_redraw()
		return
	brain_state = "wounded" if record.hp <= 0 else ("shelter" if game.state.raid_status == "active" or record.hp < 30 else ("rest" if game.state.minutes >= 1200 else "work"))
	var drift: float = 4 if brain_state in ["shelter", "rest","weather_shelter"] else 12
	var target: Vector2 = home + Vector2(roundf(sin(time / 3 + int(record.id))) * drift, roundf(cos(time / 4)) * drift)
	var previous: Vector2 = position
	position = position.move_toward(target, delta * 12) if record.hp > 0 else position
	walking = position.distance_to(previous) > 0.01
	if walking: walk_clock += delta
	material.set_shader_parameter("motion_clock", time)
	material.set_shader_parameter("motion_amount", 0.6 if walking else 0.12)
	queue_redraw()
func weather_shelter(delta: float) -> bool:
	var climate=game.world.environment.regional
	var local_event="clear"
	if climate!=null:
		var forced=climate.forced_event if game.world.screen_bounds().grow(80).has_point(position) else ""
		local_event=YinRegionalClimate.forecast(position,game.state.day,game.state.minutes,game.state.weather,forced)
	if record.hp<=0 or climate==null or local_event not in ["rain","snow","sandstorm"]:
		shelter_target=Vector2(INF,INF);shelter_clock=0;return false
	brain_state="weather_shelter";shelter_clock-=delta
	if shelter_clock<=0:
		shelter_clock=3;var best=700.0
		for body in game.world.actors.get_children():
			if not body is StaticBody2D:continue
			var sprite=body.get_node_or_null("ArtSprite")
			if sprite==null:continue
			if body.get_meta("biome_prop","") not in ["edo_shop","edo_house","mountain_hut"] and sprite.texture not in [YinArt.texture("cottage"),YinArt.texture("store")]:continue
			var at: Vector2=body.position+Vector2(0,20)
			var distance=position.distance_to(at)
			if distance<best and game.world.is_safe_position(at):best=distance;shelter_target=at
		if is_finite(shelter_target.x):weather_route=game.world.path_to(position,shelter_target,Vector2(7,5))
	if not is_finite(shelter_target.x):return false
	walking=position.distance_to(shelter_target)>8
	if walking:
		while not weather_route.is_empty() and position.distance_to(weather_route[0])<8:weather_route.remove_at(0)
		var next: Vector2=weather_route[0] if not weather_route.is_empty() else shelter_target
		velocity=position.direction_to(next)*22;move_and_slide();walk_clock+=delta
	else:velocity=Vector2.ZERO
	record.at=[position.x,position.y]
	return true
func defend(delta: float) -> bool:
	if record.hp<=0:return false
	combat_target=null
	var best: float=300
	for foe in get_tree().get_nodes_in_group("enemies"):
		if foe.is_queued_for_deletion() or foe.record.dead or YinFactions.friendly(game.state,foe.record):continue
		if foe.position.distance_to(home)>360:continue
		var d: float=position.distance_to(foe.position)
		if d<best:best=d;combat_target=foe
	if combat_target==null:return false
	brain_state="defend";walking=false
	var ranged: bool=int(record.id)%2==0
	var reach: float=144 if ranged else 42
	if best>reach:
		var next: Vector2=combat_target.position
		if not game.world.clear_body_path(position,combat_target.position,Vector2(7,5)):
			if combat_repath<=0 or route_target!=combat_target.get_instance_id():
				combat_route=game.world.path_to(position,combat_target.position);combat_repath=0.6;route_target=combat_target.get_instance_id()
			while not combat_route.is_empty() and position.distance_to(combat_route[0])<10:combat_route.remove_at(0)
			if not combat_route.is_empty():next=combat_route[0]
		velocity=position.direction_to(next)*40;move_and_slide();walking=true;walk_clock+=delta
	elif attack_cooldown<=0:
		var ray=PhysicsRayQueryParameters2D.create(position+Vector2(0,-10),combat_target.position+Vector2(0,-10),1)
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			attack_cooldown=1.35 if ranged else 0.9;attack_flash=0.22;attack_count+=1
			if ranged:game.world.spell_trace(position+Vector2(0,-24),combat_target.position+Vector2(0,-20),"lightning")
			combat_target.receive_faction_hit(12 if ranged else 16)
			game.world.impact(combat_target.position+Vector2(0,-20),position.direction_to(combat_target.position),"sword")
	record.at=[position.x,position.y]
	return true
func receive_hit(damage: int) -> void:
	if record.hp <= 0 or invincible > 0: return
	record.hp = maxi(0, record.hp - damage)
	invincible = 0.6
	game.world.damage_number(position, damage, Color("d18c82"))
	if record.hp == 0: game.notify_action(record.name + "受伤倒下，需要保护其他村民。")
func _draw() -> void:
	var available: bool=false
	var ready_to_claim: bool=false
	for id in YinAdventure.QUESTS:
		if YinAdventure.QUESTS[id].npc!=int(record.id) or not YinAdventure.available(game.state,id):continue
		if not game.state.quests.has(id):available=true
		elif not game.state.quests[id].claimed and YinAdventure.progress(game.state,id)>=YinAdventure.QUESTS[id].target:ready_to_claim=true
	if record.hp>0:
		if ready_to_claim:draw_string(ThemeDB.fallback_font,Vector2(-3,-75),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f1cf83"))
		elif available:draw_texture_rect(preload("res://assets/third_party/kenney/interaction.png"),Rect2(-7,-85,14,14),false,Color("e3ce9f"))
	YinActorArt.contact_shadow(self,9)
	var pose: Dictionary = YinActorArt.npc_pose(int(record.id), walk_clock, walking, game.player.position.distance_to(position) < 50 and not walking)
	YinActorArt.draw_pose(self, pose, Color("98aaa0") if record.hp == 0 else Color.WHITE)
	if attack_flash>0:
		var direction: Vector2=position.direction_to(combat_target.position) if is_instance_valid(combat_target) else Vector2.RIGHT
		draw_line(Vector2(6,-22),Vector2(6,-22)+direction*29,Color("e6d9a9"),3)
		draw_arc(Vector2(0,-20)+direction*17,18,-PI*0.7,PI*0.3,12,Color("f4ddb4"),2)
	if record.hp < 100:
		draw_rect(Rect2(-18, -60, 36, 3), Color("162d2c"))
		draw_rect(Rect2(-18, -60, 36 * float(record.hp) / 100, 3), Color("a5b780"))
	if position.distance_to(game.player.position) < 125 or record.hp < 100:
		var caption: String = record.name + (" · 养伤" if record.hp == 0 else "")
		draw_string_outline(ThemeDB.fallback_font, Vector2(-25, -64), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, Color("102725"))
		draw_string(ThemeDB.fallback_font, Vector2(-25, -64), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e5d4ab"))
