class_name FarmState
extends RefCounted

const WIDTH = 8
const HEIGHT = 6
const CROPS = {
	"turnip": preload("res://resources/crops/turnip.tres"),
	"carrot": preload("res://resources/crops/carrot.tres"),
	"tomato": preload("res://resources/crops/tomato.tres")
}
var day: int = 1
var money: int = 120
var energy: int = 100
var seeds: int = 8
var harvest: int = 0
var inventory: Dictionary = {"carrot_seeds": 3, "tomato_seeds": 2, "carrot": 0, "tomato": 0}
var selected_crop: String = "turnip"
var plots: Array = []
var minutes: float = 360.0
var weather: String = "sun"
var total_harvest: int = 0
var quest_claimed: bool = false
var talked_day: int = 0
var player_position: Vector2 = Vector2(300, 350)
var saved_facing: Vector2 = Vector2.RIGHT

func _init() -> void:
	for i in range(WIDTH * HEIGHT):
		plots.append({"tilled": false, "crop": "", "growth": 0, "watered": false})

func seed_count(id: String) -> int:
	return seeds if id == "turnip" else int(inventory.get(id + "_seeds", 0))

func crop_count(id: String) -> int:
	return harvest if id == "turnip" else int(inventory.get(id, 0))

func use_tool(index: int, tool: int) -> String:
	if index < 0 or index >= plots.size():
		return "走近田地，对着田块使用工具。"
	var p: Dictionary = plots[index]
	if tool == 3:
		if p.crop == "" or p.growth < CROPS[p.crop].growth_days:
			return "还没成熟。按浇水天数生长，雨天自动浇水。"
		if p.crop == "turnip":
			harvest += 1
		else:
			inventory[p.crop] += 1
		total_harvest += 1
		var name_text: String = CROPS[p.crop].display_name
		p.crop = ""
		p.growth = 0
		p.watered = false
		return "收获 %s！带到小屋旁的出货箱出售。" % name_text
	if energy < 5:
		return "体力不足了，走到小屋门口按 E 休息。"
	match tool:
		0:
			if p.tilled:
				return "这块土已经翻好了。"
			p.tilled = true
		1:
			if not p.tilled or p.crop != "":
				return "请先翻土，再在空地播种。"
			if seed_count(selected_crop) < 1:
				return "种子不足，去桥边杂货铺补货。"
			if selected_crop == "turnip":
				seeds -= 1
			else:
				inventory[selected_crop + "_seeds"] -= 1
			p.crop = selected_crop
			p.watered = weather == "rain"
		2:
			if p.crop == "":
				return "空地不需要浇水。"
			if p.watered:
				return "今天已经浇过水啦。"
			p.watered = true
		_:
			return "请选择工具。"
	energy -= 5
	minutes = minf(1320, minutes + 3)
	return ["翻土完成，可以播种了。", "播下 %s，期待新生命。" % CROPS[selected_crop].display_name, "浇水完成，睡觉后作物会生长。"][tool]

func next_day() -> void:
	for p in plots:
		if p.crop != "" and p.watered:
			p.growth = mini(CROPS[p.crop].growth_days, p.growth + 1)
	day += 1
	energy = 100
	minutes = 360
	weather = "rain" if day % 4 == 0 else "sun"
	for p in plots:
		p.watered = p.crop != "" and weather == "rain"

func tick(delta: float) -> void:
	minutes = minf(1320, minutes + delta * 2)

func buy_seeds(id: String = "", count: int = 5) -> String:
	if id == "":
		id = selected_crop
	if not CROPS.has(id) or count < 1:
		return "无效商品。"
	var price: int = CROPS[id].seed_price * count
	if money < price:
		return "金币不足，需要 %d G。" % price
	money -= price
	if id == "turnip":
		seeds += count
	else:
		inventory[id + "_seeds"] += count
	return "买到了 %d 包%s种子。" % [count, CROPS[id].display_name]

func sell() -> String:
	var earned: int = 0
	for id in CROPS:
		earned += crop_count(id) * CROPS[id].sell_price
	if earned == 0:
		return "出货箱空空的，先去收获作物吧。"
	money += earned
	harvest = 0
	inventory.carrot = 0
	inventory.tomato = 0
	return "全部作物已出货，获得 %d G！" % earned

