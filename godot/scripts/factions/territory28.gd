class_name YinTerritory28
extends RefCounted
const HOLD_SECONDS=6.0
static func initial() -> Dictionary:
 var result={}
 for id in YinFactions.IDS:result[id]={"owner":id,"changed_day":0,"captures":0}
 return result
static func valid(value: Variant) -> bool:
 if not value is Dictionary or value.size()!=4:return false
 for id in YinFactions.IDS:
  if not value.get(id) is Dictionary or value[id].size()!=3:return false
  if value[id].get("owner") not in YinFactions.IDS:return false
  for key in ["changed_day","captures"]:
   if not FarmState.valid_int(value[id].get(key),0):return false
 return true
static func owner(s,region: String) -> String:return s.territories[region].owner
static func region_for(s,faction: String) -> String:
 if owner(s,faction)==faction:return faction
 for id in YinFactions.IDS:
  if owner(s,id)==faction:return id
 return ""
static func post(region: String) -> Vector2:return YinContinent.CAPITALS[region]+Vector2(0,176)
static func guards(s,region: String) -> Array:
 return s.enemies.filter(func(e):return not e.dead and e.get("garrison_region","")==region)
static func target(s,war: Dictionary) -> Vector2:return post(war.get("target_region",war.defender))
static func occupy(s,region: String,faction: String,survivors: Array) -> void:
 s.territories[region]={"owner":faction,"changed_day":s.day,"captures":int(s.territories[region].captures)+1}
 var old=guards(s,region)
 for e in old:e.dead=true
 station(s,region,faction,survivors)
 s.add_log("领地易手："+YinFactions.NAMES[region]+"归"+YinFactions.NAMES[faction]+"控制，远征幸存者留驻。")
static func report(s) -> String:
 var lines:Array[String]=["实际领地与驻军"]
 for id in YinFactions.IDS:
  lines.append("%s：%s控制 · 驻守%d人 / 在途%d人"%[YinFactions.NAMES[id],YinFactions.NAMES[owner(s,id)],present_guards(s,id),guards(s,id).size()-present_guards(s,id)])
 return "\n".join(lines)

static func station(s,region: String,faction: String,survivors: Array) -> void:
 var available=maxi(0,3-guards(s,region).size())
 survivors=survivors.filter(func(e):return "head" not in e.get("severed",[]))
 var at=post(region)
 survivors.sort_custom(func(a,b):return Vector2(a.at[0],a.at[1]).distance_squared_to(at)<Vector2(b.at[0],b.at[1]).distance_squared_to(at))
 for i in range(mini(available,survivors.size())):
  var e: Dictionary=survivors[i]
  e.erase("war_id");e.erase("war_side");e.garrison_region=region;e.faction=faction
  e.dead=false;e.hp=maxi(e.hp,int(e.max_hp*.5));e.zone=region
static func restore_homeland(s,region: String) -> String:
 if region not in YinFactions.IDS or owner(s,region)==region:return "此地已由原属势力控制。"
 var current=owner(s,region);var troops=guards(s,region)
 if current!="village" and not troops.is_empty() and not troops.all(func(e):return e.get("player_allied",false)):return "先击败占领军，再归还据点。"
 for war in s.factions.wars:
  if war.get("target_region",war.defender)==region:return "此地仍在争夺，先结束交战。"
 if current=="village" or troops.all(func(e):return e.get("player_allied",false)):
  var home=region_for(s,current)
  for e in troops:e.garrison_region=home if home!="" and home!=region else current # Allied troops walk home using their existing bodies.
 s.territories[region]={"owner":region,"changed_day":s.day,"captures":int(s.territories[region].captures)+1}
 s.factions.powers[region].troops=mini(180,int(s.factions.powers[region].troops)+10)
 s.factions.powers[region].supply=mini(140,int(s.factions.powers[region].supply)+5)
 s.add_log("调停归还："+YinFactions.NAMES[region]+"恢复领地；盟军驻军自行返程。")
 return "领地已归还"+YinFactions.NAMES[region]+"，兵力+10、物资+5。"

static func present_guards(s,region: String) -> int:
 var at=post(region)
 return guards(s,region).filter(func(e):return Vector2(e.at[0],e.at[1]).distance_to(at)<180).size()
