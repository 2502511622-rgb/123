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
const SPIRITS = {"hungry_ghost": "施食役灵", "wraith": "幽魂役灵", "rakshasa": "罗刹役灵", "kumbhanda": "梦守役灵", "asura": "修罗役灵", "yaksha": "夜叉役灵", "kappa": "河童役灵", "chochin": "纸灯役灵", "ippon_datara": "踏鞴役灵", "jorogumo": "蛛姬役灵", "sogenbi": "罪火役灵", "itsumade": "金羽役灵", "daitengu": "山风役灵", "ryomen_sukuna": "双面武灵", "water": "担水尸", "bone": "掘土骨", "child": "食秽童", "archer": "吐骨役灵", "lantern": "追灯役灵", "gunner": "纸铳役灵", "brute": "山魈役灵", "boss": "棺将", "well_boss": "井中龙婆", "opera_boss": "无面伶王"}
const INVENTORY_KEYS = ["candle_seeds", "vine_seeds", "gourd_seeds", "rice_seeds", "candle", "vine", "gourd", "rice"]
var appearance: Dictionary = YinAppearance.initial()
var temple_journal: Dictionary = YinTemple.initial()
var factions: Dictionary = YinFactions.initial()
var island_journal: Dictionary = {"visited": false, "hunted": [], "defeated": []}
var opened_chests: Array = []
var quests: Dictionary = {}
var tracked_quest: String = ""
var visited_landmarks: Dictionary = {}
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
var weapon_slots: Dictionary = {"melee": 1, "primary": 0, "secondary": 2}
var active_slot: String = "melee"
var skill_ranks: Dictionary = {"seal": 1, "fire": 0, "breath": 0, "command": 0}
var skill_charges: Dictionary = {"seal": 2, "fire": 2}
var skill_timers: Dictionary = {"seal": 0.0, "fire": 0.0}
var energy_fraction: float = 0
var villagers: Array = []
var letters: Array = []
var raid_day: int = 0
var raid_status: String = "quiet"
var village_integrity: int = 100
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
var cargo: Array = [] # Legacy saves only; migrated to courtyard remains.
var mainline_claimed: Array = []
var defense_minute: float = 0
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
	for i in range(6):
		villagers.append({"id": i + 1, "name": ["村长柳伯", "药婆秋婶", "铁匠阿祁", "灯匠小满", "农人禾生", "书生砚青"][i], "hp": 100, "max_hp": 100, "at": [260.0 + (i % 3) * 300, 300.0 + int(i / 3) * 320]})
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
			return "未成熟。作物逐日生长，可先去探索；浇灌是可选操作。"
		if p.crop == "rice" and not p.sealed:
			return "稻穗传来师父的声音。不要答应：靠近按 E，以镇符技能封声。"
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
	minutes = minf(1799.99, minutes + 2)
	return ["土下隐约有叩门声。翻土完成。", "播下 %s。" % CROPS[selected_crop].display_name, "浇灌完成。"][tool]

func seal_plot(index: int) -> String:
	if index < 0 or index >= plots.size() or plots[index].crop != "rice":
		return "没有需要封声的禁种。"
	if plots[index].sealed:
		return "这一株已封声。"
	if not spend_skill("seal"):
		return "镇符体力或充能不足。"
	plots[index].sealed = true
	pollution = maxi(0, pollution - 5)
	return "符纸贴上稻穗，声音停了。现在可以安全收获。"

func capacity() -> int:
	return (2 if hall_level == 1 else 3) + int((YinBalance.level(cultivation) - 1) / 3) + int(skill_ranks.command)

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
	var spirit: Dictionary = {"id": next_id, "kind": kind, "name": spirit_name, "branch": branch, "job": "rest", "risk": clampi(risk, 0, 90), "affinity": 0, "level": 1, "source_kind": "lantern" if kind == "child" else kind, "hp": YinAbilities.spirit_hp(kind, 1), "max_hp": YinAbilities.spirit_hp(kind, 1), "xp": 0, "active": true, "assignment":"follow", "guard_villager":0}
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
	settle_raid()
	for s in spirits:
		if called_day != day:
			s.risk += 20
		if oil >= YinAbilities.deployment_cost(s.source_kind):
			oil -= YinAbilities.deployment_cost(s.source_kind)
			s.hp = mini(s.max_hp, s.hp + maxi(8, int(s.max_hp / 4)))
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
		elif s.job == "dig" and s.kind in ["bone", "brute"]:
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
		if p.crop != "":
			p.growth = mini(CROPS[p.crop].growth_days, p.growth + 1)
	day += 1
	energy = 100
	health = mini(100, health + 45)
	minutes = 360
	weather = "rain" if day % 4 == 0 else "sun"
	for villager in villagers: villager.hp = mini(100, villager.hp + 15)
	if day % 3 == 0:
		raid_day = day
		raid_status = "warned"
		letters.append({"day": day, "status": "warned", "read": false})
		while letters.size() > 12: letters.pop_front()
		add_log("青槐村来信：今夜邪祟将袭村，请到村口救援。")
	for p in plots:
		p.watered = p.crop != "" and weather == "rain"
	ward = maxi(0, ward - 5 - int(pollution / 20))
	last_report = " / ".join(report) if not report.is_empty() else "天亮了。田里留下了一行朝向义庄的脚印。"
	add_log(last_report)
	if day <= 10:
		add_log(story_line())

func preferred_job(s: Dictionary) -> String:
	if s.kind == "water": return "water"
	if s.kind in ["bone", "brute"]: return "dig"
	if s.kind != "child": return "guard"
	return "guard" if s.branch == "light" else "clean"

