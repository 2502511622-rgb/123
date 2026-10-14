class_name FarmState
extends RefCounted
# Pure game rules. All rites and spirit mechanics are fictional resource systems.
const WIDTH = 8
const HEIGHT = 6
const CROPS = {
	"candle": preload("res://resources/crops/candle.tres"),
	"vine": preload("res://resources/crops/vine.tres"),
	"gourd": preload("res://resources/crops/gourd.tres"),
	"rice": preload("res://resources/crops/rice.tres")
}
const SPIRITS = {"water": "担水尸", "bone": "掘土骨", "child": "食秽童"}
const INVENTORY_KEYS = ["candle_seeds", "vine_seeds", "gourd_seeds", "rice_seeds", "candle", "vine", "gourd", "rice"]
var day: int = 1
var money: int = 90
var energy: int = 100
var health: int = 100
var minutes: float = 360
var weather: String = "sun"
var selected_crop: String = "candle"
var inventory: Dictionary = {"candle_seeds": 8, "vine_seeds": 5, "gourd_seeds": 2, "rice_seeds": 1, "candle": 0, "vine": 0, "gourd": 0, "rice": 0}
var supplies: Dictionary = {"wood": 0, "stone": 0, "paper_lamp": 0, "ward_stake": 0, "light_ammo": 36, "rifle_ammo": 0, "scrap": 0}
var equipment: Array = [YinBalance.make_gear(1, "sword"), YinBalance.make_gear(2, "pistol")]
var gear_drops: Array = []
var equipped_gear: int = 1
var equipped_armor: int = 0
var next_gear_id: int = 3
var smart_farming: bool = true
var storage: Dictionary = {}
var bag_slots: Array = []
var chest_slots: Array = []
var terrain: Dictionary = {}
var drops: Array = []
var placements: Array = []
var plots: Array = []
var oil: int = 8
var talismans: int = 6
var bones: int = 0
var ash: int = 0
var reputation: int = 0
var cultivation: int = 0
var pollution: int = 0
var ward: int = 60
var hall_level: int = 1
var spirits: Array = []
var remains: Array = []
var cargo: Array = []
var enemies: Array = []
var enemy_day: int = 0
var next_id: int = 1
var total_harvest: int = 0
var called_day: int = 0
var ritual_count: int = 0
var ritual_path: String = ""
var boss_spawned: bool = false
var boss_defeated: bool = false
var ending: String = ""
var intro_seen: bool = false
var player_position := Vector2(300, 350)
var saved_facing := Vector2.RIGHT
var zone: String = "farm"
var journal: Array = ["师父遗书：田里长出人声，不要答应。驱使的东西，每夜都要点名。祠堂里的神，不是祖宗。"]
var last_report: String = ""
var order: String = "follow"

func _init() -> void:
	for id in YinItemCatalog.IDS: storage[id] = 0
	for i in range(WIDTH * HEIGHT):
		plots.append({"tilled": false, "crop": "", "growth": 0, "watered": false, "yin": 0, "sealed": false, "branch": "eat"})

func add_log(text: String) -> void:
	journal.append("第 %d 日：%s" % [day, text])
	while journal.size() > 24:
		journal.pop_front()

func seed_count(id: String) -> int:
	return int(inventory.get(id + "_seeds", 0))

func crop_count(id: String) -> int:
	return int(inventory.get(id, 0))

func use_tool(index: int, tool: int) -> String:
	if index < 0 or index >= plots.size():
		return "走近灵田，对着田块使用工具。"
	var p: Dictionary = plots[index]
	if tool == 3:
		if p.crop == "" or p.growth < CROPS[p.crop].growth_days:
			return "未成熟。每日浇灌后，睡觉推进生长。"
		if p.crop == "rice" and not p.sealed:
			return "稻穗传来师父的声音。不要答应：靠近按 E，以一张符封声。"
		if not can_gain(p.crop, 1): return "行囊已满，先去仓箱存放物品。"
		inventory[p.crop] += 1
		total_harvest += 1
		var crop_name: String = CROPS[p.crop].display_name
		p.crop = ""
		p.growth = 0
		p.watered = false
		p.sealed = false
		return "收获 %s，去义庄旁的货箱交易。" % crop_name
	if energy < 4:
		return "气力耗尽，回义庄休息。"
	match tool:
		0:
			if p.tilled:
				return "土地已翻好。"
			p.tilled = true
		1:
			if not p.tilled or p.crop != "":
				return "先翻土，在空地播种。"
			if seed_count(selected_crop) < 1:
				return "种子不足，到槐阴村杂货铺补货。"
			inventory[selected_crop + "_seeds"] -= 1
			p.crop = selected_crop
			p.watered = weather == "rain"
			p.sealed = false
			p.branch = "eat"
		2:
			if p.crop == "" or p.watered:
				return "这块田无需浇水。"
			p.watered = true
		_:
			return "选择一种工具。"
	energy -= 4
	minutes = minf(1439, minutes + 2)
	return ["土下隐约有叩门声。翻土完成。", "播下 %s。" % CROPS[selected_crop].display_name, "浇灌完成。"][tool]

