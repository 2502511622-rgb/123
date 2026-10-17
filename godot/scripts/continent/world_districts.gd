class_name YinWorldDistricts
extends RefCounted
## Authored places and routes. Every landmark has an approach, readable use and a story.
const ROUTES=[
 [Vector2(1504,2400),Vector2(1504,1808),Vector2(1376,1536),Vector2(1504,1056),Vector2(1984,1008),Vector2(2480,1120),Vector2(3200,1056)],
 [Vector2(1056,1536),Vector2(1376,1536),Vector2(1248,1216),Vector2(1168,896),Vector2(1440,752),Vector2(1760,800),Vector2(1984,1008),Vector2(2048,1408),Vector2(1648,1440),Vector2(1504,1056)],
 [Vector2(3200,1056),Vector2(3968,1056),Vector2(4448,960),Vector2(4896,1056),Vector2(4896,1600),Vector2(4896,2400)],
 [Vector2(4896,608),Vector2(4896,1056),Vector2(5200,1056),Vector2(5312,1280),Vector2(5120,1584),Vector2(4896,1600),Vector2(4512,1584),Vector2(4384,1216),Vector2(4448,960)],
 [Vector2(3200,3552),Vector2(3872,3504),Vector2(4320,3648),Vector2(4896,3552),Vector2(5120,3168),Vector2(4800,2816),Vector2(4896,2400)],
 [Vector2(4320,3648),Vector2(4544,3200),Vector2(4800,3264),Vector2(4896,3552),Vector2(5280,3744),Vector2(5440,4080),Vector2(5008,4256),Vector2(4608,3968),Vector2(4320,3648)],
 [Vector2(800,3552),Vector2(1168,3552),Vector2(1504,3552),Vector2(2048,3488),Vector2(2576,3616),Vector2(3200,3552)],
 [Vector2(1504,2400),Vector2(1584,2800),Vector2(1392,3136),Vector2(1504,3552),Vector2(1616,3888),Vector2(1248,3952),Vector2(1088,3744),Vector2(1168,3552)],
 [Vector2(1504,3552),Vector2(1808,3264),Vector2(2096,3312),Vector2(2048,3488)],
 [Vector2(4320,3648),Vector2(4464,3728),Vector2(4592,3784),Vector2(4704,3795)],
 [Vector2(3872,3504),Vector2(4000,3408),Vector2(4136,3336),Vector2(4224,3284)],
 [Vector2(4896,1600),Vector2(5152,1776),Vector2(5376,1952),Vector2(5536,2128),Vector2(5664,2072)],
 ]
