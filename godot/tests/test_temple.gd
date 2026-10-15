extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node2D
func check(ok: bool, text: String) -> void:
	checks += 1
	print("TEMPLE ", "PASS " if ok else "FAIL ", text)
	if not ok: failures += 1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT", "1")
	call_deferred("run")
func frames(n: int = 4) -> void:
	for i in range(n): await physics_frame
func key(code: int) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event, true)
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
func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("YINTIAN_CAPTURE_DIR") == "": return
	game.player.get_node("Camera2D").reset_smoothing()
	game.player.get_node("Camera2D").force_update_scroll()
	await RenderingServer.frame_post_draw
	var folder: String = OS.get_environment("YINTIAN_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name_value + ".png")) == OK, "capture " + name_value)
func actor(kind: String, at: Vector2 = Vector2(688, 928)) -> YinEnemy:
	var result: YinEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
	result.record = game.state.spawn_record(kind, game.state.zone, at, 1)
	result.record.home_at = [at.x, at.y]
	result.game = game
	result.position = at
	result.add_to_group("enemies")
	game.world.actors.add_child(result)
	result.set_physics_process(false)
	result.victim = game.player
	return result
func run() -> void:
	var s := FarmState.new()
	check(YinTemple.validate(s.temple_journal) and YinFactions.IDS.size() == 4, "temple journal and fourth faction initialize")
	check(YinBalance.MONSTERS.size() == 23 and YinTemple.BOSSES.all(func(k): return k in YinAbilities.BOSSES), "six new enemies include two registered bosses")
	s.prepare_enemies()
	check(s.enemies.filter(func(e): return e.zone == "temple" and e.kind in YinTemple.MINIONS).size() == 16, "temple has sixteen native enemies")
	var first_ids: Array = s.enemies.filter(func(e): return e.zone == "temple").map(func(e): return e.id)
	s.prepare_enemies()
	check(s.enemies.filter(func(e): return e.zone == "temple").map(func(e): return e.id) == first_ids, "same-day preparation does not duplicate temple encounters")
	var locked: Dictionary = s.enemies.filter(func(e): return e.kind == "yaksha")[0]
	s.kill_enemy(locked.id, Vector2.ZERO)
	check(not locked.dead and not YinTemple.available(s, "yaksha"), "night guardian cannot be killed before asura")
	check("前置" in YinAdventure.accept(s, "temple_wisdom"), "artifact quest is gated by complete chain")
	for id in ["temple_arrival", "temple_catalog", "temple_wrath", "temple_guardian", "temple_wisdom"]:
		check("接取" in YinAdventure.accept(s, id), "accept " + id)
		if id == "temple_arrival": s.temple_journal.visited = true
		if id == "temple_catalog":
			for kind in YinTemple.MINIONS:
				var record: Dictionary = s.enemies.filter(func(e): return e.kind == kind and not e.has("war_id"))[0]
				s.kill_enemy(record.id, Vector2(record.at[0], record.at[1]))
		if id in ["temple_wrath", "temple_guardian"]:
			var boss: String = YinAdventure.QUESTS[id].boss
			var record: Dictionary = s.enemies.filter(func(e): return e.kind == boss)[0]
			s.kill_enemy(record.id, Vector2(record.at[0], record.at[1]))
		check(YinAdventure.progress(s, id) == YinAdventure.QUESTS[id].target, "completed objective " + id)
		check("委托人" in YinAdventure.claim(s, id, 99), "wrong NPC cannot claim " + id)
		check("完成" in YinAdventure.claim(s, id, YinAdventure.QUESTS[id].npc), "claim " + id)
	check(s.equipment.filter(func(g): return g.weapon == "prajna").size() == 1, "chain awards exactly one wisdom blade")
	check(s.grant_gear("prajna").is_empty() and "已经" in YinAdventure.claim(s, "temple_wisdom", 3), "artifact cannot be duplicated")
	var blade: Dictionary = s.equipment.filter(func(g): return g.weapon == "prajna")[0]
	check(FarmState.valid_gear(blade) and blade.enchantment == "all", "artifact carries all elements with valid innate affixes")
	check(s.equip(blade.id) and s.active_slot == "melee", "wisdom sword equips in melee slot")
	check(YinBalance.damage(25, 20, blade) > YinBalance.damage(25, 1, blade) * 2, "actual damage scales with character cultivation level")
	check("Lv20" in YinAbilities.affix_text(blade, 20), "equipment describes current character-linked growth")
	var restored := FarmState.new()
	var snapshot: Dictionary = s.snapshot()
	check(restored.restore(JSON.parse_string(JSON.stringify(snapshot))) and restored.snapshot() == snapshot, "temple enemies quests relic and factions survive exact JSON roundtrip")
	var legacy: Dictionary = FarmState.new().snapshot()
	legacy.version = 9
	legacy.erase("temple_journal")
	legacy.factions.powers.erase("temple")
	check(restored.restore(legacy) and restored.factions.powers.has("temple") and not restored.temple_journal.visited, "v0.12 save migrates without resetting existing factions")
	var old_campaign := FarmState.new()
	old_campaign.factions.powers.island.troops = 91
	var old_war: Dictionary = YinFactions.declare(old_campaign, "island", "graveyard")
	YinFactions.deploy(old_campaign, old_war)
	var old_save: Dictionary = old_campaign.snapshot()
	old_save.version = 9
	old_save.erase("temple_journal")
	old_save.factions.powers.erase("temple")
	check(restored.restore(JSON.parse_string(JSON.stringify(old_save))) and restored.factions.powers.island.troops == 91 and restored.factions.wars[0].id == old_war.id, "legacy active war and customized old strength survive migration")
	var bad: Dictionary = s.snapshot()
	bad.temple_journal.defeated = ["yaksha"]
	check(not restored.restore(bad), "impossible temple boss sequence rejected")
	bad = s.snapshot()
	bad.equipment[0].enchantment = "all"
	check(not restored.restore(bad), "all-elements enchantment restricted to wisdom relic")
	bad = s.snapshot()
	bad.equipment[-1].enchantment = "burn"
	check(not restored.restore(bad), "relic cannot lose innate confluence on load")
	var dead_boss_ids: Array = s.enemies.filter(func(e): return e.kind in YinTemple.BOSSES).map(func(e): return e.id)
	s.next_day()
	s.prepare_enemies()
	check(s.enemies.filter(func(e): return e.kind in YinTemple.BOSSES).all(func(e): return e.dead and e.id in dead_boss_ids), "temple bosses stay defeated across dawn")
	check(s.enemies.filter(func(e): return e.zone == "temple" and e.kind in YinTemple.MINIONS and not e.dead).size() == 16, "native minions refresh each day")
	for defender in ["island", "graveyard", "village"]:
		var sample := FarmState.new()
		var war: Dictionary = YinFactions.declare(sample, "temple", defender)
		YinFactions.deploy(sample, war)
		check(YinFactions.survivors(sample, war, "attacker").all(func(e): return e.kind in YinTemple.MINIONS), "temple expedition uses temple troops against " + defender)
	var siege := FarmState.new()
	var war: Dictionary = YinFactions.declare(siege, "island", "temple")
	YinFactions.deploy(siege, war)
	check(FarmState.new().restore(JSON.parse_string(JSON.stringify(siege.snapshot()))), "active invasion of temple restores")
	check("护法" in YinNpcDialogue.new().reply(s, {"id": 6, "hp": 100}, "大佛寺") and "共存" in YinNpcDialogue.new().reply(s, {"id": 3, "hp": 100}, "文殊般若剑"), "offline NPC links region and artifact rules")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state.intro_seen = true
	game.travel("village")
	await frames()
	var scholar: Node2D = get_nodes_in_group("villagers").filter(func(n): return n.record.id == 6 and n.get_parent() == game.world.actors)[0]
	game.player.position = scholar.position + Vector2(0, 32)
	await key(KEY_E)
	check(await choose("委托"), "villager UI opens commission list")
	check(await choose("接取 · 北山梵影") and game.state.quests.has("temple_arrival"), "real UI accepts temple arrival commission")
	game.close_modal()
	game.player.position = YinTemple.VILLAGE_GATE
	await key(KEY_E)
	await frames(20)
	check(game.state.zone == "temple" and game.state.temple_journal.visited, "village mountain gate enters temple and records visit")
	check(game.world.level_size == Vector2(1600, 1280) and game.player.held_item in YinBalance.MELEE, "large temple map enters armed")
	check(game.world.path_to(YinTemple.ENTRY, YinTemple.ARENAS.asura).size() > 0 and game.world.path_to(YinTemple.ARENAS.asura, YinTemple.ARENAS.yaksha).size() > 0, "entrance and both arenas have navigable connected routes")
	check(game.state.enemies.filter(func(e): return e.zone == "temple").all(func(e): return game.world.is_safe_position(Vector2(e.at[0], e.at[1]))), "native spawns avoid temple walls and statues")
	check(get_nodes_in_group("enemies").any(func(e): return e.record.kind == "asura") and not get_nodes_in_group("enemies").any(func(e): return e.record.kind == "yaksha"), "second boss stays sealed in actual map")
	await key(KEY_TAB)
	await capture("temple-map")
	game.close_modal()
	game.player.position = YinTemple.EXIT
	await key(KEY_E)
	check(game.state.zone == "village" and game.world.is_safe_position(game.player.position), "temple exit returns to safe village gate")
	game.travel("temple")
	await frames()
	# Freeze native encounters to isolate individual mechanics without disabling the world.
	for e in get_nodes_in_group("enemies"): e.set_physics_process(false)
	game.player.position = Vector2(656, 928)
	var hungry := actor("hungry_ghost")
	hungry.record.hp -= 35
	var remains_id: int = game.state.next_id
	game.state.remains.append({"id": remains_id, "kind": "bone", "zone": "temple", "at": [688, 928], "integrity": 100, "fierceness": 10, "name": "试验遗骸", "regret": "未散", "yin": "土阴", "source_level": 1})
	game.state.next_id += 1
	var before: int = hungry.record.hp
	YinTempleCombat.passive(hungry)
	check(hungry.record.hp == before + 18 and not game.state.remains.any(func(r): return r.id == remains_id), "hungry ghost consumes nearby remains to heal")
	hungry.record.hp -= 10
	hungry.record.suppressed = true
	before = hungry.record.hp
	YinTempleCombat.passive(hungry)
	check(hungry.record.hp == before, "seal suppresses hunger passive")
	hungry.record.suppressed = false
	game.player.invincible = 0
	game.state.energy = 80
	game.state.health = 100
	YinTempleCombat.melee(hungry, 48)
	check(game.state.energy == 72 and game.state.health < 100, "hunger bite drains energy on successful contact")
	game.player.invincible = 10
	var energy: int = game.state.energy
	YinTempleCombat.melee(hungry, 48)
	check(game.state.energy == energy, "dodge immunity also blocks hunger drain")
	var ghost := actor("wraith", Vector2(768, 928))
	ghost.record.hp = 500
	ghost.record.max_hp = 500
	ghost.receive_hit(50, "bullet")
	var resisted: int = 500 - ghost.record.hp
	ghost.record.hp = 500
	ghost.record.suppressed = true
	ghost.receive_hit(50, "bullet")
	check(500 - ghost.record.hp > resisted * 2, "seal exposes ghost to physical damage")
	ghost.record.suppressed = false
	ghost.record.hp = 500
	ghost.receive_hit(50, "fire")
	check(500 - ghost.record.hp > resisted * 2 and YinIsland.anatomy("wraith").is_empty(), "elemental rites bypass ethereal body and ghost has no severable limbs")
	var rakshasa := actor("rakshasa", Vector2(832, 928))
	check(YinTempleCombat.phantom(rakshasa), "rakshasa starts with periodic deceptive form")
	rakshasa.record.suppressed = true
	check(not YinTempleCombat.phantom(rakshasa), "seal dispels rakshasa illusion")
	var dream := actor("kumbhanda", Vector2(896, 928))
	dream.attack_center = game.player.position
	game.world.projectiles.bullets.clear()
	YinTempleCombat.attack(dream)
	check(game.world.projectiles.bullets.size() == 3 and game.world.projectiles.bullets.all(func(b): return b.payload.snare > 0 and b.payload.drain == 12), "dream demon fires slow energy-draining nightmare beads")
	var asura: YinEnemy = get_nodes_in_group("enemies").filter(func(e): return e.record.kind == "asura")[0]
	asura.victim = game.player
	asura.attack_center = asura.position + Vector2.RIGHT * 100
	game.player.position = asura.position + Vector2.from_angle(PI / 6) * 80
	game.player.invincible = 0
	game.state.health = 100
	YinTempleCombat.attack(asura)
	check(game.state.health == 100, "six-arm sword formation leaves safe angular gaps")
	game.world.projectiles.bullets.clear()
	YinTempleCombat.attack(asura)
	check(game.world.projectiles.bullets.size() == 12, "asura alternates six-arm attack with wrath barrage")
	asura.receive_hit(100000, "fire")
	await frames()
	check(game.state.temple_journal.defeated.has("asura") and get_nodes_in_group("enemies").any(func(e): return e.record.kind == "yaksha"), "actual asura death releases yaksha")
	var yaksha: YinEnemy = get_nodes_in_group("enemies").filter(func(e): return e.record.kind == "yaksha")[0]
	yaksha.set_physics_process(false)
	yaksha.victim = game.player
	YinTempleCombat.passive(yaksha)
	check(yaksha.shield > 0, "yaksha regenerates guardian shield")
	yaksha.receive_hit(1, "seal")
	check(yaksha.shield == 0 and yaksha.record.suppressed, "seal breaks yaksha shield")
	yaksha.attack_center = yaksha.position + Vector2.RIGHT * 100
	YinTempleCombat.attack(yaksha)
	check(yaksha.charge_time > 0, "yaksha telegraphed strike initiates guardian charge")
	game.player.position = Vector2(656, 928)
	var relic: Dictionary = game.state.grant_gear("prajna", 2)
	game.state.equip(relic.id)
	game.player.held_item = "prajna"
	game.player.facing = Vector2.RIGHT
	game.player.invincible = 100
	game.state.cultivation = 800
	for fixture in [hungry, ghost, rakshasa, dream]: fixture.position = Vector2(1408, 1120)
	var dummy := actor("bone", Vector2(704, 928))
	dummy.record.hp = 2000
	dummy.record.max_hp = 2000
	var neighbor := actor("bone", Vector2(800, 928))
	neighbor.record.hp = 2000
	neighbor.record.max_hp = 2000
	game.world.projectiles.bullets.clear()
	game.action_cooldown = 0
	game.player.state_machine.reset()
	check(game.combat.trigger("sword") and get_nodes_in_group("prajna_slashes").size() == 4, "equipped sword creates four independent wisdom-element ribbons")
	var payload: Dictionary = game.combat.pending.payload
	check(payload.elements == YinBalance.ELEMENTS and payload.power > 3, "every relic swing carries all growing elemental powers")
	await frames(8)
	check(dummy.record.hp < 2000 and dummy.burn_time > 0 and dummy.chill_time > 0, "actual melee contact applies burn and ice together")
	check(neighbor.record.hp < 2000, "same strike also chains lightning to adjacent enemy")
	await capture("temple-prajna")
	game.show_equipment()
	await capture("temple-artifact-equipment")
	game.close_modal()
	game.combat.apply_payload(dummy, {"element": "freeze", "power": 3})
	check(dummy.burn_time == 0, "ordinary elemental weapons keep original fire-ice cancellation")
	var refined_id: int = game.state.remains.filter(func(r): return r.kind == "asura")[0].id
	var refined: String = game.state.process_remains(refined_id, "refine")
	check("役灵" in refined and game.state.spirits.any(func(sp): return sp.source_kind == "asura"), "new boss remains refine into corresponding temple spirit")
	game.spawn_spirits()
	var temple_spirit: Node2D = get_nodes_in_group("companions").filter(func(sp): return sp.record.source_kind == "asura")[0]
	temple_spirit.set_physics_process(false)
	game.world.projectiles.bullets.clear()
	temple_spirit.use_inherited_skill(dummy)
	check(game.world.projectiles.bullets.size() == 6, "refined asura actor uses inherited six-way formation")
	game.world.projectiles.bullets.clear()
	game.player.position = Vector2(1104, 176)
	yaksha.hit_flash = 0
	yaksha.material.set_shader_parameter("flash", 0.0)
	yaksha.windup = 0.8
	yaksha.attack_center = game.player.position
	await capture("temple-yaksha")
	game.show_factions()
	await capture("temple-factions")
	check("大佛寺" in YinFactions.report(game.state), "four-faction screen includes temple")
	game.close_modal()
	check(FarmState.new().restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))), "played temple session remains a valid save")
	game.queue_free()
	await frames()
	print("TEMPLE RESULT ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
