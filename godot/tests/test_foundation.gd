extends SceneTree
var checks: int = 0
var failures: int = 0
var commits: int = 0
var ticks: int = 0
var dawns: int = 0
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
	var s := FarmState.new()
	var bag := YinInventoryModel.new(s, "bag")
	var chest := YinInventoryModel.new(s, "chest")
	check(bag.sync() and chest.sync() and bag.slots().size() == 24, "24-slot inventory resources")
	check(bag.move(0, bag, 10, 4), "split stack into empty slot")
	check(bag.slots()[0].count == 4 and bag.slots()[10].count == 4 and s.inventory.candle_seeds == 8, "splitting preserves item total")
	check(bag.move(10, chest, 0), "transfer to warehouse")
	check(s.inventory.candle_seeds == 4 and s.storage.candle_seeds == 4, "warehouse transfer applies ledger once")
	check(bag.move(1, chest, 0), "cross-container swap")
	check(s.inventory.candle_seeds == 8 and s.storage.vine_seeds == 5 and s.inventory.vine_seeds == 0, "swap conserves both item kinds")
	var previous: Dictionary = s.inventory.duplicate()
	check(not bag.move(-1, chest, 0) and s.inventory == previous, "invalid slot cannot destroy items")
	check(bag.compact(), "compact inventory")
	check(bag.slots()[0].count == 8, "compact merges split stacks")
	var full := FarmState.new()
	full.storage.oil = 99 * 24
	var full_chest := YinInventoryModel.new(full, "chest")
	check(full_chest.sync(), "warehouse can hold 24 full stacks")
	var oil_index: int = -1
	for i in range(24):
		if bag.slots()[i].id == "oil": oil_index = i
	check(not bag.move(oil_index, full_chest, 0, 1) and s.oil == 8 and full.storage.oil == 99 * 24, "full matching stack rejects transfer atomically")
	var restored := FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(s.snapshot()))) and restored.storage.vine_seeds == 5, "new warehouse and slot layout persist")
	var legacy: Dictionary = s.snapshot()
	legacy.version = 3
	for key in ["supplies", "storage", "bag_slots", "chest_slots", "terrain", "drops", "placements"]: legacy.erase(key)
	check(restored.restore(JSON.parse_string(JSON.stringify(legacy))) and restored.inventory.candle_seeds == 8, "v0.3 save migrates without crop or economic reset")
	var fsm := YinPlayerStateMachine.new()
	root.add_child(fsm)
	check(fsm.begin("tool", 0.25, func(): commits += 1), "action state begins")
	check(not fsm.begin("attack", 0.2) and commits == 1, "incompatible simultaneous action rejected")
	check(fsm.update(0.1, Vector2.RIGHT, false) == Vector2.ZERO, "tool action blocks movement")
	var remaining: float = fsm.action.remaining
	fsm.update(3, Vector2.RIGHT, true)
	check(fsm.action.remaining == remaining, "pause freezes action state")
	check(fsm.update(0.2, Vector2.RIGHT, false) == Vector2.RIGHT and fsm.current == "walk", "action returns to movement")
	var clock := YinGameClock.new()
	root.add_child(clock)
	clock.minute_changed.connect(func(_day, _hour, _minute): ticks += 1)
	clock.dawn.connect(func(_day): dawns += 1)
	clock.bind(FarmState.new())
	clock.advance(0.1, false)
	clock.advance(5, true)
	check(ticks == 1 and dawns == 1, "clock does not emit duplicate or paused minute events")
	clock.advance(0.3, false)
	check(ticks == 2, "clock emits minute change")
	clock.state.next_day()
	clock.publish()
	check(dawns == 2, "clock emits dawn after daily settlement")
	clock.bind(clock.state)
	check(dawns == 2, "same-day scene rebind does not duplicate dawn events")
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.close_modal()
	game.state = FarmState.new()
	game.build_zone("farm", Vector2(300, 350))
	await frames(3)
	check(game.world.tile_farm.ground is TileMapLayer and game.world.tile_farm.soil is TileMapLayer, "actual layered TileMap scene")
	check(game.world.plot_at(game.world.plot_center(7)) == 7 and game.world.plot_at(Vector2(100, 100)) == -1, "TileMap coordinate conversion")
	var foe_record: Dictionary = {"id": game.state.next_id, "kind": "water", "zone": "farm", "at": [337.0, 300.0], "hp": 100, "max_hp": 100, "integrity": 100, "suppressed": false, "dead": false}
	game.state.next_id += 1
	game.state.enemies.append(foe_record)
	var foe: YinEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
	foe.game = game
	foe.record = foe_record
	foe.position = Vector2(337, 300)
	game.world.actors.add_child(foe)
	game.player.position = Vector2(286, 300)
	game.player.hitbox.radius = 80
	await frames(3)
	check(game.player.hitbox.targets(Vector2.RIGHT).is_empty(), "physical melee cannot hit through fence")
	game.player.position = Vector2(286, 348)
	foe.position = Vector2(337, 348)
	await frames(3)
	check(game.player.hitbox.targets(Vector2.RIGHT).has(foe), "open gate permits physical melee target")
	var resource: YinTerrainResource = null
	for candidate in get_nodes_in_group("terrain_resources"):
		if candidate.is_inside_tree() and candidate.world == game.world and candidate.position == Vector2(83, 295): resource = candidate
	check(resource != null, "tree is reusable harvest component")
	game.player.position = Vector2(83, 322)
	game.player.facing = Vector2.UP
	game.tool = 4
	await frames(2)
	for i in range(3):
		game.action_cooldown = 0
		game.use_terrain()
		await frames(22)
	check(game.state.terrain["farm:83:295"].hp == 0 and game.state.drops.size() == 1, "tree depletion produces persistent loose loot")
	game.player.position = Vector2(83, 300)
	await frames(32)
	check(game.state.supplies.wood == 2 and game.state.drops.is_empty(), "actual proximity pickup into inventory")
	game.state.craft("paper_lamp")
	game.player.position = Vector2(240, 340)
	game.placement.selected = "paper_lamp"
	check(not game.placement.allowed(game.world.plot_center(0)), "building footprint rejects cultivated field")
	check(game.placement.place(Vector2(240, 368)) and game.state.supplies.paper_lamp == 0, "valid placement consumes one item")
	check(game.state.placements.size() == 1, "placed structure persisted in state")
	game.travel("hall")
	await frames(3)
	check(game.state.zone == "hall" and game.world.plot_at(Vector2(335, 270)) == -1, "separate hall interior")
	check(not game.world.is_safe_position(Vector2(150, 320)), "indoor drop positions cannot escape room walls")
	game.spawn_loot("stone", 1, Vector2(480, 600))
	check(game.world.is_safe_position(Vector2(game.state.drops[0].at[0], game.state.drops[0].at[1])), "unsafe drop redirected to accessible room location")
	game.player.position = Vector2(306, 380)
	check(game.world.nearest_interaction() == "storage", "warehouse world interaction")
	game.interact()
	await frames(2)
	check(game.modal != null and get_nodes_in_group("inventory_panels").size() == 1, "actual warehouse inventory UI")
	game.close_modal()
	game.travel("shop")
	await frames(3)
	check(game.state.zone == "shop" and game.world.is_safe_position(game.player.position), "shop interior has valid spawn")
	check(game.router.install("unknown", game.state) == null and game.router.current == game.world, "invalid scene transition preserves active level")
	game.travel("farm")
	await frames(3)
	check(game.state.terrain["farm:83:295"].hp == 0 and game.state.placements.size() == 1, "terrain depletion and building survive region reload")
	var data := YinDialogueData.new()
	data.speaker = "测试村民"
	data.lines.assign(["第一句", "第二句"])
	var dialogue := YinDialoguePanel.new()
	dialogue.data = data
	game.hud.add_child(dialogue)
	dialogue.advance()
	check(dialogue.index == 0 and dialogue.text_label.visible_characters == -1, "dialogue click reveals current line")
	dialogue.advance()
	check(dialogue.index == 1, "dialogue advances after reveal")
	game.queue_free()
	fsm.queue_free()
	clock.queue_free()
	await frames(3)
	print("Reference architecture: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
