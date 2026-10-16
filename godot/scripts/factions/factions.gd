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
		if s.continent_ready and YinTerritory28.region_for(s,attacker)=="":continue
		for defender in IDS:
			if s.continent_ready and YinTerritory28.region_for(s,defender)=="":continue
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
	var war: Dictionary = {"id": int(data.next_war), "day": s.day, "attacker": attacker, "defender": defender, "status": "warned", "last_skirmish": float(s.day*1440+s.minutes), "player_side":"", "player_kills":0, "attackers": clampi(roundi(3 + ratio * 2), 4, 9), "defenders": clampi(roundi(strength(data, defender) / 28.0), 3, 7)}
	if s.continent_ready:
		war.target_region=YinTerritory28.region_for(s,defender)
		if war.target_region=="":return {}
	data.next_war += 1
	data.wars.append(war)
	s.add_log("势力战报：%s将于正午集结，进军%s。P 查看行军。" % [NAMES[attacker], NAMES[defender]])
	return war

static func deploy(s, war: Dictionary) -> void:
	war.status = "active"
	war.last_skirmish=float(s.day*1440+s.minutes)
	for side in ["attacker", "defender"]:
		var id: String = war[side]
		var count: int = int(war.attackers if side == "attacker" else war.defenders)
		for i in range(count):
			var kind: String = {"temple": ["hungry_ghost", "rakshasa", "kumbhanda"], "island": ["kappa", "chochin", "ippon_datara"], "graveyard": ["bone", "water", "brute"], "village": ["gunner", "archer", "bone"]}[id][i % 3]
			var at := Vector2((760 if side == "attacker" else 520) + (i % 2) * 34, 280 + int(i / 2) * 52)
			var e: Dictionary = s.spawn_record(kind, war.defender, at, 1 + strength(s.factions, id) / 100)
			if s.continent_ready:
				var region: String=YinTerritory28.region_for(s,id)
				var muster: Vector2=YinContinent.CAPITALS[region if region!="" else id]+Vector2((i%3)*32-32,80+int(i/3)*32)
				e.at=[muster.x,muster.y]
			e.faction = id
			e.war_id = int(war.id)
			e.war_side = side
			e.hp = 50 + strength(s.factions, id) / 4
			e.max_hp = e.hp
			e.damage = 9 + strength(s.factions, id) / 25
	s.add_log("出征：%s进军%s，双方队伍已集结，沿桥行军。" % [NAMES[war.attacker], NAMES[war.defender]])

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
	if s.continent_ready and war.get("player_side","")!="":
		for e in survivors(s,war,war.player_side):e.player_allied=true
	if attacker_won and s.continent_ready:
		YinTerritory28.occupy(s,war.get("target_region",war.defender),war.attacker,survivors(s,war,"attacker"))
	elif s.continent_ready:
		YinTerritory28.station(s,war.get("target_region",war.defender),war.defender,survivors(s,war,"defender"))
	for e in s.enemies:
		if int(e.get("war_id", 0)) == int(war.id) and not e.dead:
			if s.continent_ready:
				e.erase("war_id");e.erase("war_side")
				e.returning_region=YinTerritory28.region_for(s,e.faction)
				if e.returning_region=="":e.returning_region=e.faction
			else:e.dead=true
	var contribution: bool=int(war.get("player_kills",0))>0 or (war.defender=="village" and not s.village_guards().is_empty())
	if contribution:
		s.money+=45
		s.cultivation+=15
		s.reputation+=1
		s.add_log("参战贡献：45文、15修为。驻村随从与击杀均计入。")
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
		if not s.continent_ready:simulate_offscreen(s,war)
		var attackers: Array = survivors(s, war, "attacker")
		var defenders: Array = survivors(s, war, "defender")
		if s.continent_ready and defenders.is_empty() and not attackers.is_empty():
			# The living army must reach and hold the capital before ownership changes.
			continue
		if attackers.is_empty() or defenders.is_empty():
			settle(s, war, not attackers.is_empty())
			changed = true
		elif not s.continent_ready and (s.day > war.day or s.minutes >= 1200):
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
		lines.append("%s → %s · %s · %d 对 %d\n正午集结，经桥行军；直到一方军队覆灭才决出胜负。全境均可参战。" % [NAMES[war.attacker], NAMES[war.defender], "待集结" if war.status == "warned" else "行军 / 实体接战", war.attackers, war.defenders])
		if war.status=="active" and s.continent_ready and survivors(s,war,"defender").is_empty():lines.append("正向%s据点推进 · 守旗进度%d%%"%[NAMES[war.get("target_region",war.defender)],int(float(war.get("capture_seconds",0))/6*100)])
		if war.status=="active":lines.append("存活：攻方%d/%d · 守方%d/%d · 你的击杀%d\n支援：%s"%[survivors(s,war,"attacker").size(),war.attackers,survivors(s,war,"defender").size(),war.defenders,int(war.get("player_kills",0)),{"":"尚未选择","attacker":"攻方","defender":"守方"}.get(war.get("player_side",""),"无")])
	if s.factions.wars.is_empty(): lines.append("当前休整。每天恢复兵力与物资，各方都有机会向其他势力出兵。")
	lines.append("最近战报\n" + ("\n".join(s.factions.history) if not s.factions.history.is_empty() else "尚无战报。"))
	if s.continent_ready:lines.append(YinTerritory28.report(s))
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
		if war.has("target_region") and war.target_region not in IDS:return false
		if war.has("capture_seconds"):
			if not (war.capture_seconds is int or war.capture_seconds is float) or not is_finite(float(war.capture_seconds)) or war.capture_seconds<0 or war.capture_seconds>6:return false
		if war.get("player_side","") not in ["","attacker","defender"] or not FarmState.valid_int(war.get("player_kills",0),0,1000):return false
		var stamp: Variant=war.get("last_skirmish",0)
		if not (stamp is float or stamp is int) or not is_finite(float(stamp)) or stamp<0 or stamp>100000000:return false
		for key in ["id", "day", "attackers", "defenders"]:
			if not FarmState.valid_int(war.get(key), 1, 9 if key in ["attackers", "defenders"] else 100000000): return false
	return true

