class_name YinGroundCache30
extends Node2D
# Static terrain composition is rendered once per world chunk. Weather, water,
# lighting and gameplay remain live. Bounded GPU-only cache, no readback stall.
const CELL=256
const LIMIT=64
var world: FarmWorld
var chunks: Dictionary={}
var pending: Array[Vector2i]=[]
var busy=false
var active=false
var clock=0
var builds=0
var range_key=Rect2i()
var membership_builds=-1
var required: Array[Vector2i]=[]
var parameters: Dictionary={}
var runtime_material: ShaderMaterial
var bake_world=World2D.new()
var white: Texture2D
func _ready():
 z_index=-3
 var image=Image.create(1,1,false,Image.FORMAT_RGBA8);image.fill(Color.WHITE);white=ImageTexture.create_from_image(image)
 runtime_material=ShaderMaterial.new();runtime_material.shader=preload("res://shaders/cached_ground30.gdshader")
 runtime_material.set_shader_parameter("terrain_types",world.environment.terrain_types)
 runtime_material.set_shader_parameter("landscape_field",world.environment.landscape29.texture)
 runtime_material.set_shader_parameter("map_size",world.level_size)
func cells(rect: Rect2) -> Array[Vector2i]:
 var result: Array[Vector2i]=[]
 var lo=Vector2i((rect.position/CELL).floor()).max(Vector2i.ZERO)
 var hi=Vector2i(((rect.end-Vector2.ONE)/CELL).floor()).min(Vector2i((world.level_size-Vector2.ONE)/CELL))
 for y in range(lo.y,hi.y+1):
  for x in range(lo.x,hi.x+1):result.append(Vector2i(x,y))
 return result
func _process(_delta):
 if not world.environment.baked:return
 clock+=1
 var view=world.screen_bounds().grow(8)
 var lo=Vector2i((view.position/CELL).floor());var hi=Vector2i(((view.end-Vector2.ONE)/CELL).floor())
 var key=Rect2i(lo,hi-lo+Vector2i.ONE)
 if key!=range_key or membership_builds!=builds:
  range_key=key;membership_builds=builds;required=cells(view)
  active=not required.is_empty() and required.all(func(c):return chunks.has(c))
  world.tile_farm.ground.visible=not active
  for cell in chunks:chunks[cell].sprite.visible=active and cell in required
  var wanted=cells(view.grow(384));pending.clear()
  for cell in required+wanted:
   if not chunks.has(cell) and cell not in pending:pending.append(cell)
 for cell in required:
  if chunks.has(cell):chunks[cell].used=clock
 var env=world.environment
 runtime_material.set_shader_parameter("clock_time",env.time)
 for pair in [["wetness",env.wetness],["snow",env.regional.snow if env.regional!=null else 0.0],["dust",env.regional.dust if env.regional!=null else 0.0],["blood",env.regional.blood if env.regional!=null else 0.0]]:
  if parameters.get(pair[0])!=pair[1]:
   parameters[pair[0]]=pair[1];runtime_material.set_shader_parameter(pair[0],pair[1])
 if not busy and not pending.is_empty():build(pending[0])
func build(cell: Vector2i):
 busy=true
 var viewport=SubViewport.new();viewport.name="TerrainBake";viewport.size=Vector2i(CELL+2,CELL+2)
 viewport.transparent_bg=true;viewport.disable_3d=true;viewport.world_2d=bake_world;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;add_child(viewport)
 var at=Vector2(cell)*CELL-Vector2.ONE
 var quad=Sprite2D.new();quad.texture=white;quad.centered=false;quad.position=at;quad.scale=Vector2.ONE*(CELL+2)
 var mat=world.environment.terrain_material.duplicate();mat.set_shader_parameter("cache_mask30",true)
 for key in ["clock_time","wetness","snow","dust","blood_moon29"]:mat.set_shader_parameter(key,0.0)
 quad.material=mat;viewport.add_child(quad)
 var camera=Camera2D.new();camera.position=at+Vector2.ONE*(CELL+2)*.5;viewport.add_child(camera)
 await RenderingServer.frame_post_draw
 finish_build.call_deferred(cell,viewport,quad,camera)
func finish_build(cell: Vector2i,viewport: SubViewport,quad: Sprite2D,camera: Camera2D):
 var at=Vector2(cell)*CELL-Vector2.ONE
 if not is_inside_tree():return
 viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
 var sprite=Sprite2D.new();sprite.texture=viewport.get_texture();sprite.centered=false;sprite.position=at
 sprite.material=runtime_material;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.visible=false;add_child(sprite)
 chunks[cell]={"viewport":viewport,"sprite":sprite,"used":clock};builds+=1
 viewport.remove_child(quad);quad.queue_free();viewport.remove_child(camera);camera.queue_free()
 if chunks.size()>LIMIT:
  var oldest=cell
  for c in chunks:
   if chunks[c].used<chunks[oldest].used:oldest=c
  chunks[oldest].sprite.queue_free();chunks[oldest].viewport.queue_free();chunks.erase(oldest)
 busy=false
