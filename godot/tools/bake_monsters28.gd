extends SceneTree
const GROUPS={"grave":["water","bone","archer","lantern","gunner","brute"],"island":["kappa","chochin","ippon_datara","jorogumo","sogenbi","itsumade"],"myths":["daitengu","ryomen_sukuna","hungry_ghost","wraith","rakshasa","kumbhanda"],"bosses":["asura","yaksha","well_boss","opera_boss","boss"]}
const PARTS=["body","head","arm_left","arm_right","leg_left","leg_right"]
func anchor(image: Image,bottom=false) -> Vector2:
 var width=image.get_width();var height=image.get_height();var sum=0.0;var mass=0.0
 var lo=int(height*.8) if bottom else 0;var hi=height if bottom else maxi(1,int(height*.2))
 for y in range(lo,hi):
  for x in range(width):
   var a=image.get_pixel(x,y).a
   if a>.4:sum+=x*a;mass+=a
 return Vector2(sum/mass if mass>0 else width*.5,height-2 if bottom else 2)
func trim(image: Image) -> Image:
 var lo=Vector2i(image.get_width(),image.get_height());var hi=Vector2i.ZERO
 for y in range(image.get_height()):
  for x in range(image.get_width()):
   var c=image.get_pixel(x,y)
   if c.a<.4:image.set_pixel(x,y,Color.TRANSPARENT);continue
   lo=lo.min(Vector2i(x,y));hi=hi.max(Vector2i(x,y))
 assert(hi.x>lo.x and hi.y>lo.y,"Empty anatomical source cell")
 return image.get_region(Rect2i(lo,hi-lo+Vector2i.ONE))
func _initialize():
 var cells=JSON.parse_string(FileAccess.get_file_as_string("res://assets/monsters28/source/cells.json"));var manifest={}
 for group in GROUPS:
  var image=Image.load_from_file("res://assets/monsters28/source/"+group+".png");var grid=cells[group]
  for row in range(GROUPS[group].size()):
   var kind=GROUPS[group][row];var atlas=Image.create(768,576,false,Image.FORMAT_RGBA8);var sprites=[];var offsets=[];var anchors=[]
   for col in range(6):
    var crop=trim(image.get_region(Rect2i(grid.columns[row][col],grid.rows[row],grid.columns[row][col+1]-grid.columns[row][col],grid.rows[row+1]-grid.rows[row])))
    if kind=="hungry_ghost" and col==0:crop=trim(Image.load_from_file("res://assets/monsters28/source/hungry_torso.png"))
    var size_value=Vector2(28,24) if col==0 else Vector2(27,23) if col==1 else Vector2(13,23) if col<4 else Vector2(12,20)
    var ratio=minf(size_value.x/crop.get_width(),size_value.y/crop.get_height())
    crop.resize(maxi(1,int(crop.get_width()*ratio)),maxi(1,int(crop.get_height()*ratio)),Image.INTERPOLATE_NEAREST)
    sprites.append(crop);anchors.append(anchor(crop,col==1))
   var body: Image=sprites[0]
   var shoulder=float(body.get_width())*.43;var hip_y=52+body.get_height()-5
   var points=[Vector2(48,52),Vector2(48,52),Vector2(48-shoulder,54),Vector2(48+shoulder,54),Vector2(43,hip_y),Vector2(53,hip_y)]
   for col in range(6):
    var a: Vector2=anchors[col];var offset=points[col]-a
    offsets.append(offset)
    var canvas=Image.create(96,96,false,Image.FORMAT_RGBA8)
    canvas.blit_rect(sprites[col],Rect2i(Vector2i.ZERO,sprites[col].get_size()),Vector2i(offset))
    for frame in range(4):
     var index=frame*6+col;atlas.blit_rect(canvas,Rect2i(0,0,96,96),Vector2i(index%8,index/8)*96)
   for frame in range(4):
    for part in range(1,6):
     var wound=Image.create(96,96,false,Image.FORMAT_RGBA8);var at=Vector2i(points[part])
     for y in range(-2,3):
      for x in range(-4,5):
       if float(x*x)/16+float(y*y)/4<=1:wound.set_pixel(at.x+x,at.y+y,Color("42252f") if abs(x)>2 or abs(y)>1 else Color("a65855"))
     var index=24+frame*5+part-1;atlas.blit_rect(wound,Rect2i(0,0,96,96),Vector2i(index%8,index/8)*96)
   atlas.save_png("res://assets/monsters28/"+kind+".png")
   var pivots=points.map(func(v):return [v.x,v.y])
   manifest[kind]={"height":90-int(offsets[1].y),"frames":1,"source_poses":1,"atlas_slots":4,"motion_keys":8,"attack_keys":6,"source":group,"row":row,"independent_anatomy":true,"pivots":[pivots,pivots,pivots,pivots],"torso_override":"source/hungry_torso.png" if kind=="hungry_ghost" else "", "cut_caps":true,"root":[48,90],"parts":PARTS,"detachable":YinEnemyPack.anatomical(kind),"walk_curve":YinMonsterArt.WALK_KEYS.map(func(v):return [v.x,v.y,v.z]),"attack_curve":YinMonsterArt.ATTACK_KEYS.map(func(v):return [v.x,v.y,v.z])}
 var out=FileAccess.open("res://assets/monsters28/manifest.json",FileAccess.WRITE);out.store_string(JSON.stringify(manifest," "));out.close()
 print("BAKED 23 chibi kits from 138 independently drawn anatomical cells; no whole-character coordinate partitioning")
 quit()
