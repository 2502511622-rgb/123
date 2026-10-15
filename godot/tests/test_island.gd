extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node2D
func check(ok: bool, text: String) -> void:
	checks += 1
	print("ISLAND ", "PASS " if ok else "FAIL ", text)
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
	check(root.get_texture().get_image().save_png(folder.path_join(name_value + ".png")) == OK, "screenshot " + name_value)
func find_enemy(kind: String) -> YinEnemy:
	for enemy in get_nodes_in_group("enemies"):
		if not enemy.is_queued_for_deletion() and enemy.get_parent() == game.world.actors and enemy.record.kind == kind: return enemy
	return null
func fixture(kind: String, at: Vector2, hp: int = 1000) -> YinEnemy:
	var e: Dictionary = game.state.spawn_record(kind, game.state.zone, at, 1)
	e.hp = hp
	e.max_hp = hp
	e.armor = 0
	e.home_at = [at.x, at.y]
	game.spawn_enemies()
	for enemy in get_nodes_in_group("enemies"):
		if enemy.record.id == e.id:
			enemy.set_physics_process(false)
			return enemy
	return null
func quiet() -> void:
	for enemy in get_nodes_in_group("enemies"):
		if enemy.get_parent() == game.world.actors: enemy.set_physics_process(false)
func run() -> void:
	var state := FarmState.new()
	state.prepare_enemies()
	check(state.enemies.filter(func(e): return e.zone == "island" and e.kind in YinIsland.MINIONS).size() == 20, "island has twenty themed minor enemies")
	check(state.enemies.filter(func(e): return e.kind in YinIsland.BOSSES).size() == 3, "three persistent island bosses exist")
	var count: int = state.enemies.size()
	state.prepare_enemies()
	check(state.enemies.size() == count, "same-day preparation cannot duplicate island population")
	check(not YinIsland.available(state, "daitengu") and not YinIsland.available(state, "ryomen_sukuna"), "later arenas remain sealed")
	var last: Dictionary = state.enemies.filter(func(e): return e.kind == "ryomen_sukuna")[0]
	state.kill_enemy(last.id, YinIsland.ARENAS.ryomen_sukuna)
	check(not last.dead and state.island_journal.defeated.is_empty(), "locked boss cannot be killed out of order")
	check("前置" in YinAdventure.accept(state, "island_blade"), "artifact commission requires preceding chain")
	YinAdventure.accept(state, "island_arrival")
	state.island_journal.visited = true
	check("完成" in YinAdventure.claim(state, "island_arrival", 6), "arrival commission completes at scholar")
	YinAdventure.accept(state, "island_catalog")
	for kind in YinIsland.MINIONS:
		var enemy: Dictionary = state.enemies.filter(func(e): return e.zone == "island" and e.kind == kind)[0]
		state.kill_enemy(enemy.id, Vector2(enemy.at[0], enemy.at[1]))
	check(YinAdventure.progress(state, "island_catalog") == 5, "bestiary commission records five distinct species")
	check("完成" in YinAdventure.claim(state, "island_catalog", 6), "five-species report unlocks funeral commission")
	for pair in [["island_lament", "itsumade", 2], ["island_gale", "daitengu", 6], ["island_dual", "ryomen_sukuna", 1]]:
		YinAdventure.accept(state, pair[0])
		var enemy: Dictionary = state.enemies.filter(func(e): return e.kind == pair[1])[0]
		check(YinIsland.available(state, pair[1]), "arena available in story order: " + pair[1])
		state.kill_enemy(enemy.id, YinIsland.ARENAS[pair[1]])
		check(YinAdventure.progress(state, pair[0]) == 1 and "完成" in YinAdventure.claim(state, pair[0], pair[2]), "boss report links to next NPC: " + pair[0])
	YinAdventure.accept(state, "island_blade")
	while state.equipment.size() < 20: state.grant_gear("sword")
	check("已满" in YinAdventure.claim(state, "island_blade", 3) and not state.quests.island_blade.claimed, "full equipment keeps unique artifact reward unclaimed")
	state.equipment.resize(2)
	check("伊佩塔姆" in YinAdventure.claim(state, "island_blade", 3), "smith awards equippable Ipetam through final commission")
	var artifact: Dictionary = state.equipment[-1]
	check(artifact.weapon == "ipetam" and state.equip(artifact.id) and state.active_slot == "melee", "artifact equips in melee slot")
	check(state.grant_gear("ipetam").is_empty() and "已经" in YinAdventure.claim(state, "island_blade", 3), "artifact cannot be duplicated by granting or repeat claim")
	check("不可拆解" in state.salvage(artifact.id), "unique blade is protected from dismantling")
	var base: int = YinBalance.damage(28, 1, artifact)
	artifact.artifact_kills = 5
	check(YinBalance.artifact_level(artifact) == 2 and YinBalance.damage(28, 1, artifact) > base, "five personal kills raise artifact level and actual damage")
	artifact.artifact_kills = 100
	check(YinBalance.artifact_level(artifact) == 10 and is_equal_approx(YinBalance.lifesteal(artifact), 0.2), "artifact growth and lifesteal have bounded caps")
	state.health = 50
	check(state.artifact_hit(artifact.id, 50) == 10 and state.health == 60, "lifesteal uses actual dealt damage and artifact level")
	check(state.artifact_hit(0, 100) == 0 and state.health == 60, "unattributed attacks cannot heal through owned artifact")
	state.health = 99
	check(state.artifact_hit(artifact.id, 1000) == 1 and state.health == 100, "lifesteal cannot overheal")
	var restored := FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(state.snapshot()))) and restored.current_gear().artifact_kills == 100 and restored.island_journal == state.island_journal, "artifact growth and island chain round-trip through save")
	var before_bosses: Array = state.enemies.filter(func(e): return e.kind in YinIsland.BOSSES).map(func(e): return e.id)
	state.next_day()
	state.prepare_enemies()
	check(state.enemies.filter(func(e): return e.kind in YinIsland.BOSSES).all(func(e): return e.dead and e.id in before_bosses), "defeated bosses do not respawn next day")
	check(state.enemies.filter(func(e): return e.zone == "island" and e.kind in YinIsland.MINIONS).size() == 20, "minor enemies refresh once on new day")
	var old: Dictionary = FarmState.new().snapshot()
	old.version = 7
	old.erase("island_journal")
	check(restored.restore(old) and not restored.island_journal.visited, "version seven saves migrate with new island journal")
	var bad: Dictionary = state.snapshot()
	bad.equipment[-1].artifact_kills = -1
	check(not restored.restore(bad), "negative artifact growth rejected")
	bad = state.snapshot()
	bad.island_journal.defeated = ["ryomen_sukuna"]
	check(not restored.restore(bad), "impossible boss sequence rejected")
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
	await choose("委托")
	check(await choose("接取 · 裂海异乡") and game.state.quests.has("island_arrival"), "scholar UI accepts first island commission")
	game.close_modal()
	game.player.position = Vector2(1180, 820)
	await key(KEY_E)
	check(game.state.zone == "island" and game.world.level_size == Vector2(2240, 1600), "physical ferry interaction enters island map")
	check(game.world.tile_farm.ground.get_cell_source_id(Vector2i(69, 49)) == 0, "island terrain covers full world bounds")
	quiet()
	check(find_enemy("itsumade") != null and find_enemy("daitengu") == null and find_enemy("ryomen_sukuna") == null, "only first boss instantiates before unlocking")
	for kind in YinIsland.BOSSES:
		var path: PackedVector2Array = game.world.path_to(game.player.position, YinIsland.ARENAS[kind])
		check(path.size() > 1 and path[-1].distance_to(YinIsland.ARENAS[kind]) < 24, "arena is reachable over bridges: " + kind)
	game.player.position = Vector2(224, 1408)
	game.update_exploration()
	check(game.state.island_journal.visited, "actual island exploration records arrival")
	game.player.position = Vector2(180, 1440)
	await key(KEY_E)
	scholar = get_nodes_in_group("villagers").filter(func(n): return n.record.id == 6 and n.get_parent() == game.world.actors)[0]
	game.player.position = scholar.position + Vector2(0, 32)
	await key(KEY_E)
	await choose("委托")
	check(await choose("复命 · 1/1") and game.state.quests.island_arrival.claimed, "new commission UI can pay currency-only reward without a weapon")
	check(await choose("接取 · 五妖异闻") and game.state.quests.has("island_catalog"), "reporting unlocks next linked commission in same NPC UI")
	game.close_modal()
	game.show_quests()
	await frames()
	await capture("island-quests")
	game.close_modal()
	game.player.position = Vector2(1180, 820)
	await key(KEY_E)
	quiet()
	game.show_character("地图")
	await frames()
	await capture("island-map")
	game.close_modal()
	var kappa: YinEnemy = find_enemy("kappa")
	kappa.position = Vector2(600, 928)
	kappa.record.hp -= 10
	var hp: int = kappa.record.hp
	kappa.victim = game.player
	kappa.myth_regen = 1
	YinIslandCombat.tick(kappa, 0, YinBalance.MONSTERS.kappa)
	check(kappa.record.hp == hp + 3, "kappa recovers beside water with filled head bowl")
	kappa.receive_hit(0, "seal")
	hp = kappa.record.hp
	kappa.myth_regen = 1
	YinIslandCombat.tick(kappa, 0, YinBalance.MONSTERS.kappa)
	check(kappa.record.hp == hp, "seal spills kappa bowl and stops water regeneration")
	var chochin: YinEnemy = fixture("chochin", Vector2(700, 1000))
	hp = chochin.record.hp
	chochin.receive_hit(10, "fire")
	check(chochin.record.hp == hp - 16, "paper lantern body takes increased fire damage")
	var flame: YinEnemy = fixture("sogenbi", Vector2(720, 1120))
	hp = flame.record.hp
	flame.receive_hit(20, "fire")
	check(flame.record.hp == hp - 5, "disembodied priest flame resists fire")
	flame.record.hp = 10
	flame.receive_hit(1, "sword")
	check(flame.record.get("severed", []).is_empty(), "bodiless Sogenbi does not shed fictional arms and legs")
	var spider: YinEnemy = fixture("jorogumo", Vector2(700, 1040))
	game.player.position = Vector2(780, 1040)
	game.player.invincible = 0
	game.state.health = 100
	spider.attack_center = game.player.position
	spider.victim = game.player
	YinIslandCombat.attack(spider)
	await frames(35)
	check(game.player.snare_time > 0 and game.state.health < 100, "spider web projectile deals damage and restricts real player movement")
	game.world.projectiles.bullets.clear()
	game.player.snare_time = 0
	var hammer: YinEnemy = fixture("ippon_datara", game.player.position + Vector2(-40, 0))
	hammer.victim = game.player
	hammer.attack_center = game.player.position
	game.player.invincible = 0
	game.state.health = 100
	YinIslandCombat.attack(hammer)
	check(game.state.health < 100, "one-legged smith hammer hits inside telegraphed slam")
	game.player.invincible = 0
	game.state.health = 100
	hammer.attack_center = game.player.position + Vector2(100, 0)
	YinIslandCombat.attack(hammer)
	check(game.state.health == 100, "moving out of locked hammer area avoids damage")
	for actor in get_nodes_in_group("enemies"):
		if actor.get_parent() == game.world.actors:
			actor.hit_flash = 0
			actor.material.set_shader_parameter("flash", 0.0)
	game.refresh("苇岸异闻：河童、纸灯、独足山匠、蛛女与妖火。")
	await capture("island-yokai")
	var bird: YinEnemy = find_enemy("itsumade")
	bird.position = Vector2(700, 352)
	bird.record.hp = bird.record.max_hp
	bird.attack_center = bird.position + Vector2(100, 0)
	var unrest_before: int = YinIslandCombat.unrest(bird)
	var remains_source: Dictionary = game.state.spawn_record("chochin", "island", bird.position + Vector2(40, 0), 1)
	game.state.kill_enemy(remains_source.id, bird.position + Vector2(40, 0))
	var corpse_id: int = game.state.remains[-1].id
	check(YinIslandCombat.unrest(bird) == mini(3, unrest_before + 1), "unburied remains strengthen Itsumade lament")
	game.state.process_remains(corpse_id, "release")
	check(YinIslandCombat.unrest(bird) == unrest_before, "releasing remains weakens lament")
	game.world.projectiles.bullets.clear()
	YinIslandCombat.attack(bird)
	check(game.world.projectiles.bullets.any(func(b): return b.payload.get("poison", 0) > 0), "golden bird sends poison alongside feather fan")
	game.player.position = bird.position + Vector2(-70, 40)
	game.refresh("以津真天 · 金羽毒鸣；超度未葬遗骸可削弱怨声。")
	await capture("island-itsumade")
	game.world.projectiles.bullets.clear()
	bird.receive_hit(100000, "sword")
	await frames()
	check("itsumade" in game.state.island_journal.defeated and find_enemy("daitengu") != null, "real first boss death unlocks next arena")
	quiet()
	var tengu: YinEnemy = find_enemy("daitengu")
	tengu.windup = 0.8
	tengu.record.armor = 0
	hp = tengu.record.hp
	tengu.receive_hit(100, "bullet")
	check(tengu.record.hp == hp - 45, "tengu wind stance reduces incoming bullets")
	tengu.receive_hit(0, "seal")
	check(tengu.windup == 0 and tengu.stun > 0, "seal interrupts tengu wind stance")
	tengu.attack_center = tengu.position + Vector2(100, 0)
	YinIslandCombat.attack(tengu)
	check(game.world.projectiles.bullets.any(func(b): return b.payload.get("push", 0) > 0), "feather fan emits pushing mountain wind")
	game.player.position = tengu.position + Vector2(-70, 40)
	tengu.hit_flash = 0
	tengu.material.set_shader_parameter("flash", 0.0)
	tengu.windup = 0.6
	game.refresh("大天狗 · 羽扇山岚；镇符可打断风障。")
	await capture("island-daitengu")
	game.world.projectiles.bullets.clear()
	tengu.receive_hit(100000, "sword")
	await frames()
	quiet()
	var sukuna: YinEnemy = find_enemy("ryomen_sukuna")
	check(sukuna != null and "daitengu" in game.state.island_journal.defeated, "second boss death unlocks two-faced warrior")
	sukuna.victim = game.player
	game.player.position = sukuna.position + Vector2(-60, 0)
	sukuna.attack_center = sukuna.position + Vector2(60, 0)
	game.player.invincible = 0
	game.state.health = 100
	sukuna.myth_phase = 0
	YinIslandCombat.attack(sukuna)
	check(game.state.health < 100 and sukuna.myth_phase == 1, "two-faced sword stance threatens behind as well as in front")
	YinIslandCombat.attack(sukuna)
	check(game.world.projectiles.bullets.size() == 6 and sukuna.myth_phase == 2, "next stance fires opposed bow fans")
	game.refresh("两面宿傩 · 双面四臂；剑斩与双向弓阵交替。")
	await capture("island-sukuna")
	game.world.projectiles.bullets.clear()
	sukuna.receive_hit(100000, "sword")
	await frames()
	quiet()
	check(game.state.island_journal.defeated.size() == 3, "all three real boss deaths persist in journal")
	var blade: Dictionary = game.state.grant_gear("ipetam", 2, 3)
	game.state.equip(blade.id)
	game.player.held_item = "ipetam"
	game.player.position = Vector2(1360, 800)
	game.player.facing = Vector2.RIGHT
	game.state.health = 50
	var dummy: YinEnemy = fixture("kappa", game.player.position + Vector2(50, 0), 1000)
	dummy.set_physics_process(false)
	game.action_cooldown = 0
	game.player.state_machine.reset()
	check(game.combat.trigger("sword") and get_nodes_in_group("ipetam_slashes").size() == 3, "equipped artifact creates independent three-ribbon attack effect")
	await frames(8)
	check(dummy.record.hp < 1000 and game.state.health > 50, "real delayed artifact hit damages and lifesteals")
	await capture("island-ipetam")
	var kill: int = blade.artifact_kills
	dummy.receive_hit(10000, "sword", blade.id)
	check(blade.artifact_kills == kill + 1, "artifact last hit gains exactly one growth kill")
	dummy.receive_hit(10000, "sword", blade.id)
	check(blade.artifact_kills == kill + 1, "dead targets cannot grant repeated growth")
	var other: YinEnemy = fixture("chochin", game.player.position + Vector2(70, 0), 3)
	other.receive_hit(10000, "bullet")
	check(blade.artifact_kills == kill + 1, "gun or companion kills do not grow owned blade")
	game.state.health = 50
	var shielded: YinEnemy = fixture("kappa", game.player.position + Vector2(80, 0))
	shielded.shield = 50
	shielded.receive_hit(10, "sword", blade.id)
	check(game.state.health == 50, "absorbed damage gives no lifesteal")
	game.state.health = 50
	var weak: YinEnemy = fixture("chochin", game.player.position + Vector2(50, 0), 3)
	weak.receive_hit(10000, "sword", blade.id)
	check(game.state.health == 51, "overkill heals from actual lost health, not raw damage")
	blade.artifact_kills = 10
	game.show_equipment()
	await frames()
	check(game.modal.find_children("*", "Button", true, false).any(func(b): return "神器 Lv3" in b.text and "吸血" in b.text), "equipment displays artifact growth and lifesteal")
	await capture("island-artifact-equipment")
	game.close_modal()
	game.persist()
	check(load("res://scripts/save_store.gd").load_game(restored) and restored.current_gear().artifact_kills == 10 and restored.island_journal.defeated.size() == 3, "actual save file restores island bosses and growing weapon")
	game.player.position = Vector2(180, 1440)
	await key(KEY_E)
	check(game.state.zone == "village" and game.player.position.distance_to(Vector2(1180, 780)) < 10, "return ferry restores village east dock")
	var lore := YinNpcDialogue.new()
	check("缝合" in lore.reply(game.state, game.state.villagers[5], "岛国") and "阿伊努" in lore.reply(game.state, game.state.villagers[5], "伊佩塔姆"), "offline dialogue links stitched world and blade origin")
	game.travel("island")
	await frames()
	quiet()
	game.state.health = 1
	game.player.invincible = 0
	var previous_player: Node2D = game.player
	var fatal: YinEnemy = fixture("ippon_datara", game.player.position + Vector2(30, 0))
	fatal.victim = game.player
	fatal.attack_center = game.player.position
	fatal.windup = 0.01
	YinIslandCombat.tick(fatal, 0.02, YinBalance.MONSTERS.ippon_datara)
	check(game.state.zone == "farm" and game.player != previous_player and game.state.health == 60, "fatal island attack safely transitions to home without updating removed world")
	print("Island: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