func seal_plot(index: int) -> String:
	if index < 0 or index >= plots.size() or plots[index].crop != "rice":
		return "没有需要封声的禁种。"
	if plots[index].sealed:
		return "这一株已封声。"
	if talismans < 1:
		return "需要一张符箓，在义庄用阴灰制作。"
	talismans -= 1
	plots[index].sealed = true
	pollution = maxi(0, pollution - 5)
	return "符纸贴上稻穗，声音停了。现在可以安全收获。"

func capacity() -> int:
	return 2 if hall_level == 1 else 3

func release_gourd(index: int) -> String:
	if spirits.size() >= capacity():
		return "安置位不足，先扩建义庄。"
	if index < 0 or index >= plots.size():
		return "没有葫芦。"
	var p: Dictionary = plots[index]
	if p.crop != "gourd" or p.growth < CROPS.gourd.growth_days:
		return "童影葫芦尚未成熟。"
	var spirit: Dictionary = make_spirit("child", int(p.yin) * 2, p.branch)
	spirits.append(spirit)
	p.crop = ""
	p.growth = 0
	p.watered = false
	add_log("葫芦破壳，%s记住了你的声音。" % spirit.name)
	return "%s诞生。每夜点名，每日供养一份灯油。" % spirit.name

func make_spirit(kind: String, risk: int, branch: String = "eat") -> Dictionary:
	var spirit_name: String = SPIRITS.get(kind, "无名役灵")
	if kind == "child":
		spirit_name = {"eat": "食秽童", "light": "提灯童", "shadow": "伏影童"}.get(branch, "食秽童")
	var spirit: Dictionary = {"id": next_id, "kind": kind, "name": spirit_name, "branch": branch, "job": "rest", "risk": clampi(risk, 0, 90), "affinity": 0, "level": 1}
	next_id += 1
	return spirit

func rollcall() -> String:
	if called_day == day: return "今天已点名，役灵不会重复降低怨气。"
	called_day = day
	for s in spirits:
		s.risk = maxi(0, s.risk - 8)
	var names: String = "、".join(spirits.map(func(s): return s.name))
	add_log("点名：%s。门外多响了一声，但你没有应答。" % (names if names != "" else "无人"))
	return "已点名 %d 位役灵。每夜睡前再点一次。" % spirits.size()

func next_day() -> void:
	var report: Array[String] = []
	var kept: Array = []
	for s in spirits:
		if called_day != day:
			s.risk += 20
		if oil > 0:
			oil -= 1
		else:
			s.risk += 25
			continue_spirit_warning(report, s.name)
		var fits: bool = s.job == preferred_job(s)
		if fits:
			s.affinity = mini(100, s.affinity + 10)
			s.risk = maxi(0, s.risk - 3)
		elif s.job not in ["rest", "guard"]:
			s.risk += 8
		if s.risk >= 60:
			pollution = mini(100, pollution + 15)
			report.append(s.name + "未应点名，安置位空了。")
			continue
		kept.append(s)
		if s.job == "water" and s.kind == "water":
			for p in plots:
				if p.crop != "": p.watered = true
		elif s.job == "dig" and s.kind == "bone":
			var dug: int = 0
			for p in plots:
				if not p.tilled and dug < 3:
					p.tilled = true
					dug += 1
		elif s.job == "clean" and s.kind == "child":
			pollution = maxi(0, pollution - (10 if s.branch == "eat" else 5))
		elif s.job == "guard":
			ward = mini(100, ward + (8 if s.kind == "child" and s.branch == "light" else 3))
	spirits = kept
	for p in plots:
		if p.crop != "" and p.watered:
			p.growth = mini(CROPS[p.crop].growth_days, p.growth + 1)
		if p.crop == "rice" and p.growth >= 2 and not p.sealed:
			pollution = mini(100, pollution + 4)
			if not report.has("返魂稻开始叫你的名字。封声符可以阻止污染。"):
				report.append("返魂稻开始叫你的名字。封声符可以阻止污染。")
	day += 1
	energy = 100
	health = mini(100, health + 45)
	minutes = 360
	weather = "rain" if day % 4 == 0 else "sun"
	for p in plots:
		p.watered = p.crop != "" and weather == "rain"
	ward = maxi(0, ward - 5 - int(pollution / 20))
	last_report = " / ".join(report) if not report.is_empty() else "天亮了。田里留下了一行朝向义庄的脚印。"
	add_log(last_report)
	if day <= 10:
		add_log(story_line())

