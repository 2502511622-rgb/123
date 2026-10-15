class_name YinWorldLayout
extends RefCounted
static func gate(id: String,label: String,at: Vector2,to: String,spawn: Vector2) -> Dictionary:
	return {"id":id,"name":label,"at":at,"to":to,"spawn":spawn,"range":47.0}
static func site(id: String,label: String,at: Vector2) -> Dictionary:
	return {"id":id,"name":label,"at":at,"to":"","range":45.0}
static func points(zone: String) -> Array:
	match zone:
		"farm":return [gate("home","义庄·休息制作",Vector2(160,209),"hall",Vector2(480,435)),gate("shop","杂货铺·装备",Vector2(780,238),"shop",Vector2(480,435)),gate("gate","乱葬坡·战斗",Vector2(846,531),"graveyard",Vector2(182,533)),gate("village_gate","青槐村·委托",Vector2(900,350),"village",Vector2(180,800)),site("shipping","出货箱",Vector2(248,197)),site("npc","桥边阿婆",Vector2(778,345)),site("altar","祭坛",Vector2(214,433))]
		"graveyard":return [gate("return","义庄田园",Vector2(155,547),"farm",Vector2(810,538)),gate("forest_gate","后山铳林",Vector2(850,530),"forest",Vector2(180,1120))]
		"forest":
			var result: Array=[gate("forest_return","返回乱葬坡",Vector2(155,1140),"graveyard",Vector2(810,535)),gate("sunken_gate","沉水村",Vector2(1760,250),"sunken",Vector2(180,800)),gate("theatre_gate","废戏台",Vector2(1760,1050),"theatre",Vector2(180,800))]
			for id in YinAdventure.LANDMARKS:result.append(site("inspect_"+id,YinAdventure.LANDMARKS[id].name,YinAdventure.LANDMARKS[id].at+Vector2(0,40)))
			return result
		"village":return [gate("village_return","义庄田园",Vector2(155,820),"farm",Vector2(855,350)),gate("island_ferry","码头·岛国",Vector2(1180,820),"island",Vector2(224,1408)),gate("temple_gate","山道·大佛寺",YinTemple.VILLAGE_GATE,"temple",YinTemple.ENTRY)]
		"island":return [gate("island_return","渡口·青槐村",Vector2(180,1440),"village",Vector2(1180,780))]
		"temple":return [gate("temple_return","返回青槐村",YinTemple.EXIT,"village",YinTemple.VILLAGE_GATE+Vector2(0,40))]
		"sunken","theatre":return [gate("branch_return","返回后山",Vector2(155,820),"forest",Vector2(1700,250 if zone=="sunken" else 1050))]
		"hall":return [gate("exit_interior","义庄院落",Vector2(480,461),"farm",Vector2(160,218)),site("workbench","案台·制作",Vector2(480,267)),site("storage","仓箱",Vector2(306,361)),site("bed","卧榻",Vector2(666,327))]
		"shop":return [gate("exit_interior","返回院落",Vector2(480,461),"farm",Vector2(780,260)),site("counter","柜台·交易",Vector2(480,267))]
	return []
static func arrival(origin: String,destination: String,fallback: Vector2) -> Vector2:
	for point in points(origin):
		if point.to==destination:return point.spawn
	return fallback
