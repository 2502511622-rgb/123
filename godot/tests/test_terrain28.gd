extends SceneTree
var game
var checks=0
var failures=0
func _initialize():OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("TERRAIN28 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func difference(a: Color,b: Color) -> float:return (absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3
func run():
 if DisplayServer.get_name()=="headless":print("TERRAIN28 requires graphical GPU readback");quit(1);return
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(6);game.close_modal()
 for index in range(4):
  var origin: Vector2=[Vector2(2400,1600),Vector2(5440,1600),Vector2(2400,4160),Vector2(5440,4160)][index]
  var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(320,320);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
  var image=Image.create(1,1,false,Image.FORMAT_RGBA8);image.fill(Color.WHITE)
  var sprite=Sprite2D.new();sprite.centered=false;sprite.texture=ImageTexture.create_from_image(image);sprite.position=origin;sprite.scale=Vector2(320,320)
  sprite.material=game.world.environment.terrain_material.duplicate();sprite.material.set_shader_parameter("wetness",0.0);sprite.material.set_shader_parameter("snow",0.0);sprite.material.set_shader_parameter("dust",0.0)
  view.add_child(sprite)
  var camera=Camera2D.new();camera.position=origin+Vector2(160,160);view.add_child(camera)
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  var pixels=view.get_texture().get_image();var edge=0.0;var nearby=0.0
  for y in range(16,304):
   edge+=difference(pixels.get_pixel(159,y),pixels.get_pixel(160,y))
   for x in [144,148,152,156,164,168,172,176]:nearby+=difference(pixels.get_pixel(x-1,y),pixels.get_pixel(x,y))/8
  edge/=288;nearby/=288
  check(pixels.get_pixel(80,80).a>.99 and pixels.get_pixel(80,80).r>.03,"actual ground shader renders region "+str(index))
  check(edge<nearby*2.5+.02,"no high-contrast grid-boundary seam region %d edge=%.4f local=%.4f"%[index,edge,nearby])
  var folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
  if folder!="":DirAccess.make_dir_recursive_absolute(folder);pixels.save_png(folder.path_join("continuous-ground-"+str(index)+".png"))
  view.queue_free();await frames(1)
 game.queue_free();await frames()
 print("TERRAIN28 RESULT ",checks," checks ",failures," failures");quit(1 if failures else 0)