static func normalize(data: Dictionary) -> void:
	for key in ["last_day", "next_war", "sponsored_day"]: data[key] = int(data[key])
	for p in data.powers.values():
		for key in ["troops", "supply"]: p[key] = int(p[key])
	for war in data.wars:
		for key in ["id", "day", "attackers", "defenders"]: war[key] = int(war[key])
		if war.has("player_kills"):war.player_kills=int(war.player_kills)

static func aid_weakest(s) -> String:
	if s.factions.sponsored_day == s.day: return "今日已援助过势力，明日再来。"
	if s.money<30: return "需要30文，可通过探索宝箱、战斗与委托取得。"
	var weakest: String=IDS[0]
	for id in IDS:
		if strength(s.factions,id)<strength(s.factions,weakest):weakest=id
	s.money-=30
	s.factions.sponsored_day=s.day
	s.factions.powers[weakest].troops=mini(180,int(s.factions.powers[weakest].troops)+12)
	s.factions.powers[weakest].supply=mini(140,int(s.factions.powers[weakest].supply)+15)
	return "援助%s：兵力+12，物资+15。"%NAMES[weakest]

static func friendly(s,record: Dictionary) -> bool:
	if record.get("faction","")=="village" or record.get("player_allied",false):return true
	for war in s.factions.wars:
		if int(war.id)==int(record.get("war_id",0)) and war.get("player_side","")!="":return war.player_side==record.get("war_side","")
	return false
static func choose_side(s,id: int,side: String) -> String:
	if side not in ["attacker","defender"]:return "无效阵营。"
	for war in s.factions.wars:
		if int(war.id)!=id:continue
		if war.get("player_side","")!="" and war.player_side!=side:return "本场已经承诺支援一方，不能临阵反复。"
		war.player_side=side
		return "已支援%s；其军队不会将你视为敌人。"%NAMES[war[side]]
	return "战事已结束。"
static func simulate_offscreen(s,war: Dictionary) -> void:
	if s.continent_ready:return
	var now: float=s.day*1440+s.minutes
	if not war.has("last_skirmish"):
		war.last_skirmish=now
		return
	var previous: float=float(war.last_skirmish)
	if s.zone==war.defender:
		war.last_skirmish=now
		return
	var turns: int=mini(24,int((now-previous)/20))
	if turns<=0:return
	war.last_skirmish=now
	for turn in range(turns):
		var attackers: Array=survivors(s,war,"attacker")
		var defenders: Array=survivors(s,war,"defender")
		if s.continent_ready and defenders.is_empty() and not attackers.is_empty():
			# The living army must reach and hold the capital before ownership changes.
			continue
		if attackers.is_empty() or defenders.is_empty():break
		var attacking_damage: int=0
		var defending_damage: int=0
		for e in attackers:attacking_damage+=maxi(1,int(e.damage)/3)
		for e in defenders:defending_damage+=maxi(1,int(e.damage)/3)
		var guards: Array=s.village_guards() if war.defender=="village" else []
		for guard in guards:defending_damage+=YinAbilities.spirit_damage(guard)
		var a: Dictionary=attackers[turn%attackers.size()]
		var d: Dictionary=defenders[turn%defenders.size()]
		a.hp=maxi(0,int(a.hp)-defending_damage)
		d.hp=maxi(0,int(d.hp)-attacking_damage)
		if a.hp==0:a.dead=true
		if d.hp==0:d.dead=true
		if not guards.is_empty():
			var guard: Dictionary=guards[turn%guards.size()]
			guard.hp=maxi(0,int(guard.hp)-2)
			if guard.hp==0:guard.active=false;guard.assignment="rest"
			if a.dead:
				for helper in guards:s.gain_spirit_xp(helper,8)
