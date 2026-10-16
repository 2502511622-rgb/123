class_name YinContinentWorld
extends FarmWorld
func _ready() -> void:
 level_size=YinContinent.SIZE
 tile_farm=YinTileFarm.new();add_child(tile_farm)
 var tiles=tile_farm.tileset(YinArt.terrain("village"),32,1,32)
 tile_farm.zone="continent"
 tile_farm.ground=tile_farm.layer("WorldGround",tiles,-3,Vector2.ZERO);tile_farm.ground.scale=Vector2.ONE
 tile_farm.soil=tile_farm.layer("SaveCompatibility",tiles,-2,Vector2.ZERO);tile_farm.crops=tile_farm.layer("SaveCompatibilityEmpty",tiles,-2,Vector2.ZERO)
 for y in range(150):
  for x in range(200):
   var at=Vector2(x*32+16,y*32+16)
   var road=absf(at.y-1056)<48 or absf(at.y-3552)<48 or absf(at.x-1504)<48 or absf(at.x-4896)<48
   var id=11 if YinContinent.water(at) else (10 if road else absi(hash(Vector2i(x,y)))%8)
   for b in YinContinent.BRIDGES:
    if b.has_point(at):id=10
   tile_farm.ground.set_cell(Vector2i(x,y),0,Vector2i(id,0))
 actors=Node2D.new();actors.y_sort_enabled=true;add_child(actors)
 feedback=Node2D.new();feedback.z_index=20;add_child(feedback)
 boundary(Rect2(-32,-32,6464,32));boundary(Rect2(-32,4800,6464,32));boundary(Rect2(-32,0,32,4800));boundary(Rect2(6400,0,32,4800))
 # Continuous river banks leave only the four actual bridge openings.
 for span in [Vector2(0,960),Vector2(1152,3456),Vector2(3648,4800)]:boundary(Rect2(3104,span.x,192,span.y-span.x))
 for span in [Vector2(0,1408),Vector2(1600,4800),Vector2(4992,6400)]:boundary(Rect2(span.x,2304,span.y-span.x,192))
 var scenery=YinScenery.new();scenery.name="ArtScenery";scenery.world=self;scenery.z_index=-1;add_child(scenery)
 build_settlements()
 for placed in state.placements:install_placement(placed)
 environment=YinEnvironment.new();environment.world=self;add_child(environment)
 grass=YinLivingGrass.new();grass.world=self;add_child(grass)
 projectiles=YinProjectiles.new();projectiles.game=get_tree().get_first_node_in_group("yintian_game");projectiles.world=self;projectiles.z_index=18;add_child(projectiles)
 call_deferred("install_interactions")
func build_settlements() -> void:
 for side in YinContinent.CAPITALS:
  if side!="village":continue
  var center: Vector2=YinContinent.CAPITALS[side]
  add_sign(center+Vector2(-60,100),YinFactions.NAMES[side]+" · 领地主城")
  var building="shrine" if side=="temple" else "cottage" if side=="village" else "torii" if side=="island" else "grave"
  if not YinWorldArt.REGIONS.has(building):building="shrine"
  var lots=[Vector2(-288,-256),Vector2(288,-256),Vector2(-288,384),Vector2(576,384)] if side=="village" else [Vector2(-224,-112),Vector2(128,-144),Vector2(192,192),Vector2(-240,192)]
  for offset in lots:
   var size_value: Vector2=Vector2(YinWorldArt.SIZES[building])
   prop(building,center+offset,Vector2(-size_value.x/2,-size_value.y),Rect2(-20,-24,40,24))
  prop("lantern",center+Vector2(-64,-48),Vector2(-16,-48),Rect2(-4,-6,8,6))
 build_biomes()
 prop("cottage",YinContinent.HOME+Vector2(0,-48),Vector2(-80,-132),Rect2(-60,-90,120,84))
 prop("chest",YinContinent.HOME+Vector2(-96,0),Vector2(-20,-30),Rect2(-15,-20,30,20))
 prop("store",Vector2(1680,3488),Vector2(-64,-116),Rect2(-48,-80,96,70))
 var rng=RandomNumberGenerator.new();rng.seed=2301
 for i in range(560):
  var at=Vector2(rng.randf_range(64,6336),rng.randf_range(64,4736))
  if YinContinent.water(at) or absf(at.y-1056)<120 or absf(at.y-3552)<120 or absf(at.x-1504)<120 or absf(at.x-4896)<120:continue
  var clear=false
  for p in YinContinent.points():
   if at.distance_to(p.at)<170:clear=true
  for npc in state.villagers:
   if at.distance_to(Vector2(npc.at[0],npc.at[1]))<90:clear=true
  if clear:continue
  if not is_safe_position(at,Vector2(24,20)):continue
  var side=YinContinent.faction(at)
  var kind=YinRegionStyle.tree(side,at)
  if side=="temple":
   if i%3!=0:continue
   kind="desert_columns" if i%2==0 else "rock"
  elif side=="graveyard":kind=["dead_pine","mountain_crag","burial_cairn"][i%3]
  elif i%6==0:kind="rock"
  if kind.begins_with("tree") or kind=="dead_pine":trees.append(at)
  if YinBiomeArt.SIZES.has(kind):
   var size_value: Vector2i=YinBiomeArt.SIZES[kind]
   prop(kind,at,Vector2(-size_value.x/2,-size_value.y),Rect2(-16,-12,32,12))
  else:prop(kind,at,Vector2(-32,-88),Rect2(-8,-16,16,16))
 for b in YinContinent.BRIDGES:add_sign(b.get_center()+Vector2(-50,120),"界河桥 · 徒步通行")
