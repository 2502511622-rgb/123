class_name YinDistrictDetails
extends Node2D
var world: FarmWorld
var chunks: Dictionary={}
var clock: float=0
var refresh: float=0
func _ready() -> void:
 z_index=-1
 for id in YinWorldDistricts.PLACES:
  var place: Dictionary=YinWorldDistricts.PLACES[id]
  install(place.art,place.at)
  var marker=YinDistrictBeacon.new();marker.world=world;marker.place_id=id;marker.position=place.at+Vector2(0,18);world.actors.add_child(marker)
  var rng=RandomNumberGenerator.new();rng.seed=hash(id)
  for i in range(34):
   var at: Vector2=place.at+Vector2(rng.randf_range(-104,104),rng.randf_range(-54,84))
   var key=Vector2i((at/128).floor())
   if not chunks.has(key):chunks[key]=[]
   chunks[key].append({"at":at,"region":place.region,"type":i%4,"turn":rng.randf_range(-0.4,0.4)})
 # Props form coherent activity clusters rather than evenly spaced single buildings.
 var clusters={
 "urns":[Vector2(1664,944),Vector2(1760,896),Vector2(1200,944),Vector2(1888,1328)],
 "rubble_wall":[Vector2(1120,1504),Vector2(1200,1504),Vector2(1576,1408),Vector2(1656,1408),Vector2(1792,1360)],
 "scrolls":[Vector2(2024,1264),Vector2(1864,1184)],
 "stall":[Vector2(4752,1184),Vector2(5040,1328),Vector2(1808,3568)],
 "crates":[Vector2(4688,1136),Vector2(4720,1264),Vector2(5104,1312),Vector2(5176,1200),Vector2(1760,3616)],
 "banner":[Vector2(4800,1152),Vector2(5008,1280),Vector2(4752,720)],
 "footbridge":[Vector2(4544,1440),Vector2(4896,1440)],
 "crow_post":[Vector2(4472,3312),Vector2(4864,3216),Vector2(5192,3824),Vector2(4504,3968)],
 "rope":[Vector2(4528,3168),Vector2(5352,3696)],
 "firewood":[Vector2(4480,4016),Vector2(1280,3360),Vector2(1760,3816),Vector2(1024,3856)],
 "noodles":[Vector2(1808,3440)],"laundry":[Vector2(1144,3808)],
 "tea":[Vector2(1336,3408)],"cart":[Vector2(1992,3472)],
 }
 for art in clusters:
  for at in clusters[art]:install(art,at)
func install(art: String,at: Vector2) -> void:
 var size_value: Vector2i=YinWorldDetailArt.SIZES[art]
 # Steps, bridges and docks are ground geometry, not invisible barriers.
 if art in ["stone_steps","wood_steps","footbridge","jetty"]:
  var sprite=Sprite2D.new();sprite.texture=YinWorldDetailArt.texture(art);sprite.centered=false;sprite.position=at-Vector2(size_value.x/2,size_value.y/2);sprite.z_index=-2;world.add_child(sprite)
 else:world.prop(art,at,Vector2(-size_value.x/2,-size_value.y),Rect2(-minf(22,size_value.x*.3),-10,minf(44,size_value.x*.6),10))
func _process(delta: float) -> void:
 var game=get_tree().get_first_node_in_group("yintian_game")
 if game!=null and game.modal!=null:return
 clock+=delta;refresh+=delta
 if refresh>0.12:refresh=0;queue_redraw()
func _draw() -> void:
 if not is_instance_valid(world):return
 var rect=world.screen_bounds().grow(100)
 var lo=Vector2i((rect.position/128).floor());var hi=Vector2i((rect.end/128).floor())
 for y in range(lo.y,hi.y+1):
  for x in range(lo.x,hi.x+1):
   for detail in chunks.get(Vector2i(x,y),[]):
    var at: Vector2=detail.at
    var color=Color("93846b") if detail.region=="temple" else Color("575c57") if detail.region=="graveyard" else Color("8b8475")
    color.a=0.45
    if detail.type==0:
     draw_line(at,at+Vector2(5,2),color.darkened(.25),1)
    elif detail.type==1:
     draw_set_transform(at,detail.turn)
     draw_rect(Rect2(-2,-1,4,2),color)
     draw_set_transform(Vector2.ZERO)
    elif detail.type==2 and detail.region=="island":
     draw_line(at,at+Vector2(8,1),Color("392f2c99"),2)
    else:
     draw_circle(at,1,Color("2b342d50"))
