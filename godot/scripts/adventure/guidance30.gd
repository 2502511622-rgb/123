class_name YinGuidance30
extends RefCounted
static func war_summary(s) -> String:
 if s.factions.wars.is_empty():return "当前休整 · 前往地图查看领地与据点。\n目标：援助弱方，避免一方独占。"
 var war=s.factions.wars[0]
 return "%s → %s · %s\n%s\n选择支援方后，沿地图橙色战线前往界河桥。"%[YinFactions.NAMES[war.attacker],YinFactions.NAMES[war.defender],"正午集结" if war.status=="warned" else "行军 / 接战", "攻方 %d · 守方 %d"%[war.attackers,war.defenders]]
static func history_reply(s) -> String:
 var records=s.enemies.filter(func(e):return e.dead and e.get("player_slain",false))
 if records.is_empty():
  var progress=YinAdventure.progress(s,"first_watch")
  return "初次守夜记录已击败%d只异怪；旧记录未保存物种，不能确定刚才是哪一只。"%progress if progress>0 else "目前还没有记录到你的击杀。先沿东路过桥完成初次守夜。"
 var counts={}
 for e in records:
  var name=YinBalance.MONSTERS[e.kind].name;counts[name]=int(counts.get(name,0))+1
 var lines=[]
 for name in counts:lines.append("%s%d只"%[name,counts[name]])
 return "你的队伍已击败："+"、".join(lines)+"。这是本日留存的战斗记录。"
static func chest_hint(s,at: Vector2) -> Dictionary:
 var result={};var distance=INF
 for id in YinAdventure.CHESTS:
  if id in s.opened_chests:continue
  var place=YinAdventure.chest_at(id,s.continent_ready)
  if not s.continent_ready and YinAdventure.CHESTS[id].zone!=s.zone:continue
  var d=at.distance_to(place)
  if d<distance:
   distance=d;result={"id":id,"at":place,"name":YinAdventure.CHESTS[id].name,"distance":roundi(d/32.0)}
 return result
static func direction(from: Vector2,to: Vector2) -> String:
 var delta=to-from
 if absf(delta.x)>absf(delta.y)*2:return "东" if delta.x>0 else "西"
 if absf(delta.y)>absf(delta.x)*2:return "南" if delta.y>0 else "北"
 return ("东" if delta.x>0 else "西")+("南" if delta.y>0 else "北")