func continue_spirit_warning(report: Array[String], spirit_name: String) -> void:
	report.append(spirit_name + "没有领到供养，怨气 +25。")

func story_line() -> String:
	return ["", "师父将义庄与三亩荒田留给了你。", "井里传出担水声。桥边阿婆说：这是它生前的差事。", "棺盖内侧有师父刻下的阵图。炼骸前先看完整度。", "雨中铜钱藤的果实同时朝祠堂转去。", "祠堂祭帖写着你的名字，今年祭司已经选定。", "义庄的阵线松了。修阵、点名，也可以预览虚构祭祀的收益。", "田里说话的声音越来越像师父。不要答应。", "阿婆承认：灵田既是封印，也是地下之物的食盆。", "无论是否祭祀，今夜棺中客都将叩门。守住义庄。", "师父的最后一页：镇住它，或为共处立下新的契约。"] [mini(day, 10)]

func tick(delta: float) -> void:
	minutes += delta * 4
	# Dawn settles the farm, but never moves or heals an exploring player.
	while minutes >= 1800:
		var overflow: float = minutes - 1800
		var old_health: int = health
		var old_energy: int = energy
		next_day()
		minutes = 360 + overflow
		health = old_health
		energy = old_energy

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
	if enemy_day == day:
		prepare_forest_extension()
		YinIsland.populate(self)
		YinTemple.populate(self)
		return
	enemy_day = day
	enemies = enemies.filter(func(e): return (e.has("war_id") and not e.dead) or (e.zone == "farm" and not e.dead) or e.kind in ["well_boss", "opera_boss"] or e.kind in YinIsland.BOSSES or e.kind in YinTemple.BOSSES or (e.zone == "village" and int(e.get("raid", 0)) > 0 and not e.dead))
	for i in range(5):
		var kind: String = "water" if i % 2 == 0 else "bone"
		spawn_record(kind, "graveyard", Vector2(280 + i * 100, 240 + (i % 2) * 150), 1 + int((day - 1) / 4))
	if day >= 3:
		spawn_record("archer", "graveyard", Vector2(730, 425), 2)
		spawn_record("lantern", "graveyard", Vector2(820, 290), 2)
	for branch in ["sunken", "theatre"]:
		for i in range(8):
			spawn_record(["water", "lantern", "archer", "gunner"][i % 4], branch, Vector2(360 + (i % 4) * 190, 300 + int(i / 4) * 280), 3 + int((day - 1) / 4))
		if not enemies.any(func(e): return e.zone == branch and e.kind in ["well_boss", "opera_boss"]):
			spawn_record("well_boss" if branch == "sunken" else "opera_boss", branch, Vector2(1040, 360), 4, true)
	for i in range(16):
		var kind: String = ["archer", "lantern", "gunner", "brute"][i % 4]
		var at := Vector2(480 + (i % 4) * 360, 240 + int(i / 4) * 240)
		spawn_record(kind, "forest", at, 2 + int(i / 8) + int((day - 1) / 4), i in [6, 15])

	prepare_forest_extension()
	YinIsland.populate(self)
	YinTemple.populate(self)

func prepare_forest_extension() -> void:
	if enemies.any(func(e): return e.zone == "forest" and e.get("forest_extension", false)): return
	# Three connected eastern landmarks, with encounters off the main trail.
	for i in range(12):
		var at := Vector2(2112 + (i % 3) * 256, 320 + int(i / 3) * 384)
		var added: Dictionary = spawn_record(["bone", "gunner", "brute", "lantern"][i % 4], "forest", at, 4 + int((day - 1) / 4), i in [5, 11])
		added.forest_extension = true

func spawn_record(kind: String, zone_name: String, at: Vector2, level_value: int, elite: bool = false) -> Dictionary:
	var stats: Dictionary = YinBalance.enemy(kind, level_value, elite)
	var record: Dictionary = {"id": next_id, "kind": kind, "zone": zone_name, "at": [at.x, at.y], "hp": stats.hp, "max_hp": stats.hp, "integrity": 100, "suppressed": false, "dead": false}
	record.merge(stats)
	enemies.append(record)
	next_id += 1
	return record

func kill_enemy(id: int, at: Vector2, source_gear_id: int = 0) -> void:
	for e in enemies:
		if e.id != id or e.dead: continue
		if e.zone == "island" and not YinIsland.available(self, e.kind): return
		if e.zone == "temple" and not YinTemple.available(self, e.kind): return
		e.dead = true
		if e.has("war_id"):
			for war in factions.wars:
				if int(war.id)==int(e.war_id):war.player_kills=int(war.get("player_kills",0))+1
		YinAdventure.on_kill(self, e)
		YinIsland.on_kill(self, e)
		YinTemple.on_kill(self, e)
		for gear in equipment:
			if gear.id == source_gear_id and gear.weapon == "ipetam": gear.artifact_kills = mini(100000, gear.artifact_kills + 1)
		var boss: bool = e.kind == "boss"
		remains.append({"id": next_id, "kind": e.kind, "name": "棺将遗骸" if boss else ("担水尸骸" if e.kind == "water" else YinBalance.MONSTERS[e.kind].name + "遗骸"), "integrity": e.integrity, "regret": "守门" if boss else ("生前担水" if e.kind == "water" else {"bone": "替人掘墓", "archer": "守山残念", "lantern": "不肯熄灭的旧灯", "gunner": "未传到的军令", "brute": "山中猎食"}.get(e.kind, "未散残念")), "fierceness": 40 if e.kind in YinAbilities.BOSSES else (12 if e.suppressed else 30), "yin": "山煞" if boss else ("水阴" if e.kind == "water" else "土阴"), "at": [at.x, at.y], "zone": e.zone, "source_level": int(e.get("level", 1))})
		next_id += 1
		cultivation += (8 * int(e.get("level", 1))) if not boss else 30
		for spirit in spirits:
			if spirit.active and spirit.hp > 0: gain_spirit_xp(spirit, 8 + int(e.get("level", 1)) * 2)
		reward_enemy(e, at)
		if e.kind in ["well_boss", "opera_boss"]:
			add_log("支线首领已超克：" + YinBalance.MONSTERS[e.kind].name)
		if boss:
			boss_defeated = true
			add_log("棺中客倒下。它的棺盖内刻着与你师父相同的名字。")
		return

