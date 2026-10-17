class_name YinAdventure
extends RefCounted
const CHESTS = {
	"island_ruin": {"name":"潮痕遗匣","zone":"island","at":Vector2(1888,1488),"world_at":Vector2(5664,2072),"weapon":"silver_sword","tier":3},
	"temple_alms": {"name": "施食旧匣", "zone": "temple", "at": Vector2(576, 1056), "weapon": "silver_sword", "tier": 3},
	"temple_sutra": {"name": "梦障经匣", "zone": "temple", "at": Vector2(1376, 928), "weapon": "spellbook", "tier": 4},
	"grave_cache": {"name": "守墓人的箱子", "zone": "graveyard", "at": Vector2(448, 500), "weapon": "whip", "tier": 1},
	"forest_west": {"name": "猎人的旧箱", "zone": "forest", "at": Vector2(640, 768), "weapon": "revolver", "tier": 2},
	"camp_cache": {"name": "断碑军械箱", "zone": "forest", "at": Vector2(2304, 448), "weapon": "gatling", "tier": 3},
	"well_cache": {"name": "枯井密匣", "zone": "forest", "at": Vector2(2432, 1088), "weapon": "curse_doll", "tier": 3},
	"temple_cache": {"name": "山门经匣", "zone": "forest", "at": Vector2(2304, 1696), "weapon": "spellbook", "tier": 4},
	"sunken_cache": {"name": "沉水银匣", "zone": "sunken", "at": Vector2(1088, 704), "weapon": "silver_sword", "tier": 3},
	"theatre_cache": {"name": "戏台道具箱", "zone": "theatre", "at": Vector2(1088, 704), "weapon": "curse_doll", "tier": 3}
}
static func chest_at(id: String,continent: bool=false) -> Vector2:
	var spec: Dictionary=CHESTS[id]
	return spec.get("world_at",YinContinent.to_world(spec.zone,spec.at)) if continent else spec.at