func preferred_job(s: Dictionary) -> String:
	if s.kind == "water": return "water"
	if s.kind == "bone": return "dig"
	return "guard" if s.branch == "light" else "clean"

func continue_spirit_warning(report: Array[String], spirit_name: String) -> void:
	report.append(spirit_name + "没有领到供养，怨气 +25。")

func story_line() -> String:
	return ["", "师父将义庄与三亩荒田留给了你。", "井里传出担水声。桥边阿婆说：这是它生前的差事。", "棺盖内侧有师父刻下的阵图。炼骸前先看完整度。", "雨中铜钱藤的果实同时朝祠堂转去。", "祠堂祭帖写着你的名字，今年祭司已经选定。", "义庄的阵线松了。修阵、点名，也可以预览虚构祭祀的收益。", "田里说话的声音越来越像师父。不要答应。", "阿婆承认：灵田既是封印，也是地下之物的食盆。", "无论是否祭祀，今夜棺中客都将叩门。守住义庄。", "师父的最后一页：镇住它，或为共处立下新的契约。"] [mini(day, 10)]

func tick(delta: float) -> void:
	minutes = minf(1440, minutes + delta * 4)

func buy_seeds(id: String = "", count: int = 5) -> String:
	if id == "": id = selected_crop
	if not CROPS.has(id) or count < 1: return "无效商品。"
	var price: int = CROPS[id].seed_price * count
	if money < price: return "铜钱不足，需要 %d 文。" % price
	if not can_gain(id + "_seeds", count): return "行囊已满，无法购买。"
	money -= price
	inventory[id + "_seeds"] += count
	return "买到 %d 包%s种子。" % [count, CROPS[id].display_name]

func sell() -> String:
	var earned: int = 0
	for id in CROPS:
		earned += crop_count(id) * CROPS[id].sell_price
		inventory[id] = 0
	money += earned
	return "灵物换得 %d 文。" % earned if earned > 0 else "货箱里还没有灵物。"

func craft(which: String) -> String:
	match which:
		"oil":
			if not can_gain("oil", 4): return "行囊已满。"
			if inventory.candle < 1: return "需要 1 份烛穗。"
			inventory.candle -= 1
			oil += 4
			return "烛穗炼成 4 份灯油。"
		"talisman":
			if not can_gain("talisman", 3): return "行囊已满。"
			if ash < 1 and money < 12: return "需要 1 阴灰，或购买符纸花费 12 文。"
			if ash > 0: ash -= 1
			else: money -= 12
			talismans += 3
			return "制成 3 张镇符。"
		"ward":
			if bones < 1 or oil < 1: return "修阵需要 1 骨料与 1 灯油。"
			bones -= 1
			oil -= 1
			ward = mini(100, ward + 30)
			return "阵线加固，镇守 +30。"
		"paper_lamp":
			if supplies.wood < 2 or oil < 1: return "纸灯需要 2 槐木与 1 灯油。"
			if not can_gain("paper_lamp", 1): return "行囊已满。"
			supplies.wood -= 2
			oil -= 1
			supplies.paper_lamp += 1
			return "制成纸灯，打开行囊选中后放置。"
		"ward_stake":
			if bones < 1 or supplies.stone < 1: return "阵桩需要 1 骨料与 1 青石。"
			if not can_gain("ward_stake", 1): return "行囊已满。"
			bones -= 1
			supplies.stone -= 1
			supplies.ward_stake += 1
			return "制成阵桩，院落放置后镇守 +5。"
		"hall":
			if hall_level >= 2: return "第一版的义庄已扩建到最高级。"
			if bones < 3 or money < 80: return "扩建需要 3 骨料与 80 文。"
			bones -= 3
			money -= 80
			hall_level = 2
			return "停尸棚扩建，安置位由 2 增至 3。"
	return "未知配方。"

func prepare_enemies() -> void:
	if enemy_day == day: return
	enemy_day = day
	enemies = enemies.filter(func(e): return e.zone == "farm" and not e.dead)
	for i in range(5):
		var kind: String = "water" if i % 2 == 0 else "bone"
		spawn_record(kind, "graveyard", Vector2(280 + i * 100, 240 + (i % 2) * 150), 1 + int((day - 1) / 4))
	if day >= 3:
		spawn_record("archer", "graveyard", Vector2(730, 425), 2)
		spawn_record("lantern", "graveyard", Vector2(820, 290), 2)
	for i in range(16):
		var kind: String = ["archer", "lantern", "gunner", "brute"][i % 4]
		var at := Vector2(480 + (i % 4) * 360, 240 + int(i / 4) * 240)
		spawn_record(kind, "forest", at, 2 + int(i / 8) + int((day - 1) / 4), i in [6, 15])