func find_remains(id: int) -> Dictionary:
	for r in remains:
		if r.id == id: return r
	return {}

func pickup(id: int) -> String:
	return "运输已移除，请在遗骸旁直接炼化、拆解或超度。"

func process_remains(id: int, method: String, plot_index: int = -1) -> String:
	var r: Dictionary = find_remains(id)
	if r.is_empty(): return "没有这具遗骸。"
	match method:
		"refine":
			if r.integrity < 60: return "完整度不足 60，不能炼成完整役灵。"
			if spirits.size() >= capacity(): return "安置位不足。可先扩建或选择其他用途。"
			var spirit: Dictionary = make_spirit(r.kind, r.fierceness)
			spirit.level = clampi(int(r.get("source_level", 1)), 1, 10)
			spirit.max_hp = YinAbilities.spirit_hp(r.kind, spirit.level)
			spirit.hp = spirit.max_hp
			spirits.append(spirit)
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
	enemies.append({"id": next_id, "kind": "boss", "zone": "farm", "at": [248.0, 300.0], "hp": 520 + pollution * 2, "max_hp": 520 + pollution * 2, "damage": 23, "armor": 18, "level": 4, "elite": true, "integrity": 100, "suppressed": false, "dead": false})
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
	var data: Dictionary = {"version": 13}
	for key in save_keys(): data[key] = get(key)
	data.player_position = [player_position.x, player_position.y]
	data.saved_facing = [saved_facing.x, saved_facing.y]
	return data.duplicate(true)

static func save_keys() -> Array:
	return ["defense_minute", "mainline_claimed", "appearance", "temple_journal", "factions", "island_journal", "opened_chests", "quests", "tracked_quest", "visited_landmarks", "weapon_slots", "active_slot", "skill_ranks", "skill_charges", "skill_timers", "villagers", "letters", "raid_day", "raid_status", "village_integrity", "equipment", "gear_drops", "equipped_gear", "equipped_armor", "next_gear_id", "smart_farming", "day", "money", "energy", "health", "minutes", "weather", "selected_crop", "inventory", "supplies", "storage", "bag_slots", "chest_slots", "terrain", "drops", "placements", "plots", "oil", "talismans", "bones", "ash", "reputation", "cultivation", "pollution", "ward", "hall_level", "spirits", "remains", "cargo", "enemies", "enemy_day", "next_id", "total_harvest", "called_day", "ritual_count", "ritual_path", "boss_spawned", "boss_defeated", "ending", "intro_seen", "zone", "journal", "last_report", "order"]

