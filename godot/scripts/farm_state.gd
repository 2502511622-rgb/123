class_name FarmState
extends RefCounted

var day: int = 1
var money: int = 120
var energy: int = 100
var seeds: int = 8
var harvest: int = 0
var plots: Array = []

func _init() -> void:
	for i in range(24):
		plots.append({"tilled": false, "crop": false, "growth": 0, "watered": false})

func use_tool(index: int, tool: int) -> String:
	if index < 0 or index >= plots.size():
		return "请选择田块。"
	var p: Dictionary = plots[index]
	if tool == 3:
		if not p.crop or p.growth < 3:
			return "还没成熟，请每天浇水。"
		harvest += 1
		p.crop = false
		p.growth = 0
		p.watered = false
		return "收获了一颗小萝卜！"
	if energy < 5:
		return "体力不足，回小屋休息吧。"
	match tool:
		0:
			if p.tilled:
				return "已经翻过土啦。"
			p.tilled = true
		1:
			if not p.tilled or p.crop:
				return "请先翻土，再在空地播种。"
			if seeds < 1:
				return "种子不足，去商店购买吧。"
			seeds -= 1
			p.crop = true
		2:
			if not p.crop or p.watered:
				return "这里无需浇水。"
			p.watered = true
		_:
			return "未知工具。"
	energy -= 5
	return ["土地准备好了。", "播下了一颗种子。", "浇水完成，明天会生长。 "][tool]

func next_day() -> void:
	day += 1
	energy = 100
	for p in plots:
		if p.crop and p.watered:
			p.growth = mini(3, p.growth + 1)
		p.watered = false

func buy_seeds() -> String:
	if money < 40:
		return "金币不足，需要 40 G。"
	money -= 40
	seeds += 5
	return "购买了 5 包种子。"

func sell() -> String:
	if harvest == 0:
		return "还没有可出货的作物。"
	var earned: int = harvest * 35
	money += earned
	harvest = 0
	return "出货获得 %d G！" % earned

func snapshot() -> Dictionary:
	return {"version": 1, "day": day, "money": money, "energy": energy, "seeds": seeds, "harvest": harvest, "plots": plots}

func restore(data: Dictionary) -> bool:
	if data.get("version") != 1 or not data.get("plots") is Array or data.plots.size() != 24:
		return false
	for key in ["day", "money", "energy", "seeds", "harvest"]:
		if not data.get(key) is float and not data.get(key) is int:
			return false
		if data[key] < 0:
			return false
	for p in data.plots:
		if not p is Dictionary or not p.get("tilled") is bool or not p.get("crop") is bool or not p.get("watered") is bool:
			return false
		if not p.get("growth") is float and not p.get("growth") is int:
			return false
		if p.growth < 0 or p.growth > 3:
			return false
	day = int(data.day)
	money = int(data.money)
	energy = int(data.energy)
	seeds = int(data.seeds)
	harvest = int(data.harvest)
	plots = data.plots.duplicate(true)
	return true
