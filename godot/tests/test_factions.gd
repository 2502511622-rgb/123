extends SceneTree
var checks: int = 0
var failures: int = 0
func check(ok: bool, description: String) -> void:
	checks += 1
	print("FACTIONS ", "PASS " if ok else "FAIL ", description)
	if not ok: failures += 1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT", "1")
	call_deferred("run")
func frames(n: int = 4) -> void:
	for i in range(n): await physics_frame
func run() -> void:
	var s := FarmState.new()
	check(YinFactions.validate(s.factions), "initial three factions valid")
	check(YinFactions.strength(s.factions, "island") > YinFactions.strength(s.factions, "village"), "initial power hierarchy")
	check(YinFactions.aggression(200, 50) > YinFactions.aggression(100, 50), "greater attacking power increases invasion probability")
	check(YinFactions.aggression(100, 50) > YinFactions.aggression(100, 200), "weaker defenders attract more invasions")
	check(YinFactions.aggression(25, 200) > 0, "weak factions can counterattack")
	for attacker in YinFactions.IDS:
		for defender in YinFactions.IDS:
			if attacker == defender: continue
			var sample := FarmState.new()
			var declared: Dictionary = YinFactions.declare(sample, attacker, defender)
			check(not declared.is_empty() and declared.defender == defender, attacker + " can attack " + defender)
	var war: Dictionary = YinFactions.declare(s, "island", "village")
	s.factions.last_day = s.day
	check(war.attackers > war.defenders, "strong invaders deploy a larger army")
	check(not YinFactions.tick(s) and s.enemies.is_empty(), "morning warning does not spawn early")
	s.minutes = 720
	check(YinFactions.tick(s) and war.status == "active", "noon deploys both armies")
	var size_before: int = s.enemies.size()
	YinFactions.tick(s)
	check(s.enemies.size() == size_before, "repeated ticks do not duplicate armies")
	var restored := FarmState.new()
	var snapshot: Dictionary = s.snapshot()
	check(restored.restore(JSON.parse_string(JSON.stringify(snapshot))) and restored.snapshot() == snapshot, "active war survives JSON roundtrip exactly")
	var malformed: Dictionary = snapshot.duplicate(true)
	malformed.factions.wars[0].defender = "unknown"
	check(not restored.restore(malformed), "unknown factions rejected")
	malformed = snapshot.duplicate(true)
	malformed.factions.powers.village.troops = -1
	check(not restored.restore(malformed), "negative army rejected")
	var legacy: Dictionary = FarmState.new().snapshot()
	legacy.version = 8
	legacy.erase("factions")
	check(restored.restore(legacy) and restored.factions == YinFactions.initial(), "version eight migrates to factions")
	for e in YinFactions.survivors(s, war, "attacker"): e.dead = true
	check(YinFactions.tick(s) and s.factions.wars.is_empty(), "eliminated army settles immediately")
	check(s.village_integrity == 100 and s.factions.history.size() == 1, "successful defense protects village")
	var once: Dictionary = s.factions.duplicate(true)
	YinFactions.tick(s)
	YinFactions.settle(s, war, true)
	check(s.factions == once, "settlement cannot repeat")
	var loss := FarmState.new()
	var invasion: Dictionary = YinFactions.declare(loss, "island", "village")
	YinFactions.deploy(loss, invasion)
	loss.minutes = 1200
	loss.factions.last_day = loss.day
	check(YinFactions.tick(loss) and loss.village_integrity < 100, "unopposed stronger invasion damages village at night")
	var funds: int = s.money
	check("获得" in YinFactions.sponsor(s) and s.money == funds - 30, "funding changes actual village strength")
	YinFactions.sponsor(s)
	check(s.money == funds - 30, "funding limited to once per day")
	check("岛国" in YinNpcDialogue.new().reply(s, {"id": 1, "hp": 100}, "势力战况"), "offline NPC reports actual faction state")
	var simulation := FarmState.new()
	var days_with_war: int = 0
	for simulated_day in range(1, 61):
		simulation.day = simulated_day
		simulation.minutes = 360
		YinFactions.tick(simulation)
		if not simulation.factions.wars.is_empty(): days_with_war += 1
		simulation.minutes = 720
		YinFactions.tick(simulation)
		simulation.minutes = 1200
		YinFactions.tick(simulation)
		simulation.prepare_enemies()
	check(days_with_war > 20 and simulation.factions.history.size() == 12, "sixty-day simulation produces bounded campaign history")
	check(YinFactions.validate(simulation.factions) and simulation.factions.wars.is_empty(), "long campaign resolves daily and keeps legal strengths")
	check(FarmState.new().restore(JSON.parse_string(JSON.stringify(simulation.snapshot()))), "long campaign save remains restorable")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state.factions = YinFactions.initial()
	game.state.factions.last_day = game.state.day
	game.state.intro_seen = true
	var dormant: Dictionary = game.state.spawn_record("bone", "farm", Vector2(420, 350), 1)
	var distant: Dictionary = YinFactions.declare(game.state, "graveyard", "island")
	game.state.minutes = 720
	await frames()
	check(get_nodes_in_group("enemies").all(func(e): return e.record.id != dormant.id), "distant battle does not respawn unrelated local enemies")
	YinFactions.settle(game.state, distant, false)
	game.state.factions = YinFactions.initial()
	game.state.factions.last_day = game.state.day
	game.travel("village")
	await frames()
	var live: Dictionary = YinFactions.declare(game.state, "graveyard", "village")
	YinFactions.deploy(game.state, live)
	game.spawn_enemies()
	await frames()
	var invaders: Array = get_nodes_in_group("enemies").filter(func(e): return e.record.get("war_id", 0) == live.id and e.get_parent() == game.world.actors)
	var guards: Array = get_nodes_in_group("faction_guards").filter(func(e): return e.get_parent() == game.world.actors)
	check(invaders.size() == live.attackers and guards.size() == live.defenders, "both armies instantiate on actual defender map")
	check(guards[0].hurtbox.collision_layer == 0 and guards[0].faction_target() != game.player, "militia protected from player targeting")
	check(invaders[0].faction_target() in guards, "invaders prioritize opposing army")
	var first = invaders[0]
	var guard = guards[0]
	first.position = Vector2(660, 480)
	guard.position = Vector2(688, 480)
	first.victim = guard
	first.windup = 0.01
	first.attack_center = guard.position
	var old_hp: int = guard.record.hp
	first.faction_tick(0.02, {"speed": 40})
	check(guard.record.hp < old_hp, "telegraphed army attack damages opposing actor")
	var old_remains: int = game.state.remains.size()
	guard.receive_faction_hit(10000)
	check(guard.record.dead and game.state.remains.size() == old_remains, "NPC battle deaths do not award player loot")
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_P
		event.pressed = down
		root.push_input(event, true)
		await frames(2)
	check(game.modal != null, "faction screen accessible")
	if DisplayServer.get_name() != "headless" and OS.get_environment("YINTIAN_CAPTURE_DIR") != "":
		await RenderingServer.frame_post_draw
		var folder: String = OS.get_environment("YINTIAN_CAPTURE_DIR")
		DirAccess.make_dir_recursive_absolute(folder)
		check(root.get_texture().get_image().save_png(folder.path_join("factions-panel.png")) == OK, "capture faction screen")
	var paused_hp: int = first.record.hp
	await frames(20)
	check(first.record.hp == paused_hp, "modal pauses army combat")
	game.close_modal()
	if DisplayServer.get_name() != "headless" and OS.get_environment("YINTIAN_CAPTURE_DIR") != "":
		game.player.position = Vector2(670, 360)
		game.player.get_node("Camera2D").reset_smoothing()
		game.player.get_node("Camera2D").force_update_scroll()
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OS.get_environment("YINTIAN_CAPTURE_DIR").path_join("factions-battle.png")) == OK, "capture faction battlefield")
	game.spawn_enemies()
	check(get_nodes_in_group("faction_guards").filter(func(e): return not e.is_queued_for_deletion()).size() == live.defenders - 1, "respawning does not duplicate surviving militia")
	game.queue_free()
	await frames()
	print("FACTIONS RESULT ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
