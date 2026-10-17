class_name YinWilderness29
extends Node2D
static var textures: Dictionary={}
static var low_regions: Dictionary={}
var world: FarmWorld
var chunks: Dictionary={}
var props: Array=[]
var foliage_material: ShaderMaterial
var last_view:=Rect2()
var low_count=0
var species: Dictionary={}
static func art_texture(id: String) -> Texture2D:
 if low_regions.is_empty():low_regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/landscape29/low.json"))
 if not textures.has(id):
  if low_regions.has(id):
   var part=AtlasTexture.new();part.atlas=load("res://assets/landscape29/low.png")
   var rect=low_regions[id];part.region=Rect2(rect[0],rect[1],rect[2],rect[3]);textures[id]=part
  else:textures[id]=load("res://assets/landscape29/"+id+".png")
 return textures[id]
func _ready():
 z_index=-2;name="LayeredWilderness29"
 foliage_material=ShaderMaterial.new();foliage_material.shader=load("res://shaders/wild_foliage.gdshader")
 call_deferred("bake")
func add_detail(art: String,at: Vector2,scale_value: float=1.0):
 var cell=Vector2i((at/128).floor())
 if not chunks.has(cell):chunks[cell]=[]
 chunks[cell].append({"art":art,"at":at,"scale":scale_value});low_count+=1
 species[art]=int(species.get(art,0))+1
func add_prop(art: String,at: Vector2,foliage=false,solid=false) -> YinWildProp29:
 if not world.is_safe_position(at,Vector2(6,5)):return null
 var prop=YinWildProp29.new();prop.world=world;prop.art=art;prop.foliage=foliage;prop.position=at
 world.actors.add_child(prop);props.append(prop)
 if solid and world.environment.landscape29.sample(at)>20:
  world.boundary(Rect2(at+Vector2(-9,-7),Vector2(18,9)))
 return prop
func bake():
 var field=world.environment.landscape29
 if field==null:return
 var rng=RandomNumberGenerator.new();rng.seed=29017+hash("continent" if world is YinContinentWorld else world.state.zone)
 var candidates=["fern","clover","mushroom","dry_grass"]
 # Jittered clusters, large bare pockets, at most three small plants per cluster.
 for y in range(32,int(world.level_size.y)-32,80):
  for x in range(32,int(world.level_size.x)-32,80):
   var at=Vector2(x,y)+Vector2(rng.randf_range(-24,24),rng.randf_range(-24,24))
   var region=YinContinent.faction(at) if world is YinContinentWorld else world.state.zone
   if region in ["temple","island","hall","shop"]:continue
   if not world.is_safe_position(at) or world is YinContinentWorld and YinContinent.water(at):continue
   var forest_area=YinLandscape29.forest(at) if world is YinContinentWorld else world.state.zone in ["forest","village","farm"]
   var coverage=sin(at.x*.011+cos(at.y*.015))*sin(at.y*.009-at.x*.005)
   if rng.randf()>(.55 if forest_area else .22) or coverage< -.35:continue
   var distance_value=field.sample(at)
   if distance_value<9:continue
   var type_index=posmod(x/80+int(y/80)*3,4)
   var art=candidates[type_index] if forest_area else "dry_grass"
   if not forest_area and rng.randf()<.2:art="branch"
   for i in range(rng.randi_range(1,3)):
    var p=at+Vector2(rng.randf_range(-13,13),rng.randf_range(-9,9))
    if world.is_safe_position(p) and field.sample(p)>7:add_detail(art,p,rng.randf_range(.8,1.1))
   if forest_area and distance_value>36 and rng.randf()<.14:
    add_prop("shrub" if type_index%2==0 else "tall_grass",at+Vector2(18,20),true)
 if world is YinContinentWorld:
  for i in range(3):grave_site(YinLandscape29.GRAVES[i],i)
  forest_site(Vector2(4704,3795));forest_site(Vector2(5220,4296))
  for at in [Vector2(4960,4104),Vector2(5272,4064),Vector2(5312,4384),Vector2(4944,4384)]:
   if world.is_safe_position(at,Vector2(24,20)):world.prop("tree_pine",at,Vector2(-48,-124),Rect2(-8,-12,16,12))
  for at in [Vector2(4888,4136),Vector2(5024,4352),Vector2(5344,4328)]:add_prop("shrub",at,true)
  coast_site()
 elif world.state.zone=="graveyard":
  for i in range(3):grave_site(field.local_graves()[i],i)
 elif world.state.zone=="forest":
  forest_site(Vector2(640,768));forest_site(Vector2(2432,1088))
 queue_redraw()
