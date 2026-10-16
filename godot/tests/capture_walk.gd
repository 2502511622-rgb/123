# Controlled close-up of the actual FarmPlayer renderer, followed by normal input in-world.
extends SceneTree
class Ground extends Node2D:
 func _draw():
  draw_rect(Rect2(0,0,1024,600),Color("1c252c"))
  var font=ThemeDB.fallback_font
  draw_string(font,Vector2(22,28),"Actual player renderer / 0.25x foot close-up / 4 directions, both appearances",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ddd7c5"))
  for row in range(2):
   for col in range(4):
    var x=128+col*256;var y=272+row*280
    for k in range(-4,5):draw_line(Vector2(x+k*20,y-12),Vector2(x+k*20,y+12),Color("3b484c"))
    draw_line(Vector2(x-100,y),Vector2(x+100,y),Color("71807c"),2)
    draw_string(font,Vector2(x-32,y+36),["DOWN","UP","LEFT","RIGHT"][col],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c8c0aa"))
var folder: String
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");OS.set_environment("YINTIAN_SILENT","1");folder=OS.get_environment("YINTIAN_CAPTURE_DIR");call_deferred("run")
func frames(n=2):
 for i in range(n):await physics_frame
func shot(viewport: Viewport,name_value: String):
 await process_frame;await RenderingServer.frame_post_draw
 viewport.get_texture().get_image().save_png(folder.path_join(name_value+".png"))
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 var viewport=SubViewport.new();viewport.size=Vector2i(1024,600);viewport.world_2d=World2D.new();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var ground=Ground.new();viewport.add_child(ground)
 var players=[]
 for body in range(2):
  for row in range(4):
   var actor=load("res://scenes/actors/player.tscn").instantiate()
   actor.set_physics_process(false);actor.get_node("Camera2D").enabled=false
   actor.position=Vector2(128+row*256,272+body*280);actor.scale=Vector2(4,4)
   actor.appearance.body=body;actor.held_item="sword"
   actor.facing=[Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT][row];actor.visual_facing=actor.facing
   actor.velocity=actor.facing*FarmPlayer.SPEED;actor.gait_blend=1
   viewport.add_child(actor);actor.set_physics_process(false)
   actor.weapon_layer.hide() # Unobstructed foot close-up; world segment keeps weapons.
   players.append(actor)
 for frame in range(48):
  for actor in players:
   actor.animation_time=frame/48.0*.5
   actor.weapon_layer.show_behind_parent=actor.visual_facing.y<0
   actor.queue_redraw();actor.weapon_layer.queue_redraw()
  await frames(1);await shot(viewport,"walk-%03d"%frame)
 viewport.queue_free();await frames()
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(8);game.close_modal()
 var camera=game.player.get_node("Camera2D");camera.zoom=Vector2(2.4,2.4)
 game.player.appearance.hair=6;YinAppearance.configure(game.player.material,game.player.appearance)
 for direction in ["move_right","move_left","move_down","move_up"]:
  Input.action_press(direction)
  var start: Vector2=game.player.position
  for i in range(30):
   await frames(2)
   if i%2==0:await shot(root,"world-%s-%02d"%[direction,i])
  Input.action_release(direction)
  await frames(8)
  print("WALK input=",direction," displacement=",game.player.position.distance_to(start))
 game.queue_free();await frames();quit()
