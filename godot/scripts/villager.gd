class_name YinVillager
extends CharacterBody2D
var game: Node2D
var record: Dictionary
var time: float = 0
var invincible: float = 0
var home: Vector2
var brain_state: String = "work"
func _ready() -> void:
	home = position
	collision_layer = 0
	collision_mask = 1
	var hurtbox := YinAllyHurtbox.new()
	hurtbox.actor = self
	add_child(hurtbox)
	add_to_group("villagers")
func _physics_process(delta: float) -> void:
	if game.modal != null: return
	time += delta
	invincible = maxf(0, invincible - delta)
	brain_state = "wounded" if record.hp <= 0 else ("shelter" if game.state.raid_status == "active" or record.hp < 30 else ("rest" if game.state.minutes >= 1200 else "work"))
	var drift: float = 4 if brain_state in ["shelter", "rest"] else 12
	var target: Vector2 = home + Vector2(roundf(sin(time / 3 + int(record.id))) * drift, roundf(cos(time / 4)) * drift)
	position = position.move_toward(target, delta * 12) if record.hp > 0 else position
	queue_redraw()
func receive_hit(damage: int) -> void:
	if record.hp <= 0 or invincible > 0: return
	record.hp = maxi(0, record.hp - damage)
	invincible = 0.6
	game.world.damage_number(position, damage, Color("d18c82"))
	if record.hp == 0: game.notify_action(record.name + "受伤倒下，需要保护其他村民。")
func _draw() -> void:
	for id in YinAdventure.QUESTS:
		if YinAdventure.QUESTS[id].npc != int(record.id): continue
		var mark: String = "!" if not game.state.quests.has(id) else ("?" if not game.state.quests[id].claimed and YinAdventure.progress(game.state, id) >= YinAdventure.QUESTS[id].target else "")
		if mark != "" and record.hp > 0: draw_string(ThemeDB.fallback_font, Vector2(-3, -65), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f1cf83"))
	draw_texture_rect_region(preload("res://assets/npc.png"), Rect2(-16, -40, 32, 40), Rect2(0, 0, 16, 20), Color("98aaa0") if record.hp == 0 else Color.from_hsv(float(record.id) / 12, 0.15, 1))
	draw_rect(Rect2(-18, -46, 36, 4), Color("31443c"))
	draw_rect(Rect2(-18, -46, 36 * float(record.hp) / 100, 4), Color("9daf75"))
	draw_string(ThemeDB.fallback_font, Vector2(-25, -50), record.name + (" · 养伤" if record.hp == 0 else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("e5d4ab"))