const PLACES={
 "road_supplies":{"name":"遗落的行旅箱","at":Vector2(2544,3536),"region":"village","art":"crates","text":"箱盖留着一道爪痕，下面压着护甲和止息药。一次只能拿走一份，留下的也许能帮到后来者。"},
 "road_bowl":{"name":"桥前温汤","at":Vector2(2976,3504),"region":"village","art":"offering","text":"村民在桥前留下还温着的药汤与路费。刻在碗边的小字：活着回来，再替下一位添上。"},
 "road_tracks":{"name":"界河逃生印","at":Vector2(3456,3592),"region":"graveyard","art":"banner","text":"脚印绕开主路，通往守墓人的藏箱。布条上画着一条绕石而行的小径，旁边写着：不要追着第一声哭喊走。"},
 "temple_bell":{"name":"无声钟庭","at":Vector2(1168,896),"region":"temple","art":"bell","text":"半埋的铜钟内壁刻着同一行小字：钟响时，不要回头。最后一条刻痕却停在‘回’字上。钟舌已被人仔细取走，旁边还留着拖行的印子。"},
 "temple_library":{"name":"埋经回廊","at":Vector2(1920,1248),"region":"temple","art":"scrolls","text":"经页只剩朝内的一面没有褪色。有人将它们一张张折成路标，指向佛殿后的暗门。沙里露出一枚青槐木牌，这条朝圣路曾经通向村庄。"},
 "temple_cistern":{"name":"断水净池","at":Vector2(2048,864),"region":"temple","art":"basin","text":"净池早已干涸，池壁却湿着。石缝里不是水，是被风磨成粉末的香灰。七只水碗倒扣在边缘，只有朝向乱葬岗的一只仍是正的。"},
 "temple_gate":{"name":"朝圣者石阶","at":Vector2(1376,1536),"region":"temple","art":"stone_steps","text":"阶面上磨出了无数脚窝，返程一侧却平整如初。倒下的旗杆指向残寺，旗尾挂着写满名字的布条，其中几个名字仍出现在村里的委托上。"},
 "island_market":{"name":"空伞市集","at":Vector2(4752,896),"region":"island","art":"umbrellas","text":"摊主走得很急，所有伞却都朝同一方向合拢。货签上写着‘雪落前归还’。街角的提灯没有灯芯，影子仍跟着风轻轻摇。"},
 "island_dock":{"name":"雪渡旧栈","at":Vector2(4560,1488),"region":"island","art":"jetty","text":"栈桥边系着一条空绳，船已经不在了。木板下卡着从佛寺寄来的香料封条。有人把渡船时刻刻进桥栏，最后一班写的是‘血月之后’。"},
 "island_workshop":{"name":"灰烬铳铺","at":Vector2(5264,1248),"region":"island","art":"crates","text":"散落的铳管都朝向店门，像是工匠最后摆下的一圈防线。炉边的独脚印绕了许多圈，旁边还有一副从未交货的小号护胫。"},
 "island_shrine":{"name":"断索小社","at":Vector2(5120,1584),"region":"island","art":"rope","text":"注连绳是从里面被割断的。祈愿牌背面被改写成了同一句话：请不要再替我们许愿。冷风从倒塌的鸟居穿过，带着木屐踏雪的细响。"},
 "grave_pass":{"name":"背风吊魂径","at":Vector2(4544,3200),"region":"graveyard","art":"wood_steps","text":"木阶只够一人侧身通过，护栏上全是向外抓出的痕迹。山下的路很清楚，山上的人却把每一级台阶都钉上了返回的箭头。"},
 "grave_cairn":{"name":"无名归冢","at":Vector2(4800,3264),"region":"graveyard","art":"offering","text":"墓碑没有名字，供碗里却有新米。石堆下压着岛国的旧钱和青槐村的布结。这里埋着的从来不只是一方的人。"},
 "grave_swords":{"name":"锈剑风口","at":Vector2(5280,3744),"region":"graveyard","art":"swords","text":"剑柄都朝向来路，剑刃却插得太深。最短的一柄系着护身符，符上只剩‘勿争’两字。风吹过剑孔，会发出像人吸气的声音。"},
 "grave_cave":{"name":"守冢人的空居","at":Vector2(4608,3968),"region":"graveyard","art":"cave","text":"洞口的灯油还没有凝住。墙上贴着三地的路图，红线一条条连向青槐村。桌上的纸写了一半：真正走失的不是死人，是回家的路。"},
 "village_well":{"name":"青槐公井","at":Vector2(1376,3456),"region":"village","art":"village_well","text":"井栏上的绳槽磨得很深。村民把四种不同的钱压在井沿，盼望四地仍能相互通行。水面映着槐树，风停了，倒影仍轻轻晃动。"},
 "village_tea":{"name":"槐荫茶棚","at":Vector2(1728,3488),"region":"village","art":"tea","text":"茶碗有新有旧，凳子却摆得整齐。有人替还没回村的人留了位置。桌脚压着一张商路清单：药、灯油、铳石，最后一行是‘人’。"},
 "village_bridge":{"name":"洗衣小埠","at":Vector2(1248,3952),"region":"village","art":"laundry","text":"蓝布上缝着不同地方的旧纹样。水边的人把它们拆开，又重新缝在一起。这里的人从不问衣服从哪里来，只问穿它的人还回不回来。"},
 "village_watch":{"name":"归人灯岗","at":Vector2(2096,3312),"region":"village","art":"cart","text":"守夜人的车上没有兵器，只有几盏备用灯。车轴上系着四种颜色的布带，每亮起一盏，便是又有人从界河桥上回来。"}
 }
static func road(at: Vector2,a: Vector2,b: Vector2) -> float:
 return at.distance_to(Geometry2D.get_closest_point_to_segment(at,a,b))
