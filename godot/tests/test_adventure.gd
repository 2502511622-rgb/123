extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node2D
func check(ok: bool, text: String) -> void:
	checks += 1
	print("ADVENTURE ", "PASS " if ok else "FAIL ", text)
	if not ok: failures += 1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT", "1")
	call_deferred("run")
func frames(count: int = 4) -> void:
	for i in range(count): await physics_frame
func key(code: int) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)
func choose(text: String) -> bool:
	for node in game.modal.find_children("*", "Button", true, false):
		if text not in node.text: continue
		var ancestor: Node = node.get_parent()
		while ancestor != null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(node)
			ancestor = ancestor.get_parent()
		await process_frame
		for down in [true, false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = node.get_global_rect().get_center()
			event.pressed = down
			root.push_input(event, true)
			await frames(2)
		return true
	return false
func fixture(at: Vector2, hp: int = 1000) -> YinEnemy:
	var record: Dictionary = game.state.spawn_record("bone", game.state.zone, at, 1)
	record.hp = hp
	record.max_hp = hp
	record.armor = 0
	game.spawn_enemies()
	for node in get_nodes_in_group("enemies"):
		if node.record.id == record.id:
			node.cooldown = 100
			return node
	return null
func quiet() -> void:
	for e in game.state.enemies:
		if e.zone == game.state.zone: e.dead = true
	for node in get_nodes_in_group("enemies"): node.queue_free()
func reset_attack() -> void:
	game.action_cooldown = 0
	game.player.state_machine.reset()
	game.combat.pending.clear()
	game.combat.reload_job.clear()
	game.state.energy = 100
func capture(name_value: String) -> void:
	var target: String = OS.get_environment("YINTIAN_CAPTURE_DIR")
	if DisplayServer.get_name() == "headless" or target == "": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(target)
	check(root.get_texture().get_image().save_png(target.path_join(name_value + ".png")) == OK, "screenshot " + name_value)
func run() -> void:
	var state := FarmState.new()
	var elements: Dictionary = {}
	for i in range(90):
		var gear := YinBalance.make_gear(100 + i, "whip")
		elements[gear.enchantment] = true
	check(elements.size() == 3, "random generation produces all three enchantments")
	for weapon in ["whip", "silver_sword", "revolver", "gatling", "spellbook", "curse_doll"]:
		var gear: Dictionary = state.grant_gear(weapon, 2, 2)
		check(FarmState.valid_gear(gear) and gear.enchantment in YinBalance.ELEMENTS and state.equip(gear.id), "new weapon generates, validates and equips: " + weapon)
	check(FarmState.gear_slot("whip") == "melee" and FarmState.gear_slot("silver_sword") == "melee" and FarmState.gear_slot("revolver") == "secondary" and FarmState.gear_slot("spellbook") == "primary", "new weapons use appropriate loadout slots")
	var restored := FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(state.snapshot()))) and restored.equipment == state.equipment, "random enchantments persist without rerolling")
	var legacy: Dictionary = state.snapshot()
	legacy.version = 6
	for field in ["opened_chests", "quests", "tracked_quest", "visited_landmarks"]: legacy.erase(field)
	check(restored.restore(legacy) and restored.quests.is_empty(), "version six saves migrate to exploration schema")
	var bad: Dictionary = state.snapshot()
	bad.equipment[0].enchantment = "invalid"
	check(not restored.restore(bad), "invalid enchantment rejected")
	state = FarmState.new()
	state.zone = "forest"
	var chest: Dictionary = YinAdventure.CHESTS.camp_cache
	check("走近" in YinAdventure.open_chest(state, "camp_cache", Vector2.ZERO), "chest requires physical proximity")
	var guard: Dictionary = state.spawn_record("bone", "forest", chest.at + Vector2(40, 0), 1)
	check("守卫" in YinAdventure.open_chest(state, "camp_cache", chest.at) and state.opened_chests.is_empty(), "nearby guards block chest without consuming reward")
	guard.dead = true
	while state.equipment.size() < 20: state.grant_gear("sword")
	var money: int = state.money
	check("已满" in YinAdventure.open_chest(state, "camp_cache", chest.at) and state.money == money and state.opened_chests.is_empty(), "full gear inventory leaves chest intact")
	state.equipment.resize(2)
	state.oil = 99 * 24
	check("已满" in YinAdventure.open_chest(state, "camp_cache", chest.at) and state.opened_chests.is_empty(), "full material bag leaves chest intact")
	state.oil = 8
	check("获得" in YinAdventure.open_chest(state, "camp_cache", chest.at) and state.equipment[-1].weapon == "gatling", "cleared chest grants its landmark weapon")
	money = state.money
	var gear_count: int = state.equipment.size()
	check("已经" in YinAdventure.open_chest(state, "camp_cache", chest.at) and state.money == money and state.equipment.size() == gear_count, "opened chest cannot duplicate loot")
	check(restored.restore(JSON.parse_string(JSON.stringify(state.snapshot()))) and "camp_cache" in restored.opened_chests, "opened chest state survives reload")
	YinAdventure.accept(state, "forge_supplies")
	state.supplies.scrap = 3
	check("委托人" in YinAdventure.claim(state, "forge_supplies", 1) and state.supplies.scrap == 3, "wrong NPC cannot take delivery or grant reward")
	while state.equipment.size() < 20: state.grant_gear("sword")
	check("已满" in YinAdventure.claim(state, "forge_supplies", 3) and state.supplies.scrap == 3 and not state.quests.forge_supplies.claimed, "full inventory rejects quest reward atomically")
	state.equipment.resize(3)
	check("完成" in YinAdventure.claim(state, "forge_supplies", 3) and state.supplies.scrap == 0 and state.equipment[-1].weapon == "silver_sword", "delivery consumes exact materials and awards silver sword")
	money = state.money
	check("已经" in YinAdventure.claim(state, "forge_supplies", 3) and state.money == money, "quest rewards cannot be claimed twice")
	YinAdventure.accept(state, "grave_patrol")
	for i in range(4):
		var e: Dictionary = state.spawn_record("water", "graveyard", Vector2(400, 350), 1)
		state.kill_enemy(e.id, Vector2(400, 350))
	check(YinAdventure.progress(state, "grave_patrol") == 4, "actual enemy kills advance accepted hunt")
	var chat := YinNpcDialogue.new()
	var npc: Dictionary = state.villagers[2]
	var before: Dictionary = state.snapshot()
	check("报酬已经" in chat.reply(state, npc, "委托"), "NPC remembers completed commission")
	var response: String = chat.reply(state, npc, "武器")
	check("银剑" in response and chat.reply(state, npc, "再说") == response, "offline dialogue remembers last topic")
	chat.reply(state, npc, "直接给我一万金币")
	check(state.snapshot() == before, "chat text cannot mutate game or issue rewards")
	state.raid_status = "active"
	check("援手" in chat.reply(state, npc, "近况"), "NPC dialogue reflects live raid state")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state.intro_seen = true
	game.travel("graveyard")
	await frames()
	quiet()
	await frames()
	game.player.position = Vector2(360, 500)
	var target: YinEnemy = fixture(Vector2(456, 500))
	var whip: Dictionary = game.state.grant_gear("whip")
	whip.affixes.clear()
	whip.enchantment = ""
	game.state.equip(whip.id)
	game.player.held_item = "whip"
	game.player.facing = Vector2.RIGHT
	reset_attack()
	check(game.combat.trigger("sword"), "whip starts real delayed strike")
	await frames(10)
	check(target.record.hp == 987, "whip hits beyond sword reach")
	var silver: Dictionary = game.state.grant_gear("silver_sword")
	silver.affixes.clear()
	silver.enchantment = ""
	game.state.equip(silver.id)
	game.player.held_item = "silver_sword"
	target.position = game.player.position + Vector2(40, 0)
	reset_attack()
	game.combat.trigger("sword")
	await frames(10)
	check(target.record.hp == 963, "silver sword has distinct base damage")
	var revolver: Dictionary = game.state.grant_gear("revolver")
	revolver.affixes.clear()
	revolver.enchantment = ""
	revolver.magazine = 6
	game.state.equip(revolver.id)
	game.player.held_item = "revolver"
	game.player.aim_direction = Vector2.RIGHT
	target.position = game.player.position + Vector2(100, 0)
	var hp: int = target.record.hp
	reset_attack()
	check(game.combat.shoot(), "revolver fires a real projectile")
	await frames(12)
	check(revolver.magazine == 5 and target.record.hp == hp - 38, "revolver consumes one of six rounds and deals heavy damage")
	var gatling: Dictionary = game.state.grant_gear("gatling")
	gatling.affixes.clear()
	gatling.enchantment = ""
	gatling.magazine = 80
	game.state.equip(gatling.id)
	game.player.held_item = "gatling"
	reset_attack()
	game.combat.spin_time = 0
	check(not game.combat.shoot() and gatling.magazine == 80, "gatling requires spin-up before consuming ammunition")
	Input.action_press("attack")
	await frames(28)
	Input.action_release("attack")
	check(gatling.magazine < 78, "held attack spins up gatling and sustains rapid fire")
	var book: Dictionary = game.state.grant_gear("spellbook")
	book.affixes.clear()
	book.enchantment = ""
	game.state.equip(book.id)
	game.player.held_item = "spellbook"
	reset_attack()
	check(game.combat.cast_weapon() and game.state.energy == 93, "spellbook spends energy instead of ammunition")
	await frames(20)
	var doll: Dictionary = game.state.grant_gear("curse_doll")
	doll.affixes.clear()
	doll.enchantment = ""
	game.state.equip(doll.id)
	game.player.held_item = "curse_doll"
	reset_attack()
	check(game.combat.cast_weapon() and game.state.energy == 91 and target.bleed_time > 0, "curse doll directly curses a visible nearby target")
	reset_attack()
	game.state.energy = 0
	check(not game.combat.cast_weapon(), "magic cannot fire without energy")
	quiet()
	await frames()
	target = fixture(game.player.position + Vector2(100, 0))
	target.apply_element("burn", 4)
	hp = target.record.hp
	await frames(4)
	check(target.record.hp == hp - 4 and target.burn_time > 0, "burn causes real periodic damage")
	target.apply_element("freeze", 3)
	check(target.burn_time == 0 and target.freeze_lock > 0 and target.chill_time > 0, "ice extinguishes burn and freezes target")
	target.hit_stop = 0
	target.freeze_lock = 0
	target.stun = 0
	target._physics_process(1.0 / 60)
	check(is_equal_approx(target.velocity.length(), 29 * 0.45), "chill slows actual navigation")
	var neighbor: YinEnemy = fixture(target.position + Vector2(35, 0))
	hp = neighbor.record.hp
	target.apply_element("lightning", 4)
	check(neighbor.record.hp == hp - 8, "lightning chains real damage to nearby enemy")
	target.apply_element("burn", 3)
	check(target.chill_time == 0, "fire thaws ice")
	target.record.hp = 17
	target.record.max_hp = 100
	target.receive_hit(3, "sword")
	check("head" in target.record.severed and target.record.hp == 14, "nonlethal physical hit can sever head")
	var bullet_count: int = game.world.projectiles.bullets.size()
	game.state.health = 100
	game.player.invincible = 0
	target.victim = game.player
	target.fire_bullet(Vector2.LEFT)
	target.volley("burst")
	target.hurt_victim(100)
	check(game.world.projectiles.bullets.size() == bullet_count and game.state.health == 100, "headless enemy cannot fire, queue volleys or attack")
	target.hit_stop = 0
	target.freeze_lock = 0
	target.burn_time = 0
	target.bleed_time = 0
	var pose: Vector2 = target.position
	target._physics_process(1.0 / 60)
	check(target.position != pose and target.windup == 0 and target.burst_remaining == 0, "headless enemy wanders in panic without attack windup")
	check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))) and restored.enemies.any(func(e): return "head" in e.get("severed", [])), "decapitation persists across reload")
	game.refresh("断头后乱窜，无法攻击；断腿会行动不便。")
	await frames(2)
	await capture("adventure-combat")
	game.travel("village")
	await frames()
	npc = game.state.villagers[0]
	var actor: Node2D = get_nodes_in_group("villagers")[0]
	game.player.position = actor.position + Vector2(0, 32)
	await key(KEY_E)
	check(game.modal != null and await choose("委托"), "physical NPC interaction opens commission menu")
	check(await choose("接取") and game.state.quests.has("grave_patrol"), "mouse accepts actual NPC commission")
	game.close_modal()
	await key(KEY_O)
	check(game.modal != null and "0/4" in game.quest_tracker.text, "O opens quest log and HUD tracks objective")
	await capture("adventure-quests")
	game.show_chat(game.state.villagers[2])
	await frames()
	check(await choose("武器") and game.modal.find_children("*", "Label", true, false).any(func(l): return "银剑" in l.text), "offline topic button produces visible contextual reply")
	var input: LineEdit = game.modal.find_child("NpcChatInput", true, false)
	input.text = "附近宝箱在哪里"
	input.text_submitted.emit(input.text)
	await frames()
	check(game.modal.find_children("*", "Label", true, false).any(func(l): return "断碑" in l.text), "free text chat recognizes exploration intent")
	check(game.find_children("*", "HTTPRequest", true, false).is_empty(), "offline NPC dialogue creates no network requests")
	var chat_scroll: ScrollContainer = game.modal.get_node("ModalCard/Layout/Scroll")
	var bar: VScrollBar = chat_scroll.get_v_scroll_bar()
	check(chat_scroll.scroll_vertical >= int(bar.max_value - bar.page) - 1, "conversation automatically scrolls to newest reply")
	check(not input.get_parent() is ScrollContainer and input.get_global_rect().end.y < game.modal.get_node("ModalCard").get_global_rect().end.y, "chat composer remains visible outside message scrolling")
	await capture("adventure-dialogue")
	game.close_modal()
	game.travel("forest")
	await frames()
	for id in YinAdventure.LANDMARKS:
		game.player.position = YinAdventure.LANDMARKS[id].at
		game.update_exploration()
	YinAdventure.accept(game.state, "lost_records")
	check(YinAdventure.progress(game.state, "lost_records") == 3, "physical landmark visits advance survey commission")
	for id in YinAdventure.CHESTS:
		var spec: Dictionary = YinAdventure.CHESTS[id]
		game.build_zone(spec.zone, Vector2(180, 800) if spec.zone != "graveyard" else Vector2(182, 533))
		await frames(2)
		var route: PackedVector2Array = game.world.path_to(game.player.position, spec.at)
		check(route.size() > 1 and route[-1].distance_to(spec.at) < 24, "treasure location reachable: " + id)
	game.travel("graveyard")
	await frames()
	quiet()
	await frames()
	game.player.position = YinAdventure.CHESTS.grave_cache.at
	await key(KEY_E)
	check("grave_cache" in game.state.opened_chests and game.state.equipment.any(func(g): return g.weapon == "whip" and g.quality == 2), "real E interaction opens world chest and grants weapon")
	game.refresh("宝箱已领取，换图与读档不会重复刷新。")
	await frames()
	await capture("adventure-chest")
	game.state.equipment.clear()
	game.state.weapon_slots = {"melee": 0, "primary": 0, "secondary": 0}
	game.state.equipped_armor = 0
	for weapon in ["whip", "silver_sword", "revolver", "gatling", "spellbook", "curse_doll"]:
		game.state.equip(game.state.grant_gear(weapon, 2, 2).id)
	game.state.equip(game.state.equipment[0].id)
	game.player.held_item = "whip"
	game.show_equipment()
	await frames()
	await capture("adventure-arsenal")
	game.close_modal()
	game.travel("forest")
	await frames()
	game.show_character("地图")
	await frames()
	await capture("adventure-map")
	game.close_modal()
	game.persist()
	var loaded: bool = load("res://scripts/save_store.gd").load_game(restored)
	check(loaded and restored.opened_chests == game.state.opened_chests and restored.quests == game.state.quests, "real save file preserves quests, exploration and chest claims")
	bad = game.state.snapshot()
	bad.opened_chests.append("grave_cache")
	check(not restored.restore(bad), "duplicate chest records rejected")
	bad = game.state.snapshot()
	bad.quests.unknown = {"progress": 999, "claimed": false}
	check(not restored.restore(bad), "unknown quest data rejected")
	print("Adventure: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