func forest_site(at: Vector2):
 add_prop("stump",at+Vector2(-68,-18),false,true)
 add_prop("shrub",at+Vector2(74,26),true);add_prop("tall_grass",at+Vector2(-90,45),true)
 for pair in [["branch",Vector2(-36,42)],["mushroom",Vector2(-62,4)],["fern",Vector2(59,-21)],["clover",Vector2(28,46)]]:add_detail(pair[0],at+pair[1])
func grave_site(at: Vector2,index: int):
 add_prop("mound",at+Vector2(0,14));add_prop("stele" if index!=2 else "tablet",at+Vector2(-11,-6),false,true)
 add_prop("coffin" if index==1 else "tomb" if index==2 else "tablet",at+Vector2(73,32),false,index==2)
 for pair in [["bones",Vector2(68,45)],["dry_grass",Vector2(-42,13)],["branch",Vector2(42,53)],["chain",Vector2(83,21)]]:add_detail(pair[0],at+pair[1])
 if index==0:add_detail("wreath",at+Vector2(-18,28))
 add_detail("blood",at+Vector2(18,31));add_detail("blood",at+Vector2(61,37),.55)
func coast_site():
 var left=Vector2(5408,2144);var right=Vector2(5728,2160)
 add_prop("ruin_left",left);add_prop("ruin_right",right)
 # Pillars block at their feet; the centre of both arches remains walkable.
 for at in [left+Vector2(-53,-4),left+Vector2(44,-4),right+Vector2(-40,-4),right+Vector2(56,-4)]:
  if world.is_safe_position(at):world.boundary(Rect2(at-Vector2(7,7),Vector2(14,10)))
 for pair in [["pillar",Vector2(5336,2176)],["statue",Vector2(5792,2096)],["barrel",Vector2(5328,2072)],["planks",Vector2(5816,2200)]]:add_prop(pair[0],pair[1])
 for pair in [["shells",Vector2(5352,2208)],["shells",Vector2(5780,2216)],["salt_grass",Vector2(5312,2176)],["salt_grass",Vector2(5816,2136)],["branch",Vector2(5424,2170)],["bones",Vector2(5776,2088)]]:add_detail(pair[0],pair[1])
 for i in range(3):
  var crab=YinShoreCrab29.new();crab.world=world;crab.position=[Vector2(5334,2160),Vector2(5800,2240),Vector2(5880,2164)][i];world.actors.add_child(crab)
func _process(_delta):
 if world.environment==null:return
 var game=get_tree().get_first_node_in_group("yintian_game")
 if game!=null and game.modal!=null:return
 foliage_material.set_shader_parameter("clock_time",world.environment.time)
 foliage_material.set_shader_parameter("wind",world.environment.wind)
 foliage_material.set_shader_parameter("wetness",world.environment.wetness)
 if is_instance_valid(world.player):foliage_material.set_shader_parameter("player_at",world.player.position)
 var view=world.screen_bounds()
 if last_view.size!=view.size or last_view.position.distance_to(view.position)>32:
  last_view=view;queue_redraw()
func _draw():
 if world.environment==null:return
 var view=world.screen_bounds().grow(96)
 var lo=Vector2i((view.position/128).floor());var hi=Vector2i((view.end/128).floor())
 for y in range(lo.y,hi.y+1):
  for x in range(lo.x,hi.x+1):
   for detail in chunks.get(Vector2i(x,y),[]):
    if detail.art=="blood":
     draw_set_transform(detail.at,.13,Vector2(detail.scale,detail.scale*.48));draw_circle(Vector2.ZERO,4,Color("492c3050"));draw_set_transform(Vector2.ZERO);continue
    var texture=art_texture(detail.art);var size_value=texture.get_size()*detail.scale
    draw_texture_rect(texture,Rect2(detail.at-Vector2(size_value.x/2,size_value.y),size_value),false,Color("c1c3b5"))
 for prop in props:
  if not is_instance_valid(prop) or not view.has_point(prop.position):continue
  var width=prop.sprite.texture.get_width()*.40
  draw_set_transform(prop.position+Vector2(6,0),0,Vector2(1,.26))
  for i in range(3):draw_circle(Vector2.ZERO,width*(1-i*.14),Color(.06,.085,.08,.055))
  draw_set_transform(Vector2.ZERO)
