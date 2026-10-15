extends SceneTree
var game: Node2D
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT", "1")
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)
func find_button(node: Node, caption: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == caption: return child
		var result := find_button(child, caption)
		if result != null: return result
	return null
func click(target: Button) -> void:
	var parent := target.get_parent()
	while parent != null:
		if parent is ScrollContainer: parent.ensure_control_visible(target)
		parent = parent.get_parent()
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = target.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
func run() -> void:
	Engine.time_scale = 3
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	game.close_modal()
	game.state = FarmState.new()
	game.build_zone("graveyard", Vector2(182, 533))
	await frames(3)
	var old_world: FarmWorld = game.world
	var pose: Vector2 = game.player.position
	game.state.minutes = 1439.9
	await frames(12)
	check(game.state.minutes > 1440 and game.state.zone == "graveyard" and game.world == old_world and game.player.position == pose, "midnight keeps player and scene in place")
	game.state.minutes = 1799.9
	game.state.health = 71
	game.state.energy = 41
	var day_value: int = game.state.day
	await frames(4)
	check(game.state.day == day_value + 1 and game.state.minutes < 370 and game.world == old_world and game.player.position == pose, "dawn settles calendar without forced travel")
	check(game.state.health == 71 and game.state.energy == 41, "staying awake does not grant free sleep recovery")
	var restored := FarmState.new()
	game.state.minutes = 1501
	check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))) and restored.minutes == 1501, "after-midnight save restores")
	game.state.cultivation = 240
	check(game.state.capacity() == 3, "level four passively unlocks third companion")
	game.state.cultivation = 1440
	game.state.hall_level = 2
	check(game.state.capacity() == 9, "level nineteen and expanded hall combine capacity")
	game.state.spirits.clear()
	game.state.oil = 10
	var enemy: Dictionary = game.state.spawn_record("water", "graveyard", pose, 1)
	game.state.kill_enemy(enemy.id, pose)
	var remains_id: int = game.state.remains[-1].id
	var oil_before: int = game.state.oil
	await key(KEY_V)
	check(game.state.find_remains(remains_id).is_empty() and game.state.spirits.size() == 1 and game.state.oil == oil_before and game.state.zone == "graveyard", "V on corpse instantly refines without cart or hall")
	check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))) and restored.capacity() == 9, "increased capacity survives strict save validation")
	await key(KEY_I)
	check(game.character_tab == "背包" and game.modal != null, "I opens unified character inventory")
	await click(find_button(game.modal, "农具 · " + game.TOOL_NAMES[game.tool]))
	var tool_button: Button = find_button(game.modal, "斧头")
	check(tool_button != null, "tools have named inventory buttons")
	await click(tool_button)
	await frames(2)
	check(game.modal == null and game.player.held_item == "tool4" and not game.state.smart_farming, "real UI click equips held axe and closes inventory")
	await key(KEY_1)
	check(game.player.held_item == "tool4", "removed numeric farming toolbar has no legacy binding")
	await key(KEY_B)
	check(game.character_tab == "穿戴", "B opens worn equipment in same character UI")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await click(find_button(game.modal, "画面与分辨率设置"))
	check(game.character_tab == "设置" and find_button(game.modal, "应用分辨率") != null, "resolution controls accessible from pause menu")
	YinDisplaySettings.apply(1, false)
	var config := ConfigFile.new()
	check(config.load(YinDisplaySettings.PATH) == OK and config.get_value("display", "resolution") == 1, "resolution selection persists independently of game save")
	if DisplayServer.get_name() != "headless":
		await frames(5)
		check(DisplayServer.window_get_size() == Vector2i(1920, 1080), "actual graphics window changes to selected resolution")
	YinDisplaySettings.apply(0, false)
	game.close_modal()
	check(game.minimap.size == Vector2(118, 91) and game.player.get_node("Camera2D").zoom == Vector2.ONE, "compact minimap and native pixel camera")
	game.travel("forest")
	await frames(3)
	game.player.position = Vector2(1720, 250)
	check(game.world.nearest_interaction() == "sunken_gate", "northeast forest branch has reachable interaction")
	await key(KEY_E)
	check(game.state.zone == "sunken" and game.world.level_size == Vector2(1280, 960), "physical interaction enters expanded sunken village")
	var boss: YinEnemy
	for actor in get_nodes_in_group("enemies"):
		if actor.record.kind == "well_boss": boss = actor
	check(boss != null, "sunken branch spawns dedicated boss")
	boss.attack_center = game.player.position
	boss.volley("tide")
	check(game.world.projectiles.bullets.size() >= 18, "water boss produces alternating-speed radial barrage")
	game.state.kill_enemy(boss.record.id, boss.position)
	check(not game.state.boss_defeated, "optional boss does not falsely complete story boss")
	check(game.state.gear_drops.all(func(drop): return drop.gear.quality >= 1), "boss equipment rolls retain quality floor")
	game.state.next_day()
	game.state.prepare_enemies()
	check(game.state.enemies.filter(func(e): return e.kind == "well_boss").size() == 1 and game.state.enemies.filter(func(e): return e.kind == "well_boss")[0].dead, "defeated optional boss stays defeated across dawn")
	game.travel("forest")
	await frames(3)
	check(game.player.position.distance_to(Vector2(1700, 250)) < 5, "branch return restores nearby forest entrance")
	game.travel("theatre")
	await frames(3)
	for actor in get_nodes_in_group("enemies"):
		if actor.record.kind == "opera_boss": boss = actor
	boss.attack_center = game.player.position
	boss.volley("opera")
	check(game.state.zone == "theatre" and boss.burst_remaining > 0 and game.world.projectiles.bullets.size() >= 7, "opera branch boss combines fan and aimed bursts")
	check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))), "new branches and boss records serialize")
	game.state.spirits = [game.state.make_spirit("bone", 10)]
	game.build_zone("farm", Vector2(300, 350))
	await frames(4)
	var companion: CharacterBody2D = get_nodes_in_group("companions")[0]
	companion.position = Vector2(300, 350)
	enemy = game.state.spawn_record("bone", "farm", Vector2(420, 350), 1)
	enemy.hp = 500
	enemy.max_hp = 500
	game.spawn_enemies()
	await frames(3)
	boss = game.nearest_enemy(Vector2(420, 350), 30)
	boss.stun = 100
	var before: int = enemy.hp
	await frames(160)
	check(enemy.hp < before, "companion proactively approaches and attacks distant enemy")
	for actor in get_nodes_in_group("enemies"): actor.queue_free()
	await frames(3)
	game.state.order = "guard"
	companion.position = Vector2(480, 350)
	await frames(3)
	var anchor: Vector2 = companion.guard_anchor
	game.player.position = Vector2(200, 400)
	await frames(160)
	check(anchor.distance_to(Vector2(480, 350)) < 5 and companion.position.distance_to(anchor) < 65 and companion.position.distance_to(anchor) > 8, "guard patrols around assigned position instead of following player")
	game.spawn_spirits()
	await frames(3)
	check(get_nodes_in_group("companions")[0] == companion and companion.guard_anchor == anchor, "recruit reconciliation preserves existing guard and anchor")
	game.state.called_day = game.state.day
	game.state.oil = 20
	game.state.minutes = 1799.9
	await frames(12)
	check(get_nodes_in_group("companions")[0] == companion and companion.guard_anchor == anchor, "dawn preserves assigned guard position")
	game.state.order = "follow"
	companion.position = Vector2(610, 180)
	game.player.position = Vector2(760, 180)
	await frames(360)
	check(companion.position.x > 704 and game.world.is_safe_position(companion.position), "companion navigates bridge around solid river without clipping")
	game.queue_free()
	await frames(3)
	print("Expansion: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
