extends SceneTree
func _initialize():
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/jrpg/parts/parts.json"))
 var paths: Array=[]
 for key in data:
  for piece in data[key].parts:
   if piece.path not in paths:paths.append(piece.path)
 paths.sort()
 var atlas=Image.create(4096,4096,false,Image.FORMAT_RGBA8)
 var x=2;var y=2;var row_height=0;var regions: Dictionary={}
 for path in paths:
  var source=Image.load_from_file(path)
  source.convert(Image.FORMAT_RGBA8)
  if x+source.get_width()+2>4096:x=2;y+=row_height+4;row_height=0
  assert(y+source.get_height()+2<=4096)
  atlas.blit_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),Vector2i(x,y))
  regions[path]=[x,y,source.get_width(),source.get_height()]
  assert(atlas.get_region(Rect2i(x,y,source.get_width(),source.get_height())).get_data()==source.get_data())
  x+=source.get_width()+4;row_height=maxi(row_height,source.get_height())
 atlas=atlas.get_region(Rect2i(0,0,4096,mini(4096,ceili(float(y+row_height+2)/128)*128)))
 assert(atlas.save_png("res://assets/jrpg/parts/packed.png")==OK)
 var file=FileAccess.open("res://assets/jrpg/parts/packed.json",FileAccess.WRITE);file.store_string(JSON.stringify(regions,"\t"));file.close()
 print("PACKED PARTS PASS ",paths.size()," lossless regions; used height ",y+row_height)
 quit()