static func valid_int(value: Variant, minimum: int, maximum: int = 100000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func valid_point(value: Variant) -> bool:
	return value is Array and value.size() == 2 and (value[0] is float or value[0] is int) and (value[1] is float or value[1] is int) and is_finite(float(value[0])) and is_finite(float(value[1])) and value[0] >= 0 and value[0] <= 2880 and value[1] >= 0 and value[1] <= 1920

func restore(data: Dictionary) -> bool:
	if not valid_int(data.get("version"), 3, 13): return false
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
	if int(data.version) == 5:
		data = data.duplicate(true)
		data.version = 6
		for collection in ["equipment", "gear_drops", "spirits"]:
			if not data.get(collection) is Array: return false
		for gear in data.equipment:
			if not gear is Dictionary or gear.get("weapon") not in YinBalance.WEAPONS or not valid_int(gear.get("id"), 1): return false
		for spirit in data.spirits:
			if not spirit is Dictionary or spirit.get("kind") not in SPIRITS or not valid_int(spirit.get("level"), 0, 100000): return false
		for drop in data.gear_drops:
			if not drop is Dictionary or not drop.get("gear") is Dictionary: return false
		for key in ["weapon_slots", "active_slot", "skill_ranks", "skill_charges", "skill_timers", "villagers", "letters", "raid_day", "raid_status", "village_integrity"]:
			var value: Variant = defaults.get(key)
			data[key] = value.duplicate(true) if value is Array or value is Dictionary else value
		for slot in ["melee", "primary", "secondary"]: data.weapon_slots[slot] = 0
		for gear in data.equipment:
			gear.affixes = []
			var slot: String = gear_slot(gear.weapon)
			if gear.weapon != "armor" and data.weapon_slots[slot] == 0: data.weapon_slots[slot] = gear.id
		for gear in data.equipment:
			if gear.id == data.equipped_gear:
				data.active_slot = gear_slot(gear.weapon)
				data.weapon_slots[data.active_slot] = gear.id
		for drop in data.gear_drops: drop.gear.affixes = []
		for spirit in data.spirits:
			spirit.source_kind = "lantern" if spirit.kind == "child" else spirit.kind
			spirit.level = clampi(int(spirit.level), 1, 10)
			spirit.max_hp = YinAbilities.spirit_hp(spirit.source_kind, spirit.level)
			spirit.hp = spirit.max_hp
			spirit.xp = 0
			spirit.active = false
	if int(data.version) == 6:
		data = data.duplicate(true)
		data.version = 7
		data.opened_chests = []
		data.quests = {}
		data.tracked_quest = ""
		data.visited_landmarks = {}
	if int(data.version) == 7:
		data = data.duplicate(true)
		data.version = 8
		data.island_journal = {"visited": false, "hunted": [], "defeated": []}
	if int(data.version) == 8:
		data = data.duplicate(true)
		data.version = 9
		data.factions = YinFactions.initial()
	if int(data.version) == 9:
		data = data.duplicate(true)
		data.version = 10
		data.temple_journal = YinTemple.initial()
		if not data.get("factions") is Dictionary or not data.factions.get("powers") is Dictionary: return false
		data.factions.powers.temple = YinFactions.initial().powers.temple
	if int(data.version)==10:
		data=data.duplicate(true)
		data.version=11
		data.appearance=defaults.appearance.duplicate(true)
	if int(data.version) < 12:
		data = data.duplicate(true)
		data.version = 12
		data.mainline_claimed = []
	if not data.get("mainline_claimed") is Array or data.mainline_claimed.size()>3: return false
	for stage in data.mainline_claimed:
		if stage not in ["gear","journey","balance"] or data.mainline_claimed.count(stage)!=1: return false

	if int(data.version)<13:
		data=data.duplicate(true)
		data.version=13
		data.defense_minute=0.0
		if not data.get("spirits") is Array:return false
		for spirit in data.spirits:
			if not spirit is Dictionary or spirit.get("source_kind") not in YinAbilities.MONSTERS or not valid_int(spirit.get("level"),1,10) or not valid_int(spirit.get("max_hp"),1,300) or not valid_int(spirit.get("hp"),0,spirit.max_hp):return false
			var old_max: int=(90+(int(spirit.level)-1)*10) if spirit.source_kind in YinAbilities.BOSSES else (42+(int(spirit.level)-1)*7)
			if int(spirit.max_hp) not in [old_max,YinAbilities.spirit_hp(spirit.source_kind,int(spirit.level))]:return false
			var new_max: int=YinAbilities.spirit_hp(spirit.source_kind,int(spirit.level))
			spirit.hp=roundi(float(spirit.hp)/float(spirit.max_hp)*new_max)
			spirit.max_hp=new_max
			if not spirit.has("assignment"):spirit.assignment="follow" if spirit.get("active",false) else "rest"
			if not spirit.has("guard_villager"):spirit.guard_villager=0
	if not (data.get("defense_minute") is float or data.get("defense_minute") is int) or not is_finite(float(data.defense_minute)) or data.defense_minute<0 or data.defense_minute>100000000:return false
	for key in save_keys():
		if not data.has(key): return false
		var expected: Variant = defaults.get(key)
		if expected is int and not valid_int(data[key], 0): return false
		if expected is bool and not data[key] is bool: return false
		if expected is String and not data[key] is String: return false
		if expected is Array and not data[key] is Array: return false
		if expected is Dictionary and not data[key] is Dictionary: return false
	if not YinAppearance.validate(data.appearance): return false
	if not YinFactions.validate(data.factions): return false
	for e in data.enemies:
		if not e is Dictionary: return false
		if e.has("war_id"):
			if not valid_int(e.war_id, 1) or e.get("faction") not in YinFactions.IDS or e.get("war_side") not in ["attacker", "defender"]: return false
			if not e.get("dead", true):
				var matching: Array = data.factions.wars.filter(func(w): return int(w.id) == int(e.war_id) and w.status == "active" and w[e.war_side] == e.faction)
				if matching.size() != 1 or matching[0].defender != e.zone or matching[0][e.war_side] != e.faction: return false
	if not YinTemple.validate(data.temple_journal): return false
	if not YinIsland.validate(data.island_journal): return false
	if not YinAdventure.validate(data): return false
	if data.day < 1 or data.health > 100 or data.energy > 100 or data.ward > 100 or data.pollution > 100 or not valid_int(data.hall_level, 1, 2): return false
	if (not data.minutes is float and not data.minutes is int) or not is_finite(float(data.minutes)) or data.minutes < 360 or data.minutes >= 1800: return false
	if data.zone not in ["farm", "graveyard", "forest", "sunken", "theatre", "village", "hall", "shop", "island", "temple"] or data.weather not in ["sun", "rain"] or data.order not in ["follow", "guard", "focus"]: return false

	if data.selected_crop not in CROPS or data.plots.size() != WIDTH * HEIGHT or data.spirits.size() > ((2 if int(data.hall_level) == 1 else 3) + int((YinBalance.level(int(data.cultivation)) - 1) / 3) + int(data.skill_ranks.get("command", 0))) or data.cargo.size() > 2: return false
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
			if not record is Dictionary or not valid_int(record.get("id"), 1) or record.get("zone") not in ["farm", "graveyard", "forest", "sunken", "theatre", "village", "hall", "shop", "island", "temple"] or not valid_point(record.get("at")): return false
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
		if not r is Dictionary or r.get("kind") not in YinBalance.MONSTERS.keys() or r.get("zone") not in ["farm", "graveyard", "forest", "sunken", "theatre", "village", "cargo", "island", "temple"] or not valid_point(r.get("at")): return false
		for key in ["id", "integrity", "fierceness"]:
			if not valid_int(r.get(key), 0, 100000): return false
		for key in ["name", "regret", "yin"]:
			if not r.get(key) is String: return false
	for e in data.enemies:
		if not e is Dictionary or e.get("kind") not in YinBalance.MONSTERS.keys() or e.get("zone") not in ["farm", "graveyard", "forest", "sunken", "theatre", "village", "island", "temple"] or not valid_point(e.get("at")) or not e.get("dead") is bool or not e.get("suppressed") is bool: return false
		for key in ["id", "hp", "max_hp", "integrity"]:
			if not valid_int(e.get(key), 0, 100000): return false
		for key in ["level", "damage", "armor"]:
			if e.has(key) and not valid_int(e[key], 0, 10000): return false
		if e.has("level") and not valid_int(e.level, 1, 20): return false
		if e.has("elite") and not e.elite is bool: return false
		if e.has("home_at") and not valid_point(e.home_at): return false
		if e.has("temple_day") and not valid_int(e.temple_day, 1): return false
		if e.has("island_day") and not valid_int(e.island_day, 1): return false
		if e.has("forest_extension") and not e.forest_extension is bool: return false
		if e.has("severed"):
			if not e.severed is Array or e.severed.size() > 3: return false
			var limbs: Array = []
			for part in e.severed:
				if part not in ["arm", "leg", "head"] or part in limbs: return false
				limbs.append(part)
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
	for relic in ["ipetam", "prajna"]:
		if data.equipment.filter(func(g): return g.weapon == relic).size() > 1: return false
	if not data.equipment.any(func(g): return g.id == data.equipped_gear and g.weapon != "armor"): return false
	if data.equipped_armor != 0 and not data.equipment.any(func(g): return g.id == data.equipped_armor and g.weapon == "armor"): return false
	for drop in data.gear_drops:
		if not drop is Dictionary or not valid_int(drop.get("id"), 1) or drop.get("zone") not in ["farm", "graveyard", "forest", "sunken", "theatre", "village", "hall", "shop", "island", "temple"] or not valid_point(drop.get("at")) or not valid_gear(drop.get("gear")): return false
		if drop.gear.id in gear_ids: return false
		gear_ids.append(drop.gear.id)
	if gear_ids.any(func(id): return id >= data.next_gear_id): return false
	if data.active_slot not in ["melee", "primary", "secondary"] or data.raid_status not in ["quiet", "warned", "active", "success", "failed"] or not valid_int(data.village_integrity, 0, 100): return false
	if data.skill_ranks.size() != 4 or data.skill_charges.size() != 2 or data.skill_timers.size() != 2 or data.weapon_slots.size() != 3: return false
	for key in YinAbilities.SKILLS:
		if not valid_int(data.skill_ranks.get(key), 0, 3): return false
	if data.skill_ranks.seal < 1 or skill_spent(data.skill_ranks) > YinBalance.level(int(data.cultivation)) - 1: return false
	for key in ["seal", "fire"]:
		if not valid_int(data.skill_charges.get(key), 0, 2): return false
		var timer: Variant = data.skill_timers.get(key)
		if (not timer is float and not timer is int) or not is_finite(float(timer)) or timer < 0 or timer > 18: return false
	for spirit in data.spirits:
		if spirit.get("source_kind") not in YinAbilities.MONSTERS or not valid_int(spirit.get("level"), 1, 10): return false
		if not valid_int(spirit.get("max_hp"), 1, 300) or not valid_int(spirit.get("hp"), 0, spirit.max_hp) or not valid_int(spirit.get("xp"), 0, 400) or not spirit.get("active") is bool: return false
		if spirit.max_hp != YinAbilities.spirit_hp(spirit.source_kind, int(spirit.level)) or spirit.xp >= spirit.level * 40 or (spirit.level == 10 and spirit.xp != 0): return false
		if spirit.active:
			if spirit.hp == 0: return false
		if spirit.get("assignment") not in ["follow","village","rest"] or not valid_int(spirit.get("guard_villager"),0,6):return false
		if spirit.active and spirit.assignment=="rest":return false
	if data.villagers.size() != 6 or data.letters.size() > 12: return false
	var villager_ids: Array = []
	for villager in data.villagers:
		if not villager is Dictionary or not valid_int(villager.get("id"), 1, 6) or villager.id in villager_ids or not villager.get("name") is String or not valid_point(villager.get("at")) or not valid_int(villager.get("hp"), 0, 100) or villager.get("max_hp") != 100: return false
		villager_ids.append(villager.id)
	for letter in data.letters:
		if not letter is Dictionary or not valid_int(letter.get("day"), 1) or letter.get("status") not in ["warned", "active", "success", "failed"] or not letter.get("read") is bool: return false
	for slot in ["melee", "primary", "secondary"]:
		if not valid_int(data.weapon_slots.get(slot), 0): return false
		if data.weapon_slots[slot] != 0 and not data.equipment.any(func(gear): return gear.id == data.weapon_slots[slot] and gear_slot(gear.weapon) == slot): return false
	var normalized: Dictionary = data.duplicate(true)
	for key in YinAppearance.LABELS: normalized.appearance[key]=int(normalized.appearance[key])
	YinFactions.normalize(normalized.factions)
	for e in normalized.enemies:
		if e.has("war_id"): e.war_id = int(e.war_id)
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
		for key in ["id", "risk", "affinity", "level", "hp", "max_hp", "xp", "guard_villager"]: item[key] = int(item[key])
	for item in normalized.remains:
		for key in ["id", "integrity", "fierceness"]: item[key] = int(item[key])
		item.at = [float(item.at[0]), float(item.at[1])]
		if item.has("source_level"): item.source_level = int(item.source_level)
	for item in normalized.enemies:
		if item.has("temple_day"): item.temple_day = int(item.temple_day)
		if item.has("island_day"): item.island_day = int(item.island_day)
		if item.has("home_at"): item.home_at = [float(item.home_at[0]), float(item.home_at[1])]
		for key in ["id", "hp", "max_hp", "integrity"]: item[key] = int(item[key])
		for key in ["level", "damage", "armor"]:
			if item.has(key): item[key] = int(item[key])
		item.at = [float(item.at[0]), float(item.at[1])]
	for gear in normalized.equipment:
		for key in ["id", "tier", "quality", "bonus", "magazine"]: gear[key] = int(gear[key])
	for drop in normalized.gear_drops:
		drop.id = int(drop.id)
		for key in ["id", "tier", "quality", "bonus", "magazine"]: drop.gear[key] = int(drop.gear[key])
	for slot in normalized.weapon_slots: normalized.weapon_slots[slot] = int(normalized.weapon_slots[slot])
	for id in normalized.quests: normalized.quests[id].progress = int(normalized.quests[id].progress)
	for key in normalized.skill_ranks: normalized.skill_ranks[key] = int(normalized.skill_ranks[key])
	for key in normalized.skill_charges: normalized.skill_charges[key] = int(normalized.skill_charges[key])
	for villager in normalized.villagers:
		for key in ["id", "hp", "max_hp"]: villager[key] = int(villager[key])
	for letter in normalized.letters: letter.day = int(letter.day)
	for gear in normalized.equipment:
		if gear.weapon not in ["armor", "ipetam"] and gear.affixes.is_empty(): gear.affixes = YinBalance.make_gear(gear.id, gear.weapon, gear.tier, gear.quality).affixes
		if gear.weapon == "ipetam": gear.artifact_kills = int(gear.artifact_kills)
		for affix in gear.affixes: affix.value = int(affix.value)
	for drop in normalized.gear_drops:
		if drop.gear.weapon != "armor" and drop.gear.affixes.is_empty(): drop.gear.affixes = YinBalance.make_gear(drop.gear.id, drop.gear.weapon, drop.gear.tier, drop.gear.quality).affixes
		for affix in drop.gear.affixes: affix.value = int(affix.value)
	# Keep old transported bodies accessible without retaining the transport system.
	for r in normalized.remains:
		if r.zone == "cargo":
			r.zone = "farm"
			r.at = [200.0,300.0]
	normalized.cargo = []
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
	if gear.get("enchantment", "") not in ["", "burn", "freeze", "lightning", "all"]: return false
	if gear.get("enchantment", "") == "all" and gear.weapon != "prajna": return false
	if gear.weapon == "prajna" and (gear.quality != 3 or gear.get("enchantment") != "all" or not gear.get("affixes") is Array or gear.affixes.size() != 2): return false
	if gear.weapon == "ipetam" and (not valid_int(gear.get("artifact_kills"), 0, 100000) or gear.quality != 3 or gear.get("enchantment", "") != "" or not gear.get("affixes") is Array or not gear.affixes.is_empty()): return false
	if not gear.get("affixes") is Array or gear.affixes.size() > 2: return false
	var used: Array = []
	for affix in gear.affixes:
		if not affix is Dictionary or affix.get("id") not in YinAbilities.AFFIXES or affix.id in used or not valid_int(affix.get("value"), 1, 25): return false
		if affix.id == "bleed" and affix.value > 6: return false
		if gear.weapon == "prajna" and affix.value != {"crit": 20, "bleed": 4}[affix.id]: return false
		used.append(affix.id)
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
		else:
			equipped_gear = id
			active_slot = gear_slot(gear.weapon)
			weapon_slots[active_slot] = id
		return true
	return false
func grant_gear(weapon: String, tier: int = 1, quality: int = 0) -> Dictionary:
	if equipment.size() >= 20 or weapon not in YinBalance.WEAPONS: return {}
	if weapon in ["ipetam", "prajna"] and equipment.any(func(g): return g.weapon == weapon): return {}
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
	add_drop("rifle_ammo" if enemy.kind in ["archer", "brute"] else "light_ammo", 5 + level_value, enemy.zone, at + Vector2(14, 10))
	if random.randf() < 0.75:
		add_drop(["wood", "stone", "scrap", "bone", "ash"][random.randi_range(0, 4)], random.randi_range(1, 3), enemy.zone, at + Vector2(0, 16))
	var chance: float = 0.65 if enemy.kind in YinAbilities.BOSSES else (0.35 if enemy.get("elite", false) else 0.12)
	if gear_drops.size() < 200 and random.randf() < chance:
		var roll: float = random.randf()
		var quality: int = 3 if roll > 0.98 else (2 if roll > 0.88 else (1 if roll > 0.6 else 0))
		if enemy.get("elite", false) or enemy.kind in YinAbilities.BOSSES: quality = maxi(1, quality)
		var weapon_roll: float = random.randf()
		var weapon: String = ["sword", "whip", "silver_sword"][random.randi_range(0, 2)] if weapon_roll < 0.45 else ("armor" if weapon_roll < 0.75 else (["spellbook", "curse_doll"][random.randi_range(0, 1)] if weapon_roll < 0.90 else YinBalance.GUNS[random.randi_range(0, 4)]))
		var gear := YinBalance.make_gear(next_gear_id, weapon, mini(20, level_value), quality)
		next_gear_id += 1
		gear_drops.append({"id": next_id, "gear": gear, "zone": enemy.zone, "at": [at.x - 14, at.y + 10]})
		next_id += 1

func salvage(id: int) -> String:
	if id in [equipped_gear, equipped_armor] or id in weapon_slots.values(): return "穿戴中的装备不可拆解。"
	for gear in equipment:
		if gear.id != id: continue
		if gear.weapon in ["ipetam", "prajna"]: return "成长神器不可拆解。"
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

static func gear_slot(weapon: String) -> String:
	return "melee" if weapon in YinBalance.MELEE else ("secondary" if weapon in ["pistol", "revolver", "curse_doll"] else "primary")
func cycle_weapon(direction: int) -> String:
	var names: Array = ["melee", "primary", "secondary"]
	var index: int = names.find(active_slot)
	for offset in range(1, 4):
		var slot: String = names[posmod(index + offset * direction, 3)]
		var id: int = int(weapon_slots[slot])
		if id > 0 and equip(id): return slot
	return active_slot
static func skill_spent(ranks: Dictionary) -> int:
	return int(ranks.get("seal", 1)) - 1 + int(ranks.get("fire", 0)) + int(ranks.get("breath", 0)) + int(ranks.get("command", 0))
func skill_points() -> int:
	return maxi(0, YinBalance.level(cultivation) - 1 - skill_spent(skill_ranks))
func learn_skill(id: String) -> String:
	if id not in YinAbilities.SKILLS: return "没有此技能。"
	var spec: Dictionary = YinAbilities.SKILLS[id]
	if skill_ranks[id] >= 3: return "技能已达三阶。"
	if skill_points() < 1: return "需要技能点，提升角色等级获得。"
	if YinBalance.level(cultivation) < spec.level or (spec.parent != "" and skill_ranks[spec.parent] == 0): return "等级不足或前置技能未学习。"
	skill_ranks[id] += 1
	return "已学习 %s 第 %d 阶。" % [spec.name, skill_ranks[id]]
func update_combat(delta: float) -> void:
	energy_fraction += delta * (0.5 + int(skill_ranks.breath) * 0.25)
	if energy_fraction >= 1:
		energy = mini(100, energy + int(energy_fraction))
		energy_fraction -= int(energy_fraction)
	for id in ["seal", "fire"]:
		if skill_ranks[id] < 1 or skill_charges[id] >= 2: continue
		var period: float = skill_recharge(id)
		skill_timers[id] += delta
		while skill_timers[id] >= period and skill_charges[id] < 2:
			skill_charges[id] += 1
			skill_timers[id] -= period
		if skill_charges[id] == 2: skill_timers[id] = 0.0
func skill_recharge(id: String) -> float:
	return float(YinAbilities.SKILLS[id].recharge) * (1.0 - maxi(0, int(skill_ranks[id]) - 1) * 0.15)
func spend_skill(id: String) -> bool:
	if id not in ["seal", "fire"] or skill_ranks[id] < 1 or skill_charges[id] < 1 or energy < YinAbilities.SKILLS[id].cost: return false
	energy -= int(YinAbilities.SKILLS[id].cost)
	skill_charges[id] -= 1
	return true
func deployment_used() -> int:
	var result: int = 0
	for spirit in spirits:
		if spirit.get("active", false) and spirit.get("hp", 1) > 0: result += 1
	return result
func deploy_spirit(id: int, active: bool) -> String:
	for spirit in spirits:
		if spirit.id != id: continue
		if active and spirit.hp <= 0: return "役灵已倒下，先疗养。"
		spirit.active = active
		spirit.assignment="follow" if active else "rest"
		return "已出战。" if active else "已召回义庄。"
	return "没有这位役灵。"
func dismiss_spirit(id: int) -> String:
	for spirit in spirits:
		if spirit.id == id:
			spirits.erase(spirit)
			return "已解除契约：" + spirit.name
	return "役灵已不在册。"
func gain_spirit_xp(spirit: Dictionary, amount: int) -> void:
	if spirit.level >= 10: return
	spirit.xp += amount
	while spirit.level < 10 and spirit.xp >= spirit.level * 40:
		spirit.xp -= spirit.level * 40
		spirit.level += 1
		spirit.max_hp = YinAbilities.spirit_hp(spirit.source_kind, spirit.level)
		spirit.hp = mini(spirit.max_hp, spirit.hp + 12)
	if spirit.level == 10: spirit.xp = 0
func train_spirit(id: int) -> String:
	for spirit in spirits:
		if spirit.id != id: continue
		if spirit.level >= 10: return "役灵已达十级。"
		if bones < 2: return "训练需要 2 骨料。"
		bones -= 2
		gain_spirit_xp(spirit, int(spirit.level) * 40)
		return "训练完成，技能强度随役灵等级成长。"
	return "没有这位役灵。"
func heal_spirit(id: int) -> String:
	for spirit in spirits:
		if spirit.id != id: continue
		if spirit.hp == spirit.max_hp: return "生命已满。"
		if oil < 3: return "疗养需要 3 灯油。"
		oil -= 3
		spirit.hp = spirit.max_hp
		return "疗养完成，倒下的役灵可重新出战。"
	return "没有这位役灵。"
func update_raid() -> bool:
	if raid_status == "warned" and day == raid_day and minutes >= 1080:
		raid_status = "active"
		defense_minute=day*1440+minutes
		for letter in letters:
			if letter.day == raid_day: letter.status = "active"
		for i in range(4 + mini(2, int(day / 6))):
			var enemy: Dictionary = spawn_record(["water", "bone", "archer", "brute"][i % 4], "village", Vector2(1080, 230 + i * 100), 1 + int(day / 6))
			enemy.raid = raid_day
		add_log("青槐村夜袭开始，村民正受到威胁。")
		return true
	if raid_status=="active" and zone!="village":resolve_village_guard()
	if raid_status == "active" and not enemies.any(func(e): return e.zone == "village" and int(e.get("raid", 0)) == raid_day and not e.dead):
		raid_status = "success"
		money += 30
		reputation += 2
		village_integrity = mini(100, village_integrity + 10)
		for letter in letters:
			if letter.day == raid_day: letter.status = "success"
		add_log("青槐村守住了。村民赠予 30 文，声望 +2。")
	return false
func settle_raid() -> void:
	if raid_status in ["warned", "active"] and day >= raid_day:
		raid_status = "failed"
		village_integrity = maxi(0, village_integrity - 20)
		for villager in villagers: villager.hp = maxi(0, villager.hp - 30)
		for enemy in enemies:
			if enemy.zone == "village" and int(enemy.get("raid", 0)) == raid_day: enemy.dead = true
		for letter in letters:
			if letter.day == raid_day: letter.status = "failed"
		add_log("未能守住青槐村：村庄完好度 -20，村民受伤。")

func artifact_hit(source_gear_id: int, actual_damage: int) -> int:
	if actual_damage <= 0: return 0
	for gear in equipment:
		if gear.id != source_gear_id or gear.weapon != "ipetam": continue
		var amount: int = mini(100 - health, maxi(1, floori(actual_damage * YinBalance.lifesteal(gear))))
		health += amount
		return amount
	return 0

func mainline_stages() -> Array:
	var strengths: Array=[]
	for id in YinFactions.IDS: strengths.append(YinFactions.strength(factions,id))
	strengths.sort()
	return [
		{"id":"gear","name":"整备旅装","done":equipment.any(func(g):return g.weapon!="armor" and int(g.tier)>=2),"hint":"击败精英或开启宝箱，获得二阶以上武器","reward":80},
		{"id":"journey","name":"走遍缝合世界","done":island_journal.visited and temple_journal.visited and not visited_landmarks.is_empty(),"hint":"调查后山地标，并抵达岛国与大佛寺","reward":120},
		{"id":"balance","name":"四方制衡","done":int(strengths.back())-int(strengths.front())<=45 and factions.wars.is_empty(),"hint":"援助弱方、拦截强方，实力差压到45以内且无交战","reward":200}]
func mainline_summary() -> String:
	var lines: Array[String]=[]
	for stage in mainline_stages():
		lines.append("%s %s · %s"%["已领" if stage.id in mainline_claimed else ("可领" if stage.done else "进行中"),stage.name,stage.hint])
	return "\n".join(lines)
func claim_mainline() -> String:
	for stage in mainline_stages():
		if stage.done and stage.id not in mainline_claimed:
			mainline_claimed.append(stage.id)
			money+=stage.reward
			cultivation+=25
			return "%s完成：%d文、25修为。"%[stage.name,stage.reward]
	return "暂没有可领取的奖励。探索、装备提升与势力调停都无需种田。"

func spirit_present(spirit: Dictionary,zone_name: String) -> bool:
	return spirit.active and spirit.hp>0 and (spirit.get("assignment","follow")=="follow" or zone_name=="village" and spirit.get("assignment")=="village")
func village_guards() -> Array:
	return spirits.filter(func(s):return s.active and s.hp>0 and s.get("assignment","")=="village")
func assign_spirit(id: int,duty: String,villager_id: int=0) -> String:
	if duty not in ["follow","village","rest"] or villager_id<0 or villager_id>6:return "无效指令。"
	for spirit in spirits:
		if spirit.id!=id:continue
		if duty!="rest" and spirit.hp<=0:return "役灵已倒下，先疗养。"
		spirit.assignment=duty
		spirit.guard_villager=villager_id
		spirit.active=duty!="rest"
		return spirit.name+{"follow":"已归队随行。","village":"已前往青槐村驻守；离开村庄后仍参与守卫。","rest":"已回义庄休整。"}[duty]
	return "没有这位役灵。"
func resolve_village_guard() -> void:
	var now: float=day*1440+minutes
	if defense_minute==0:defense_minute=now
	var turns: int=mini(24,int((now-defense_minute)/10))
	if turns<=0:return
	defense_minute=now
	for turn in range(turns):
		var defenders: Array=village_guards()
		var attackers: Array=enemies.filter(func(e):return e.zone=="village" and int(e.get("raid",0))==raid_day and not e.dead)
		if attackers.is_empty() or defenders.is_empty():break
		var damage: int=0
		for guard in defenders:damage+=YinAbilities.spirit_damage(guard)*2
		var target: Dictionary=attackers[0]
		target.hp=maxi(0,int(target.hp)-damage)
		var defender: Dictionary=defenders[turn%defenders.size()]
		defender.hp=maxi(0,int(defender.hp)-maxi(1,int(target.get("damage",9))/3))
		if defender.hp==0:defender.active=false;defender.assignment="rest"
		if target.hp==0:
			target.dead=true
			for guard in defenders:gain_spirit_xp(guard,10)
