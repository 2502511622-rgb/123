class_name YinNpcDialogue
extends RefCounted
# Offline intent rules and short conversation memory, not a network or local LLM.
var previous_topics: Dictionary = {}
func reply(state, npc: Dictionary, message: String) -> String:
	message = message.strip_edges().substr(0, 500)
	if message == "": return "想问什么？可以聊委托、宝箱、武器或村里的近况。"
	var topic: String = "greeting"
	if "委托" in message or "帮" in message or "任务" in message: topic = "quest"
	elif "宝箱" in message or "探索" in message or "地图" in message: topic = "explore"
	elif "武器" in message or "附魔" in message or "冰" in message or "火" in message: topic = "weapon"
	elif "断头" in message or "鬼" in message or "怪" in message: topic = "enemy"
	elif "救" in message or "夜" in message or "近况" in message: topic = "raid"
	elif "再说" in message or "然后" in message: topic = previous_topics.get(npc.id, "greeting")
	previous_topics[npc.id] = topic
	if npc.hp <= 0: return "我受伤了……先护住其他村民，等安全后帮我疗伤。"
	match topic:
		"quest":
			for id in YinAdventure.QUESTS:
				var spec: Dictionary = YinAdventure.QUESTS[id]
				if spec.npc != int(npc.id): continue
				if not state.quests.has(id): return spec.description + " 你愿意接下吗？在委托菜单确认即可。"
				if state.quests[id].claimed: return "上次的事多亏你了，报酬已经交给你。"
				if YinAdventure.progress(state, id) >= spec.target: return "事情办妥了。打开委托菜单复命，我把报酬交给你。"
				return "还差一点。%s 目前 %d/%d。" % [spec.description, YinAdventure.progress(state, id), spec.target]
			return "我暂时没有委托。柳伯、小满、阿祁和砚青正需要帮忙。"
		"explore": return "主路连接出入口，东侧支路通向断碑营地、枯井、山门。箱子附近有守卫，腾出行囊再去。"
		"weapon": return "鞭子够远，银剑稳，左轮每发都得算着打。魔法书与娃娃耗气力。燃烧持续灼伤，冰冻减速，闪电跳跃；火冰会消解。"
		"enemy": return "鬼物断腿会跛行，断头后会乱窜，无法再攻击；不过已经射出的弹丸仍有危险。"
		"raid": return "今夜正需援手，先看书信，护住村里人。" if state.raid_status in ["warned", "active"] else "村庄完好度 %d。每三日可能收到求救信，黄昏前做好准备。" % state.village_integrity
	return {1: "村里的路要靠大家守住。先清理乱葬坡，再往后山走。", 2: "身上带伤，就来找我。别把气力全耗在一次施术上。", 3: "没有一把兵器适合所有敌人。留好副武器，换着打。", 4: "三份槐木就够修灯了；余下的路，我替你照着。", 5: "村西的田还能种。种田、护村、探索，都能谋生。", 6: "我想知道后山三处遗址还留下什么。亲自走到那里，回来告诉我。"}.get(int(npc.id), "小心夜路。")
