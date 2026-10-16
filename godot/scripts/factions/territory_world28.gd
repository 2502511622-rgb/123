class_name YinTerritoryWorld28
extends Node2D
var world: FarmWorld
var clock=0.0
var elapsed=0.0
func _ready():
 name="TerritoryFronts";z_index=-1
func _physics_process(delta: float):
 var game=get_tree().get_first_node_in_group("yintian_game")
 if game==null or game.modal!=null:return
 elapsed+=delta
 if elapsed<.1:return
 var dt=elapsed;elapsed=0;clock+=dt
 for id in YinFactions.IDS:
  if world.player.position.distance_to(YinTerritory28.post(id))<140 and not world.state.visited_posts.has(id):
   world.state.visited_posts[id]=true;game.queue_save()
 for war in world.state.factions.wars.duplicate():
  if war.status!="active" or not YinFactions.survivors(world.state,war,"defender").is_empty():continue
  var attackers=YinFactions.survivors(world.state,war,"attacker")
  if attackers.is_empty():continue
  var at=YinTerritory28.target(world.state,war)
  var defenders=YinTerritory28.guards(world.state,war.get("target_region",war.defender)).filter(func(e):return e.faction!=war.attacker and Vector2(e.at[0],e.at[1]).distance_to(at)<160)
  var present=attackers.filter(func(e):return Vector2(e.at[0],e.at[1]).distance_to(at)<100 and "head" not in e.get("severed",[]))
  war.capture_seconds=clampf(float(war.get("capture_seconds",0))+(dt if not present.is_empty() and defenders.is_empty() else -dt*.5),0,YinTerritory28.HOLD_SECONDS)
  if war.capture_seconds>=YinTerritory28.HOLD_SECONDS:
   YinFactions.settle(world.state,war,true);world.state.factions.wars.erase(war)
   game.spawn_enemies();game.refresh("据点已占领，幸存远征军转为驻军。P查看领地，Tab查看旗帜。")
   game.queue_save()
 queue_redraw()
func _draw():
 if world==null:return
 var font=preload("res://assets/mossfield-font.ttf")
 var bounds=world.screen_bounds().grow(100)
 for region in YinFactions.IDS:
  var at=YinTerritory28.post(region)
  if not bounds.has_point(at):continue
  var owner=YinTerritory28.owner(world.state,region)
  var color: Color=YinFactions.COLORS[owner]
  draw_line(at,at+Vector2(0,-58),Color("6d6653"),3)
  var wave=sin(clock*3)*2
  draw_colored_polygon(PackedVector2Array([at+Vector2(1,-56),at+Vector2(24,-53+wave),at+Vector2(20,-36+wave),at+Vector2(1,-39)]),color)
  draw_circle(at,5,Color("928366"))
  draw_string(font,at+Vector2(-48,16),YinFactions.NAMES[owner]+" · 驻守%d / 在途%d"%[YinTerritory28.present_guards(world.state,region),YinTerritory28.guards(world.state,region).size()-YinTerritory28.present_guards(world.state,region)],HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)
  for war in world.state.factions.wars:
   if war.status=="active" and war.get("target_region",war.defender)==region and war.get("capture_seconds",0)>0:
    draw_arc(at,24,-PI/2,-PI/2+TAU*float(war.capture_seconds)/6,24,YinFactions.COLORS[war.attacker],3)