func spawn_record(kind: String, zone_name: String, at: Vector2, level_value: int, elite: bool = false) -> Dictionary:
	var stats: Dictionary = YinBalance.enemy(kind, level_value, elite)
	var record: Dictionary = {"id": next_id, "kind": kind, "zone": zone_name, "at": [at.x, at.y], "hp": stats.hp, "max_hp": stats.hp, "integrity": 100, "suppressed": false, "dead": false}
	record.merge(stats)
	enemies.append(record)
	next_id += 1
	return record

func kill_enemy(id: int, at: Vector2) -> void:
	for e in enemies:
		if e.id != id or e.dead: continue
		e.dead = true
		var boss: bool = e.kind == "boss"
		remains.append({"id": next_id, "kind": e.kind, "name": "棺将遗骸" if boss else ("担水尸骸" if e.kind == "water" else YinBalance.MONSTERS[e.kind].name + "遗骸"), "integrity": e.integrity, "regret": "守门" if boss else ("生前担水" if e.kind == "water" else {"bone": "替人掘墓", "archer": "守山残念", "lantern": "不肯熄灭的旧灯", "gunner": "未传到的军令", "brute": "山中猎食"}.get(e.kind, "未散残念")), "fierceness": 50 if boss else (12 if e.suppressed else 30), "yin": "山煞" if boss else ("水阴" if e.kind == "water" else "土阴"), "at": [at.x, at.y], "zone": e.zone})
		next_id += 1
		cultivation += (8 * int(e.get("level", 1))) if not boss else 30
		reward_enemy(e, at)
		if boss:
			boss_defeated = true
			add_log("棺中客倒下。它的棺盖内刻着与你师父相同的名字。")
		return

func find_remains(id: int) -> Dictionary:
	for r in remains:
		if r.id == id: return r
	return {}

func pickup(id: int) -> String:
	if cargo.size() >= 2: return "运输车最多装 2 具，先带回义庄。"
	var r: Dictionary = find_remains(id)
	if r.is_empty(): return "遗骸已不在这里。"
	r.zone = "cargo"
	cargo.append(id)
	return "装上运输车，移速降低。稀有遗骸会引来追踪者。"

func process_remains(id: int, method: String, plot_index: int = -1) -> String:
	var r: Dictionary = find_remains(id)
	if r.is_empty(): return "没有这具遗骸。"
	match method:
		"refine":
			if r.kind not in ["water", "bone"]: return "此类遗骸尚不可收役，可拆解、埋田或超度。"
			if r.integrity < 60: return "完整度不足 60，不能炼成完整役灵。"
			if spirits.size() >= capacity(): return "安置位不足。可先扩建或选择其他用途。"
			if oil < 2: return "炼化需要 2 灯油。"
			oil -= 2
			spirits.append(make_spirit(r.kind, r.fierceness))
		"dismantle":
			if not can_gain_many({"bone": 2 if r.integrity >= 60 else 1, "ash": 2 if r.kind == "boss" else 1}): return "行囊已满，遗骸保持原状。"
			bones += 2 if r.integrity >= 60 else 1
			ash += 2 if r.kind == "boss" else 1
		"bury":
			if plot_index < 0 or plot_index >= plots.size(): return "请指定一块空灵田。"
			if plots[plot_index].crop != "": return "已有作物，不能埋入遗骸。"
			plots[plot_index].tilled = true
			plots[plot_index].yin += 1
			pollution = mini(100, pollution + int(r.fierceness / 5))
		"release":
			reputation += 1
			pollution = maxi(0, pollution - 8)
			money += 12
			add_log(r.regret + "：祠堂供的是一位不曾入谱的客人。")
		_:
			return "未知处理方式。"
	cargo.erase(id)
	remains.erase(r)
	return {"refine": "役灵安置完成。记得按契合工作、供养与点名。", "dismantle": "拆解得到骨料与阴灰，完整役灵已放弃。", "bury": "遗骸埋入灵田：阴性 +1，污染上升。", "release": "残念得度，声望 +1，污染 -8，线索记入手札。"}[method]

