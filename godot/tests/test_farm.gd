extends SceneTree
const SaveStore = preload("res://scripts/save_store.gd")
var failures: int = 0
var checks: int = 0
func check(condition: bool, name_text: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + name_text)

func _initialize() -> void:
	var s := FarmState.new()
	check(s.plots.size() == 48, "48 plots")
	s.use_tool(0, 1)
	check(s.seeds == 8 and s.energy == 100, "cannot plant grass")
	s.use_tool(0, 0)
	s.use_tool(0, 1)
	check(s.seeds == 7 and s.energy == 90, "hoe and plant costs")
	s.next_day()
	check(s.plots[0].growth == 0, "dry crop does not grow")
	for i in range(3):
		s.use_tool(0, 2)
		var energy_before: int = s.energy
		s.use_tool(0, 2)
		check(s.energy == energy_before, "duplicate watering has no cost")
		s.next_day()
	check(s.plots[0].growth == 3, "turnip matures after three watered days")
	s.use_tool(0, 3)
	check(s.harvest == 1 and s.plots[0].crop == "", "harvest resets plot")
	s.sell()
	check(s.money == 155 and s.harvest == 0, "turnip sells for 35")
	s.buy_seeds()
	check(s.money == 115 and s.seeds == 12, "seed purchase")
	s.money = 0
	var old_count: int = s.seeds
	s.buy_seeds()
	check(s.seeds == old_count and s.money == 0, "insufficient money")
	s.energy = 0
	s.use_tool(1, 0)
	check(not s.plots[1].tilled, "no energy blocks work")
	s.use_tool(-1, 0)
	s.use_tool(99, 0)
	check(s.energy == 0, "out of range tool input")
	for id in FarmState.CROPS:
		var crop := FarmState.new()
		crop.selected_crop = id
		crop.use_tool(0, 0)
		crop.use_tool(0, 1)
		check(crop.plots[0].crop == id, "%s planting" % id)
		for i in range(FarmState.CROPS[id].growth_days):
			crop.use_tool(0, 2)
			crop.next_day()
		crop.use_tool(0, 3)
		check(crop.crop_count(id) == 1, "%s harvest" % id)
		crop.sell()
		check(crop.money == 120 + FarmState.CROPS[id].sell_price, "%s sale" % id)
	var rain := FarmState.new()
	rain.day = 3
	rain.use_tool(0, 0)
	rain.use_tool(0, 1)
	rain.next_day()
	check(rain.weather == "rain" and rain.plots[0].watered, "rain waters existing plants")
	rain.use_tool(1, 0)
	rain.use_tool(1, 1)
	check(rain.plots[1].watered, "rain waters newly planted crops")
	rain.next_day()
	check(rain.plots[0].growth == 1 and not rain.plots[0].watered, "rain growth and watering reset")
	var quest := FarmState.new()
	quest.total_harvest = 3
	quest.talk()
	quest.talk()
	check(quest.money == 220 and quest.quest_claimed, "quest grants reward only once")
	var source := FarmState.new()
	source.selected_crop = "tomato"
	source.player_position = Vector2(444, 300)
	source.saved_facing = Vector2.LEFT
	source.use_tool(3, 0)
	source.use_tool(3, 1)
	var restored := FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(source.snapshot()))), "JSON save restores")
	check(restored.player_position == source.player_position and restored.selected_crop == "tomato", "position and selected seed restore")
	check(restored.plots[3].crop == "tomato", "crop kind restores")
	var invalid: Dictionary = source.snapshot()
	invalid.inventory.carrot = -1
	check(not restored.restore(invalid), "negative inventory rejected")
	invalid = source.snapshot()
	invalid.energy = 101
	check(not restored.restore(invalid), "energy out of bounds rejected")
	invalid = source.snapshot()
	invalid.plots[0].crop = "unknown"
	check(not restored.restore(invalid), "unknown crop rejected")
	invalid = source.snapshot()
	invalid.player_position = [650, INF]
	check(not restored.restore(invalid), "nonfinite position rejected")
	invalid = source.snapshot()
	invalid.money = 1.2
	check(not restored.restore(invalid), "fractional money rejected")
	check(restored.plots[3].crop == "tomato", "failed restore is atomic")
	var legacy: Dictionary = {"version": 1, "day": 3, "money": 140, "energy": 90, "seeds": 4, "harvest": 1, "plots": []}
	for i in range(24):
		legacy.plots.append({"tilled": i == 0, "crop": i == 0, "growth": 2 if i == 0 else 0, "watered": false})
	check(restored.restore(legacy), "v1 save migration")
	check(restored.plots.size() == 48 and restored.plots[0].crop == "turnip" and restored.money == 140, "migration preserves old crops and economy")
	check(SaveStore.save_game(source), "atomic file save")
	var disk := FarmState.new()
	check(SaveStore.load_game(disk), "file load")
	check(disk.snapshot() == source.snapshot(), "disk save roundtrip")
	print("Farm rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
