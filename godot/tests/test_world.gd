extends SceneTree
var failures: int = 0
var checks: int = 0
var game: Node2D
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + text)
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.close_modal()
	game.state = FarmState.new()
	game.build_zone("farm", Vector2(300, 350))
	await frames(3)
	check(not game.world.is_safe_position(Vector2(660, 150)), "river collision")
	check(game.world.is_safe_position(Vector2(660, 256)), "bridge clearance")
	var before: Vector2 = game.player.position
	Input.action_press("move_down")
	await frames(20)
	Input.action_release("move_down")
	check(game.player.position.y > before.y + 15, "physical movement")
	game.player.position = Vector2(617, 180)
	await frames(3)
	Input.action_press("move_right")
	await frames(35)
	Input.action_release("move_right")
	check(game.player.position.x < 635, "river blocks physical movement")
	game.player.position = Vector2(617, 256)
	await frames(3)
	Input.action_press("move_right")
	await frames(75)
	Input.action_release("move_right")
	check(game.player.position.x > 704, "bridge can be crossed")
	game.player.position = Vector2(100, 300)
	game.use_plot(0)
	check(not game.state.plots[0].tilled, "distant work blocked")
	game.player.position = Vector2(332, 291)
	game.action_cooldown = 0
	game.use_plot(0)
	check(game.state.plots[0].tilled, "nearby plot can be worked")
	game.show_inventory()
	before = game.player.position
	var clock: float = game.state.minutes
	Input.action_press("move_right")
	await frames(15)
	Input.action_release("move_right")
	check(game.player.position == before and game.state.minutes == clock, "menus pause movement and time")
	game.close_modal()
	game.travel("graveyard")
	await frames(3)
	check(game.state.zone == "graveyard" and game.world.plot_at(Vector2(335, 270)) == -1, "separate cemetery map")
	check(get_nodes_in_group("enemies").filter(func(e): return not e.is_queued_for_deletion()).size() == 5, "cemetery spawns enemies")
	for actor in get_nodes_in_group("enemies"): actor.stun = 100
	var enemy: YinEnemy = game.nearest_enemy(Vector2(280, 240), 40)
	var enemy_record: Dictionary = enemy.record
	game.player.position = Vector2(280, 273)
	game.player.facing = Vector2.UP
	game.action_cooldown = 0
	game.attack("seal")
	check(enemy.stun >= 2.9 and enemy.record.integrity == 100, "real seal spell suppresses without destroying remains")
	await frames(23)
	for i in range(4):
		if enemy_record.dead: break
		game.player.position = Vector2(enemy_record.at[0], enemy_record.at[1] + 32)
		game.player.facing = Vector2.UP
		await frames(1)
		game.action_cooldown = 0
		game.attack("sword")
		await frames(21)
	check(enemy_record.dead and game.state.remains.size() == 1, "melee kill leaves ground remains")
	await frames(2)
	var r: Dictionary = game.state.remains[0]
	check(r.zone == "graveyard" and r.integrity == 100 and r.fierceness == 12, "suppressed combat yields better remains")
	game.state.pickup(r.id)
	game.state.cultivation = 80
	game.state.learn_skill("fire")
	var second: YinEnemy = game.nearest_enemy(Vector2(380, 390), 45)
	var second_record: Dictionary = second.record
	game.player.position = Vector2(380, 423)
	game.player.facing = Vector2.UP
	for i in range(2):
		game.action_cooldown = 0
		game.attack("fire")
		await frames(23)
	check(second_record.dead and second_record.integrity == 30, "real fire kills faster but burns remains")
	await frames(2)
	var burnt: Dictionary = game.state.remains[1]
	game.state.pickup(burnt.id)
	check(game.state.enemies.filter(func(e): return e.zone == "graveyard").size() == 5, "removed transport spawns no pursuer")
	game.player.burden = true
	var carrying: int = game.state.cargo.size()
	game.travel("farm")
	await frames(3)
	check(game.state.cargo.size() == carrying and not game.player.burden, "travel has no corpse transport penalty")
	game.state.process_remains(r.id, "refine")
	game.spawn_spirits()
	await frames(2)
	check(game.state.spirits.size() == 1 and get_nodes_in_group("companions").size() == 1, "actual refined spirit actor spawns")
	game.player.invincible = 0
	game.take_damage(500)
	await frames(2)
	check(game.state.health == 60 and game.state.cargo.is_empty() and game.state.find_remains(burnt.id).zone == "graveyard", "defeat leaves unprocessed remains where they fell")
	game.state.day = 9
	game.state.minutes = 1080
	for i in range(4): await process_frame
	check(game.has_live_boss(), "ninth-night raid reaches actual farm scene")
	check(game.atmosphere.get("state") == game.state and game.atmosphere.call("night_alpha") > 0, "night overlay is attached to current live scene state")
	var boss: YinEnemy = null
	for node in get_nodes_in_group("enemies"):
		if not node.is_queued_for_deletion() and node.record.kind == "boss": boss = node
	check(boss != null, "boss physically instantiated")
	game.player.dodge()
	var hp: int = game.state.health
	game.take_damage(20)
	check(game.state.health == hp, "dodge grants real invulnerability")
	if boss != null: boss.receive_hit(10000, "sword")
	await frames(2)
	check(game.state.boss_defeated and not game.has_live_boss(), "boss defeated through scene combat")
	game.advance_day()
	check(game.state.day == 10 and game.state.zone == "farm", "battle unlocks tenth dawn")
	check(game.world.is_safe_position(game.player.position), "wake-up outside house collision")
	game.state.choose_ending("seal")
	check(game.state.ending == "seal", "first chapter can complete")
	print("Yintian world: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await frames(2)
	quit(1 if failures else 0)