const LANDMARKS = {
	"camp": {"name": "断碑营地", "at": Vector2(2304, 384)},
	"well": {"name": "枯井", "at": Vector2(2432, 1024)},
	"temple": {"name": "山门遗址", "at": Vector2(2304, 1632)}
}
const QUESTS = {
	"first_watch": {"npc":0,"name":"初次守夜","kind":"hunt","target":2,"money":35,"weapon":"silver_sword","description":"义庄告示：沿东路跨过界河桥前往乱葬岗，击败两只异怪。红圈亮起时先闪避，镇符可打断。返回义庄，在O委托页领取二阶银剑与35文，再按B换装。"},
	"temple_arrival": {"npc": 6, "name": "北山梵影", "kind": "temple_visit", "target": 1, "money": 40, "weapon": "", "description": "砚青请你沿青槐村北侧山道进入大佛寺，记录缝合而来的护法异境。"},
	"temple_catalog": {"npc": 2, "name": "四障异闻", "kind": "temple_hunt", "target": 4, "money": 90, "weapon": "", "parent": "temple_arrival", "description": "秋婶请你分别调查饿鬼、幽魂、罗刹、鸠槃茶。镇符可破虚化幻身，先处理遗骸可阻饿鬼吞食。"},
	"temple_wrath": {"npc": 1, "name": "止息修罗", "kind": "temple_boss", "boss": "asura", "target": 1, "money": 130, "weapon": "", "parent": "temple_catalog", "description": "柳伯请你平息阿修罗的争斗嗔怒。六臂战阵留有空隙，半血后的战意更盛。"},
	"temple_guardian": {"npc": 6, "name": "守藏之问", "kind": "temple_boss", "boss": "yaksha", "target": 1, "money": 160, "weapon": "", "parent": "temple_wrath", "description": "砚青请你前往大佛下的护法殿，挑战守藏夜叉。镇符可破护障，避开疾刺路线。"},
	"temple_wisdom": {"npc": 3, "name": "般若开锋", "kind": "temple_relic", "target": 1, "money": 60, "weapon": "prajna", "parent": "temple_guardian", "description": "向阿祁讲述佛寺四障与两位护法的见闻，领取文殊般若剑。剑随修为成长，每次命中三相附魔共存。"},
	"island_arrival": {"npc": 6, "name": "裂海异乡", "kind": "island_visit", "target": 1, "money": 35, "weapon": "", "description": "沿界河桥与北行驿路抵达东北岛国，再向砚青讲述缝合海岸。"},
	"island_catalog": {"npc": 6, "name": "五妖异闻", "kind": "island_hunt", "target": 5, "money": 80, "weapon": "", "parent": "island_arrival", "description": "分别击败河童、提灯妖怪、一本踏鞴、络新妇、丛原火，记录它们的特点。"},
	"island_lament": {"npc": 2, "name": "何时安葬", "kind": "island_boss", "boss": "itsumade", "target": 1, "money": 100, "weapon": "", "parent": "island_catalog", "description": "找秋婶接续异闻；超度荒冢附近遗骸可削弱以津真天，平息金羽毒鸣后复命。"},
	"island_gale": {"npc": 6, "name": "风山修验", "kind": "island_boss", "boss": "daitengu", "target": 1, "money": 120, "weapon": "", "parent": "island_lament", "description": "砚青请你登风山。镇符可打断大天狗的风障蓄势；击败后归还山路。"},
	"island_dual": {"npc": 1, "name": "双面四臂", "kind": "island_boss", "boss": "ryomen_sukuna", "target": 1, "money": 150, "weapon": "", "parent": "island_gale", "description": "向柳伯接令，进入双面社，避开两面宿傩交替的双向剑弓，完成武人试炼。"},
	"island_blade": {"npc": 3, "name": "饥刃缔约", "kind": "island_relic", "target": 1, "money": 60, "weapon": "ipetam", "parent": "island_dual", "description": "带三处祭场平息的见闻找阿祁，由他见证与嗜血神器伊佩塔姆的契约。"},
	"grave_patrol": {"npc": 1, "name": "清理乱葬坡", "kind": "hunt", "target": 4, "money": 65, "weapon": "whip", "description": "在乱葬坡击败四只鬼物，回村向柳伯复命。"},
	"lamp_supplies": {"npc": 4, "name": "修复村口纸灯", "kind": "delivery", "target": 3, "item": "wood", "money": 45, "weapon": "revolver", "description": "交给灯匠小满三份槐木，修好村口纸灯。"},
	"forge_supplies": {"npc": 3, "name": "重铸银剑", "kind": "delivery", "target": 3, "item": "scrap", "money": 30, "weapon": "silver_sword", "description": "交给铁匠阿祁三份零件，换取一把银剑。"},
	"lost_records": {"npc": 6, "name": "后山遗迹调查", "kind": "survey", "target": 3, "money": 100, "weapon": "spellbook", "description": "调查后山遗址或四方领地的遗留物，记录三处见闻，再找砚青。"}
}
static func accept(state, id: String) -> String:
	if not QUESTS.has(id): return "没有这项委托。"
	if not available(state, id): return "前置委托尚未复命。"
	if state.quests.has(id): return "这项委托已经接取。"
	state.quests[id] = {"progress": 0, "claimed": false}
	state.tracked_quest = id
	return "接取委托：" + QUESTS[id].name
static func progress(state, id: String) -> int:
	if not state.quests.has(id) or not QUESTS.has(id): return 0
	var spec: Dictionary = QUESTS[id]
	if spec.kind == "temple_visit": return 1 if state.temple_journal.visited else 0
	if spec.kind == "temple_hunt": return state.temple_journal.hunted.size()
	if spec.kind == "temple_boss": return 1 if spec.boss in state.temple_journal.defeated else 0
	if spec.kind == "temple_relic": return 1 if "yaksha" in state.temple_journal.defeated else 0
	if spec.kind == "island_visit": return 1 if state.island_journal.visited else 0
	if spec.kind == "island_hunt": return state.island_journal.hunted.size()
	if spec.kind == "island_boss": return 1 if spec.boss in state.island_journal.defeated else 0
	if spec.kind == "island_relic": return 1 if "ryomen_sukuna" in state.island_journal.defeated else 0
	if spec.kind == "delivery": return mini(spec.target, state.container_count("bag", spec.item))
	if spec.kind == "survey": return mini(spec.target, state.visited_landmarks.size()+state.world_echoes.size())
	return mini(spec.target, int(state.quests[id].progress))