func ritual_preview(path: String) -> String:
	return {"earth": "消耗：2 烛穗 + 2 灯油。收益：镇守 +25，污染 -10。代价：地脉依赖，污染 +5。", "guest": "消耗：2 铜钱藤 + 2 灯油。收益：80 文。代价：污染 +15，夜袭提前。", "mountain": "消耗：2 骨料 + 2 灯油。收益：统御修为 +20，镇守 +15。代价：污染 +20，夜袭提前。"}.get(path, "")

func ritual(path: String) -> String:
	if day < 6: return "第六日后，才可按照手札主持虚构祭祀。"
	if ritual_count > 0: return "第一版只提供一次祭祀事件。"
	if oil < 2: return "需要 2 灯油。"
	if path == "earth":
		if inventory.candle < 2: return "需要 2 烛穗。"
		inventory.candle -= 2
		ward = mini(100, ward + 25)
		pollution = maxi(0, pollution - 10) + 5
	elif path == "guest":
		if inventory.vine < 2: return "需要 2 铜钱藤。"
		inventory.vine -= 2
		money += 80
		pollution = mini(100, pollution + 15)
	elif path == "mountain":
		if bones < 2: return "需要 2 骨料。"
		bones -= 2
		cultivation += 20
		ward = mini(100, ward + 15)
		pollution = mini(100, pollution + 20)
	else: return "请选择祭坛对象。"
	oil -= 2
	ritual_path = path
	ritual_count = 1
	add_log("你主持了祭祀。收益已经显现，门外有东西站了起来。")
	return "祭祀完成。天黑后，义庄门前将出现棺中客。"

func maybe_boss() -> bool:
	if boss_spawned or minutes < 1080 or (day < 9 and ritual_count == 0): return false
	boss_spawned = true
	enemies.append({"id": next_id, "kind": "boss", "zone": "farm", "at": [248.0, 300.0], "hp": 220 + pollution, "max_hp": 220 + pollution, "integrity": 100, "suppressed": false, "dead": false})
	next_id += 1
	add_log("夜袭：棺中客循着田里的声音，来到了义庄。")
	return true

func talk() -> String:
	return story_line() + (" 十日之后，带着自己的答案回来。" if not boss_defeated else "棺中客已倒下，十日之约将至。")

func choose_ending(choice: String) -> String:
	if day < 10 or not boss_defeated: return "第十日并击败棺中客后，才可决定灵田的归宿。"
	if ending != "": return "誓约已经写下，第一章的选择不可反复更改。"
	if choice not in ["seal", "coexist"]: return "无效选择。"
	ending = choice
	if choice == "seal":
		ward = 100
		pollution = maxi(0, pollution - 25)
	else:
		for s in spirits:
			s.affinity = mini(100, s.affinity + 20)
			s.risk = maxi(0, s.risk - 10)
	add_log("你选择封镇地下之物。" if choice == "seal" else "你选择立下人与役灵共处的新契约。")
	return "第一章完成。农场仍可继续经营，手札保留了你的选择。"

func snapshot() -> Dictionary:
	YinInventoryModel.new(self, "bag").sync()
	YinInventoryModel.new(self, "chest").sync()
	var data: Dictionary = {"version": 5}
	for key in save_keys(): data[key] = get(key)
	data.player_position = [player_position.x, player_position.y]
	data.saved_facing = [saved_facing.x, saved_facing.y]
	return data.duplicate(true)

static func save_keys() -> Array:
	return ["equipment", "gear_drops", "equipped_gear", "equipped_armor", "next_gear_id", "smart_farming", "day", "money", "energy", "health", "minutes", "weather", "selected_crop", "inventory", "supplies", "storage", "bag_slots", "chest_slots", "terrain", "drops", "placements", "plots", "oil", "talismans", "bones", "ash", "reputation", "cultivation", "pollution", "ward", "hall_level", "spirits", "remains", "cargo", "enemies", "enemy_day", "next_id", "total_harvest", "called_day", "ritual_count", "ritual_path", "boss_spawned", "boss_defeated", "ending", "intro_seen", "zone", "journal", "last_report", "order"]

