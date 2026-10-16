extends SceneTree
const GROUPS={
 "grave":{"rows":[0,201,412,646,833,1032,1295],"kinds":["water","bone","archer","lantern","gunner","brute"]},
 "island":{"rows":[0,186,389,608,846,1045,1312],"kinds":["kappa","chochin","ippon_datara","jorogumo","sogenbi","itsumade"]},
 "myths":{"rows":[0,198,400,602,818,1029,1274],"kinds":["daitengu","ryomen_sukuna","hungry_ghost","wraith","rakshasa","kumbhanda"]},
 "bosses":{"rows":[0,259,514,746,996,1295],"kinds":["asura","yaksha","well_boss","opera_boss","boss"]}}
const PARTS=["body","head","arm_left","arm_right","leg_left","leg_right"]
func _initialize():
 var manifest={}
 for group in GROUPS:
  var sheet=Image.load_from_file("res://assets/monsters27/source/"+group+".png")
  var data=GROUPS[group]
  for row in range(data.kinds.size()):
   var kind=data.kinds[row];var frames=[];var largest=Vector2.ZERO
   for col in range(4):
    var x0=int(col*sheet.get_width()/4.0);var x1=int((col+1)*sheet.get_width()/4.0)
    var crop=sheet.get_region(Rect2i(x0,data.rows[row],x1-x0,data.rows[row+1]-data.rows[row]))
    var used=crop.get_used_rect();var cut=crop.get_region(used)
    frames.append(cut);largest=largest.max(Vector2(cut.get_size()))
   var boss=kind in ["itsumade","daitengu","ryomen_sukuna","asura","yaksha","well_boss","opera_boss","boss"]
   var ratio=minf((79.0 if boss else 62.0)/largest.y,90.0/largest.x)
   var atlas=Image.create(768,576,false,Image.FORMAT_RGBA8);var pivots=[]
   for frame in range(4):
    var cut: Image=frames[frame];cut.resize(maxi(1,int(cut.get_width()*ratio)),maxi(1,int(cut.get_height()*ratio)),Image.INTERPOLATE_NEAREST)
    var origin=Vector2i((96-cut.get_width())/2,92-cut.get_height())
    var layers=[]
    for i in range(6):layers.append(Image.create(96,96,false,Image.FORMAT_RGBA8))
    var joints=[Vector2(48,65),Vector2(48,origin.y+cut.get_height()*0.27),Vector2(origin.x+cut.get_width()*0.3,origin.y+cut.get_height()*0.44),Vector2(origin.x+cut.get_width()*0.7,origin.y+cut.get_height()*0.44),Vector2(43,origin.y+cut.get_height()*0.76),Vector2(53,origin.y+cut.get_height()*0.76)]
    for y in range(cut.get_height()):
     for x in range(cut.get_width()):
      var c=cut.get_pixel(x,y)
      if c.a<0.12:continue
      var nx=float(x)/cut.get_width();var ny=float(y)/cut.get_height();var part=0
      if kind not in ["wraith","sogenbi","lantern","chochin"]:
       if ny<0.28 and nx>0.28 and nx<0.72:part=1
       elif ny>0.77:part=4 if nx<0.5 else 5
       elif ny>0.30 and ny<0.77 and (nx<0.28 or nx>0.72):part=2 if nx<0.5 else 3
       if kind=="ippon_datara" and part==4:part=5
      elif kind=="chochin":part=1
      layers[part].set_pixel(x+origin.x,y+origin.y,c)
    for i in range(6):
     var index=frame*6+i;atlas.blit_rect(layers[i],Rect2i(0,0,96,96),Vector2i(index%8,index/8)*96)
    for i in range(5):
     var part=i+1;var wound=Image.create(96,96,false,Image.FORMAT_RGBA8);var pivot=Vector2i(joints[part])
     for dy in range(-1,2):
      for dx in range(-2,3):
       if pivot.x+dx>=0 and pivot.x+dx<96 and pivot.y+dy>=0 and pivot.y+dy<96:wound.set_pixel(pivot.x+dx,pivot.y+dy,Color("652d3d") if dy<=0 else Color("a65753"))
     var index=24+frame*5+i;atlas.blit_rect(wound,Rect2i(0,0,96,96),Vector2i(index%8,index/8)*96)
    pivots.append(joints.map(func(v):return [v.x,v.y]))
   atlas.save_png("res://assets/monsters27/"+kind+".png")
   manifest[kind]={"frames":4,"pivots":pivots,"source":group,"row":row}
 var f=FileAccess.open("res://assets/monsters27/manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify(manifest," "));f.close()
 var details=Image.load_from_file("res://assets/districts27/source.png")
 var keys=YinWorldDetailArt.SIZES.keys()
 for i in range(keys.size()):
  var size_value: Vector2i=YinWorldDetailArt.SIZES[keys[i]]
  var crop=details.get_region(Rect2i(int((i%6)*details.get_width()/6.0),int((i/6)*details.get_height()/4.0),int(details.get_width()/6.0),int(details.get_height()/4.0)))
  crop=crop.get_region(crop.get_used_rect());var ratio=minf(float(size_value.x)/crop.get_width(),float(size_value.y)/crop.get_height())
  crop.resize(maxi(1,int(crop.get_width()*ratio)),maxi(1,int(crop.get_height()*ratio)),Image.INTERPOLATE_NEAREST)
  var target=Image.create(size_value.x,size_value.y,false,Image.FORMAT_RGBA8);target.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i((size_value.x-crop.get_width())/2,size_value.y-crop.get_height()))
  target.save_png("res://assets/districts27/"+keys[i]+".png")
 print("BAKED 23 unique monsters, 92 authored poses and 24 district objects")
 quit()
