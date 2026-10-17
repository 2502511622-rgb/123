extends SceneTree
const NAMES=["fern","clover","mushroom","shrub","tall_grass","dry_grass","stump","branch","stele","mound","coffin","tomb","bones","wreath","chain","tablet"]
const SIZES=[Vector2i(20,16),Vector2i(15,10),Vector2i(13,12),Vector2i(46,40),Vector2i(28,34),Vector2i(20,18),Vector2i(38,36),Vector2i(22,12),Vector2i(42,56),Vector2i(72,34),Vector2i(66,42),Vector2i(80,56),Vector2i(20,13),Vector2i(20,16),Vector2i(22,12),Vector2i(34,42)]
func _initialize():
 var cells=JSON.parse_string(FileAccess.get_file_as_string("res://assets/landscape29/source/cells.json"))
 var source=Image.load_from_file("res://assets/landscape29/source/props.png")
 for i in range(16):
  var c=cells.props[i];var rect=Rect2i(c[0],c[1],c[2],c[3])
  var image=source.get_region(rect);image=image.get_region(image.get_used_rect())
  var factor=minf(float(SIZES[i].x)/image.get_width(),float(SIZES[i].y)/image.get_height())
  image.resize(maxi(1,roundi(image.get_width()*factor)),maxi(1,roundi(image.get_height()*factor)),Image.INTERPOLATE_NEAREST)
  for y in range(image.get_height()):
   for x in range(image.get_width()):
    var pixel=image.get_pixel(x,y)
    if pixel.a<.42:image.set_pixel(x,y,Color.TRANSPARENT)
  image.save_png("res://assets/landscape29/"+NAMES[i]+".png")
 var materials=Image.load_from_file("res://assets/landscape29/source/materials.png")
 var atlas=Image.create(1024,768,false,Image.FORMAT_RGB8)
 for row in range(3):
  for col in range(4):
   var tile=materials.get_region(Rect2i(Vector2i(col*materials.get_width()/4,row*materials.get_height()/3),Vector2i(materials.get_width()/4,materials.get_height()/3)))
   tile.resize(256,256,Image.INTERPOLATE_NEAREST);atlas.blit_rect(tile,Rect2i(0,0,256,256),Vector2i(col*256,row*256))
 atlas.save_png("res://assets/landscape29/materials.png")
 var coast=Image.load_from_file("res://assets/landscape29/source/coast-props.png")
 var names=["ruin_left","ruin_right","pillar","statue","barrel","planks","shells","salt_grass"]
 var sizes=[Vector2i(160,140),Vector2i(160,128),Vector2i(72,38),Vector2i(42,42),Vector2i(30,32),Vector2i(50,20),Vector2i(20,13),Vector2i(24,20)]
 for i in range(8):
  var c=cells["coast-props"][i];var image=coast.get_region(Rect2i(c[0],c[1],c[2],c[3]))
  image=image.get_region(image.get_used_rect())
  var factor=minf(float(sizes[i].x)/image.get_width(),float(sizes[i].y)/image.get_height())
  image.resize(maxi(1,roundi(image.get_width()*factor)),maxi(1,roundi(image.get_height()*factor)),Image.INTERPOLATE_NEAREST)
  image.save_png("res://assets/landscape29/"+names[i]+".png")
 var coast_ground=Image.load_from_file("res://assets/landscape29/source/coast.png")
 coast_ground.resize(512,512,Image.INTERPOLATE_NEAREST);coast_ground.save_png("res://assets/landscape29/coast.png")
 var low_names=["fern","clover","mushroom","dry_grass","branch","bones","wreath","chain","shells","salt_grass"]
 var low_atlas=Image.create(128,96,false,Image.FORMAT_RGBA8);var regions={}
 for i in range(low_names.size()):
  var image=Image.load_from_file("res://assets/landscape29/"+low_names[i]+".png")
  var at=Vector2i(i%4*32+2,i/4*32+2)
  low_atlas.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),at)
  regions[low_names[i]]=[at.x,at.y,image.get_width(),image.get_height()]
 low_atlas.save_png("res://assets/landscape29/low.png")
 var file=FileAccess.open("res://assets/landscape29/low.json",FileAccess.WRITE);file.store_string(JSON.stringify(regions," "));file.close()
 print("LANDSCAPE29 baked 24 props, 16 terrain variants and shared low-plant atlas");quit()