static func on_kill(state, enemy: Dictionary) -> void:
	if enemy.zone=="graveyard" and not enemy.has("war_id") and state.quests.has("first_watch") and not state.quests.first_watch.claimed:
		state.quests.first_watch.progress=mini(2,int(state.quests.first_watch.progress)+1)
	if enemy.zone != "graveyard" or not state.quests.has("grave_patrol"): return
	var quest: Dictionary = state.quests.grave_patrol
	if not quest.claimed: quest.progress = mini(4, int(quest.progress) + 1)
static func claim(state, id: String, npc_id: int) -> String:
	if not QUESTS.has(id) or not state.quests.has(id): return "尚未接取。"
	var spec: Dictionary = QUESTS[id]
	if id=="first_watch" and state.zone!="farm":return "请先返回义庄，在告示处复命。"
	if spec.npc != npc_id: return "请向委托人复命。"
	if state.quests[id].claimed: return "奖励已经领取。"
	if progress(state, id) < spec.target: return "委托尚未完成。"
	if spec.weapon != "" and state.equipment.size() >= 20: return "装备位已满，请先整理，再来领取。"
	if spec.kind == "delivery": state.set_container_count("bag", spec.item, state.container_count("bag", spec.item) - spec.target)
	if spec.weapon != "":
		if spec.weapon not in ["ipetam", "prajna"] or not state.equipment.any(func(g): return g.weapon == spec.weapon): state.grant_gear(spec.weapon, 2, 1)
	state.money += spec.money
	state.quests[id].claimed = true
	if state.tracked_quest == id: state.tracked_quest = ""
	state.add_log("完成委托：" + spec.name)
	return "委托完成：%d 文%s。" % [spec.money, "与" + YinBalance.WEAPONS[spec.weapon].name if spec.weapon != "" else ""]
static func open_chest(state, id: String, player_at: Vector2) -> String:
	if not CHESTS.has(id): return "没有这个宝箱。"
	var spec: Dictionary = CHESTS[id]
	if id in state.opened_chests: return "宝箱已经打开。"
	var position_value: Vector2=chest_at(id,state.continent_ready)
	if (not state.continent_ready and spec.zone != state.zone) or player_at.distance_to(position_value) > 56: return "走近宝箱再开启。"
	if state.enemies.any(func(e): return e.zone == spec.zone and not e.dead and Vector2(e.at[0], e.at[1]).distance_to(position_value) < 150): return "附近仍有守卫，先清理再开箱。"
	var supplies: Dictionary = {"light_ammo": 12, "rifle_ammo": 6, "scrap": 1}
	if state.equipment.size() >= 20 or not state.can_gain_many(supplies): return "装备或行囊已满，宝箱奖励仍保留。"
	var gear: Dictionary = state.grant_gear(spec.weapon, spec.tier, 2)
	for item in supplies: state.set_container_count("bag", item, state.container_count("bag", item) + supplies[item])
	state.money += 20 * spec.tier
	state.opened_chests.append(id)
	return "获得 %s、弹药、零件与 %d 文。" % [YinBalance.gear_name(gear), 20 * spec.tier]
static func validate(data: Dictionary) -> bool:
	if data.opened_chests.size() > CHESTS.size() or data.visited_landmarks.size() > LANDMARKS.size() or data.quests.size() > QUESTS.size(): return false
	var opened: Array = []
	for id in data.opened_chests:
		if not id is String or not CHESTS.has(id) or id in opened: return false
		opened.append(id)
	for id in data.visited_landmarks:
		if not id is String or not LANDMARKS.has(id) or data.visited_landmarks[id] != true: return false
	for id in data.quests:
		if not QUESTS.has(id) or not data.quests[id] is Dictionary: return false
		var quest: Dictionary = data.quests[id]
		if id=="first_watch" and quest.has("equipped") and not quest.equipped is bool:return false
		if not quest.get("claimed") is bool or not FarmState.valid_int(quest.get("progress"), 0, QUESTS[id].target): return false
	return data.tracked_quest == "" or (data.quests.has(data.tracked_quest) and not data.quests[data.tracked_quest].claimed)

static func available(state, id: String) -> bool:
	if not QUESTS.has(id): return false
	var parent: String = QUESTS[id].get("parent", "")
	return parent == "" or (state.quests.has(parent) and state.quests[parent].claimed)