static func valid_int(value: Variant, minimum: int, maximum: int = 100000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func valid_point(value: Variant) -> bool:
	return value is Array and value.size() == 2 and (value[0] is float or value[0] is int) and (value[1] is float or value[1] is int) and is_finite(float(value[0])) and is_finite(float(value[1])) and value[0] >= 0 and value[0] <= 1920 and value[1] >= 0 and value[1] <= 1280

func restore(data: Dictionary) -> bool:
	if not valid_int(data.get("version"), 3, 5): return false
	var defaults := FarmState.new()
	if int(data.version) == 3:
		data = data.duplicate(true)
		data.version = 4
		for key in ["supplies", "storage", "bag_slots", "chest_slots", "terrain", "drops", "placements"]:
			data[key] = defaults.get(key).duplicate(true)
	if int(data.version) == 4:
		data = data.duplicate(true)
		data.version = 5
		for key in ["equipment", "gear_drops", "equipped_gear", "equipped_armor", "next_gear_id", "smart_farming"]:
			var value: Variant = defaults.get(key)
			data[key] = value.duplicate(true) if value is Array else value
		for key in defaults.supplies:
			if not data.supplies.has(key): data.supplies[key] = defaults.supplies[key]
		for id in YinItemCatalog.IDS:
			if not data.storage.has(id): data.storage[id] = 0
	for key in save_keys():
		if not data.has(key): return false
		var expected: Variant = defaults.get(key)
		if expected is int and not valid_int(data[key], 0): return false
		if expected is bool and not data[key] is bool: return false
		if expected is String and not data[key] is String: return false
		if expected is Array and not data[key] is Array: return false
		if expected is Dictionary and not data[key] is Dictionary: return false
	if data.day < 1 or data.health > 100 or data.energy > 100 or data.ward > 100 or data.pollution > 100 or not valid_int(data.hall_level, 1, 2): return false
	if (not data.minutes is float and not data.minutes is int) or not is_finite(float(data.minutes)) or data.minutes < 360 or data.minutes > 1440: return false
	if data.zone not in ["farm", "graveyard", "forest", "hall", "shop"] or data.weather not in ["sun", "rain"] or data.order not in ["follow", "guard", "focus"]: return false
	if data.selected_crop not in CROPS or data.plots.size() != WIDTH * HEIGHT or data.spirits.size() > (2 if int(data.hall_level) == 1 else 3) or data.cargo.size() > 2: return false
	for key in INVENTORY_KEYS:
		if not valid_int(data.inventory.get(key), 0): return false
	for key in defaults.supplies:
		if not valid_int(data.supplies.get(key), 0): return false
	for id in YinItemCatalog.IDS:
		if not valid_int(data.storage.get(id), 0): return false
	for layout in [data.bag_slots, data.chest_slots]:
		if layout.size() != 0 and layout.size() != 24: return false
		for slot in layout:
			if not slot is Dictionary or not slot.get("id") is String or not valid_int(slot.get("count"), 0, 99): return false
			if slot.id == "" and slot.count != 0: return false
			if slot.id != "" and (slot.id not in YinItemCatalog.IDS or slot.count < 1): return false
	for key in data.terrain:
		var record: Variant = data.terrain[key]
		if not key is String or not record is Dictionary or not valid_int(record.get("hp"), 0, 3): return false
	for collection in [data.drops, data.placements]:
		for record in collection:
			if not record is Dictionary or not valid_int(record.get("id"), 1) or record.get("zone") not in ["farm", "graveyard", "forest", "hall", "shop"] or not valid_point(record.get("at")): return false
	for drop in data.drops:
		if drop.get("item") not in YinItemCatalog.IDS or not valid_int(drop.get("count"), 1, 99): return false
	for placed in data.placements:
		if placed.get("kind") not in ["paper_lamp", "ward_stake"]: return false
	for p in data.plots:
		if not p is Dictionary or not p.get("tilled") is bool or not p.get("watered") is bool or not p.get("sealed") is bool: return false
		if p.get("crop") not in ["", "candle", "vine", "gourd", "rice"] or not valid_int(p.get("growth"), 0, 6) or not valid_int(p.get("yin"), 0, 100): return false
		if p.get("branch") not in ["eat", "light", "shadow"]: return false
	for s in data.spirits:
		if not s is Dictionary or s.get("kind") not in SPIRITS or not s.get("name") is String or s.get("branch") not in ["eat", "light", "shadow"] or s.get("job") not in ["rest", "water", "dig", "clean", "guard"]: return false
		for key in ["id", "risk", "affinity", "level"]:
			if not valid_int(s.get(key), 0, 100000): return false
	for r in data.remains:
		if not r is Dictionary or r.get("kind") not in YinBalance.MONSTERS.keys() or r.get("zone") not in ["farm", "graveyard", "forest", "cargo"] or not valid_point(r.get("at")): return false
		for key in ["id", "integrity", "fierceness"]:
			if not valid_int(r.get(key), 0, 100000): return false
		for key in ["name", "regret", "yin"]:
			if not r.get(key) is String: return false
	for e in data.enemies:
		if not e is Dictionary or e.get("kind") not in YinBalance.MONSTERS.keys() or e.get("zone") not in ["farm", "graveyard", "forest"] or not valid_point(e.get("at")) or not e.get("dead") is bool or not e.get("suppressed") is bool: return false
		for key in ["id", "hp", "max_hp", "integrity"]:
			if not valid_int(e.get(key), 0, 100000): return false
		for key in ["level", "damage", "armor"]:
			if e.has(key) and not valid_int(e[key], 0, 10000): return false
		if e.has("level") and not valid_int(e.level, 1, 20): return false
		if e.has("elite") and not e.elite is bool: return false
		if e.max_hp < 1 or e.hp > e.max_hp or e.integrity > 100: return false
	for id in data.cargo:
		if not valid_int(id, 1) or not data.remains.any(func(r): return r.id == id and r.zone == "cargo"): return false
	for entry in data.journal:
		if not entry is String: return false
	if data.journal.size() > 24 or not valid_point(data.get("player_position")): return false
	if not data.get("saved_facing") is Array or data.saved_facing.size() != 2: return false
	for value in data.saved_facing:
		if (not value is float and not value is int) or not is_finite(float(value)): return false
	var face: Array = data.get("saved_facing", [])
	if face.size() != 2 or absf(Vector2(face[0], face[1]).length() - 1.0) > 0.01: return false
	if data.equipment.size() < 1 or data.equipment.size() > 20 or data.gear_drops.size() > 200: return false
	var gear_ids: Array = []
	for gear in data.equipment:
		if not valid_gear(gear) or gear.id in gear_ids: return false
		gear_ids.append(gear.id)
	if not data.equipment.any(func(g): return g.id == data.equipped_gear and g.weapon != "armor"): return false
	if data.equipped_armor != 0 and not data.equipment.any(func(g): return g.id == data.equipped_armor and g.weapon == "armor"): return false
	for drop in data.gear_drops:
		if not drop is Dictionary or not valid_int(drop.get("id"), 1) or drop.get("zone") not in ["farm", "graveyard", "forest", "hall", "shop"] or not valid_point(drop.get("at")) or not valid_gear(drop.get("gear")): return false
		if drop.gear.id in gear_ids: return false
		gear_ids.append(drop.gear.id)
	if gear_ids.any(func(id): return id >= data.next_gear_id): return false
	var normalized: Dictionary = data.duplicate(true)
	for key in save_keys():
		if defaults.get(key) is int: normalized[key] = int(normalized[key])
	for key in INVENTORY_KEYS: normalized.inventory[key] = int(normalized.inventory[key])
	for key in normalized.supplies: normalized.supplies[key] = int(normalized.supplies[key])
	for key in normalized.storage: normalized.storage[key] = int(normalized.storage[key])
	for layout in [normalized.bag_slots, normalized.chest_slots]:
		for slot in layout: slot.count = int(slot.count)
	for record in normalized.terrain.values(): record.hp = int(record.hp)
	for collection in [normalized.drops, normalized.placements]:
		for record in collection:
			record.id = int(record.id)
			record.at = [float(record.at[0]), float(record.at[1])]
	for record in normalized.drops: record.count = int(record.count)
	for p in normalized.plots:
		for key in ["growth", "yin"]: p[key] = int(p[key])
	for item in normalized.spirits:
		for key in ["id", "risk", "affinity", "level"]: item[key] = int(item[key])
	for item in normalized.remains:
		for key in ["id", "integrity", "fierceness"]: item[key] = int(item[key])
		item.at = [float(item.at[0]), float(item.at[1])]
	for item in normalized.enemies:
		for key in ["id", "hp", "max_hp", "integrity"]: item[key] = int(item[key])
		for key in ["level", "damage", "armor"]:
			if item.has(key): item[key] = int(item[key])
		item.at = [float(item.at[0]), float(item.at[1])]
	for gear in normalized.equipment:
		for key in ["id", "tier", "quality", "bonus", "magazine"]: gear[key] = int(gear[key])
	for drop in normalized.gear_drops:
		drop.id = int(drop.id)
		for key in ["id", "tier", "quality", "bonus", "magazine"]: drop.gear[key] = int(drop.gear[key])
	normalized.cargo = normalized.cargo.map(func(id): return int(id))
	for key in save_keys(): set(key, normalized[key])
	player_position = Vector2(data.player_position[0], data.player_position[1])
	saved_facing = Vector2(face[0], face[1])
	return true

func container_count(container: String, id: String) -> int:
	if container == "chest": return int(storage.get(id, 0))
	if inventory.has(id): return int(inventory[id])
	if supplies.has(id): return int(supplies[id])
	return int(get({"oil": "oil", "talisman": "talismans", "bone": "bones", "ash": "ash"}.get(id, "oil"))) if id in ["oil", "talisman", "bone", "ash"] else 0

func set_container_count(container: String, id: String, count: int) -> void:
	if container == "chest": storage[id] = count
	elif inventory.has(id): inventory[id] = count
	elif supplies.has(id): supplies[id] = count
	elif id in ["oil", "talisman", "bone", "ash"]: set({"oil": "oil", "talisman": "talismans", "bone": "bones", "ash": "ash"}[id], count)

func can_gain(id: String, count: int) -> bool:
	return can_gain_many({id: count})

func can_gain_many(additions: Dictionary) -> bool:
	var values: Dictionary = {}
	for id in YinItemCatalog.IDS: values[id] = container_count("bag", id) + int(additions.get(id, 0))
	return YinInventoryModel.fits(values)

static func valid_gear(gear: Variant) -> bool:
	if not gear is Dictionary or gear.get("weapon") not in YinBalance.WEAPONS: return false
	for key in ["id", "tier", "quality", "bonus", "magazine"]:
		if not valid_int(gear.get(key), 0): return false
	return gear.id >= 1 and gear.tier >= 1 and gear.tier <= 20 and gear.quality <= 3 and gear.bonus == gear.quality * 8 and gear.magazine <= YinBalance.WEAPONS[gear.weapon].magazine
func current_gear() -> Dictionary:
	for gear in equipment:
		if gear.id == equipped_gear: return gear
	return {}
func armor_gear() -> Dictionary:
	for gear in equipment:
		if gear.id == equipped_armor: return gear
	return {}
func equip(id: int) -> bool:
	for gear in equipment:
		if gear.id != id: continue
		if gear.weapon == "armor": equipped_armor = id
		else: equipped_gear = id
		return true
	return false
func grant_gear(weapon: String, tier: int = 1, quality: int = 0) -> Dictionary:
	if equipment.size() >= 20 or weapon not in YinBalance.WEAPONS: return {}
	var gear := YinBalance.make_gear(next_gear_id, weapon, tier, quality)
	next_gear_id += 1
	equipment.append(gear)
	return gear
func add_drop(item: String, count: int, zone_name: String, at: Vector2) -> void:
	drops.append({"id": next_id, "item": item, "count": count, "zone": zone_name, "at": [at.x, at.y]})
	next_id += 1
func reward_enemy(enemy: Dictionary, at: Vector2) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = int(enemy.id) * 92821 + day * 193
	var level_value: int = int(enemy.get("level", 1))
	add_drop("rifle_ammo" if enemy.kind in ["archer", "brute"] else "light_ammo", 3 + level_value, enemy.zone, at + Vector2(14, 10))
	if gear_drops.size() < 200 and (random.randf() < 0.35 or enemy.get("elite", false) or enemy.kind == "boss"):
		var roll: float = random.randf()
		var quality: int = 3 if roll > 0.98 else (2 if roll > 0.88 else (1 if roll > 0.6 else 0))
		if enemy.get("elite", false) or enemy.kind == "boss": quality = maxi(1, quality)
		var weapon: String = ["sword", "pistol", "smg", "rifle", "armor"][random.randi_range(0, 4)]
		var gear := YinBalance.make_gear(next_gear_id, weapon, mini(20, level_value), quality)
		next_gear_id += 1
		gear_drops.append({"id": next_id, "gear": gear, "zone": enemy.zone, "at": [at.x - 14, at.y + 10]})
		next_id += 1
func salvage(id: int) -> String:
	if id in [equipped_gear, equipped_armor]: return "穿戴中的装备不可拆解。"
	for gear in equipment:
		if gear.id != id: continue
		var gain: int = 1 + int(gear.quality)
		var ammo: String = YinBalance.WEAPONS[gear.weapon].ammo
		var additions: Dictionary = {"scrap": gain}
		if ammo != "" and gear.magazine > 0: additions[ammo] = gear.magazine
		if not can_gain_many(additions): return "行囊已满，装备未拆解。"
		for item in additions: set_container_count("bag", item, container_count("bag", item) + int(additions[item]))
		equipment.erase(gear)
		return "拆解完成，零件和未用弹药已回收入行囊。"
	return "没有这件装备。"
func craft_ammo(ammo: String) -> String:
	if ammo not in ["light_ammo", "rifle_ammo"]: return "无效弹种。"
	var amount: int = 12 if ammo == "light_ammo" else 6
	if supplies.scrap < 1 or bones < 1: return "弹药需要 1 铳器零件和 1 骨料。"
	if not can_gain(ammo, amount): return "行囊已满。"
	supplies.scrap -= 1
	bones -= 1
	supplies[ammo] += amount
	return "制成 %s ×%d。" % [YinItemCatalog.spec(ammo).display_name, amount]
