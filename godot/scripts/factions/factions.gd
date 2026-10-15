class_name YinFactions
extends RefCounted
const IDS = ["temple", "island", "graveyard", "village"]
const NAMES = {"temple": "大佛寺", "island": "岛国", "graveyard": "乱葬岗", "village": "青槐村"}
const COLORS = {"temple": Color("d6ba6d"), "island": Color("c46e61"), "graveyard": Color("a48bc3"), "village": Color("8fbd81")}

static func initial() -> Dictionary:
	return {"last_day": 0, "next_war": 1, "sponsored_day": 0, "powers": {"temple": {"troops": 105, "supply": 90}, "island": {"troops": 120, "supply": 100}, "graveyard": {"troops": 85, "supply": 75}, "village": {"troops": 60, "supply": 65}}, "wars": [], "history": []}

static func strength(data: Dictionary, id: String) -> int:
	return int(data.powers[id].troops) + int(data.powers[id].supply) / 2

static func aggression(attacker: int, defender: int) -> float:
	return clampf(0.24 * float(attacker) / maxi(1, defender), 0.08, 0.82)

static func plan(s) -> void:
	var data: Dictionary = s.factions
	if data.last_day >= s.day: return
	data.last_day = s.day
	for id in IDS:
		data.powers[id].troops = mini(180, int(data.powers[id].troops) + 7)
		data.powers[id].supply = mini(140, int(data.powers[id].supply) + 5)
	# Seeded per day: reloading cannot reroll diplomacy.
	var rng := RandomNumberGenerator.new()
	rng.seed = s.day * 7919 + int(data.next_war) * 101
	var candidates: Array = []
	for attacker in IDS:
		for defender in IDS:
			if attacker == defender: continue
			var chance: float = aggression(strength(data, attacker), strength(data, defender))
			if rng.randf() < chance:
				candidates.append({"attacker": attacker, "defender": defender, "priority": chance + rng.randf() * 0.2})
	candidates.sort_custom(func(a, b): return a.priority > b.priority)
	# One expedition per day keeps battles readable and gives weak factions recovery time.
	for candidate in candidates:
		if not data.wars.is_empty(): break
		if candidate.defender == "village" and s.day % 3 == 0: continue
		declare(s, candidate.attacker, candidate.defender)
		break

static func declare(s, attacker: String, defender: String) -> Dictionary:
	var data: Dictionary = s.factions
	if attacker not in IDS or defender not in IDS or attacker == defender or not data.wars.is_empty(): return {}
	var ratio: float = float(strength(data, attacker)) / maxi(1, strength(data, defender))
	var war: Dictionary = {"id": int(data.next_war), "day": s.day, "attacker": attacker, "defender": defender, "status": "warned", "attackers": clampi(roundi(3 + ratio * 2), 4, 9), "defenders": clampi(roundi(strength(data, defender) / 28.0), 3, 7)}
	data.next_war += 1
	data.wars.append(war)
	s.add_log("势力战报：%s将于正午进攻%s。P 查看局势。" % [NAMES[attacker], NAMES[defender]])
	return war

static func deploy(s, war: Dictionary) -> void:
	war.status = "active"
	for side in ["attacker", "defender"]:
		var id: String = war[side]
		var count: int = int(war.attackers if side == "attacker" else war.defenders)
		for i in range(count):
			var kind: String = {"temple": ["hungry_ghost", "rakshasa", "kumbhanda"], "island": ["kappa", "chochin", "ippon_datara"], "graveyard": ["bone", "water", "brute"], "village": ["gunner", "archer", "bone"]}[id][i % 3]
			var at := Vector2((760 if side == "attacker" else 520) + (i % 2) * 34, 280 + int(i / 2) * 52)
			var e: Dictionary = s.spawn_record(kind, war.defender, at, 1 + strength(s.factions, id) / 100)
			e.faction = id
			e.war_id = int(war.id)
			e.war_side = side
			e.hp = 50 + strength(s.factions, id) / 4
			e.max_hp = e.hp
			e.damage = 9 + strength(s.factions, id) / 25
	s.add_log("交战：%s进军%s，双方队伍已接战。" % [NAMES[war.attacker], NAMES[war.defender]])

static func survivors(s, war: Dictionary, side: String) -> Array:
	return s.enemies.filter(func(e): return int(e.get("war_id", 0)) == int(war.id) and e.get("war_side", "") == side and not e.dead)