func talk() -> String:
	if total_harvest >= 3 and not quest_claimed:
		quest_claimed = true
		money += 100
		return "小禾：你已经收获了 3 颗作物！这是送你的 100 G。"
	if talked_day != day:
		talked_day = day
		return "小禾：欢迎回来！帮我收获 3 颗作物，我送你 100 G。"
	return "小禾：雨天不用浇水，晚上回小屋好好休息吧。"

func snapshot() -> Dictionary:
	return {"version": 2, "day": day, "money": money, "energy": energy, "seeds": seeds, "harvest": harvest, "plots": plots.duplicate(true), "inventory": inventory.duplicate(), "selected_crop": selected_crop, "minutes": minutes, "weather": weather, "total_harvest": total_harvest, "quest_claimed": quest_claimed, "talked_day": talked_day, "player_position": [player_position.x, player_position.y], "facing": [saved_facing.x, saved_facing.y]}

static func valid_int(value: Variant, minimum: int, maximum: int = 100000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

func restore(data: Dictionary) -> bool:
	var version: Variant = data.get("version")
	if version != 1 and version != 2:
		return false
	if not data.get("plots") is Array or data.plots.size() != (24 if version == 1 else WIDTH * HEIGHT):
		return false
	for key in ["day", "money", "energy", "seeds", "harvest"]:
		if not valid_int(data.get(key), 1 if key == "day" else 0, 100 if key == "energy" else 100000000):
			return false
	var checked_plots: Array = []
	for p in data.plots:
		if not p is Dictionary or not p.get("tilled") is bool or not p.get("watered") is bool:
			return false
		var crop: Variant = p.get("crop")
		if version == 1:
			if not crop is bool:
				return false
			crop = "turnip" if crop else ""
		if not crop is String or (crop != "" and not CROPS.has(crop)):
			return false
		if crop != "" and not p.tilled:
			return false
		var growth_max: int = CROPS[crop].growth_days if crop != "" else 0
		if not valid_int(p.get("growth"), 0, growth_max):
			return false
		checked_plots.append({"tilled": p.tilled, "watered": p.watered, "crop": crop, "growth": int(p.growth)})
	var checked_inventory: Dictionary = {"carrot_seeds": 3, "tomato_seeds": 2, "carrot": 0, "tomato": 0}
	var checked_position := Vector2(300, 350)
	var checked_facing := Vector2.DOWN
	if version == 2:
		if not data.get("inventory") is Dictionary:
			return false
		for key in checked_inventory:
			if not valid_int(data.inventory.get(key), 0):
				return false
			checked_inventory[key] = int(data.inventory[key])
		if not data.get("selected_crop") is String or not CROPS.has(data.selected_crop):
			return false
		if not data.get("minutes") is float and not data.get("minutes") is int:
			return false
		if not is_finite(float(data.minutes)) or data.minutes < 360 or data.minutes > 1320:
			return false
		if data.get("weather") not in ["sun", "rain"] or not data.get("quest_claimed") is bool:
			return false
		if not valid_int(data.get("total_harvest"), 0) or not valid_int(data.get("talked_day"), 0):
			return false
		for key in ["player_position", "facing"]:
			if not data.get(key) is Array or data[key].size() != 2:
				return false
			for value in data[key]:
				if (not value is int and not value is float) or not is_finite(float(value)):
					return false
		checked_position = Vector2(data.player_position[0], data.player_position[1])
		if checked_position.x < 16 or checked_position.x > 944 or checked_position.y < 16 or checked_position.y > 624:
			return false
		checked_facing = Vector2(data.facing[0], data.facing[1])
		if checked_facing not in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
			return false
	day = int(data.day)
	money = int(data.money)
	energy = int(data.energy)
	seeds = int(data.seeds)
	harvest = int(data.harvest)
	inventory = checked_inventory
	selected_crop = data.get("selected_crop", "turnip")
	minutes = float(data.get("minutes", 360))
	weather = data.get("weather", "sun")
	total_harvest = int(data.get("total_harvest", 0))
	quest_claimed = data.get("quest_claimed", false)
	talked_day = int(data.get("talked_day", 0))
	player_position = checked_position
	saved_facing = checked_facing
	plots = checked_plots
	while plots.size() < WIDTH * HEIGHT:
		plots.append({"tilled": false, "crop": "", "growth": 0, "watered": false})
	return true
