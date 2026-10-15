extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node2D
func check(ok: bool, message: String) -> void:
	checks += 1
	print("REDESIGN ", "PASS " if ok else "FAIL ", message)
	if not ok: failures += 1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT", "1")
	call_deferred("run")
func frames(count: int = 4) -> void:
	for i in range(count): await physics_frame
func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var target: String = OS.get_environment("YINTIAN_CAPTURE_DIR")
	if target != "":
		DirAccess.make_dir_recursive_absolute(target)
		check(root.get_texture().get_image().save_png(target.path_join(name_value + ".png")) == OK, "rendered screenshot " + name_value)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state.intro_seen = true
	game.show_inventory()
	await frames()
	var navigation: HBoxContainer = game.modal.get_node("ModalCard/Layout/Navigation")
	check(navigation.get_child_count() == 4, "only four primary character destinations")
	check(not navigation.get_parent() is ScrollContainer, "navigation stays outside scrolling content")
	var scroll: ScrollContainer = game.modal.get_node("ModalCard/Layout/Scroll")
	check(scroll.get_h_scroll_bar().max_value <= scroll.size.x + 1, "inventory has no horizontal overflow")
	check(scroll.get_v_scroll_bar().max_value <= scroll.size.y + 1, "default inventory fits without scrolling")
	var bag: YinInventoryPanel = get_first_node_in_group("inventory_panels")
	check(not bag.build_action.visible and not bag.drop_action.visible, "irrelevant item actions are hidden")
	bag.select(bag.controls[0], false)
	check(bag.drop_action.visible and not bag.build_action.visible, "selected seeds offer dropping but no placement")
	bag.selected_slot = null
	bag.hint.visible = false
	bag.refresh()
	await frames()
	await capture("redesign-inventory")
	game.show_equipment()
	await frames()
	check(not game.modal.find_children("*", "Button", true, false).any(func(b): return "铭刻" in b.text), "equipment UI has no inscription")
	await capture("redesign-equipment")
	game.close_modal()
	for quality in range(4):
		var gear := YinBalance.make_gear(40 + quality, "rifle", 3, quality)
		check(FarmState.valid_gear(gear) and gear.affixes.size() == (2 if quality >= 2 else 1), "innate affixes generated at quality %d" % quality)
	var data := FarmState.new()
	data.oil = 0
	for kind in ["water", "boss"]:
		var source: Dictionary = data.spawn_record(kind, "graveyard", Vector2(400, 350), 1)
		data.kill_enemy(source.id, Vector2(400, 350))
		var corpse: Dictionary = data.remains[-1]
		check("完成" in data.process_remains(corpse.id, "refine") and data.oil == 0, "zero-material refinement: " + kind)
	var damaged: Dictionary = data.spawn_record("water", "graveyard", Vector2(400, 350), 1)
	data.kill_enemy(damaged.id, Vector2(400, 350))
	var corpse: Dictionary = data.remains[-1]
	corpse.integrity = 30
	check("不足" in data.process_remains(corpse.id, "refine") and not data.find_remains(corpse.id).is_empty(), "failed refinement preserves damaged remains")
	game.build_zone("graveyard", Vector2(360, 500))
	for node in get_nodes_in_group("enemies"): node.queue_free()
	await frames()
	var record: Dictionary = game.state.spawn_record("bone", "graveyard", Vector2(480, 500), 1)
	record.hp = 100
	record.max_hp = 100
	record.armor = 0
	game.spawn_enemies()
	var enemy: YinEnemy
	for node in get_nodes_in_group("enemies"):
		if node.record.id == record.id: enemy = node
	enemy.receive_hit(45, "sword")
	check(record.hp == 55 and record.severed == ["arm"], "melee severs arm at sixty percent health")
	check(enemy.hit_stop > 0 and enemy.hit_flash > 0 and enemy.knockback.length() > 0 and enemy.material.get_shader_parameter("flash") == 1.0, "hit has local pause, flash and directional knockback")
	check(enemy.health_trail == 100 and enemy.trail_delay > 0, "health bar shows delayed damage trail")
	enemy.receive_hit(30, "bullet")
	check(record.hp == 25 and record.severed == ["arm", "leg"], "bullet severs leg at thirty percent health")
	check(record.integrity == 100, "dismemberment preserves refinement eligibility")
	var fragments: Array = game.world.feedback.get_children().filter(func(n): return n is YinSeveredLimb)
	check(fragments.size() == 2, "detached sprite fragments spawn once per limb")
	enemy.receive_hit(1, "bullet")
	check(game.world.feedback.get_children().filter(func(n): return n is YinSeveredLimb).size() == 2, "repeat hits cannot duplicate severed limbs")
	game.state.health = 100
	game.player.invincible = 0
	enemy.victim = game.player
	enemy.hurt_victim(20)
	check(game.state.health == 85, "arm loss reduces actual attack damage by twenty-five percent")
	enemy.hit_stop = 0
	enemy.stun = 0
	enemy.cooldown = 100
	enemy._physics_process(1.0 / 60)
	check(is_equal_approx(enemy.velocity.length(), 29 * 0.62), "leg loss slows actual movement")
	game.show_pause()
	var fragment_age: float = fragments[0].age
	await frames(8)
	check(fragments[0].age == fragment_age, "pause freezes fragment effects")
	game.close_modal()
	var restored := FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))), "dismembered enemy saves restore")
	check(restored.enemies.any(func(e): return e.id == record.id and e.get("severed", []) == ["arm", "leg"]), "limb loss persists across reload")
	var bad: Dictionary = game.state.snapshot().duplicate(true)
	bad.enemies[-1].severed = ["leg", "leg"]
	check(not restored.restore(bad), "invalid duplicate limb data is rejected")
	enemy.set_physics_process(false)
	game.player.frozen = true
	await frames(2)
	await capture("redesign-combat")
	game.player.frozen = false
	var legacy: Dictionary = game.state.snapshot().duplicate(true)
	legacy.equipment[0].affixes = []
	check(restored.restore(legacy) and not restored.equipment[0].affixes.is_empty(), "legacy weapons receive innate affixes on load")
	game.travel("forest")
	await frames()
	check(game.world.level_size == Vector2(2880, 1920), "forest area expands by 2.25 times")
	check(game.world.tile_farm.ground.get_cell_source_id(Vector2i(89, 59)) == 0, "terrain covers farthest expanded corner")
	for destination in [Vector2(2304, 384), Vector2(2432, 1024), Vector2(2304, 1632)]:
		var route: PackedVector2Array = game.world.path_to(Vector2(1800, 592), destination+Vector2(0,40))
		check(route.size() > 1 and route[-1].distance_to(destination+Vector2(0,40)) < 24, "new landmark has a navigable route: " + str(destination))
	check(game.state.enemies.filter(func(e): return e.zone == "forest" and e.at[0] > 1920).size() == 12, "expanded territory contains twelve new enemies")
	var original_ids: Array = game.state.enemies.filter(func(e): return e.zone == "forest" and e.at[0] <= 1920).map(func(e): return e.id)
	game.state.enemies = game.state.enemies.filter(func(e): return e.zone != "forest" or e.at[0] <= 1920)
	game.state.prepare_enemies()
	check(game.state.enemies.filter(func(e): return e.zone == "forest" and e.at[0] > 1920).size() == 12, "old same-day saves populate expanded territory immediately")
	game.state.prepare_enemies()
	check(game.state.enemies.filter(func(e): return e.zone == "forest" and e.at[0] > 1920).size() == 12 and original_ids.all(func(id): return game.state.enemies.any(func(e): return e.id == id)), "re-entering does not duplicate encounters or reset old enemies")
	for e in game.state.enemies:
		if e.get("forest_extension", false): e.at[0] = 1850
	var before_chase: int = game.state.enemies.size()
	game.state.prepare_enemies()
	check(game.state.enemies.size() == before_chase, "chasing enemies across old map border cannot respawn their encounter")
	game.player.position = Vector2(2400, 1500)
	check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))), "expanded enemies and coordinates serialize")
	game.persist()
	var saved := FarmState.new()
	check(load("res://scripts/save_store.gd").load_game(saved) and saved.player_position == game.player.position, "real save file restores position beyond old map bounds")
	game.show_character("地图")
	await frames()
	await capture("redesign-map")
	print("Redesign: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
