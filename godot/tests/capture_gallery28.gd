extends SceneTree
class Gallery extends Node2D:
 func _draw():
  draw_rect(Rect2(0,0,1200,960),Color("18212b"))
  var font=preload("res://assets/mossfield-font.ttf")
  draw_string(font,Vector2(24,30),"阴诡世界 · Q版怪物图鉴 / v0.28",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ddceaa"))
  var kinds=YinMonsterArt.metadata().keys()
  for i in range(kinds.size()):
   var at=Vector2(120+(i%5)*238,200+(i/5)*175)
   draw_set_transform(at,0,Vector2(2,2))
   var pose=YinActorArt.enemy_pose(kinds[i],Vector2.LEFT,0,false,false,false)
   YinActorArt.draw_enemy(self,kinds[i],pose,[],0,false,false,Color.WHITE)
   draw_set_transform(Vector2.ZERO)
   draw_string(font,at+Vector2(-65,21),YinBalance.MONSTERS[kinds[i]].name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("b5b1a7"))
func _initialize():call_deferred("run")
func run():
 var view=SubViewport.new();view.size=Vector2i(1200,960);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 view.add_child(Gallery.new())
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 var result=view.get_texture().get_image().save_png(folder.path_join("monster-roster.png"))
 print("GALLERY27 ",result);view.queue_free();await process_frame;quit(result)
