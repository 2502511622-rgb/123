extends SceneTree
const SaveStore = preload("res://scripts/save_store.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + text)

func corpse(s: FarmState, kind: String = "water", integrity: int = 100, fierceness: int = 20) -> int:
	var id: int = s.next_id
	s.next_id += 1
	s.remains.append({"id": id, "kind": kind, "name": "测试遗骸", "integrity": integrity, "regret": "生前担水", "fierceness": fierceness, "yin": "水阴", "at": [300.0, 300.0], "zone": "graveyard"})
	return id

func _initialize() -> void:
	var s := FarmState.new()
	check(s.plots.size() == 48 and s.day == 1, "starting farm")
	s.use_tool(0, 1)
	check(s.seed_count("candle") == 8 and s.energy == 100, "planting requires tilled earth")
	for id in FarmState.CROPS:
		var crop := FarmState.new()
		crop.selected_crop = id
		crop.use_tool(0, 0)
		crop.use_tool(0, 1)
		check(crop.plots[0].crop == id, id + " plants")
		crop.next_day()
		check(crop.plots[0].growth == 0, id + " dry crop does not grow")
		for i in range(FarmState.CROPS[id].growth_days):
			crop.use_tool(0, 2)
			var energy: int = crop.energy
			crop.use_tool(0, 2)
			check(crop.energy == energy, "watering twice does not cost")
			crop.next_day()
		if id == "rice":
			crop.use_tool(0, 3)
			check(crop.crop_count(id) == 0, "unsealed forbidden crop cannot be harvested")
			crop.seal_plot(0)
		crop.use_tool(0, 3)
		check(crop.crop_count(id) == 1, id + " harvested")
		crop.sell()
		check(crop.money == 90 + FarmState.CROPS[id].sell_price, id + " economy")
	var forbidden := FarmState.new()
	forbidden.plots[0].crop = "rice"
	forbidden.plots[0].tilled = true
	forbidden.plots[0].growth = 2
	forbidden.next_day()
	check(forbidden.pollution == 4, "forbidden crop pollution has visible rule")
	forbidden.seal_plot(0)
	var pollution_before: int = forbidden.pollution
	forbidden.next_day()
	check(forbidden.pollution == pollution_before, "seal stops forbidden pollution")
	var water := FarmState.new()
	water.spirits.append(water.make_spirit("water", 20))
	water.spirits[0].job = "water"
	water.use_tool(0, 0)
	water.use_tool(0, 1)
	water.rollcall()
	var risk: int = water.spirits[0].risk
	water.rollcall()
	check(water.spirits[0].risk == risk, "rollcall cannot be spammed")
	water.next_day()
	check(water.plots[0].growth == 1 and water.oil == 7, "water spirit irrigates and consumes upkeep")
	check(water.spirits[0].affinity == 10, "appropriate job raises affinity")
	var lost := FarmState.new()
	lost.spirits.append(lost.make_spirit("bone", 30))
	lost.oil = 0
	lost.next_day()
	check(lost.spirits.is_empty() and lost.pollution == 15, "missed name and supply cause predictable disappearance")
	var gourd := FarmState.new()
	gourd.plots[0].crop = "gourd"
	gourd.plots[0].tilled = true
	gourd.plots[0].growth = 4
	gourd.plots[0].branch = "light"
	gourd.release_gourd(0)
	check(gourd.spirits.size() == 1 and gourd.spirits[0].name == "提灯童", "gourd branch creates spirit")
	check(gourd.plots[0].crop == "", "gourd release cannot repeat")
	check(gourd.preferred_job(gourd.spirits[0]) == "guard", "lantern child's fitting work")
	var remains := FarmState.new()
	var r1: int = corpse(remains)
	var r2: int = corpse(remains, "bone", 100, 20)
	var r3: int = corpse(remains)
	remains.pickup(r1)
	remains.pickup(r2)
	remains.pickup(r3)
	check(remains.cargo.size() == 2 and remains.find_remains(r3).zone == "graveyard", "cart capacity and ground persistence")
	remains.process_remains(r1, "refine")
	check(remains.spirits.size() == 1 and remains.oil == 6 and remains.cargo.size() == 1, "transported remains refined")
	remains.process_remains(r2, "dismantle")
	check(remains.bones == 2 and remains.ash == 1, "dismantle material output")
	remains.process_remains(r3, "release")
	check(remains.reputation == 1 and remains.money == 102 and remains.find_remains(r3).is_empty(), "exorcism exchanges material for story and reputation")
	var burnt: int = corpse(remains, "water", 30)
	remains.process_remains(burnt, "refine")
	check(not remains.find_remains(burnt).is_empty() and remains.spirits.size() == 1, "burnt remains cannot form complete spirit")
	remains.process_remains(burnt, "bury", 5)
	check(remains.plots[5].yin == 1 and remains.pollution > 0, "burial modifies land with known cost")
	remains.bones = 3
	remains.money = 80
	remains.craft("hall")
	check(remains.capacity() == 3 and remains.bones == 0 and remains.money == 0, "hall expansion capacity")
	var rites := FarmState.new()
	rites.day = 6
	rites.inventory.candle = 2
	rites.ritual("earth")
	check(rites.ritual_count == 1 and rites.oil == 6 and rites.ward == 85, "ritual preview matches cost and benefit")
	var oil: int = rites.oil
	rites.ritual("earth")
	check(rites.oil == oil, "single ritual cannot repeat")
	rites.minutes = 1080
	check(rites.maybe_boss() and not rites.maybe_boss(), "ritual triggers exactly one boss")
	var low := FarmState.new()
	low.day = 9
	low.minutes = 1080
	check(low.maybe_boss(), "low ritual route still has ninth-night boss")
	low.kill_enemy(low.enemies[0].id, Vector2(250, 300))
	check(low.boss_defeated and low.remains.size() == 1, "boss death leaves actual remains")
	low.day = 10
	low.choose_ending("coexist")
	check(low.ending == "coexist", "tenth-day story choice")
	var saved := FarmState.new()
	saved.prepare_enemies()
	var id: int = corpse(saved)
	saved.pickup(id)
	saved.spirits.append(saved.make_spirit("water", 20))
	var restored := FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(saved.snapshot()))), "complete JSON roundtrip")
	check(restored.cargo == saved.cargo and restored.remains == saved.remains and restored.spirits == saved.spirits, "cargo, ground remains and spirits persist")
	var bad: Dictionary = saved.snapshot()
	bad.saved_facing = []
	check(not restored.restore(bad), "invalid direction rejected without crash")
	bad = saved.snapshot()
	bad.enemies[0].hp = -1
	check(not restored.restore(bad), "invalid enemy data rejected")
	bad = saved.snapshot()
	bad.spirits[0].kind = "unknown"
	check(not restored.restore(bad), "unknown spirit rejected")
	bad = saved.snapshot()
	bad.cargo = [99999]
	check(not restored.restore(bad), "dangling cart reference rejected")
	check(restored.cargo == saved.cargo, "failed restore stays atomic")
	check(SaveStore.save_game(saved), "file save")
	check(SaveStore.load_game(restored) and restored.snapshot() == saved.snapshot(), "disk roundtrip")
	var loaded_id: int = restored.cargo[0]
	restored.process_remains(loaded_id, "dismantle")
	check(restored.cargo.is_empty() and restored.find_remains(loaded_id).is_empty(), "loaded numeric cart IDs can be consumed without dangling references")
	var ten_days := FarmState.new()
	for i in range(9): ten_days.next_day()
	check(ten_days.day == 10 and ten_days.journal.any(func(line): return "最后一页" in line), "ten-day narrative advances")
	print("Yintian rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
