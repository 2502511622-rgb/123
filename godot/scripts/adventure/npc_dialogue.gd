class_name YinNpcDialogue
extends RefCounted
# Offline intent rules and short conversation memory, not a network or local LLM.
var previous_topics: Dictionary = {}
func reply(state, npc: Dictionary, message: String) -> String:
	message = message.strip_edges().substr(0, 500)
	if message == "": return "想问什么？可以聊委托、宝箱、武器或村里的近况。"
	if "势力" in message or "进攻" in message or "战况" in message: return YinFactions.report(state)
	if "文殊" in message or "般若" in message: return "般若剑随你的修为成长。每次命中都让燃烧、冰冻、闪电共存，无需刻录。完成砚青、秋婶、柳伯的佛寺调查，再请阿祁开锋。"
	if "饿鬼" in message: return "饿鬼细喉大腹，饥渴难填；会吞附近遗骸疗伤，咬中还会夺气。先超度遗骸，燃烧和镇符也能阻止吞食。"
	if "幽魂" in message: return "幽魂没有可斩落的肢体，魂躯能削弱刀枪；镇符让它显形，符火和附魔也能穿透虚化。"
	if "罗刹" in message: return "罗刹善幻化、持毒刃。紫色幻身会绕侧并削弱刀枪伤害，镇符可破幻，别追着影子打。"
	if "鸠槃茶" in message or "鸠槃荼" in message: return "大腹梦鬼也称鸠槃荼，会以梦压飞珠拖慢身形、夺取气力。飞珠慢，留好闪避，镇符可打断蓄势。"
	if "阿修罗" in message: return "阿修罗好争斗，三面六臂起剑阵，六道剑锋之间留有空隙；也会放射战火。半血后攻势更急，平息它才能问夜叉。"
	if "夜叉" in message: return "佛寺夜叉是守藏护法，疾刺前会标明路线，随后三叉投锋；护障会恢复，镇符能破障并打断蓄势。"
	if "佛寺" in message: return "青槐村北侧山道通往大佛寺。施食庭、塔林、梦障院连着修罗道场和护法殿。先找砚青接北山梵影；大佛寺也参与四方势力争斗。"
	if "神器" in message and "伊佩塔姆" not in message: return "岛国的伊佩塔姆靠亲手击杀成长并吸血；大佛寺的文殊般若剑随角色修为成长，每次命中三相附魔共存。两条调查委托都从砚青处接续，最后找阿祁。"
	if "伊佩塔姆" in message: return "那是裂海带来的阿伊努嗜血之刃。平息三处祭场后，经砚青、秋婶、柳伯的委托，找阿祁缔约。装备后亲手击杀使它成长，剑伤能回补命息。"
	if "河童" in message: return "河童依赖头皿中的水，靠近水岸会恢复。镇符可令水皿失效，离水作战也能压住它。"
	if "以津真天" in message: return "荒冢金鸟在问亡者何时安葬。附近未处理遗骸越多，毒鸣越强；先超度，再战。"
	if "天狗" in message: return "风山修验者以羽扇起山岚。风障蓄势时子弹难进，镇符能打断它。"
	if "宿傩" in message: return "双面四臂武人轮换双向剑斩与弓阵。贴身看双刃，远处避两面弓箭，别只盯着正面。"
	if "岛国" in message or "世界" in message: return "这片世界由不同时地的诡异传说缝合。村东渡船通往岛国，苇岸、荒冢、风山、双面社各有异闻。先找砚青接裂海委托。"
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
			var completed: bool = false
			for id in YinAdventure.QUESTS:
				var spec: Dictionary = YinAdventure.QUESTS[id]
				if spec.npc != int(npc.id) or not YinAdventure.available(state, id): continue
				if not state.quests.has(id): return spec.description + " 在委托菜单确认即可。"
				if state.quests[id].claimed:
					completed = true
					continue
				if YinAdventure.progress(state, id) >= spec.target: return "事情办妥了。打开委托菜单复命，我把报酬交给你。"
				return "还差一点。%s 目前 %d/%d。" % [spec.description, YinAdventure.progress(state, id), spec.target]
			return "上次的事多亏你了，报酬已经交给你。" if completed else "暂时没有新委托，找砚青了解裂海与佛寺异闻。"
		"explore": return "主路连接出入口，东侧支路通向断碑营地、枯井、山门。箱子附近有守卫，腾出行囊再去。"
		"weapon": return "鞭子够远，银剑稳，左轮每发都得算着打。魔法书与娃娃耗气力。燃烧持续灼伤，冰冻减速，闪电跳跃；火冰会消解。"
		"enemy": return "鬼物断腿会跛行，断头后会乱窜，无法再攻击；不过已经射出的弹丸仍有危险。"
		"raid": return "今夜正需援手，先看书信，护住村里人。" if state.raid_status in ["warned", "active"] else "村庄完好度 %d。每三日可能收到求救信，黄昏前做好准备。" % state.village_integrity
	return {1: "村里的路要靠大家守住。先清理乱葬坡，再往后山走。", 2: "身上带伤，就来找我。别把气力全耗在一次施术上。", 3: "没有一把兵器适合所有敌人。留好副武器，换着打。", 4: "三份槐木就够修灯了；余下的路，我替你照着。", 5: "村西的田还能种。种田、护村、探索，都能谋生。", 6: "我想知道后山三处遗址还留下什么。亲自走到那里，回来告诉我。"}.get(int(npc.id), "小心夜路。")
