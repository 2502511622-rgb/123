class_name YinLandscape29
extends RefCounted
# Static, world-space distance/relief field. Geometry is baked once, never per frame.
const STEP=8
const COAST=Rect2(5232,1840,848,464)
const GRAVES=[Vector2(4240,3360),Vector2(4768,3328),Vector2(5120,3808)]
var world: FarmWorld
var texture: ImageTexture
var size: Vector2i
var values:=PackedFloat32Array()
var road_cells: Dictionary={}
var bake_ms: int=0
static func is_road(id: int) -> bool:return id==10 or id>=16
static func forest(at: Vector2) -> bool:
 return at.x<3104 and at.y>2496 or at.x>3296 and (at.y>3856 or at.x>5200 and at.y>3328)
func center(cell: Vector2i) -> Vector2:
 var at=Vector2(cell)*32+Vector2(16,16)
 return at+Vector2(sin(at.y*.019)*2.4,sin(at.x*.023)*2.4)
func radius(at: Vector2) -> float:return 15.5+sin(at.x*.014+at.y*.009)*2.3
func capsule(a: Vector2,b: Vector2,base_radius: float=-1) -> void:
 var bounds=Rect2(a,b-a).abs().grow(54)
 var lo=Vector2i((bounds.position/STEP).floor()).clamp(Vector2i.ZERO,size-Vector2i.ONE)
 var hi=Vector2i((bounds.end/STEP).ceil()).clamp(Vector2i.ZERO,size-Vector2i.ONE)
 var ab=b-a;var length2=maxf(.001,ab.length_squared())
 for y in range(lo.y,hi.y+1):
  for x in range(lo.x,hi.x+1):
   var at=Vector2(x*STEP+STEP/2,y*STEP+STEP/2)
   var t=clampf((at-a).dot(ab)/length2,0,1)
   var nearest=a+ab*t
   var width=radius(nearest) if base_radius<0 else base_radius+sin(nearest.x*.014+nearest.y*.009)*3.0
   var d=at.distance_to(nearest)-width
   var index=(y*size.x+x)*3
   values[index]=minf(values[index],d)
func ellipse(at: Vector2,extent: Vector2,height: float,channel: int=1) -> void:
 var lo=Vector2i(((at-extent)/STEP).floor()).clamp(Vector2i.ZERO,size-Vector2i.ONE)
 var hi=Vector2i(((at+extent)/STEP).ceil()).clamp(Vector2i.ZERO,size-Vector2i.ONE)
 for y in range(lo.y,hi.y+1):
  for x in range(lo.x,hi.x+1):
   var p=(Vector2(x*STEP+4,y*STEP+4)-at)/extent
   var r=p.length()+sin(p.x*11+p.y*7)*.10+sin(p.x*5-p.y*13)*.04
   var weight=1-smoothstep(.12,1,r)
   var index=(y*size.x+x)*3+channel
   values[index]+=weight*height
func bake(owner_world: FarmWorld) -> void:
 var started=Time.get_ticks_msec();world=owner_world;size=Vector2i((world.level_size/STEP).ceil())
 values.resize(size.x*size.y*3);values.fill(0)
 for i in range(size.x*size.y):values[i*3]=48
 for cell in world.tile_farm.ground.get_used_cells():
  if is_road(world.tile_farm.ground.get_cell_atlas_coords(cell).x):road_cells[cell]=true
 if world is YinContinentWorld:
  # The TileMap still carries navigation types. Visible roads follow the actual
  # route centreline, not the square union of its rasterized tile cells.
  for route_index in range(YinWorldDistricts.ROUTES.size()):
   var route=YinWorldDistricts.ROUTES[route_index]
   var width=14.5 if route_index>=9 else 26.0
   for i in range(route.size()-1):
    var a: Vector2=route[maxi(0,i-1)];var b: Vector2=route[i]
    var c: Vector2=route[i+1];var d: Vector2=route[mini(route.size()-1,i+2)]
    var count=maxi(2,int(b.distance_to(c)/24));var previous: Vector2=b
    for j in range(1,count+1):
     var t=float(j)/count
     var at=.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
     capsule(previous,at,width);previous=at
 else:
  for cell in road_cells:
   var a=center(cell);capsule(a,a)
   for direction in [Vector2i.RIGHT,Vector2i.DOWN]:
    if road_cells.has(cell+direction):capsule(a,center(cell+direction))
 if world is YinContinentWorld:
  for at in GRAVES:
   ellipse(at+Vector2(0,5),Vector2(60,35),.85)
   ellipse(at+Vector2(73,32),Vector2(48,28),-.95)
  for at in [Vector2(4560,4080),Vector2(5220,4296),Vector2(5600,4016)]:
   ellipse(at,Vector2(70,40),.45);ellipse(at+Vector2(85,40),Vector2(50,25),-.45)
  for at in [Vector2(5376,2136),Vector2(5752,2176)]:
   ellipse(at,Vector2(100,50),-.75);ellipse(at+Vector2(24,24),Vector2(80,36),-.35)
  ellipse(Vector2(5544,2112),Vector2(100,120),.35)
 elif world.state.zone in ["forest","graveyard"]:
  for at in local_graves():ellipse(at,Vector2(58,32),.8);ellipse(at+Vector2(65,26),Vector2(42,26),-.8)
 for at in world.trees:ellipse(at+Vector2(18,8),Vector2(60,32),.25,2)
 var image=Image.create_from_data(size.x,size.y,false,Image.FORMAT_RGBF,values.to_byte_array())
 texture=ImageTexture.create_from_image(image);bake_ms=Time.get_ticks_msec()-started
func local_graves() -> Array:
 return [Vector2(220,180),Vector2(560,440),Vector2(800,150)]
func sample(at: Vector2,channel: int=0) -> float:
 var p=at/STEP-Vector2(.5,.5);var c=Vector2i(p.floor());var f=p-Vector2(c)
 var a=c.clamp(Vector2i.ZERO,size-Vector2i.ONE);var b=(c+Vector2i.ONE).clamp(Vector2i.ZERO,size-Vector2i.ONE)
 return lerpf(lerpf(values[(a.y*size.x+a.x)*3+channel],values[(a.y*size.x+b.x)*3+channel],f.x),lerpf(values[(b.y*size.x+a.x)*3+channel],values[(b.y*size.x+b.x)*3+channel],f.x),f.y)