static func paint_roads(world: FarmWorld) -> void:
 for route_index in range(ROUTES.size()):
  var route=ROUTES[route_index]
  for i in range(route.size()-1):
   var a: Vector2=route[i];var b: Vector2=route[i+1]
   var bounds=Rect2(a,b-a).abs().grow(52)
   var lo=Vector2i((bounds.position/32).floor());var hi=Vector2i((bounds.end/32).ceil())
   for y in range(lo.y,hi.y+1):
    for x in range(lo.x,hi.x+1):
     var at=Vector2(x*32+16,y*32+16)
     if road(at,a,b)<(18 if route_index>=9 else 29) and not YinContinent.water(at):world.tile_farm.ground.set_cell(Vector2i(x,y),0,Vector2i(10,0))
static func build(world: YinContinentWorld) -> void:
 paint_roads(world)
 # Temple: a broken processional axis, a sheltered side library and a dry-water court.
 for pair in [["desert_hall",Vector2(1472,784)],["desert_buddha",Vector2(1712,848)],["desert_hall",Vector2(1984,1216)]]:
  world.biome_prop(pair[0],pair[1],96)
 for at in [Vector2(1184,1168),Vector2(1712,1360),Vector2(1088,736),Vector2(2112,720)]:world.biome_prop("desert_stupa",at,30)
 for at in [Vector2(1280,1440),Vector2(1536,1440),Vector2(1824,1024),Vector2(1792,1168),Vector2(1168,1040)]:world.biome_prop("desert_columns",at,42)
 # Edo: staggered fronts, a service alley, a small canal and two genuine crossings.
 for y in [656,896,1200,1552]:
  world.biome_prop("edo_shop",Vector2(4656+(32 if y==1200 else 0),y),92)
  world.biome_prop("edo_house",Vector2(5136-(24 if y==896 else 0),y+24),92)
 for at in [Vector2(4776,688),Vector2(5008,880),Vector2(4776,1232),Vector2(5008,1552)]:world.biome_prop("street_lantern",at,8)
 world.biome_prop("broken_torii",Vector2(5200,1536),42)
 for span in [Rect2(4320,1408,160,64),Rect2(4608,1408,208,64),Rect2(4976,1408,112,64)]:
  world.boundary(span)
  for y in range(int(span.position.y/32),int(span.end.y/32)):
   for x in range(int(span.position.x/32),int(span.end.x/32)):world.tile_farm.ground.set_cell(Vector2i(x,y),0,Vector2i(11,0))
 # Mountain: clusters and winding passages, not a cemetery laid out like a town.
 for at in [Vector2(4480,3120),Vector2(4720,3104),Vector2(5152,3008),Vector2(4512,3504),Vector2(5264,3520),Vector2(5408,3920),Vector2(4848,4112)]:world.biome_prop("mountain_crag",at,50)
 for at in [Vector2(4696,3344),Vector2(5120,3680),Vector2(4544,3840),Vector2(5232,4080)]:world.biome_prop("dead_pine",at,18)
 # Three authored grave groups are installed by YinWilderness29.
 world.biome_prop("mountain_hut",Vector2(4544,4000),64)
 # Village: shared spaces, a market lane and a lived-in river approach.
 for at in [Vector2(1264,3328),Vector2(1824,3376),Vector2(1696,3808),Vector2(1072,3856)]:world.prop("cottage",at,Vector2(-80,-136),Rect2(-38,-24,76,24))
 for at in [Vector2(1264,3504),Vector2(1792,3552),Vector2(1536,3856)]:world.prop("lantern",at,Vector2(-16,-48),Rect2(-4,-6,8,6))
 # Join paving edges to adjacent path cells so roads have worn borders.
 var roads=[]
 for y in range(150):
  for x in range(200):
   var cell=Vector2i(x,y)
   if world.tile_farm.ground.get_cell_atlas_coords(cell)==Vector2i(10,0):roads.append(cell)
 for cell in roads:
  var mask=0
  var directions=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
  for i in range(4):
   var tile=world.tile_farm.ground.get_cell_atlas_coords(cell+directions[i]).x
   if tile==10 or tile>=16:mask|=1<<i
  world.tile_farm.ground.set_cell(cell,0,Vector2i(16+mask,0))
 var dressing=YinDistrictDetails.new();dressing.world=world;dressing.name="AuthoredDistrictDetails";world.add_child(dressing)
static func nearest(world: FarmWorld,at: Vector2) -> String:
 var best=52.0;var chosen=""
 for id in PLACES:
  var d=at.distance_to(PLACES[id].at+Vector2(0,18))
  if d<best and world.can_interact(PLACES[id].at+Vector2(0,18),54):best=d;chosen=id
 return chosen