static func settle(s, war: Dictionary, attacker_won: bool) -> void:
	var data: Dictionary = s.factions
	if war.status == "settled": return
	war.status = "settled"
	var winner: String = war.attacker if attacker_won else war.defender
	var loser: String = war.defender if attacker_won else war.attacker
	var severity: int = clampi(roundi(10.0 * strength(data, winner) / maxi(1, strength(data, loser))), 8, 26)
	data.powers[loser].troops = maxi(25, int(data.powers[loser].troops) - severity)
	data.powers[winner].troops = maxi(25, int(data.powers[winner].troops) - 5)
	var loot: int = mini(severity, int(data.powers[loser].supply))
	data.powers[loser].supply -= loot
	data.powers[winner].supply = mini(140, int(data.powers[winner].supply) + loot)
	if attacker_won and war.defender == "village":
		s.village_integrity = maxi(0, s.village_integrity - severity)
		for villager in s.villagers: villager.hp = maxi(1, int(villager.hp) - severity / 2)
	for e in s.enemies:
		if int(e.get("war_id", 0)) == int(war.id): e.dead = true
	var line: String = "第%d日：%s战胜%s，败方损失%d兵力、%d物资。" % [s.day, NAMES[winner], NAMES[loser], severity, loot]
	data.history.push_front(line)
	if data.history.size() > 12: data.history.resize(12)
	s.add_log(line)

static func tick(s) -> bool:
	plan(s)
	var changed: bool = false
	for war in s.factions.wars:
		if war.status == "warned" and (s.day > war.day or s.minutes >= 720):
			deploy(s, war)
			changed = true
		if war.status != "active": continue
		var attackers: Array = survivors(s, war, "attacker")
		var defenders: Array = survivors(s, war, "defender")
		if attackers.is_empty() or defenders.is_empty():
			settle(s, war, not attackers.is_empty())
			changed = true
		elif s.day > war.day or s.minutes >= 1200:
			var attack_hp: int = 0
			var defend_hp: int = 0
			for e in attackers: attack_hp += int(e.hp)
			for e in defenders: defend_hp += int(e.hp)
			settle(s, war, attack_hp > defend_hp * 1.15)
			changed = true
	s.factions.wars = s.factions.wars.filter(func(w): return w.status != "settled")
	return changed

static func sponsor(s) -> String:
	if s.factions.sponsored_day == s.day: return "今日已运送过物资。"
	if s.money < 30: return "需要 30 文军资。"
	s.money -= 30
	s.factions.sponsored_day = s.day
	var village: Dictionary = s.factions.powers.village
	village.troops = mini(180, int(village.troops) + 12)
	village.supply = mini(140, int(village.supply) + 15)
	return "青槐村获得 12 兵力、15 物资；此后出兵与防守均受实力影响。"

static func report(s) -> String:
	var lines: Array[String] = ["实力 = 兵力 + 半数物资。强方更易侵袭弱方，兵力差决定远征规模与战败掠夺。"]
	for id in IDS:
		var p: Dictionary = s.factions.powers[id]
		lines.append("%s   实力 %d   兵力 %d / 物资 %d" % [NAMES[id], strength(s.factions, id), p.troops, p.supply])
	for war in s.factions.wars:
		lines.append("%s → %s · %s · %d 对 %d\n正午开战，入夜结算；前往守方地图可参战。" % [NAMES[war.attacker], NAMES[war.defender], "行军中" if war.status == "warned" else "交战中", war.attackers, war.defenders])
	if s.factions.wars.is_empty(): lines.append("当前休整。每天恢复兵力与物资，各方都有机会向其他势力出兵。")
	lines.append("最近战报\n" + ("\n".join(s.factions.history) if not s.factions.history.is_empty() else "尚无战报。"))
	return "\n\n".join(lines)

static func validate(data: Dictionary) -> bool:
	if data.size() != 6: return false
	for key in ["last_day", "next_war", "sponsored_day"]:
		if not FarmState.valid_int(data.get(key), 0): return false
	if not data.get("powers") is Dictionary or data.powers.size() != IDS.size(): return false
	for id in IDS:
		if not data.powers.get(id) is Dictionary: return false
		for key in ["troops", "supply"]:
			if not FarmState.valid_int(data.powers[id].get(key), 0, 180 if key == "troops" else 140): return false
	if not data.get("history") is Array or data.history.size() > 12: return false
	for line in data.history:
		if not line is String or line.length() > 250: return false
	if not data.get("wars") is Array or data.wars.size() > 1: return false
	for war in data.wars:
		if not war is Dictionary: return false
		if int(war.get("id", 0)) >= int(data.next_war): return false
		if war.get("attacker") not in IDS or war.get("defender") not in IDS or war.attacker == war.defender: return false
		if war.get("status") not in ["warned", "active"]: return false
		for key in ["id", "day", "attackers", "defenders"]:
			if not FarmState.valid_int(war.get(key), 1, 9 if key in ["attackers", "defenders"] else 100000000): return false
	return true

static func normalize(data: Dictionary) -> void:
	for key in ["last_day", "next_war", "sponsored_day"]: data[key] = int(data[key])
	for p in data.powers.values():
		for key in ["troops", "supply"]: p[key] = int(p[key])
	for war in data.wars:
		for key in ["id", "day", "attackers", "defenders"]: war[key] = int(war[key])
