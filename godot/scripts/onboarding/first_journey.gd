class_name YinFirstJourney
extends RefCounted
const ID="first_watch"
static func start(state) -> void:
	if not state.quests.has(ID):YinAdventure.accept(state,ID)
	if not state.quests[ID].claimed:state.tracked_quest=ID
static func guide(state) -> Dictionary:
	if not state.quests.has(ID):return {}
	if state.tracked_quest!="" and state.tracked_quest!=ID:return {}
	var quest: Dictionary=state.quests[ID]
	if not quest.claimed:
		if YinAdventure.progress(state,ID)<2:
			var enemies: Array=state.enemies.filter(func(e):return e.zone=="graveyard" and not e.dead and not e.has("war_id"))
			var target: Vector2=Vector2(enemies[0].at[0],enemies[0].at[1]) if not enemies.is_empty() else Vector2(280,240)
			return {"title":"初次守夜 · %d/2"%YinAdventure.progress(state,ID),"hint":"东南灯门 → 乱葬坡" if state.zone=="farm" else "击败异怪 · 红圈亮起先闪避", "at":Vector2(846,501) if state.zone=="farm" else target,"zone":"farm" if state.zone=="farm" else "graveyard"}
		return {"title":"守夜完成 · 领取银剑","hint":"O复命 · 领取银剑与35文" if state.zone=="farm" else "西南灯门返回义庄 · O复命", "at":Vector2(155,547),"zone":"graveyard"}
	if quest.get("equipped",false):return {}
	var reward: Array=state.equipment.filter(func(g):return g.weapon=="silver_sword" and g.tier>=2)
	if not reward.is_empty() and state.weapon_slots.melee!=reward[0].id:
		return {"title":"新银剑已入行囊","hint":"B 打开装备 · 对比并换上银剑", "zone":"","at":Vector2.ZERO}
	return {}
