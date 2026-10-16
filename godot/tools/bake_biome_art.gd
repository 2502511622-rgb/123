extends SceneTree
const SOURCE="res://assets/biomes26/source.png"
func _initialize():call_deferred("run")
func run():
 var image=Image.load_from_file(SOURCE)
 var rows=[0,370,720,1086]
 var ids=YinBiomeArt.SIZES.keys()
 for row in range(3):
  var cols=[0,424,775,1090 if row==0 else 1148,1448]
  for column in range(4):
   var id: String=ids[row*4+column]
   var raw=image.get_region(Rect2i(cols[column]+2,rows[row]+2,cols[column+1]-cols[column]-4,rows[row+1]-rows[row]-4))
   for y in range(raw.get_height()):
    for x in range(raw.get_width()):
     if raw.get_pixel(x,y).a<0.5:raw.set_pixel(x,y,Color.TRANSPARENT)
   raw=raw.get_region(raw.get_used_rect())
   var size: Vector2i=YinBiomeArt.SIZES[id]
   var scale_value=minf(float(size.x)/raw.get_width(),float(size.y)/raw.get_height())
   var fitted=Vector2i(maxi(1,roundi(raw.get_width()*scale_value)),maxi(1,roundi(raw.get_height()*scale_value)))
   raw.resize(fitted.x,fitted.y,Image.INTERPOLATE_NEAREST)
   var result=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
   result.blit_rect(raw,Rect2i(Vector2i.ZERO,fitted),Vector2i((size.x-fitted.x)/2,size.y-fitted.y))
   result.save_png("res://assets/biomes26/"+id+".png")
   print("BIOME ",id," ",size)
 quit()
