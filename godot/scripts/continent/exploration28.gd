class_name YinExploration28
extends RefCounted
const RELICS={"temple_library":"spellbook","island_workshop":"revolver","grave_swords":"whip","village_watch":"armor"}
static func reward_text(id: String) -> String:
 if RELICS.has(id):return "二阶"+YinBalance.WEAPONS[RELICS[id]].name+" · 固定优良品质"
 return "18文 · 6修为"+(" · 回复12生命" if id=="village_well" else "")
static func claim(s,id: String) -> String:
 if not YinWorldDistricts.PLACES.has(id) or not s.world_echoes.has(id):return "先调查此处的遗留物。"
 if s.exploration_rewards.has(id):return "这处遗物已经领取。"
 s.exploration_rewards[id]=true
 if RELICS.has(id):
  var gear=s.grant_gear(RELICS[id],2,1)
  if gear.weapon!="armor":gear.enchantment={"spellbook":"lightning","revolver":"burn","whip":"freeze"}[gear.weapon]
 else:
  s.money+=18;s.cultivation+=6
  if id=="village_well":s.health=mini(100,s.health+12)
 s.add_log("探索所得："+YinWorldDistricts.PLACES[id].name+" · "+reward_text(id))
 return "获得："+reward_text(id)
static func road_speed(game: Node2D) -> float:
 if game==null or not game.state.continent_ready or game.player.attack_time>0 or game.player.dodge_time>0:return 1.0
 var cell=Vector2i((game.player.position/32).floor())
 var tile=game.world.tile_farm.ground.get_cell_atlas_coords(cell).x
 if tile!=10 and tile<16:return 1.0
 if game.nearest_enemy(game.player.position,250)!=null:return 1.0
 return 1.5
