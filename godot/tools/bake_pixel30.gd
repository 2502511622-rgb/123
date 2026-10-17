extends SceneTree
# Technical import only: preserve independently generated poses, common scale,
# fixed cell origin and opaque alpha. No procedural pose creation or tween bake.
func _initialize():
 var manifest={}
 for action in ["walk","combat","alt-walk","alt-combat"]:
  var image=Image.load_from_file("res://assets/pixel30/source/hero-"+action+".png")
  if image==null:quit(1);return
  var atlas=Image.create(768,384,false,Image.FORMAT_RGBA8);var rows=[]
  for row in range(4):
   var frames=[];var cell=Vector2i(image.get_width()/8,image.get_height()/4)
   var height=0
   for col in range(8):
    var rect=image.get_region(Rect2i(Vector2i(col,row)*cell,cell)).get_used_rect()
    height=maxi(height,rect.size.y)
   var factor=50.0/height
   for col in range(8):
    var source=image.get_region(Rect2i(Vector2i(col,row)*cell,cell));var used=source.get_used_rect()
    var crop=source.get_region(used)
    crop.resize(maxi(1,roundi(crop.get_width()*factor)),maxi(1,roundi(crop.get_height()*factor)),Image.INTERPOLATE_NEAREST)
    var offset=Vector2i(roundi(48+(used.position.x-cell.x*.5)*factor),90-crop.get_height())
    var hand=Vector2(58,65);var found=[]
    for y in range(crop.get_height()):
     for x in range(crop.get_width()):
      var p=crop.get_pixel(x,y)
      if p.a<.65:crop.set_pixel(x,y,Color.TRANSPARENT)
      else:
       p.a=1;crop.set_pixel(x,y,p)
       if y>crop.get_height()*.40 and y<crop.get_height()*.76 and p.r>.38 and p.r>p.g*1.15 and p.g>p.b*1.15:
        found.append(Vector2(x,y)+Vector2(offset))
    if not found.is_empty():
     found.sort_custom(func(a,b):return a.x<b.x)
     var extreme=found[0].x if row==2 else found[-1].x;var total=Vector2.ZERO;var n=0
     for at in found:
      if absf(at.x-extreme)<=1:total+=at;n+=1
     hand=total/maxi(n,1)
    atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(col,row)*96+offset)
    frames.append({"rect":[col*96+offset.x,row*96+offset.y,crop.get_width(),crop.get_height()],"anchor":[48-offset.x,90-offset.y],"hand":[hand.x-offset.x,hand.y-offset.y],"mirror":false})
   rows.append(frames)
  atlas.save_png("res://assets/pixel30/hero-"+action+".png");manifest[action]=rows
 var npc_path="res://assets/pixel30/source/npc.png"
 if FileAccess.file_exists(npc_path):
  var image=Image.load_from_file(npc_path);var atlas=Image.create(384,256,false,Image.FORMAT_RGBA8);var rows=[]
  var cell=Vector2i(image.get_width()/6,image.get_height()/4)
  var factor=48.0/(cell.y-10)
  for row in range(4):
   var frames=[]
   for col in range(6):
    var source=image.get_region(Rect2i(Vector2i(col,row)*cell,cell));var used=source.get_used_rect();var crop=source.get_region(used)
    crop.resize(maxi(1,roundi(crop.get_width()*factor)),maxi(1,roundi(crop.get_height()*factor)),Image.INTERPOLATE_NEAREST)
    var offset=Vector2i(roundi(32+(used.position.x-cell.x*.5)*factor),60-crop.get_height())
    for y in range(crop.get_height()):
     for x in range(crop.get_width()):
      var p=crop.get_pixel(x,y)
      if p.a<.65:p=Color.TRANSPARENT
      else:p.a=1
      crop.set_pixel(x,y,p)
    atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(col,row)*64+offset)
    frames.append({"rect":[col*64+offset.x,row*64+offset.y,crop.get_width(),crop.get_height()],"anchor":[32-offset.x,60-offset.y],"mirror":false})
   rows.append(frames)
  manifest.npc=rows;atlas.save_png("res://assets/pixel30/npc.png")
 var f=FileAccess.open("res://assets/pixel30/manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify(manifest," "));f.close()
 print("PIXEL30 imported two presets, each 32 walk and 32 combat/idle/hurt source poses");quit()
