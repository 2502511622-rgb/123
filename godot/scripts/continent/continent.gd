class_name YinContinent
extends RefCounted
const SIZE=Vector2(6400,4800)
const RIVER_X=3200.0
const RIVER_Y=2400.0
const HALF=96.0
const CAPITALS={"temple":Vector2(1504,1056),"island":Vector2(4896,1056),"village":Vector2(1504,3552),"graveyard":Vector2(4896,3552)}
const ORIGINS={"farm":Vector2(192,3168),"village":Vector2(1312,3104),"temple":Vector2(480,256),"island":Vector2(3776,256),"graveyard":Vector2(3776,2784),"forest":Vector2(4288,3296),"sunken":Vector2(96,4224),"theatre":Vector2(5376,2688),"hall":Vector2(192,3168),"shop":Vector2(1312,3104)}
const SCALES={"forest":0.65,"sunken":0.45,"theatre":0.65}
const HOME=Vector2(800,3552)
const BRIDGES=[Rect2(3104,960,192,192),Rect2(3104,3456,192,192),Rect2(1408,2304,192,192),Rect2(4800,2304,192,192)]
static func to_world(zone: String,at: Vector2) -> Vector2:
 return ORIGINS.get(zone,Vector2.ZERO)+at*float(SCALES.get(zone,1.0))
static func faction(at: Vector2) -> String:
 return ("temple" if at.x<RIVER_X else "island") if at.y<RIVER_Y else ("village" if at.x<RIVER_X else "graveyard")
static func zone_at(at: Vector2) -> String:
 var side=faction(at)
 if side=="village":
  if Rect2(160,3104,1056,768).has_point(at):return "farm"
  if Rect2(96,4224,640,480).has_point(at):return "sunken"
 if side=="graveyard":
  if Rect2(5376,2688,928,640).has_point(at):return "theatre"
  if at.y>3856 or (at.x>5200 and at.y>3328):return "forest"
 return side
static func water(at: Vector2) -> bool:
 for bridge in BRIDGES:
  if bridge.has_point(at):return false
 return absf(at.x-RIVER_X)<HALF or absf(at.y-RIVER_Y)<HALF
static func points() -> Array:
 return [{"id":"workbench","name":"义庄·整备与休息","at":HOME,"range":60.0,"to":""},{"id":"storage","name":"义庄仓箱","at":HOME+Vector2(-96,0),"range":46.0,"to":""},{"id":"counter","name":"青槐商队","at":Vector2(1680,3552),"range":60.0,"to":""},{"id":"altar","name":"祈愿祭坛","at":Vector2(1440,1184),"range":48.0,"to":""}]
static func migrate(s) -> void:
 if s.continent_ready:return
 s.prepare_enemies()
 for collection in [s.enemies,s.remains,s.drops,s.gear_drops,s.placements]:
  for r in collection:
   if r.zone=="cargo":continue
   var at=to_world(r.zone,Vector2(r.at[0],r.at[1]));r.at=[at.x,at.y]
   if r.has("home_at"):
    var home=to_world(r.zone,Vector2(r.home_at[0],r.home_at[1]));r.home_at=[home.x,home.y]
 for npc in s.villagers:
  var at=to_world("village",Vector2(npc.at[0],npc.at[1]));npc.at=[at.x,at.y]
 s.player_position=HOME+Vector2(0,96)
 s.zone="farm";s.continent_ready=true;s.smart_farming=false
 s.raid_status="quiet"
 for spirit in s.spirits:spirit.job="guard" if spirit.active else "rest"
 # Retain schema slots solely for importing old saves; there is no farming simulation.
 for p in s.plots:p.merge({"tilled":false,"crop":"","growth":0,"watered":false,"yin":0,"sealed":false,"branch":"eat"},true)
 for id in ["candle_seeds","vine_seeds","gourd_seeds","rice_seeds","candle","vine","gourd","rice"]:
  var amount=s.container_count("bag",id)+s.container_count("chest",id)
  s.money+=amount*2
  s.set_container_count("bag",id,0);s.set_container_count("chest",id,0)
 s.terrain.clear()
 s.add_log("抵达阴诡世界：四方领地由河流分隔，桥梁连通全境。")
