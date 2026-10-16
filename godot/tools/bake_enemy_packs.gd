extends SceneTree
## Technical normalization of generated components, not silhouette slicing.
const SOURCE="res://assets/enemy_packs/source/components.png"
const COLS=[0,246,486,687,889,1128,1374]
const ROWS=[0,220,441,664,888,1145]
var colors: Array[Color]=[]
func _initialize() -> void:call_deferred("run")
func blank() -> Image:return Image.create(64,64,false,Image.FORMAT_RGBA8)
func quantize(image: Image) -> void:
 for y in range(image.get_height()):
  for x in range(image.get_width()):
   var c=image.get_pixel(x,y)
   if c.a<0.35:image.set_pixel(x,y,Color.TRANSPARENT);continue
   var best=colors[0];var distance=100.0
   for candidate in colors:
    var d=Vector3(c.r-candidate.r,c.g-candidate.g,c.b-candidate.b).length_squared()
    if d<distance:distance=d;best=candidate
   image.set_pixel(x,y,best)
func composite(layers: Dictionary,clock: float,moving: bool,hit: int=-1) -> Image:
 var image=blank()
 for part in ["leg_left","leg_right","arm_left","arm_right","body","head"]:
  var transform=YinEnemyPack.transform_for(part,clock,moving,false,hit)
  transform.origin+=Vector2(32,61)
  var inverse=transform.affine_inverse()
  for y in range(64):
   for x in range(64):
    var p=inverse*Vector2(x,y)+YinEnemyPack.PIVOTS[part]
    var u=int(roundf(p.x));var v=int(roundf(p.y))
    if u>=0 and v>=0 and u<64 and v<64:
     var c=layers[part].get_pixel(u,v)
     if c.a>0:image.set_pixel(x,y,c)
 return image
func run() -> void:
 for hex in YinEnemyPack.PALETTE:colors.append(Color(hex))
 var source=Image.load_from_file(SOURCE)
 if source==null:push_error("Missing generated source");quit(1);return
 for row in range(5):
  var pack: String=YinEnemyPack.IDS[row]
  var folder="res://assets/enemy_packs/"+pack+"/"
  for sub in ["parts","stumps","blood"]:DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder+sub))
  var atlas=Image.create(512,320,false,Image.FORMAT_RGBA8)
  var layers: Dictionary={};var manifest={"id":pack,"cell_size":[64,64],"palette":YinEnemyPack.PALETTE,"root":[32,61],"parts":{},"stumps":{},"animations":{}}
  for column in range(6):
   var part: String=YinEnemyPack.PARTS[column]
   var crop=source.get_region(Rect2i(COLS[column]+6,ROWS[row]+6,COLS[column+1]-COLS[column]-12,ROWS[row+1]-ROWS[row]-12))
   # Discard antialias fringes and atlas guide lines before measuring alpha.
   for y in range(crop.get_height()):
    for x in range(crop.get_width()):
     var c=crop.get_pixel(x,y)
     if c.a<0.5:crop.set_pixel(x,y,Color.TRANSPARENT)
   crop=crop.get_region(crop.get_used_rect())
   var target=Vector2i(24,25);var at=Vector2i(20,19)
   if part=="head":target=Vector2i(20,24);at=Vector2i(22,0)
   elif part.begins_with("arm_"):target=Vector2i(11,27);at=Vector2i(YinEnemyPack.PIVOTS[part])-Vector2i(5,3)
   elif part.begins_with("leg_"):target=Vector2i(10,23);at=Vector2i(YinEnemyPack.PIVOTS[part])-Vector2i(5,2)
   crop.resize(target.x,target.y,Image.INTERPOLATE_LANCZOS);quantize(crop)
   if part=="body":
    # Source torso shoulder ornaments are retained, but no baked arm can extend below the shoulder.
    for y in range(crop.get_height()):
     for x in range(crop.get_width()):
      if y>8 and (x<3 or x>=21):crop.set_pixel(x,y,Color.TRANSPARENT)
   var layer=blank();layer.blit_rect(crop,Rect2i(Vector2i.ZERO,target),at);layers[part]=layer
   layer.save_png(folder+"parts/"+part+".png")
   atlas.blit_rect(layer,Rect2i(0,0,64,64),Vector2i(column*64,0))
   manifest.parts[part]={"index":column,"pivot":[YinEnemyPack.PIVOTS[part].x,YinEnemyPack.PIVOTS[part].y],"file":"parts/"+part+".png"}
  for i in range(4):
   var part: String=YinEnemyPack.LIMBS[i];var stump=blank();var center=Vector2i(YinEnemyPack.PIVOTS[part])
   for y in range(-1,2):
    for x in range(-2,3):
     if abs(x)+abs(y)<=2:stump.set_pixel(center.x+x,center.y+y,Color("834348") if y<1 else Color("b26256"))
   stump.save_png(folder+"stumps/"+part+".png");var index=6+i
   atlas.blit_rect(stump,Rect2i(0,0,64,64),Vector2i(index%8,index/8)*64)
   manifest.stumps[part]={"index":index,"file":"stumps/"+part+".png"}
  for i in range(3):
   var blood=blank()
   for y in range(-4,5):
    for x in range(-6,7):
     var draw_pixel=(abs(x)<=1 and y>=-3 and y<=1) if i==0 else ((x*x+9*y*y<37) if i==1 else (abs(x)+abs(y)<2))
     if draw_pixel:blood.set_pixel(32+x,32+y,Color("834348") if i!=2 else Color("b26256"))
   var label=["drop","stain","splash"][i];blood.save_png(folder+"blood/"+label+".png")
   atlas.blit_rect(blood,Rect2i(0,0,64,64),Vector2i((10+i)%8,(10+i)/8)*64)
  var residual=blank()
  for part in ["body","head"]:residual.blend_rect(layers[part],Rect2i(0,0,64,64),Vector2i.ZERO)
  residual.save_png(folder+"residual.png");atlas.blit_rect(residual,Rect2i(0,0,64,64),Vector2i(5,1)*64)
  var neck=blank()
  for y in range(2):
   for x in range(5):neck.set_pixel(30+x,21+y,Color("834348"))
  atlas.blit_rect(neck,Rect2i(0,0,64,64),Vector2i(6,1)*64);neck.save_png(folder+"stumps/neck.png")
  for clip in ["idle","walk","hit"]:
   var count={"idle":4,"walk":8,"hit":3}[clip];var start={"idle":16,"walk":24,"hit":32}[clip]
   var strip=Image.create(64*count,64,false,Image.FORMAT_RGBA8)
   for frame in range(count):
    var clock=frame*TAU/(10 if clip=="walk" else 2)/count
    var full=composite(layers,clock,clip=="walk",frame if clip=="hit" else -1)
    strip.blit_rect(full,Rect2i(0,0,64,64),Vector2i(frame*64,0))
    atlas.blit_rect(full,Rect2i(0,0,64,64),Vector2i((start+frame)%8,(start+frame)/8)*64)
   strip.save_png(folder+clip+".png");manifest.animations[clip]={"index":start,"frames":count,"fps":12 if clip!="hit" else 18,"file":clip+".png"}
  atlas.save_png(folder+"atlas.png")
  var file=FileAccess.open(folder+"manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"));file.close()
  print("BAKED ",pack," 64px components, 4 idle / 8 walk / 3 hit, stumps and blood")
 quit()