func biome_prop(kind: String,at: Vector2,width: float=40) -> void:
 var size_value: Vector2i=YinBiomeArt.SIZES[kind]
 prop(kind,at,Vector2(-size_value.x/2,-size_value.y),Rect2(-width/2,-24,width,24))
func build_biomes() -> void:
 # Main military corridors and all river crossings remain open.
 biome_prop("desert_hall",Vector2(1312,864),132)
 biome_prop("desert_buddha",Vector2(1744,864),60)
 for at in [Vector2(1248,1344),Vector2(1760,1344)]:biome_prop("desert_stupa",at,34)
 for at in [Vector2(1008,832),Vector2(1952,1408),Vector2(1728,624)]:biome_prop("desert_columns",at,56)
 for wall in [Rect2(1088,608,288,20),Rect2(1632,608,288,20),Rect2(1088,1456,288,20),Rect2(1632,1456,288,20)]:
  boundary(wall);YinWallFace.install(self,wall)
 for y in [704,960,1312,1568]:
  biome_prop("edo_shop",Vector2(4672,y),96)
  biome_prop("edo_house",Vector2(5120,y+16),96)
  biome_prop("street_lantern",Vector2(4800,y+20),10)
  biome_prop("street_lantern",Vector2(4992,y+20),10)
 biome_prop("broken_torii",Vector2(4656,1472),54)
 for at in [Vector2(4544,3280),Vector2(5216,3296),Vector2(4544,3824),Vector2(5248,3856)]:
  biome_prop("mountain_crag",at,64)
  biome_prop("burial_cairn",at+Vector2(112,48),42)
 for at in [Vector2(4672,3408),Vector2(5072,3728),Vector2(5344,3504)]:biome_prop("dead_pine",at,22)
 biome_prop("mountain_hut",Vector2(4704,3840),68)
 add_sign(Vector2(1280,1184),"大佛寺 · 沙海残殿")
 add_sign(Vector2(4720,1136),"岛国 · 江户荒街")
 add_sign(Vector2(4720,3640),"乱葬岗 · 荒岭孤坟")
func _process(delta: float) -> void:
 time+=delta
func _draw() -> void:
 for b in YinContinent.BRIDGES:draw_texture_rect(YinWorldArt.surface(3),b,true,Color("a6a090"))
func front_plot() -> int:return -1
func plot_at(_at: Vector2) -> int:return -1
func install_interactions() -> void:
 var trail=YinTrailGuide.new();trail.world=self;feedback.add_child(trail)
 for id in YinAdventure.LANDMARKS:
  var at: Vector2=YinContinent.to_world("forest",YinAdventure.LANDMARKS[id].at)
  prop({"well":"well","camp":"brazier","temple":"shrine"}[id],at,Vector2(-32,-64),Rect2(-16,-14,32,14))
 for point in YinContinent.points():
  var beacon=YinInteractionBeacon.new();beacon.world=self;beacon.point=point;beacon.position=point.at;feedback.add_child(beacon)
func nearest_interaction() -> String:
 var best=INF;var selected=""
 var chest=nearest_chest()
 if chest!="":selected="treasure";best=player.position.distance_to(YinContinent.to_world(YinAdventure.CHESTS[chest].zone,YinAdventure.CHESTS[chest].at))
 for p in YinContinent.points():
  var d=player.position.distance_to(p.at)
  if d<best and can_interact(p.at,p.range):best=d;selected=p.id
 for id in YinAdventure.LANDMARKS:
  var at=YinContinent.to_world("forest",YinAdventure.LANDMARKS[id].at)+Vector2(0,40)
  var d=player.position.distance_to(at)
  if d<best and can_interact(at,45):best=d;selected="inspect_"+id
 for npc in get_tree().get_nodes_in_group("villagers"):
  var d=player.position.distance_to(npc.position)
  if d<best and can_interact(npc.position,56):best=d;selected="villager"
 return selected
func nearest_chest() -> String:
 for id in YinAdventure.CHESTS:
  var p=YinAdventure.CHESTS[id]
  if id not in state.opened_chests and can_interact(YinContinent.to_world(p.zone,p.at),46):return id
 return ""
func install_chests(game: Node2D) -> void:
 for id in YinAdventure.CHESTS:
  var chest=YinTreasureChest.new();chest.chest_id=id;chest.game=game;chest.position=YinContinent.to_world(YinAdventure.CHESTS[id].zone,YinAdventure.CHESTS[id].at);actors.add_child(chest)
