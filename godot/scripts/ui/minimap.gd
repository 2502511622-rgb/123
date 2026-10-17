class_name YinMinimap
extends Control
var game: Node2D
var expanded: bool = false
const NAMES = {"temple": "大佛寺 · 护法异境", "island": "岛国 · 缝合海域","village": "青槐村", "farm": "义庄营地", "graveyard": "乱葬坡", "forest": "后山铳林", "sunken": "沉水村", "theatre": "废戏台", "hall": "义庄", "shop": "杂货铺"}
var redraw_clock: float=0
func _process(delta: float) -> void:
	redraw_clock+=delta
	if redraw_clock>=0.1:redraw_clock=0;queue_redraw()
func point(at: Vector2) -> Vector2: return Vector2(5, 17) + at / game.world.level_size * (size - Vector2(10, 23))
func _draw() -> void:
	if not is_instance_valid(game.world): return
	if game.state.continent_ready:
		draw_continent()
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("182231e8"))
	draw_rect(Rect2(Vector2.ZERO, size), YinPixelTheme.GOLD, false, 1)
	draw_string(ThemeDB.fallback_font, Vector2(5, 12), NAMES.get(game.state.zone, game.state.zone), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d3d0b0"))
	for rect in game.world.obstacles:
		draw_rect(Rect2(point(rect.position), rect.size / game.world.level_size * (size - Vector2(10, 23))), Color("526170"))
	for id in YinAdventure.CHESTS:
		var spec: Dictionary = YinAdventure.CHESTS[id]
		if spec.zone == game.state.zone and id not in game.state.opened_chests:
			draw_rect(Rect2(point(spec.at) - Vector2(2, 2), Vector2(4, 4)), Color("d9a552"), false, 1)
	if game.state.zone == "temple":
		for name_value in YinTemple.REGIONS:
			var at: Vector2 = point(YinTemple.REGIONS[name_value])
			draw_circle(at, 2, Color("d6ba6e"))
			if size.x > 200: draw_string(ThemeDB.fallback_font, at + Vector2(4, 0), name_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ddd2ab"))
	if game.state.zone == "island":
		for name_value in YinIsland.REGIONS:
			var at: Vector2 = point(YinIsland.REGIONS[name_value])
			draw_circle(at, 2, Color("d8b77d"))
			if size.x > 200: draw_string(ThemeDB.fallback_font, at + Vector2(4, 0), name_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d3d0b0"))
	if game.state.zone == "forest":
		for id in YinAdventure.LANDMARKS:
			var spec: Dictionary = YinAdventure.LANDMARKS[id]
			var at: Vector2 = point(spec.at)
			draw_circle(at, 2, Color("9bbfc0") if game.state.visited_landmarks.has(id) else Color("667c73"))
			if size.x > 200: draw_string(ThemeDB.fallback_font, at + Vector2(4, 0), spec.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d3d0b0"))
	var first: Dictionary=YinFirstJourney.guide(game.state)
	if not first.is_empty() and first.zone==game.state.zone:
		var target: Vector2=point(first.at)
		draw_arc(target,4.0,0,TAU,12,Color("ffe1a0"),1.4)
		if size.x>200:draw_string(ThemeDB.fallback_font,target+Vector2(6,-4),"当前目标",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe1a0"))
	var gate_names: Array=gate_labels()
	var exits: Array=gates()
	for i in range(exits.size()):
		var at: Vector2=point(exits[i])
		draw_rect(Rect2(at-Vector2(2,2),Vector2(4,4)),Color("e9c47b"))
		if size.x>200 and i<gate_names.size():
			var text_at:=Vector2(clampf(at.x+5,5,size.x-100),clampf(at.y-4,29,size.y-5))
			draw_string(ThemeDB.fallback_font,text_at,gate_names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f0dca8"))
	if size.x>200:
		for villager in game.get_tree().get_nodes_in_group("villagers"):
			if not villager.is_queued_for_deletion():draw_string(ThemeDB.fallback_font,point(villager.position)+Vector2(3,-4),villager.record.get("name","村民"),HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("c4d8ba"))
	for enemy in game.get_tree().get_nodes_in_group("enemies") + game.get_tree().get_nodes_in_group("faction_guards"):
		if not enemy.is_queued_for_deletion(): draw_rect(Rect2(point(enemy.position) - Vector2.ONE, Vector2(2, 2)), YinFactions.COLORS.get(enemy.record.get("faction", ""), Color("d8776b")))
	for spirit in game.get_tree().get_nodes_in_group("companions"):
		if not spirit.is_queued_for_deletion(): draw_rect(Rect2(point(spirit.position) - Vector2.ONE, Vector2(2, 2)), Color("d5c283") if spirit.record.get("assignment")=="village" else Color("82bbc3"))
	for villager in game.get_tree().get_nodes_in_group("villagers"):
		if not villager.is_queued_for_deletion(): draw_rect(Rect2(point(villager.position) - Vector2.ONE, Vector2(2, 2)), Color("d5b784"))
	draw_rect(Rect2(point(game.player.position) - Vector2(2, 2), Vector2(4, 4)), Color("fff1c1"))
func gates() -> Array:
	var result: Array=[]
	for point in YinWorldLayout.points(game.state.zone):
		if point.to!="":result.append(point.at)
	return result
func gate_labels() -> Array:
	var result: Array=[]
	for point in YinWorldLayout.points(game.state.zone):
		if point.to!="":result.append(point.name)
	return result

func draw_continent() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("182231ee"))
	draw_rect(Rect2(Vector2.ZERO,size),YinPixelTheme.GOLD,false,1)
	draw_string(ThemeDB.fallback_font,Vector2(5,12),"阴诡世界 · 四方领地",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e4d4ae"))
	for id in YinContinent.CAPITALS:
		var c: Vector2=YinContinent.CAPITALS[id]
		var origin=Vector2(0 if c.x<3200 else 3200,0 if c.y<2400 else 2400)
		draw_rect(Rect2(point(origin),Vector2(3200,2400)/YinContinent.SIZE*(size-Vector2(10,23))),Color(YinFactions.COLORS[YinTerritory28.owner(game.state,id)],0.19))
	for river in [Rect2(3104,0,192,4800),Rect2(0,2304,6400,192)]:
		draw_rect(Rect2(point(river.position),river.size/YinContinent.SIZE*(size-Vector2(10,23))),Color("56828b"))
	for route in YinWorldDistricts.ROUTES:
		for i in range(route.size()-1):draw_line(point(route[i]),point(route[i+1]),Color("8b8665"),1)
	if size.x>200:
		for id in YinWorldDistricts.PLACES:
			var place: Dictionary=YinWorldDistricts.PLACES[id]
			var known=game.state.world_echoes.has(id)
			var at=point(place.at)
			draw_circle(at,1.8,Color("b8c999") if known else Color("d6bb76"))
			if known:draw_string(preload("res://assets/mossfield-font.ttf"),at+Vector2(3,9),place.name,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("d1c6ad"))
	for b in YinContinent.BRIDGES:draw_rect(Rect2(point(b.position),b.size/YinContinent.SIZE*(size-Vector2(10,23))).grow(1),Color("c1a276"))
	for id in YinContinent.CAPITALS:
		var at: Vector2=point(YinContinent.CAPITALS[id])
		draw_rect(Rect2(at-Vector2(2,2),Vector2(4,4)),YinFactions.COLORS[YinTerritory28.owner(game.state,id)])
		if size.x>200:draw_string(ThemeDB.fallback_font,at+Vector2(6,-4),YinFactions.NAMES[id],HORIZONTAL_ALIGNMENT_LEFT,-1,11,YinFactions.COLORS[id])
	if size.x>200:
		for region in YinFactions.IDS:
			var owner=YinTerritory28.owner(game.state,region)
			if owner!=region:draw_string(ThemeDB.fallback_font,point(YinContinent.CAPITALS[region])+Vector2(6,10),"占领："+YinFactions.NAMES[owner],HORIZONTAL_ALIGNMENT_LEFT,-1,9,YinFactions.COLORS[owner])
	if size.x>200:draw_string(ThemeDB.fallback_font,point(YinContinent.HOME)+Vector2(-14,15),"义庄",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e4d4ae"))
	for id in YinAdventure.CHESTS:
		if id in game.state.opened_chests:continue
		var spec: Dictionary=YinAdventure.CHESTS[id]
		draw_rect(Rect2(point(YinAdventure.chest_at(id,true))-Vector2.ONE,Vector2(2,2)),Color("d6bb76"),false)
	for actor in get_tree().get_nodes_in_group("enemies")+get_tree().get_nodes_in_group("faction_guards"):
		if actor.is_queued_for_deletion() or actor.record.dead:continue
		var at=point(actor.position)
		draw_circle(at,2.2 if actor.record.has("war_id") else 1.0,Color("d77d6d") if actor.is_in_group("enemies") else Color("83bbb8"))
	for war in game.state.factions.wars:
		if size.x>200:
			var from: Vector2=point(YinContinent.CAPITALS[war.attacker]);var to: Vector2=point(YinContinent.CAPITALS[war.defender])
			draw_dashed_line(from,to,Color("d7a27388"),1,5)
	var guide: Dictionary=YinFirstJourney.guide(game.state)
	if not guide.is_empty() and guide.at!=Vector2.ZERO:draw_arc(point(guide.at),4,0,TAU,12,Color("ffe0a2"),1)
	draw_navigation30()
	draw_circle(point(game.player.position),2.5,Color("fff0be"))

func _gui_input(event: InputEvent):
	if size.x<200 or not game.state.continent_ready:return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var at=(event.position-Vector2(5,17))/(size-Vector2(10,23))*game.world.level_size
		# Snap to actual landmarks and cache positions when the click is nearby.
		var label="标记地点";var closest=9.0
		for id in YinAdventure.CHESTS:
			if id in game.state.opened_chests:continue
			var place=YinAdventure.chest_at(id,true);var distance=event.position.distance_to(point(place))
			if distance<closest:closest=distance;at=place;label=YinAdventure.CHESTS[id].name
		for id in YinWorldDistricts.PLACES:
			var place=YinWorldDistricts.PLACES[id];var distance=event.position.distance_to(point(place.at))
			if distance<closest:closest=distance;at=place.at;label=place.name
		var route=game.world.path_to(game.player.position,at,Vector2(8,6))
		if not route.is_empty():game.navigation_target={"at":at,"name":label,"route":route};queue_redraw()
		accept_event()
func _get_tooltip(at: Vector2) -> String:
	if size.x<200:return "Tab 查看地图与路线"
	for id in YinWorldDistricts.PLACES:
		var place=YinWorldDistricts.PLACES[id]
		if point(place.at).distance_to(at)<9:return place.name+" · "+str(roundi(game.player.position.distance_to(place.at)/32.0))+"步"
	return "左键标记可行路线"
func draw_navigation30():
	var target: Dictionary=game.get("navigation_target") if game.get("navigation_target")!=null else {}
	if target.is_empty():
		var guide=YinFirstJourney.guide(game.state)
		if not guide.is_empty() and guide.at!=Vector2.ZERO:target={"at":guide.at,"name":guide.title}
	if target.is_empty():return
	var at=point(target.at)
	if size.x>200:
		var route: PackedVector2Array=target.get("route",PackedVector2Array())
		for i in range(1,route.size()):draw_line(point(route[i-1]),point(route[i]),Color("e2d4a8"),1.5)
		var label="%s · 约%d步"%[target.name,roundi(game.player.position.distance_to(target.at)/32.0)]
		draw_string(preload("res://assets/mossfield-font.ttf"),Vector2(7,size.y-5),label,HORIZONTAL_ALIGNMENT_LEFT,size.x-14,10,Color("ffe4a2"))
	draw_circle(at,4,Color("17222c"));draw_arc(at,4,0,TAU,16,Color("ffe4a2"),1.5)
	var origin=point(game.player.position);var direction=(at-origin).normalized()
	draw_line(origin+direction*4,origin+direction*11,Color("ffe4a2"),2)
